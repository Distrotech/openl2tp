# BEGIN CONFIGURABLE SETTINGS

# Compile-time features
L2TP_FEATURE_LAC_SUPPORT=	y
L2TP_FEATURE_LNS_SUPPORT=	y
L2TP_FEATURE_RPC_MANAGEMENT=	n
L2TP_FEATURE_LAIC_SUPPORT=	y
L2TP_FEATURE_LAOC_SUPPORT=	y
L2TP_FEATURE_LNIC_SUPPORT=	y
L2TP_FEATURE_LNOC_SUPPORT=	y
L2TP_FEATURE_LOCAL_CONF_FILE=	y
#L2TP_FEATURE_LOCAL_STAT_FILE=	y

# Define USE_DMALLOC to enable dmalloc memory debugging
# USE_DMALLOC=		y

# Define to include test code. This must be defined to run the
# regression tests
# L2TP_TEST=		y

# Define to compile in debug code. Also makes default trace flags
# enable all messages
# L2TP_DEBUG=		y

# Use asynchronous RPC requests where appropriate
# Affects only L2TP-PPP-IPPOOL interfaces, not management interfaces.
L2TP_USE_ASYNC_RPC=	y

# Build for UML environment?
# UML_TARGET=		y

# Location of shared libs. This is usually /usr/lib, but can be
# /usr/lib32 or /usr/lib64 on 64-bit multi-arch systems. On 64-bit
# systems which don't have 32-bit multi-arch libs installed, the
# standard says build with /usr/lib. But Fedora uses /usr/lib64. We
# try to handle these cases by deriving the CPU architecture
# name. Things are made more complicated by the fact that the CPU
# architecture is output by either uname -m or uname -p, depending on
# uname version. Override SYS_LIBDIR from the command line when
# necessary.
SYS_LIBDIR=/usr/lib
ifeq ($(CROSS_COMPILE),)
 ifeq ($(strip $(wildcard /etc/debian_version*)),)
  ifeq ($(shell uname -p),x86_64)
  SYS_LIBDIR=/usr/lib64
  else
   ifeq ($(shell uname -m),x86_64)
   SYS_LIBDIR=/usr/lib64
   endif
  endif
 endif
endif

# Points to pppd install.  By default, pppd headers are assumed to be
# in the pppd subdirectory of the compiler's default search path
# (e.g. /usr/include/pppd). but can be pointed to another directory if
# desired.
PPPD_VERSION=		2.4.5
# PPPD_INCDIR=		/usr/include/pppd
# PPPD_LIBDIR=		$(SYS_LIBDIR)/pppd/$(PPPD_VERSION)

# Points to readline install root. READLINE_DIR should have lib/ &
# include/ subdirs If not defined, readline is assumed to be installed
# in the standard places that the compiler looks.
READLINE_DIR=		

# For cross-compiling
CROSS_COMPILE=

# END CONFIGURABLE SETTINGS

AS		= $(CROSS_COMPILE)as
LD		= $(CROSS_COMPILE)ld
CC		= $(CROSS_COMPILE)gcc
AR		= $(CROSS_COMPILE)ar
NM		= $(CROSS_COMPILE)nm
STRIP		= $(CROSS_COMPILE)strip
INSTALL		= $(CROSS_COMPILE)install

ifneq ($(READLINE_DIR),)
READLINE_LDFLAGS=	-L $(READLINE_DIR)/lib
READLINE_CFLAGS=	-I $(READLINE_DIR)/include
endif

export PPPD_VERSION PPPD_SRCDIR PPPD_LIBDIR READLINE_LDFLAGS READLINE_CFLAGS
export CROSS_COMPILE AS LD CC AR NM STRIP OBJCOPY OBJDUMP INSTALL UML_TARGET
export DESTDIR SYS_LIBDIR

# Feature options are exported to sub-makes
export L2TP_FEATURE_LAC_SUPPORT
export L2TP_FEATURE_LNS_SUPPORT
export L2TP_FEATURE_RPC_MANAGEMENT
export L2TP_FEATURE_LAIC_SUPPORT
export L2TP_FEATURE_LAOC_SUPPORT
export L2TP_FEATURE_LNIC_SUPPORT
export L2TP_FEATURE_LNOC_SUPPORT
export L2TP_FEATURE_LOCAL_CONF_FILE
export L2TP_FEATURE_LOCAL_STAT_FILE

# Build pppd dir only if ppp version is earlier than 2.4.5 since the
# openl2tp plugins were integrated in ppp-2.4.5.
PPPD_SUBDIR=pppd
ifeq ($(PPPD_VERSION),2.4.5)
PPPD_SUBDIR=
endif

SUBDIRS=		usl cli plugins $(PPPD_SUBDIR) test doc

.PHONY:			$(SUBDIRS:%=subdir-%)

L2TP_RPC_STEM=		l2tp_rpc

RPC_FILES=		$(L2TP_RPC_STEM).h
ifeq ($(L2TP_FEATURE_RPC_MANAGEMENT),y)
RPC_FILES+=		$(L2TP_RPC_STEM)_server.c $(L2TP_RPC_STEM)_client.c $(L2TP_RPC_STEM)_xdr.c
endif

ifeq ($(L2TP_FEATURE_LOCAL_CONF_FILE),y)
PARSE_FILES=		l2tp_config_token.c l2tp_config_parse.c l2tp_config_parse.h
endif

L2TPD_SRCS.c=		l2tp_main.c l2tp_common.c l2tp_avp.c l2tp_packet.c \
			l2tp_network.c l2tp_tunnel.c l2tp_peer.c l2tp_transport.c \
			l2tp_session.c l2tp_ppp.c \
			l2tp_plugin.c l2tp_event.c l2tp_test.c md5.c
ifeq ($(L2TP_FEATURE_RPC_MANAGEMENT),y)
L2TPD_SRCS.c+=		l2tp_api.c
endif
ifeq ($(L2TP_FEATURE_LOCAL_STAT_FILE),y)
L2TPD_SRCS.c+=		l2tp_statusfile.c
endif

L2TPD_SRCS.h=		l2tp_api.h l2tp_avp.h l2tp_private.h md5.h

ifeq ($(L2TP_TEST),y)
CPPFLAGS.l2tptest=	-DL2TP_TEST
endif

L2TPCONFIG_SRCS.c=	l2tp_config.c

L2TPD_SRCS.o=		$(L2TPD_SRCS.c:%.c=%.o)
ifeq ($(L2TP_FEATURE_RPC_MANAGEMENT),y)
L2TPD_SRCS.o+=		$(L2TP_RPC_STEM)_server.o $(L2TP_RPC_STEM)_xdr.o
endif
L2TPCONFIG_SRCS.o=	$(L2TPCONFIG_SRCS.c:%.c=%.o) $(L2TP_RPC_STEM)_client.o $(L2TP_RPC_STEM)_xdr.o

L2TPD_SRCS.o+=		$(filter-out l2tp_config_parse.h, $(PARSE_FILES:%.c=%.o))

ifeq ($(USE_DMALLOC),y)
CPPFLAGS.dmalloc=	-DL2TP_DMALLOC
LIBS.dmalloc=		-ldmalloc
export USE_DMALLOC
endif

CPPFLAGS=		$(CPPFLAGS.l2tptest) $(CPPFLAGS-y)
CFLAGS=			-I. -Iusl -Icli -isystem include \
				-MMD -Wall -Werror -Wno-strict-aliasing \
				$(CPPFLAGS) $(CPPFLAGS.dmalloc) \
				-DSYS_LIBDIR=$(SYS_LIBDIR)
LDFLAGS.l2tpd=		-Wl,-E -L. -Lusl -lusl -ldl $(LIBS.dmalloc) -lc
LDFLAGS.l2tpconfig=	-Lcli -lcli -lreadline $(LIBS.dmalloc) $(READLINE_LDFLAGS) -lc

OPT_CFLAGS?=		-O

ifeq ($(L2TP_DEBUG),y)
CFLAGS.optimize=	-g
CFLAGS.optimize+=	-DDEBUG
else
CFLAGS.optimize=	$(OPT_CFLAGS)
endif
export CFLAGS.optimize

CFLAGS+=		$(CFLAGS.optimize)

ifeq ($(L2TP_USE_ASYNC_RPC),y)
CPPFLAGS+=		-DL2TP_ASYNC_RPC
endif

ifeq ($(L2TP_FEATURE_RPC_MANAGEMENT),y)
APP=			l2tpconfig
endif

RPCGEN=			rpcgen
RPCGENFLAGS=		-N -M -C -L

.PHONY:			all clean distclean install daemon app test

all:			generated-files daemon $(APP)

daemon:			generated-files $(SUBDIRS:%=subdir-%) openl2tpd

app:			generated-files l2tpconfig

test:			subdir-test
			$(MAKE) -C $@ $(MFLAGS) $@


.PHONY:			$(SUBDIRS:%=subdir-%)

$(SUBDIRS:%=subdir-%):	FORCE
			$(MAKE) -C $(@:subdir-%=%) $(MFLAGS) EXTRA_CFLAGS="$(CPPFLAGS)"

ifeq ($(L2TP_FEATURE_LOCAL_CONF_FILE),y)
# Config file parser
LEX=			flex
YACC=			bison
LDFLAGS.l2tpd+=		-lfl
%.c:	%.l
			$(LEX) -o$@ $<

%.h %.c: %.y
			$(YACC) -d -o l2tp_config_parse.c $<

l2tp_config_token.o:	l2tp_config_token.c
			$(CC) -I. -MMD -w $(CFLAGS.optimize) -c -DYY_NO_UNPUT $<

l2tp_config_parse.o:	l2tp_config_parse.c l2tp_config_parse.h
			$(CC) -I. -MMD -w $(CFLAGS.optimize) -c -DYY_NO_UNPUT $<
endif

# Compile without -Wall because rpcgen-generated code is full of warnings.
%_xdr.o:		%_xdr.c
			$(CC) -I. -MMD -w $(CFLAGS.optimize) -c $(CPPFLAGS) $<

%_client.o:		%_client.c
			$(CC) -I. -MMD -w $(CFLAGS.optimize) -c $(CPPFLAGS) $<

%_server.o:		%_server.c
			$(CC) -I. -MMD -w $(CFLAGS.optimize) -c $(CPPFLAGS) $<

%_xdr.c:		%.x
			-$(RM) $@
			$(RPCGEN) $(RPCGENFLAGS) -c -o $@ $<

%_server.c:		%.x
			-$(RM) $@ $@.tmp
			$(RPCGEN) $(RPCGENFLAGS) -m -o $@.tmp $<
			cat $@.tmp | sed -e 's/switch (rqstp->rq_proc) {/if (l2tp_api_rpc_check_request(transp) < 0) return; switch (rqstp->rq_proc) {/' > $@

%_client.c:		%.x
			-$(RM) $@
			$(RPCGEN) $(RPCGENFLAGS) -l -o $@ $<

%.h:			%.x
			-$(RM) $@
			$(RPCGEN) $(RPCGENFLAGS) -h -o $@ $<

.PHONY:			generated-files plugins clean distclean

generated-files:	$(RPC_FILES) $(PARSE_FILES) l2tp_options.h

clean:
			@for d in $(SUBDIRS); do $(MAKE) -C $$d $(MFLAGS) $@; if [ $$? -ne 0 ]; then exit 1; fi; done
			-$(MAKE) -C redhat $(MFLAGS) $@
			-$(RM) $(L2TPD_SRCS.o) $(L2TPCONFIG_SRCS.o) openl2tpd l2tpconfig $(RPC_FILES)
			-$(RM) l2tp_options.h l2tp_options.h.tmp
			-$(RM) l2tp_config_parse.c l2tp_config_parse.h l2tp_config_token.c
			-$(RM) $(wildcard *.d)
			-$(RM) $(wildcard l2tp_*rpc_*.tmp)

distclean:		clean
			-$(RM) TAGS

TAGS:
			@for d in $(SUBDIRS); do $(MAKE) -C $$d $(MFLAGS) $@; done
			etags $(wildcard *.c) $(wildcard *.h)

openl2tpd:		$(L2TPD_SRCS.o)
			$(CC) -o $@ $^ $(LDFLAGS.l2tpd)

l2tpconfig:		$(L2TPCONFIG_SRCS.o)
			$(CC) -o $@ $^ $(LDFLAGS.l2tpconfig)

%.o:	%.c
			$(CC) -c $(CFLAGS) $< -o $@

l2tp_options.h:	FORCE
	@rm -f $@.tmp
	@echo '/* This file is auto-generated. DO NOT EDIT. */' >> $@.tmp
	@echo '#ifndef L2TP_OPTIONS_H' >> $@.tmp
	@echo '#define L2TP_OPTIONS_H' >> $@.tmp
	@echo >> $@.tmp
ifeq ($(L2TP_FEATURE_LOCAL_CONF_FILE),y)
	@echo '#define L2TP_FEATURE_LOCAL_CONF_FILE' >> $@.tmp
endif
ifeq ($(L2TP_FEATURE_LOCAL_STAT_FILE),y)
	@echo '#define L2TP_FEATURE_LOCAL_STAT_FILE' >> $@.tmp
endif
ifeq ($(L2TP_FEATURE_LAC_SUPPORT),y)
	@echo '#define L2TP_FEATURE_LAC_SUPPORT' >> $@.tmp
endif
ifeq ($(L2TP_FEATURE_LNS_SUPPORT),y)
	@echo '#define L2TP_FEATURE_LNS_SUPPORT' >> $@.tmp
endif
ifeq ($(L2TP_FEATURE_LAIC_SUPPORT),y)
	@echo '#define L2TP_FEATURE_LAIC_SUPPORT' >> $@.tmp
endif
ifeq ($(L2TP_FEATURE_LAOC_SUPPORT),y)
	@echo '#define L2TP_FEATURE_LAOC_SUPPORT' >> $@.tmp
endif
ifeq ($(L2TP_FEATURE_LNIC_SUPPORT),y)
	@echo '#define L2TP_FEATURE_LNIC_SUPPORT' >> $@.tmp
endif
ifeq ($(L2TP_FEATURE_LNOC_SUPPORT),y)
	@echo '#define L2TP_FEATURE_LNOC_SUPPORT' >> $@.tmp
endif
ifeq ($(L2TP_FEATURE_RPC_MANAGEMENT),y)
	@echo '#define L2TP_FEATURE_RPC_MANAGEMENT' >> $@.tmp
endif
	@echo >> $@.tmp
	@echo '#endif' >> $@.tmp
	@if [ -e $@ ]; then \
		diff -q $@ $@.tmp > /dev/null ;\
		if [ $$? -ne 0 ]; then \
			mv $@.tmp $@ ;\
		fi ;\
	else \
		mv $@.tmp $@ ;\
	fi

.PHONY:			all install-all install-daemon install-app

install:		install-all

install-all:		all install-daemon install-app

install-daemon:
			@for d in $(filter-out usl,$(SUBDIRS)); do $(MAKE) -C $$d $(MFLAGS) EXTRA_CFLAGS="$(CPPFLAGS)" install; if [ $$? -ne 0 ]; then exit 1; fi; done
			$(INSTALL) -d $(DESTDIR)/usr/sbin
			$(INSTALL) openl2tpd $(DESTDIR)/usr/sbin

install-app:
			$(INSTALL) -d $(DESTDIR)/usr/bin
ifeq ($(L2TP_FEATURE_RPC_MANAGEMENT),y)
			$(INSTALL) l2tpconfig $(DESTDIR)/usr/bin
endif
			$(INSTALL) -d $(DESTDIR)$(SYS_LIBDIR)/openl2tp
			$(INSTALL) -m 0644 l2tp_rpc.x $(DESTDIR)$(SYS_LIBDIR)/openl2tp/l2tp_rpc.x
			$(INSTALL) -m 0644 l2tp_event.h $(DESTDIR)$(SYS_LIBDIR)/openl2tp/l2tp_event.h

FORCE:

huh:
	@set
	@echo $(_libdir)
	@echo $(LIBDIR)

sinclude		$(wildcard *.d) /dev/null
