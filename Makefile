VERSION := $(shell git describe --match 'v[0-9].[0-9]' --tags --long | grep -Eo 'v[0-9]+\.[0-9]+-[0-9]+' | tr - . | cut -c 2-)
DEBFACTORY := DebFactory

README: pp
	pod2text pp >README
	git add README
	git commit -m 'Auto update from POD'

commit: README
	git commit -a

push: commit
	git push

version:
	echo "VERSION IS $(VERSION)"

clean:
	-rm -r $(DEBFACTORY)

deb:
	mkdir $(DEBFACTORY)
	mkdir -p $(DEBFACTORY)/usr/bin $(DEBFACTORY)/usr/share/man
	cp -a pp $(DEBFACTORY)/usr/bin
	cp -ar Distro/DEBIAN $(DEBFACTORY)
	perl -pi -e 's/\$$VERSION/$(VERSION)/' $(DEBFACTORY)/DEBIAN/control
	pod2man pp $(DEBFACTORY)/usr/share/man/pp.1
	gzip -f $(DEBFACTORY)/usr/share/man/pp.1
	dpkg -b $(DEBFACTORY) pp_$(VERSION).deb
	mv pp_$(VERSION).deb Distro
	make clean
