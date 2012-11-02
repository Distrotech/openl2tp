Summary: An L2TP client/server, designed for VPN use.
Name: openl2tp
Version: %%VER%%
Release: %%REL%%%{?dist}
License: GPL
Group: System Environment/Daemons
URL: ftp://downloads.sourceforge.net/projects/openl2tp/%{name}-%{version}.tar.gz
Source0: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}
Requires: ppp == %%PPPVER%%, readline >= 4.2, portmap
ExclusiveOS: Linux

BuildRequires: ppp == %%PPPVER%%, readline-devel >= 4.2, glibc >= 2.4, flex, bison, kernel-headers >= 2.6.23

%define needs_pppd_plugins %(test %%PPPVER%% == 2.4.5 && echo 0 || echo 1)

%description
OpenL2TP is a complete implementation of RFC2661 - Layer Two Tunneling
Protocol Version 2, able to operate as both a server and a client. It
is ideal for use as an enterprise L2TP VPN server, supporting more
than 100 simultaneous connected users. It may also be used as a client
on a home PC or roadwarrior laptop.

OpenL2TP has been designed and implemented specifically for Linux. It
consists of

- a daemon, openl2tpd, handling the L2TP control protocol exchanges
  for all tunnels and sessions

- a plugin for pppd to allow its PPP connections to run over L2TP
  sessions

- a Linux kernel driver for efficient datapath (integrated into the
  standard kernel from 2.6.23).

- a command line application, l2tpconfig, for management.

%package devel
Summary: OpenL2TP support files for plugin development
Group: Development/Libraries

%description devel
This package contains support files for building plugins for OpenL2TP,
or applications that use the OpenL2TP APIs.

%if %needs_pppd_plugins
%package ppp
Requires: openl2tp
Summary: OpenL2TP support files for pppd
Group: System Environment/Libraries

%description ppp
This package contains pppd plugins for OpenL2TP. Not
required if using pppd 2.4.5 or later, since these plugins were
integrated into ppp-2.4.5.
%endif

%prep
%setup -q

%build
make OPT_CFLAGS="$RPM_OPT_FLAGS" \
	PPPD_VERSION=%%PPPVER%%

%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT \
	PPPD_VERSION=%%PPPVER%%

%{__mkdir} -p $RPM_BUILD_ROOT/etc/rc.d/init.d $RPM_BUILD_ROOT/%{_sysconfdir}/sysconfig
%{__cp} -f etc/rc.d/init.d/openl2tpd $RPM_BUILD_ROOT%{_sysconfdir}/rc.d/init.d/openl2tpd
%{__cp} -f etc/sysconfig/openl2tpd $RPM_BUILD_ROOT%{_sysconfdir}/sysconfig/openl2tpd

%clean
if [ "$RPM_BUILD_ROOT" != `echo $RPM_BUILD_ROOT | sed -e s/openl2tp-//` ]; then
	rm -rf $RPM_BUILD_ROOT
fi

%files
%defattr(-,root,root,-)
%doc README LICENSE
%dir %{_libdir}/openl2tp
%{_bindir}/l2tpconfig
%{_sbindir}/openl2tpd
%{_libdir}/openl2tp/ppp_null.so
%{_libdir}/openl2tp/ppp_unix.so
%{_libdir}/openl2tp/ipsec.so
%{_libdir}/openl2tp/event_sock.so
%{_mandir}/man1/l2tpconfig.1.gz
%{_mandir}/man4/openl2tp_rpc.4.gz
%{_mandir}/man5/openl2tpd.conf.5.gz
%{_mandir}/man7/openl2tp.7.gz
%{_mandir}/man8/openl2tpd.8.gz
%{_initrddir}/openl2tpd
%config %{_sysconfdir}/sysconfig/openl2tpd

%files devel
%defattr(-,root,root,-)
%doc plugins/README doc/README.event_sock
%{_libdir}/openl2tp/l2tp_rpc.x
%{_libdir}/openl2tp/l2tp_event.h
%{_libdir}/openl2tp/event_sock.h

%if %needs_pppd_plugins
%files ppp
%defattr(-,root,root,-)
%{_libdir}/pppd/%%PPPVER%%/openl2tp.so
%{_libdir}/pppd/%%PPPVER%%/pppol2tp.so
%endif

%changelog

* %%DATE%% %%AUTHOR%% - %%VER%%

  Built from upstream version.
