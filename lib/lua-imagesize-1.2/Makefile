PACKAGE=lua-imagesize
VERSION=$(shell head -1 Changes | sed 's/ .*//')
RELEASEDATE=$(shell head -1 Changes | sed 's/.* //')
PREFIX=/usr/local
DISTNAME=$(PACKAGE)-$(VERSION)

# The path to where the module's source files should be installed.
LUA_SPATH:=$(shell pkg-config lua5.1 --define-variable=prefix=$(PREFIX) \
                              --variable=INSTALL_LMOD)

all: doc/lua-imagesize.3

doc/lua-imagesize.3: doc/lua-imagesize.pod Changes
	sed -e 's/E<copy>/(c)/g' -e "s/‘/'/g" -e "s/’/'/g" <$< | \
	    pod2man --center="Lua module for getting image sizes" \
	            --name="LUA-IMAGESIZE" --section=3 \
	            --release="$(VERSION)" --date="$(RELEASEDATE)" >$@

test: all
	echo 'lunit.main({...})' | $(VALGRIND) lua -llunit - test/*.lua

install: all
	mkdir -p $(LUA_SPATH)/imagesize
	mkdir -p $(LUA_SPATH)/imagesize/format
	install --mode=644 imagesize.lua $(LUA_SPATH)/
	install --mode=644 imagesize/util.lua $(LUA_SPATH)/imagesize/
	for f in imagesize/format/*.lua; do \
	    install --mode=644 $$f $(LUA_SPATH)/imagesize/format/; \
	done
	mkdir -p $(PREFIX)/share/man/man3
	gzip -c doc/lua-imagesize.3 >$(PREFIX)/share/man/man3/lua-imagesize.3.gz


dist: all
	@if [ -e tmp ]; then \
	    echo "Can't proceed if file 'tmp' exists"; \
	    false; \
	fi
	mkdir -p tmp/$(DISTNAME)
	tar cf - --files-from MANIFEST | (cd tmp/$(DISTNAME) && tar xf -)
	cd tmp && tar cf - $(DISTNAME) | gzip -9 >../$(DISTNAME).tar.gz
	rm -rf tmp

clean:
realclean: clean
	rm -f doc/lua-imagesize.3

.PHONY: all test install dist clean realclean
