PREFIX ?= /usr

all:
	@echo Run \'make install\' to install bib.awk.

install:
	@mkdir -p $(DESTDIR)$(PREFIX)/bin
	@cp -p bib.awk $(DESTDIR)$(PREFIX)/bin/bib.awk
	@cp -p bib_tui.awk $(DESTDIR)$(PREFIX)/bin/bib_tui.awk
	@chmod 755 $(DESTDIR)$(PREFIX)/bin/bib.awk
	@chmod 755 $(DESTDIR)$(PREFIX)/bin/bib_tui.awk

install-bib:
	@mkdir -p $(DESTDIR)$(PREFIX)/bin
	@cp -p bib.awk $(DESTDIR)$(PREFIX)/bin/bib.awk
	@chmod 755 $(DESTDIR)$(PREFIX)/bin/bib.awk

install-tui:
	@mkdir -p $(DESTDIR)$(PREFIX)/bin
	@cp -p bib_tui.awk $(DESTDIR)$(PREFIX)/bin/bib_tui.awk
	@chmod 755 $(DESTDIR)$(PREFIX)/bin/bib_tui.awk

uninstall:
	@rm -rf $(DESTDIR)$(PREFIX)/bin/bib.awk
	@rm -rf $(DESTDIR)$(PREFIX)/bin/bib_tui.awk
