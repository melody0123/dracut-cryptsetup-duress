Name:           dracut-cryptsetup-duress
Version:        0.1.0
Release:        1%{?dist}
Summary:        Dracut module for duress password protection with cryptsetup

License:        GPLv3
URL:            https://github.com/melody0123/dracut-cryptsetup-duress
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
Requires:       dracut
Requires:       cryptsetup

%description
A dracut module that enables a duress password for LUKS encrypted drives.
When the duress password is entered, specific actions (like header destruction) are triggered.

%prep
%setup -q -c

%install
mkdir -p %{buildroot}/usr/lib/dracut/modules.d/99duress
install -v -m 755 src/99duress/module-setup.sh %{buildroot}/usr/lib/dracut/modules.d/99duress/
install -v -m 755 src/99duress/cryptsetup-duress-hook.sh %{buildroot}/usr/lib/dracut/modules.d/99duress/
install -v -m 644 src/99duress/cryptsetup-duress.service %{buildroot}/usr/lib/dracut/modules.d/99duress/
install -v -m 755 src/duressctl -t /usr/bin/

%files
/usr/lib/dracut/modules.d/99duress/*
%doc README.md
%license LICENSE

%post
echo "----------------------------------------------------------------"
echo "Installation successful."
echo "Please run 'dracut -f -v' to regenerate your initramfs."
echo "----------------------------------------------------------------"

%changelog
* Sat Jan 03 2026 Your Name <your.email@example.com> - 0.1.0-1
- Initial release
