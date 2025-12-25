.PHONY: install uninstall

install:
	# Create directory
	sudo mkdir -p /lib/dracut/modules.d/99duress

	# Install SCRIPTS (Executable 755)
	sudo install -v -m 755 ./99duress/module-setup.sh /lib/dracut/modules.d/99duress/
	sudo install -v -m 755 ./99duress/cryptsetup-duress-hook.sh /lib/dracut/modules.d/99duress/

	# Install SERVICE UNIT (Read-Only 644) - FIXES THE WARNING
	sudo install -v -m 644 ./99duress/cryptsetup-duress.service /lib/dracut/modules.d/99duress/

	# Install Helper Tool
	sudo install -v -m 755 ./duressctl -t /usr/bin/

uninstall:
	sudo rm -rf /lib/dracut/modules.d/99duress /usr/bin/duressctl /etc/dracut-cryptsetup-duress-signals /etc/dracut-cryptsetup-duress-mode
