#!/bin/bash
#
# Used to build a single package.
# Dependencies are expected to be built and released beforehand.
#
# Usage: bash tools/shi_single.sh <path to .rcp file> <build|clean|release|..>
#

SHI_DEBUG=1
SHI_DEPTH=1

cd $(dirname $0) && source shi_env.sh

RCPFILE="$1"
COMMAND="$2"
if [ -z "$RCPFILE" ]; then
	usage $0 "single"
	exit 1
fi
if [ -z "$COMMAND" ]; then
	usage $0 "single"
	exit 1
fi

handle_recipe $RCPFILE $COMMAND || __nok "failed to $COMMAND recipe $RCPFILE"
