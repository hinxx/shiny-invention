#!/bin/bash
#
# Usage: import into other SHI scripts to setup environment
#
# Note: SHI_TOP has to be set externally!

if [ -z "$SHI_TOP" ]; then
  echo "Aborting: SHI_TOP not set, do something like:"
  echo "export SHI_TOP=\$(pwd)"
  exit 1
fi

# include common functions
source shi_lib.sh

# this is inside this repository
SHI_PKGS=$SHI_TOP/packages
SHI_TOOLS=$SHI_TOP/tools
if [ ! -d "$SHI_PKGS" ]; then
	__abort "Must be started from SHI root!"
fi
if [ ! -d "$SHI_TOOLS" ]; then
	__abort "Must be started from SHI root!"
fi

# this is outside this repository - default to /opt/shi is not set differently
[ -z "$SHI_TOPOUT" ] && SHI_TOPOUT=/opt/shi
if [ ! -d "$SHI_TOPOUT" ]; then
	__abort "$SHI_TOPOUT folder must exists and be writable for user $USER!"
fi
SHI_STAGE=$SHI_TOPOUT/stage
SHI_POOL=$SHI_TOPOUT/pool
SHI_ROOT=$SHI_TOPOUT/root

# enter the top folder
cd $SHI_TOP

__dbg "SHI environment & library sourced .."
