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

SHI_PKGS=$SHI_TOP/packages
SHI_STAGE=$SHI_TOP/stage
SHI_POOL=$SHI_TOP/pool
SHI_ROOT=$SHI_TOP/root
SHI_TOOLS=$SHI_TOP/tools
if [ ! -d "$SHI_PKGS" ]; then
	__abort "Must be started from SHI root!"
fi
if [ ! -d "$SHI_TOOLS" ]; then
	__abort "Must be started from SHI root!"
fi

# enter the top folder
cd $SHI_TOP

__dbg "SHI environment & library sourced .."
