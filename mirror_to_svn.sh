#!/bin/bash
#
#	Author: Noah Huetter
#	Date: 27.09.2017
#	
#	Clones the git repository $GIT_REP and force pushes it to the $SVN_REP
#	using the username $SVN_USR to authenticate

GIT_REP="https://gitlab.fhnw.ch/noah.huetter/diip"

SVN_REP="https://wi18as33037.adm.ds.fhnw.ch:8443/svn/2017_HS_P5_DIIP/trunk/"
SVN_USR="noah.huetter"

SVN_COMMIT_MSG="Automatic Mirror from gitlab.fhnw.ch repo"

ORIG_PWD="$(pwd)"

cd /tmp
mkdir mirror_to_svn
cd mirror_to_svn/

svn checkout --username $SVN_USR $SVN_REP
git clone $GIT_REP

cd trunk/

rm -rf *
cp -rv ../diip/* .

# add new and modified files
svn add * --force
# remove deleted files
svn st | grep ^! | awk '{print " --force "$2}' | xargs svn rm

svn stat | tee ../svn_mirror_stat.log

# push
svn commit -m "\"$SVN_COMMIT_MSG\""

cd /tmp
rm -rf mirror_to_svn

cd $ORIG_PWD
