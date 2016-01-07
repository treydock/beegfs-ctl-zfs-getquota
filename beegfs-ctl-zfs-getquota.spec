Name:		    beegfs-ctl-zfs-getquota
Version:	  0.0.1
Release:	  1%{?dist}
Summary:	  Collect user and group space usage across a set BeeGFS storage nodes that run ZFS
License:	  Apache-2.0
URL:		    https://github.com/treydock/%{name}
Source0:	  %{name}-%{version}.tar.gz
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

Requires: python-prettytable

%description
This project is intended to allow a method to collect user and group space usage across a set BeeGFS storage nodes that run ZFS.

Currently the data collection method only supports storage systems with a single storage target per storage server.

%prep
%setup -q


%build
make %{?_smp_mflags}


%install
rm -rf %{buildroot}
make install DESTDIR=%{buildroot}


%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%doc README.md
%config %{_sysconfdir}/default/%{name}.conf
%{_sysconfdir}/cron.hourly/beegfs_quota
%{_libexecdir}/%{name}


%changelog
* Mon Dec 14 2015 Trey Dockendorf <treydock@gmail.com> 0.0.1-1
- Initial release
