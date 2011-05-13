#! /bin/bash
#
# Overide RPM directories to be current dir
#

mkdir -p rpmbuild/BUILD rpmbuild/RPMS rpmbuild/SOURCES rpmbuild/SPECS rpmbuild/SRPMS
cp deltacloud-condor deltacloud-condor-0.3.0.gem deltacloudd-condor rpmbuild/SOURCES
rpmbuild --define '_rpmdir '$PWD --define '_sourcedir '$PWD/rpmbuild/SOURCES --buildroot $PWD/rpmbuild/BUILD -ba deltacloud-condor.spec
rm -rf rpmbuild
