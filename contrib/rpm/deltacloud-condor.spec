%global app_root %{_datadir}/%{name}

Summary: Deltacloud REST API for Condor Cloud
Name: deltacloud-condor
Version: 0.3.0
Release: 3%{?dist}
Group: Development/Languages
License: ASL 2.0 and MIT
URL: http://incubator.apache.org/deltacloud
Source0: http://gems.rubyforge.org/gems/%{name}-%{version}.gem
Source1: deltacloudd-condor
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires: rubygems
Requires: ruby(abi) = 1.8
Requires: rubygem(haml)
Requires: rubygem(sinatra)
Requires: rubygem(rack)
Requires: rubygem(thin)
Requires: rubygem(net-ssh)
Requires: rubygem(json)
Requires: rubygem(rack-accept)
Requires: rubygem(nokogiri)
Requires: rubygem(uuid)
Requires: rubygem(rest-client)
Requires(post):   chkconfig
Requires(preun):  chkconfig
Requires(preun):  initscripts
Requires(postun): initscripts
#BuildRequires: rubygems
#BuildRequires: ruby(abi) = 1.8
#BuildRequires: rubygem(rake)
BuildArch: noarch

%description
The Deltacloud API is built as a service-based REST API.
You do not directly link a Deltacloud library into your program to use it.
Instead, a client speaks the Deltacloud API over HTTP to a server
which implements the REST interface. This is Condor driver enabled
version

%package doc
Summary: Documentation for %{name}
Group: Documentation
Requires:%{name} = %{version}-%{release}

%description doc
Documentation for %{name}

%prep
%setup -q -c -T 
gem unpack -V --target=%{_builddir} %{SOURCE0}

%build

%install
mkdir -p %{buildroot}%{app_root}
mkdir -p %{buildroot}%{_initddir}
mkdir -p %{buildroot}%{_bindir}
cp -r %{_builddir}/%{name}-%{version}/* %{buildroot}%{app_root}
mv %{buildroot}%{app_root}/support/fedora/%{name} %{buildroot}%{_initddir}
install -m 0755 %{SOURCE1} %{buildroot}%{_bindir}/deltacloudd-condor
find %{buildroot}%{app_root}/lib -type f | xargs chmod -x
chmod 0755 %{buildroot}%{_initddir}/%{name}
chmod 0755 %{buildroot}%{app_root}/bin/deltacloudd-condor
rm -rf %{buildroot}%{app_root}/support
rdoc --op %{buildroot}%{_defaultdocdir}/%{name}

%clean

%post
# This adds the proper /etc/rc*.d links for the script
/sbin/chkconfig --add %{name}

%preun
if [ $1 -eq 0 ] ; then
    /sbin/service %{name} stop >/dev/null 2>&1
    /sbin/chkconfig --del %{name}
fi

%postun
if [ "$1" -ge "1" ] ; then
    /sbin/service %{name} condrestart >/dev/null 2>&1 || :
fi

%files
%defattr(-, root, root, -)
%{_initddir}/%{name}
%{_bindir}/deltacloudd-condor
%dir %{app_root}/
%{app_root}/bin
%{app_root}/config.ru
%{app_root}/*.rb
%{app_root}/views
%{app_root}/lib
%{app_root}/config
%dir %{app_root}/public
%{app_root}/public/images
%{app_root}/public/stylesheets
%{app_root}/public/favicon.ico
%doc %{app_root}/DISCLAIMER
%doc %{app_root}/NOTICE
%doc %{app_root}/LICENSE
# MIT
%{app_root}/public/javascripts

%files doc
%defattr(-, root, root, -)
%{_defaultdocdir}/%{name}
%{app_root}/tests
%{app_root}/deltacloud-core.gemspec
%{app_root}/Rakefile

%changelog
* Thu May 19 2011 Michal Fojtik <mfojtik@redhat.com> - 0.3.0-3
- Fixed Rakefile to apply new instance UI patch correctly
- Fixed bug in Condor cloud driver

* Mon May 16 2011 Michal Fojtik <mfojtik@redhat.com> - 0.3.0-2
- Fixed uuid dependency
- Fixed wrong deltacloudd-condor file
- Added HOST option for initializer script

* Fri Apr 29 2011 Michal Fojtik <mfojtik@redhat.com> - 0.3.0-1
- Initial import of Deltacloud Condor

* Tue Mar 15 2011 Michal Fojtik <mfojtik@redhat.com> - 0.2.0-4
- Added missing runtime dependencies

* Mon Jan 31 2011 Michal Fojtik <mfojtik@redhat.com> - 0.2.0-3
- Removed cache and specification
- Added Sinatra to build dependecies

* Mon Jan 31 2011 Michal Fojtik <mfojtik@redhat.com> - 0.2.0-2
- Moved application to app_root (https://fedoraproject.org/wiki/Packaging_talk:Ruby#Applications)

* Mon Jan 31 2011 Michal Fojtik <mfojtik@redhat.com> - 0.2.0-1
- Initial package
