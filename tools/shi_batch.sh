#!/bin/bash
#
# Used to build all the packages in dependency chain leading up to top package.
#
# Usage: bash tools/shi_batch.sh <path to .rcp file>
#

SHI_DEBUG=1
SHI_DEPTH=1

cd $(dirname $0) && source shi_env.sh

RCPFILE="$1"
if [ -z "$RCPFILE" ]; then
	usage $0 "batch"
	exit 1
fi

function __build_dep() {
	__in

	__inf "$SHI_DEPTH IN  for $1"

	[ -z "$1" ] && __nok "package name not specified"

	local name=$(echo "$1" | cut -f1 -d':')
	local ver=$(echo "$1" | cut -f2 -d':')
	local rcp="$ver.rcp"
	local pkg="packages/$name/$rcp"

	# get needed libs and prods
	local libs=$(grep '^SHI_PKG_NEED_LIBS=' $SHI_PKGS/$name/$rcp | cut -f2 -d'=' | sed -e's/"//g')
	local prods=$(grep '^SHI_PKG_NEED_PRODS=' $SHI_PKGS/$name/$rcp | cut -f2 -d'=' | sed -e's/"//g')
	local deps="$libs $prods"
# 	__inf "all direct dependencies to build: $deps"
	local dep=
	for dep in $deps; do
# 		__inf "found dependency to build: $dep"
		SHI_DEPTH=$(($SHI_DEPTH+1))
#		__build_dependencies "$dep"
		__build_dep "$dep"
		SHI_DEPTH=$(($SHI_DEPTH-1))
	done

	if [ "$name" != "$SHI_PKG_NAME" ]; then
	 	__inf "building: $name for $SHI_PKG_NAME"

		__inf "handle_recipe $pkg release"
		handle_recipe $pkg release || __nok "failed to release recipe $pkg"
	else
	 	__inf "NOT building: $name for $SHI_PKG_NAME"
	fi

	__inf "$SHI_DEPTH OUT for $1"

	__ok
}

function build_dependencies() {
	__in

 	[ -z "$1" ] && __nok "package name not specified"

	__build_dep "$1" || __nok "failed to build dependencies"

	__ok
}

__load_recipe "$RCPFILE"

build_dependencies "$SHI_PKG_NAME:$SHI_PKG_VERSION" || __nok "failed to build dependencies!"
