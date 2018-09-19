#!/usr/bin/env bash

##
## Generates REKALL profile:
##
## (1) Copies current directory to target Linux system (a VM), builds
##     rekall profile, and copies back to host machine.
## (2) Converts profile to JSON format via rekal virtual env
##


VENV=~/.virtualenvs/rekall
LOCAL_REKALL_PROFILES=~/.rekall_profiles
# ssh location: cleaner to pull from the environment
REMOTE_USER=matt
REMOTE_OS=ubuntu
REKALL_TARGET=$REMOTE_USER@ubsrv.local
REKALL_REMOTE_LOC=rekall

KERNEL=`ssh $REKALL_TARGET uname -r`

JSON_PROFILE=$LOCAL_REKALL_PROFILES/$REMOTE_OS-$KERNEL.json

runme() {
    echo "$*"
    $*
}
bob() {
runme scp -rq $PWD $REKALL_TARGET:$REKALL_REMOTE_LOC.tmp

runme ssh -t $REKALL_TARGET \
    "sudo apt install linux-headers-$KERNEL linux-modules-$KERNEL && \
     sudo rm -fr $REKALL_REMOTE_LOC && \
     mv $REKALL_REMOTE_LOC.tmp $REKALL_REMOTE_LOC && \
     cd $REKALL_REMOTE_LOC && sudo make profile && \
     sudo zip $KERNEL.zip module_dwarf.ko /boot/System.map-$KERNEL"

runme scp -rq $REKALL_TARGET:$REKALL_REMOTE_LOC/$KERNEL.zip /tmp
}


mkdir -p $VENV
pushd $VENV

cat <<EOF > ./runme.sh
echo Installing rekal
pip install rekall
echo Generating $JSON_PROFILE
rekal.py convert_profile /tmp/$KERNEL.zip $JSON_PROFILE
echo Done generating $JSON_PROFILE
EOF

chmod +x $VENV/runme.sh

source bin/activate
./runme.sh
deactivate

popd
