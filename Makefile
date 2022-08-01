PREFIX ?= /usr

all:
	@echo Run \'make install\' to install bib.awk.

install:
	@mkdir -p $(DESTDIR)$(PREFIX)/bin
	@cp -p bib.awk $(DESTDIR)$(PREFIX)/bin/bib.awk
	@chmod 755 $(DESTDIR)$(PREFIX)/bin/bib.awk

uninstall:
	@rm -rf $(DESTDIR)$(PREFIX)/bin/bib.awk
