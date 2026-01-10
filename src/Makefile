DESTDIR ?=

.PHONY: install uninstall

install:
	sudo install -v -Dm 755 ./99duress/module-setup.sh -t $(DESTDIR)/usr/lib/dracut/modules.d/99duress/
	sudo install -v -Dm 755 ./99duress/cryptsetup-duress-hook.sh -t $(DESTDIR)/usr/lib/dracut/modules.d/99duress/
	sudo install -v -Dm 644 ./99duress/cryptsetup-duress.service -t $(DESTDIR)/usr/lib/dracut/modules.d/99duress/
	sudo install -v -Dm 755 ./duressctl -t $(DESTDIR)/usr/bin/

uninstall:
	sudo rm -rf $(DESTDIR)/usr/lib/dracut/modules.d/99duress \
				$(DESTDIR)/usr/bin/duressctl \
				$(DESTDIR)/etc/dracut-cryptsetup-duress-signals \
				$(DESTDIR)/etc/dracut-cryptsetup-duress-mode
