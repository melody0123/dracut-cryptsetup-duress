# Dracut Cryptsetup Duress Module

## Project Overview

This project is a Linux kernel `initramfs` module designed to enhance **Full Disk Encryption (FDE)** security. It implements a plausible deniability and emergency data protection protocol using the `dracut` infrastructure.

In high-security environments, standard encryption (data-at-rest protection) protects against theft but may be insufficient if physical security is compromised and the user is coerced into decrypting the device. This module allows the registration of specific "duress" signals. When a duress signal is detected during the early boot stage, the system executes a cryptographic erasure of the LUKS headers. This renders the data permanently inaccessible before any decryption keys can be extracted.

This project serves as a research implementation of **defensive asset protection mechanisms** within the Linux boot process, utilizing `systemd`, kernel keyrings, and LUKS management tools.

## Technical Context & Related Works

The concept of "Emergency Data Protection" is established in mobile security research (e.g., **GrapheneOS**, which supports duress PINs for profile wiping) and desktop privacy tools.
* **Hidden Volumes:** Tools like **VeraCrypt** and **Shufflecake** (Linux) use nested containers to hide data existence.
* **Destructive Wiping:** This project focuses on the *Cryptographic Erasure* approach. By destroying the encryption header, the data remains on the disk but becomes statistically indistinguishable from random noise, effectively preventing recovery even if the correct master key is later obtained.

## Implementation Details

This solution is delivered as a custom **Dracut module**. It integrates into the `initramfs` (initial RAM filesystem) to intercept user input before the root file system is mounted.

### Work Flow

1. System boots. Duress systemd service unit runs before standard `systemd-cryptsetup` service units. Invoke the hook script.
2. The hook script reads the configuration file. Decide the operation mode (see below, Mode Configuration). Show the emergency prompt (indistinguishable from the standard login prompt used by `systemd-cryptsetup`).
3. User types in the password. If password matches any registered emergency signal, emergency data protection protocol is triggered. Boot will fail later. Password will be pushed into the kernel keyring store, regardless of whether it's an emergency signal.
4. Duress systemd service unit exits. Standard `systemd-cryptsetup` service units run. They look into the kernel keyring store and fetch the password pushed by the duress service unit. If password is correct, disk is unlocked and boot proceeds. Otherwise, they may ask the user password again. If multiple passwords are used to unlock different disks, they will be asked in this step. If the data protection protocol was previously triggered, the boot process will fail after this step.

### Architecture

1.  **User-Space Utility (`duressctl`):** A management tool to register duress signal hashes and configure the boot prompt mode (Passphrase vs. TPM).
2.  **Kernel Keyring Hook:** A script that intercepts input using `systemd-ask-password`. It pushes input to the kernel keyring to allow seamless handover to the actual `systemd-cryptsetup` process if the standard password is used.
3.  **Boot Integration:** A systemd service ensures the hook runs prior to the standard decryption target.

### Installation and Uninstallation

#### Manual Install & Uninstall

The project includes a `Makefile` for automated installation of the module and utilities.

```shell
sudo make install
```

For uninstallation, use

```shell
sudo make uninstall
```

#### Package Manager

Packaging is still under development. We plan to support Ubuntu, Fedora and Arch Linux.

**Jan 12, 2026 Update:** 
  * RPM and Pacman packages have been released on GitHub, without signature. Signature will be added in the future. Copr and AUR repositories will also be provided in the future. 
  * Since test did not pass on Ubuntu 24.04 Desktop with Dracut, support for Debian-based distributions is still undergoing development.

**Note:** At this point, the module hasn't been integrated into the initramfs. You need to complete the following configuration steps and regenerate initramfs to complete the integration.

### Usage & Configuration

#### 1. Registering Signals

Use the control utility to hash and store emergency signals. These are stored in the system configuration. The emergency signals are global, applying to all operation modes (see below). Any registered signal typed in the emergency prompt (i.e. password prompt used by this tool) will trigger the emergency data protection protocol.

```shell
sudo duressctl add
```

#### 2. Mode Configuration

The tool currently supports passphrase and TPM2 key binding for `cryptsetup`. In passphrase mode, the emergency data protection protocol executes the `cryptsetup erase` command on all LUKS devices visible to the OS. In TPM2 mode, a custom Storage Key (SK) will be generated to seal the volume master key (VMK) of all LUKS containers visible to the OS. Then the user will be handed over to the standard `systemd-cryptenroll` to bind all LUKS containers to the SK. Note that in this step, the TPM PIN is a normal PIN used to unlock the disk, not emergency signals. Emergency data protection protocol executes the `tpm2_evictcontrol` command on the custom SK.

Since passphrase mode essentially just drops all keyslots in LUKS header, it can be used together with TPM2 mode. The effect is the combination of both. In this operation mode, the TPM PIN prompt will be shown as the emergency prompt.

```shell
sudo duressctl mode passphrase      # passphrase mode
sudo duressctl mode tpm             # tpm mode, only PIN as policy for authentication, no PCR is used
sudo duressctl mode tpm --pcrs 0,7  # tpm mode, with PIN + PCRs #0 and #7 as authentication policy
sudo duressctl mode tpm passphrase  # tpm mode without PCR policy + passphrase mode
```

The configuration process is designed to be interactive, because the tool relies on the standard `systemd-cryptenroll` to bind VMKs to the TPM. This process requires the user to type in the existing passphrase to unlock the container, which is interactive.

To maintain operational security (OpSec), the emergency prompt used by tool is indistinguishable from the standard login prompt used by `systemd-cryptsetup`.

**WARNING:** If you use the TPM2 mode with PCR policy, make sure you have a backup recovery plan (However, the plan should not be setting up another non-TPM bound keyslot, see below, Security Analysis & Limitations). Otherwise, any event that makes the PCRs change (e.g., update UEFI firmware or bootloader) will prevent the TPM from unsealing the VMK.

#### 3. System Integration

Once configured, the `initramfs` image must be regenerated to include the new module and configurations.

```shell
sudo dracut -f -v                      # Fedora Linux
sudo dracut -f -v <path_to_initramfs>  # Arch Linux
```

**Note:** On Arch Linux, you may need to specify the initramfs location.

**Note:** You **must** complete all configuration in order to make `dracut` include this module into initramfs.

## Security Analysis & Limitations

### 1. Pre-Imaging
* **Disk Pre-Imaging:** This protocol defends against *immediate* physical compromise. If it is not configured to operate in TPM2 mode OR there is any other non-TPM bound keyslot, it cannot protect against attacks where an unauthorized actor has already cloned (imaged) the encrypted drive prior to the invocation of the duress protocol. In such cases, the erased header could be restored from the backup image.

* **fTPM NVRAM Pre-Imaging**: Many modern consumer-grade computers utilize Firmware TPMs (fTPM) rather than Discrete TPMs (dTPM), such as AMD Secure Processor (AMD SP, formerly Platform Security Processor, PSP) and Intel Platform Trust Technology (PTT). These implementations typically integrate the TPM logic within the CPU/SoC and utilize the motherboard's SPI Flash (sometimes called BIOS chip) as the TPM NVRAM ([Source 1](https://www.amd.com/en/resources/support-articles/faqs/PA-410.html), [Source 2](https://arxiv.org/abs/2304.14717), [Source 3](https://doc.coreboot.org/soc/amd/psp_integration.html)). However, the contents of the SPI Flash can be cloned using inexpensive external tools, such as a CH341A programmer ([Source](https://www.mr-iot.blog/blog/dumping-firmware-from-spi-flash-chips---ch341a-programmer)). An unauthorized actor can clone the SPI flash beforehand and restore the erased custom SK from the fTPM.
  * **Note:** TPM 2.0 specification mandates that "If a TPM uses external memory for non-volatile storage of TPM state (including seeds and proof values), movement of the TPM state to and from the NV memory constitutes a vendor-defined operation that is allowed by this specification. The protection profile of that TPM should include a description of the protections of that data to ensure confidentiality and integrity of the data and to mitigate against rollback attacks." Consequently, verifying the correct implementation and efficacy of rollback protections in proprietary firmware is difficult. 
  * Mitigation: Use a dTPM with at least Common Criteria (CC) Evaluation Assurance Level 4 with augmentation (EAL4+), which provides "Resistance to physical attack" (FPT_PHP.3). Such dTPM usually has its NVRAM inside the tamper-resistant package. Note that dTPM implementations may be susceptible to bus sniffing attacks (e.g., LPC/SPI interposer) if Parameter Encryption is not enforced during CPU-TPM communication.

### 2. SSD Wear Leveling
On NAND-based storage (SSDs), issuing a header wipe command does not guarantee immediate physical overwriting of the data cells due to wear-leveling algorithms. The controller may mark the old header block as "invalid" and write zeros to a new block. Sophisticated forensic analysis at the controller level could potentially recover the old header before the drive's Garbage Collection (GC) cycle completes.
* *Mitigation Research (Implemented):* Configure the tool works under the TPM2 mode. This binds the LUKS volume master key to the **TPM NVRAM**. Since TPM storage can be reset instantly and reliably, this would bypass SSD wear-leveling concerns. However, this requires that there should be only one keyslot in the LUKS header, and that keyslot is bound to the custom SK generated by `duressctl mode tpm`. Otherwise, an unauthorized actor could compel the victim to reveal the passphrase of the non-TPM volume master key, bypassing the TPM protection.

### 3. Boot Chain Integrity

This tool operates under the assumption that the BIOS/UEFI firmware, bootloader, kernel, and initramfs possess integrity and have not been tampered with. If the boot chain is compromised by an unauthorized actor, the security model fails, as:

  1. A software keylogger could silently record the victim's input.
  2. The duress module code could be identified and disabled during the boot process.
  3. ...

### 4. Post-Unlocking Leakage
It is worth mentioning that this tool can only protect a subject from coercion at boot time. Once the volume is decrypted, this tool provides no further protection against data exfiltration. Examples are:

* **DMA Memory Dump:** If the IOMMU (Input-Output Memory Management Unit) is not strictly configured and victim's machine is running, an external unauthorized device can dump entire memory by manipulating Direct Memory Access (DMA). This dump may contain the Volume Master Key (VMK) residing in RAM. 
* **Cold Boot Memory Dump:** Data may persist in DRAM for several minutes (or longer) after power loss due to remanence effects. An attacker could exploit this window to physically transfer the memory modules to a specialized reader and extract residual data.

### 5. Emergency Shell
If the data protection protocol is triggered, the boot process will fail (as the encrypted volume is no longer accessible), and the system may drop into a `dracut` emergency shell. To prevent unauthorized actors from utilizing this shell to probe the remaining hardware state, it is critical to **lock the root account**.
* *Solution:* Ensure the root is locked in the `/etc/shadow` file included in the initramfs generation.

### 6. Operational Risks
This tool is destructive by design. There is no recovery mechanism once the LUKS header is wiped or SK is dropped from TPM NVRAM. Users are advised to maintain secure, off-site backups if data recovery is required after a false-positive trigger.

### 7. Behavioral Assumptions (Rational Actor Model)
This protocol implements a technical data protection mechanism. It assumes a "rational actor" threat model, where the unauthorized actor's primary goal is data acquisition. The premise is that demonstrating the irretrievable loss of data removes the incentive for continued coercion. However, this tool is strictly a technical control; it cannot mitigate physical safety risks if the unauthorized actor behaves irrationally or punitively following the data loss.

## Known Issues

* **Delayed Input on Arch Linux:** The module is tested on Arch Linux without Plymouth. We noticed that first few characters typed in were not captured. User can determine if the input is captured by seeing if the prompt `(press TAB for no echo)` disappears or not, and if the small dots representing user input show or not.

* **Bug on Ubuntu 24.04:** After switching to Dracut and integrating the module into initramfs, we found that after typing in passphrase, boot process freezed. Root cause is still undergoing investigation.

## Project Roadmap

The primary focus for future development addresses the granularity of the emergency signal.

* **Finer-grained Emergency Signal:**
    Emergency signals are currently global. Any registered signal will trigger the emergency data protection protocol on all LUKS containers. In certain scenarios, a signal tied to a specific LUKS container is desirable, rather than affecting all of them.

    *Community contributions and Pull Requests regarding finer-grained emergency signal are highly encouraged.*

## Legal Disclaimer

### 1. Educational and Defensive Purpose
This software is developed for **educational and research purposes** in the fields of computer security, operating system architecture, and privacy engineering. It is intended to demonstrate methods for asset protection in high-security environments. The author does not condone the use of this software for concealing evidence of illegal activity or obstructing justice.

### 2. No Warranty (GPLv3)
This program is free software: you can redistribute it and/or modify it under the terms of the **GNU General Public License (GPLv3)**. This program is distributed in the hope that it will be useful, but **WITHOUT ANY WARRANTY**; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

### 3. Liability for Data Loss
**WARNING:** The primary function of this software is the **permanent and irretrievable destruction of data access**. The author is not responsible for any data loss, system damage, or operational failures resulting from the use, misuse, or malfunction of this software. Users deploy this tool at their own risk.

### 4. Compliance
Users are responsible for ensuring that their use of this software complies with all applicable local, state, and federal laws, including data retention regulations and export control laws.