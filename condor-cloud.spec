Name: condor-cloud
Summary: Condor Cloud Master Setup
Version: 0.1
Release: 1%{?dist}
License: apache
Group: Applications/System
URL: http://imain.fedorapeople.org/condor_cloud/
Source0: http://imain.fedorapeople.org/condor_cloud/%{name}-%{version}.tar.gz
Requires: condor-vm-gahp >= 7.7.0
Requires: libvirt >= 0.8.8
Requires: deltacloud-core >= 0.3

BuildArch: noarch

%description
Condor Cloud provides an IaaS cloud implementation using Condor and the Deltacloud API.  This package provides a starting configuration for the master condor cloud host.

%package node
Summary: Condor Cloud Node Setup
Requires: condor-vm-gahp >= 7.7.0
Requires: libvirt >= 0.8.8

%description node
Condor Cloud provides an IaaS cloud implementation using Condor and the Deltacloud API.  This package provides a starting configuration for one of multiple nodes in the cloud.

%prep
%setup

%build

%install
%{__mkdir} -p %{buildroot}%{_datadir}/%{name}-doc
%{__mkdir} -p %{buildroot}%{_sysconfdir}/condor/config.d
%{__mkdir} -p %{buildroot}%{_libexecdir}/condor

%{__cp} bash/* %{buildroot}%{_libexecdir}/condor/
%{__cp} config/50condor_cloud.config %{buildroot}%{_sysconfdir}/condor/config.d/
%{__cp} config/50condor_cloud_node.config %{buildroot}%{_sysconfdir}/condor/config.d/
%{__cp} docs/fedora_install.txt %{buildroot}%{_datadir}/%{name}-doc/

%clean
%{__rm} -rf %{buildroot}

%post

%postun

%files
%attr(0644,root,root) %{_datadir}/%{name}-doc/fedora_install.txt
%attr(0644,root,root) %{_sysconfdir}/condor/config.d/50condor_cloud.config 
%attr(0755,root,root) %{_libexecdir}/condor/*

%files node
%attr(0644,root,root) %{_datadir}/%{name}-doc/fedora_install.txt
%attr(0644,root,root) %{_sysconfdir}/condor/config.d/50condor_cloud_node.config 
%attr(0755,root,root) %{_libexecdir}/condor/*

%changelog
* Wed Jul 20 2011 Ian Main <imain@redhat.com> 0.1-1
- Initial packaging.

