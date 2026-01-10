DESTDIR ?=

.PHONY: install uninstall

install:
	install -v -Dm 755 ./99duress/module-setup.sh -t $(DESTDIR)/usr/lib/dracut/modules.d/99duress/
	install -v -Dm 755 ./99duress/cryptsetup-duress-hook.sh -t $(DESTDIR)/usr/lib/dracut/modules.d/99duress/
	install -v -Dm 644 ./99duress/cryptsetup-duress.service -t $(DESTDIR)/usr/lib/dracut/modules.d/99duress/
	install -v -Dm 644 ../README.md -t $(DESTDIR)/usr/share/doc/dracut-cryptsetup-duress
	install -v -Dm 644 ../LICENSE -t $(DESTDIR)/usr/share/licenses/dracut-cryptsetup-duress
	install -v -Dm 755 ./duressctl -t $(DESTDIR)/usr/bin/

uninstall:
	rm -rf $(DESTDIR)/usr/lib/dracut/modules.d/99duress \
			$(DESTDIR)/usr/share/doc/dracut-cryptsetup-duress \
			$(DESTDIR)/usr/share/licenses/dracut-cryptsetup-duress \
			$(DESTDIR)/usr/bin/duressctl \
			$(DESTDIR)/etc/dracut-cryptsetup-duress-signals \
			$(DESTDIR)/etc/dracut-cryptsetup-duress-mode
