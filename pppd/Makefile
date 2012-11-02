# BEGIN CONFIGURABLE SETTINGS

ifdef PPPD_INCDIR
CFLAGS.pppd=	-I$(PPPD_INCDIR)
endif
ifndef PPPD_LIBDIR
PPPD_LIBDIR=	$(SYS_LIBDIR)/pppd/$(PPPD_VERSION)
endif

# END CONFIGURABLE SETTINGS

CFLAGS	+= $(CFLAGS.optimize) -I../include -I.. \
	$(CFLAGS.pppd) -DHAVE_MULTILINK -fPIC
LDFLAGS	+= -shared

PLUGINS=	pppol2tp.so
PLUGINS+=	openl2tp.so

all:	$(PLUGINS)

pppol2tp.so: pppol2tp.c
	$(CC) -o $@ $(LDFLAGS) $(CFLAGS) -D_linux_=1 $^

openl2tp.so: openl2tp.c
	$(CC) -o $@ $(LDFLAGS) $(CFLAGS) -D_linux_=1 $^

install: pppol2tp.so
	$(INSTALL) -d $(DESTDIR)$(PPPD_LIBDIR)
	$(INSTALL) pppol2tp.so $(DESTDIR)$(PPPD_LIBDIR)
	$(INSTALL) openl2tp.so $(DESTDIR)$(PPPD_LIBDIR)

clean:
	-rm -rf *.o *.so *.d
