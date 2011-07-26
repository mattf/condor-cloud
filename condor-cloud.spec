Name: condor-cloud
Summary: Condor Cloud Master Setup
Version: 0.1
Release: 3%{?dist}
License: ASL 2.0
Group: Applications/System
URL: http://imain.fedorapeople.org/condor_cloud/
Source0: http://imain.fedorapeople.org/condor_cloud/%{name}-%{version}.tar.gz
Requires: condor-vm-gahp >= 7.7.0
Requires: libvirt >= 0.8.8
Requires: deltacloud-core >= 0.3
Requires: qemu-kvm >= 0.14
Conflicts: condor-cloud-node

BuildArch: noarch

%description
Condor Cloud provides an IaaS cloud implementation using Condor and the
Deltacloud API.  This package provides a starting configuration for the
master condor cloud host.

%package node
Summary: Condor Cloud Node Setup
Requires: condor-vm-gahp >= 7.7.0
Requires: libvirt >= 0.8.8
Requires: qemu-kvm >= 0.14
Conflicts: condor-cloud

%description node
Condor Cloud provides an IaaS cloud implementation using Condor and the
Deltacloud API.  This package provides a starting configuration for one
of multiple nodes in the cloud.

%prep
%setup -q

%build

%install
%{__mkdir} -p %{buildroot}%{_datadir}/doc/%{name}
%{__mkdir} -p %{buildroot}%{_sysconfdir}/condor/config.d
%{__mkdir} -p %{buildroot}%{_libexecdir}/condor
%{__mkdir} -p %{buildroot}%{_localstatedir}/lib/condor-cloud/shared_images/
%{__mkdir} -p %{buildroot}%{_localstatedir}/lib/condor-cloud/shared_images/staging
%{__mkdir} -p %{buildroot}%{_localstatedir}/lib/condor-cloud/local_cache/

%{__cp} bash/* %{buildroot}%{_libexecdir}/condor/
%{__cp} config/50condor_cloud.config %{buildroot}%{_sysconfdir}/condor/config.d/
%{__cp} config/50condor_cloud_node.config %{buildroot}%{_sysconfdir}/condor/config.d/
#%{__cp} docs/fedora_install.txt %{buildroot}%{_datadir}/doc/%{name}/

%clean
%{__rm} -rf %{buildroot}

%post

%postun

%files
%doc docs/fedora_install.txt
%config(noreplace) %attr(0644,root,root) %{_sysconfdir}/condor/config.d/50condor_cloud.config 
%attr(0755,root,root) %{_libexecdir}/condor/*
%dir %attr(0755, root, root) %{_localstatedir}/lib/condor-cloud/shared_images/
%dir %attr(0755, root, root) %{_localstatedir}/lib/condor-cloud/shared_images/staging/
%doc COPYING
# Jobs on the local machine will be run as 'condor' as set in deltacloud API.
# Local cache must be writable to job submitter.
%dir %attr(0755, condor, condor) %{_localstatedir}/lib/condor-cloud/local_cache/

%files node
%doc docs/fedora_install.txt
%config(noreplace) %attr(0644,root,root) %{_sysconfdir}/condor/config.d/50condor_cloud_node.config 
%attr(0755,root,root) %{_libexecdir}/condor/*
%dir %attr(0755, root, root) %{_localstatedir}/lib/condor-cloud/shared_images/
%doc COPYING

# Jobs on remote machines are run as 'nobody'.
%dir %attr(0755, nobody, nobody) %{_localstatedir}/lib/condor-cloud/local_cache/

%changelog
* Tue Jul 26 2011 Ian Main <imain@redhat.com> 0.1-3
- Some tweaks as per review.

* Mon Jul 25 2011 Ian Main <imain@redhat.com> 0.1-2
- Change permissions and ownership of cache/shared image dirs.

* Wed Jul 20 2011 Ian Main <imain@redhat.com> 0.1-1
- Initial packaging.

