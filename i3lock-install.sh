#! /usr/bin/env bash

exec 6>&1
exec 7>&2
exec 1>/dev/null
exec 2>/dev/null

CONFS_PATH=$(echo ~/afs/.confs) # expand tilde
INSTALL_PATH="$CONFS_PATH/install.sh"

I3LOCK_FLAKE_NAME="i3lock-epitdc"
I3LOCK_PATH="$CONFS_PATH/$I3LOCK_FLAKE_NAME"
I3LOCK_URL="https://github.com/EpiTDC/i3lock-bin"

VERBOSE=0
REMOVE=0
while getopts rv opt; do
    case "$opt" in
        r)  REMOVE=1
            ;;
        v)  VERBOSE=1
            ;;
        ?)  echo "use '-r' to remove i3lock and '-v' to show debug logs" >&6
            exit 0
            ;;
    esac
done

[ $VERBOSE -eq 1 ] && exec 1>&6 && exec 2>&7

if [ $REMOVE -eq 1 ]; then
    echo -n "removing i3lock..." >&6; [ $VERBOSE -eq 1 ] && echo
    nix profile list | grep "$I3LOCK_FLAKE_NAME" # TODO find better way
    [ $? -eq 0 ] && nix profile remove $I3LOCK_FLAKE_NAME
    rm -rf "$I3LOCK_PATH"
elif [ ! -d "$I3LOCK_PATH" ]; then
    echo -n "installing i3lock..." >&6; [ $VERBOSE -eq 1 ] && echo
    git clone -b flake $I3LOCK_URL $I3LOCK_PATH || { echo; echo "[ERROR] Couldn't clone repo!" >&6; exit 1; } # TODO remove branch name
    nix profile install git+file:$I3LOCK_PATH
    echo '
######################
# EpiTDC i3lock Hook #
######################
CONFS_PATH=$(echo ~/afs/.confs)
I3LOCK_FLAKE_NAME="i3lock-epitdc"
I3LOCK_PATH="$CONFS_PATH/$I3LOCK_FLAKE_NAME"
if [ -z ${EPITDC_I3LOCK_UNIQUE+x} ] && [ -d "$I3LOCK_PATH" ]; then
    EPITDC_I3LOCK_UNIQUE=1
    pushd $I3LOCK_PATH
    git pull
    nix profile list | grep "$I3LOCK_FLAKE_NAME"
    [ $? -eq 0 ] && nix profile upgrade $I3LOCK_FLAKE_NAME || nix profile install
    popd
fi' >> $INSTALL_PATH
else
    echo -n "updating i3lock..." >&6; [ $VERBOSE -eq 1 ] && echo
    pushd $I3LOCK_PATH
    git pull
    nix profile list | grep "$I3LOCK_FLAKE_NAME" # TODO find better way
    [ $? -eq 0 ] && nix profile upgrade $I3LOCK_FLAKE_NAME || nix profile install
    popd
fi
[ $VERBOSE -eq 0 ] && echo -n " " >&6
echo "Done!" >&6
