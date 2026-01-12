Name:           dracut-cryptsetup-duress
Version:        0.1.0
Release:        1%{?dist}
Summary:        A Dracut module for defensive data protection and emergency key management in high-security environments.

License:        GPLv3
URL:            https://github.com/melody0123/dracut-cryptsetup-duress
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
BuildRequires:  make coreutils
Requires:       dracut bash cryptsetup python3 tpm2-tools systemd systemd-udev coreutils keyutils openssl

%description
A dracut module that enables a duress password for LUKS encrypted drives.
When the duress password is entered, specific actions (like keyslot erasure or TPM key eviction) are triggered.

%prep
%setup -q -c

%install
make DESTDIR=%{buildroot} install

%files
/usr/lib/dracut/modules.d/99duress
/usr/bin/duressctl
%doc README.md
%license LICENSE

%changelog
* Sat Jan 12 2026 Chenglong Yu <chenglong.yu.cs@proton.me> - 0.1.0-1
- Initial release
