#!/bin/bash
#
# Source this file from shi_env.sh to get all the handy functions.
#

##################################################################
#							HELPERS
##################################################################

function __dbg() {
	[ -n "$SHI_DEBUG" ] && echo "[DBG] $@"
}
function __inf() {
	echo "[INF] $@"
}
function __wrn() {
	echo "[WRN] $@"
}
function __err() {
	echo "[ERR] $@"
}
function __abort() {
	echo "======================================================="
	echo "[ABORT] $@"
	echo "======================================================="
	exit 1
}
function __in() {
	__dbg "${FUNCNAME[1]} >>>"
}
function __ok() {
	__dbg "${FUNCNAME[1]} <<< OK"
}
function __nok() {
	__abort "${FUNCNAME[1]} <<< $*"
}
function __warn() {
	__wrn "${FUNCNAME[1]} <<< $*"
}

##################################################################
#							WORKERS
##################################################################

function __load_recipe() {
	__in

	rcpfile="$1"
	[ -z "$rcpfile" ] && __nok "recipe file not specified"
	[ ! -f "$rcpfile" ] && __nok "recipe file not found"
	source "$rcpfile"

	set | grep ^SHI_PKG_

	# figure out version based on supplied tag / branch
	SHI_PKG_VERSION=
	[ -n "$SHI_PKG_TAG" ] && SHI_PKG_VERSION="$SHI_PKG_TAG"
	[ -z "$SHI_PKG_VERSION" ] && SHI_PKG_VERSION="$SHI_PKG_BRANCH"
	[ -z "$SHI_PKG_VERSION" ] && __nok "version not set"

	SHI_PKG_DEPENDS=
	export SHI_PKG_DEPENDS
	SHI_PKG_RECIPE="$(basename $rcpfile .rcp)"
	export SHI_PKG_RECIPE
	SHI_PKG_RECIPE_FILE="$rcpfile"
	export SHI_PKG_RECIPE_FILE
	SHI_PKG_FULL_NAME="$SHI_PKG_NAME-$SHI_PKG_RECIPE"
	export SHI_PKG_FULL_NAME

	__ok
}

function __load_needed_libs() {
	__in

	[ -z "$1" ] && __nok "package name not specified"

	name=$(echo "$1" | cut -f1 -d':')
	ver=$(echo "$1" | cut -f2 -d':')
	rcp="$ver.rcp"

	[ ! -f $SHI_PKGS/$name/$rcp ] && __nok "recipe $SHI_PKGS/$name/$rcp not found"
	
	# get needed libs
	deps=$(grep '^SHI_PKG_NEED_LIBS=' $SHI_PKGS/$name/$rcp | cut -f2 -d'=' | sed -e's/"//g')

	for dep in $deps; do
		__inf "LIB depend: $dep"
		SHI_PKG_DEPENDS="$SHI_PKG_DEPENDS $dep"
		__load_dependencies "$dep"
	done

	__ok
}

function __load_needed_prods() {
	__in

	[ -z "$1" ] && __nok "package name not specified"

	name=$(echo "$1" | cut -f1 -d':')
	ver=$(echo "$1" | cut -f2 -d':')
	rcp="$ver.rcp"

	# get needed prods
	deps=$(grep '^SHI_PKG_NEED_PRODS=' $SHI_PKGS/$name/$rcp | cut -f2 -d'=' | sed -e's/"//g')
	for dep in $deps; do
		__inf "PROD depend: $dep"
		SHI_PKG_DEPENDS="$SHI_PKG_DEPENDS $dep"
		__load_dependencies "$dep"
	done

	__ok
}

function __load_dependencies() {
	__in

 	[ -z "$1" ] && __nok "package name not specified"

	__load_needed_libs "$1"
	if [ "$SHI_PKG_GROUP" = "iocs" ]; then
		__load_needed_prods "$1"
	fi
	deps=$(echo "$SHI_PKG_DEPENDS" | tr ' ' '\n' | sort | uniq)
	SHI_PKG_DEPENDS="$(echo $deps | tr '\n' ' ')"

	__ok
}

function __get_released_base_versions() {
	__in

	tmp=""
	pushd $SHI_ROOT || __nok "root dir not found"
	for dir in $(ls --color=never | grep ^R); do
		if [ -d "$dir/base" ]; then
			tmp="$tmp $dir"
		fi
	done
	bases="SHI_BASE_VERSIONS=\"$tmp\""
	eval "$bases"
	if [ -z "$SHI_BASE_VERSIONS" -a "$SHI_PKG_NAME" != "base" ]; then
		__nok "no released bases found in $SHI_ROOT!"
	else
		__inf "released base: $SHI_BASE_VERSIONS"
	fi
	popd

	__ok
}

function __create_stamp() {
	__in

	stamp="$1"
	[ -z "$stamp" ] && __nok "stamp not specified"

	if [ ! -f "$stamp" ]; then
		touch "$stamp" || __nok "failed to create stamp $stamp"
		__dbg "created stamp $stamp"
	else
		__dbg "stamp already exists $stamp"
	fi

	__ok
}

function __remove_stamp() {
	__in

	stamp="$1"
	[ -z "$stamp" ] && __nok "stamp not specified"

	if [ ! -f "$stamp" ]; then
		__dbg "stamp absent $stamp"
	else
		rm -f "$stamp"
		__dbg "removed stamp $stamp"
	fi

	__ok
}

function __have_stamp() {
	__in

	stamp="$1"
	[ -z "$stamp" ] && __nok "stamp not specified"

	ret=0
	if [ ! -f "$stamp" ]; then
		__dbg "stamp absent $stamp"
		ret=1
	else
		__dbg "stamp exists $stamp"
	fi

	__ok
	return $ret
}

function __init() {
	__in

	for d in "$SHI_STAGE" "$SHI_POOL" "$SHI_ROOT"; do
		[ ! -d "$d" ] && mkdir -p "$d"
	done

	__load_recipe "$1"
	__load_dependencies "$SHI_PKG_NAME:$SHI_PKG_VERSION"
	__inf "final dependency list: $SHI_PKG_DEPENDS"
	__get_released_base_versions

	for base_ver in $SHI_BASE_VERSIONS; do
		for d in modules iocs; do
			[ ! -d "$SHI_STAGE/$base_ver/$d" ] && mkdir -p "$SHI_STAGE/$base_ver/$d"
			[ ! -d "$SHI_ROOT/$base_ver/$d" ] && mkdir -p "$SHI_ROOT/$base_ver/$d"
		done
	done

	__ok
}

function __clone() {
	__in

	arg="$1"
	[ -z "$arg" ] && __nok "missing argument"
	dir="$SHI_STAGE/$arg"

	if [ ! -d "$dir" ]; then
		git clone "$SHI_PKG_SOURCE" "$dir" || __nok "clone failed"
	fi

	__ok
}

function __checkout() {
	__in

	arg="$1"
	[ -z "$arg" ] && __nok "missing argument"
	dir="$SHI_STAGE/$arg"
	[ ! -d "$dir" ] && __nok "src dir not found"

	__have_stamp "$dir/checkout_done.stamp" && return 0

	pushd "$dir" || __nok "cd to src dir failed"
	# is version based on tag or branch?
	if [ -n "$SHI_PKG_TAG" -a "$SHI_PKG_TAG" = "$SHI_PKG_VERSION" ]; then
		ver=$(git describe --tags --always)
		if [ "$ver" != "$SHI_PKG_VERSION" ]; then
			git checkout --detach "$SHI_PKG_VERSION" || __nok "checkout failed"
		fi
		ver=$(git describe --tags)
		[ "$ver" != "$SHI_PKG_VERSION" ] && __nok "tag checkout failed"
	else
		git checkout "$SHI_PKG_VERSION" || __nok "checkout failed"
	fi
	popd
	__inf "Checked out version (tag/branch): $SHI_PKG_NAME:$SHI_PKG_VERSION"

	if [ ! -f "$dir/$SHI_PKG_RECIPE_FILE" ]; then
		cp "$SHI_PKG_RECIPE_FILE" "$dir" || __nok "recipe not found"
	fi

	__create_stamp "$dir/checkout_done.stamp" || __nok "failed to create checkout_done.stamp"

	__ok
}

function __distclean() {
	__in

	arg="$1"
	[ -z "$arg" ] && __nok "missing argument"
	dir="$SHI_STAGE/$arg"
	[ ! -d "$dir" ] && __nok "src dir not found"

	pushd "$dir" || __nok "cd to src dir failed"
	make -j distclean
	popd

	__remove_stamp "$dir/config_done.stamp"
	__remove_stamp "$dir/build_done.stamp"

	__ok
}

function __compile() {
	__in

	arg="$1"
	[ -z "$arg" ] && __nok "missing argument"
	dir="$SHI_STAGE/$arg"
	[ ! -d "$dir" ] && __nok "src dir not found"

	__have_stamp "$dir/build_done.stamp" && return 0

	pushd "$dir" || __nok "cd to src dir failed"
	make -j || __nok "compile failed"
	popd

	__create_stamp "$dir/build_done.stamp" || __nok "failed to create build_done.stamp"

	__ok
}

function __deploy() {
	__in

	arg="$1"
	[ -z "$arg" ] && __nok "missing argument"
	# modules provide package full name as second argument (base does not)
	[ -n "$2" ] && arg="$arg/$2"
	dir="$SHI_STAGE/$arg"
	[ ! -d "$dir" ] && __nok "src dir not found"

	__have_stamp "$dir/build_done.stamp" || return 1

	rm -fr "$SHI_ROOT/$arg"
	mkdir -p "$SHI_ROOT/$arg" || __nok "failed to create folder"

	rsync -a --exclude="O.*" --exclude=".git*" "$SHI_STAGE/$arg/" "$SHI_ROOT/$arg/" || __nok "failed to deploy"

	if [ "$SHI_PKG_GROUP" = "iocs" ]; then
		# change any 'stage' parts of the path to 'root' for envPaths
		find "$SHI_ROOT/$arg" -name envPaths | xargs sed -i -e 's#/stage/#/root/#'
		# remove unused generated files cdCommands and dllPath.bat
		find "$SHI_ROOT/$arg" -name cdCommands -o -name dllPath.bat | xargs rm -f
	fi

	__ok
}

function __release() {
	__in

	[ -z "$1" ] && __nok "missing argument"
	arg="$1"
	# modules provide package full name as second argument (base does not)
	[ -n "$2" ] && arg="$arg/$2"
	dir="$SHI_ROOT/$arg"
	[ ! -d "$dir" ] && __nok "src dir not found"

	archive="$SHI_PKG_FULL_NAME.tar.bz2"
	rm -f "/tmp/$archive"

	if [ -f "$SHI_POOL/$archive" ]; then
		__inf "archive $SHI_POOL/$archive already exists!"
		__ok
		return 0
	fi

	pushd "$SHI_ROOT"
	tar --exclude="O.*" --exclude-vcs -jcf "/tmp/$archive" "$arg" || __nok "tar stage dir failed"
	popd

# XXX: do we need this?
#      should we be allowed to overwrite existing archive that might be different from
#       one already existing - this should be prevented as current package might alredy
#       be distributed to users!!!!

#	if [ ! -f "$SHI_POOL/$archive" ]; then
#		mv "$SHI_STAGE/$archive" "$SHI_POOL" || __nok "failed to move archive to pool"
#	else
#		__inf "archive already in the pool"
#	fi
	rm -f "$SHI_POOL/$archive"
	mv "/tmp/$archive" "$SHI_POOL" || __nok "failed to move archive to pool"

	__ok
}

function __remove() {
	__in

	arg="$1"
	[ -z "$arg" ] && __nok "missing argument"

	# remove stuff from all folders!

	dir="$SHI_STAGE/$arg"
	[ ! -d "$dir" ] && __wrn "stage dir not found"
	rm -fr "$dir"
	dir="$SHI_ROOT/$arg"
	[ ! -d "$dir" ] && __wrn "root dir not found"
	rm -fr "$dir"
	file="$SHI_POOL/$SHI_PKG_FULL_NAME".tar.bz2
	[ ! -d "$file" ] && __wrn "pool archive not found"
	rm -fr "$file"

	__ok
}

##################################################################
#							BASE
##################################################################

function __distclean_base() {
	__in

	__distclean "$SHI_PKG_VERSION/base"

	__ok
}

function __devel_base() {
	__in

	__clone "$SHI_PKG_VERSION/base"

	__ok
}

function __build_base() {
	__in

	__clone "$SHI_PKG_VERSION/base"
	__checkout "$SHI_PKG_VERSION/base"
	__compile "$SHI_PKG_VERSION/base"
	__deploy "$SHI_PKG_VERSION/base"

	__ok
}

function __rebuild_base() {
	__in

	__clone "$SHI_PKG_VERSION/base"
	__distclean "$SHI_PKG_VERSION/base"
	__checkout "$SHI_PKG_VERSION/base"
	__compile "$SHI_PKG_VERSION/base"
	__deploy "$SHI_PKG_VERSION/base"

	__ok
}

function __release_base() {
	__in

	__build_base
	__release "$SHI_PKG_VERSION/base"

	__ok
}

function __remove_base() {
	__in

	__remove "$SHI_PKG_VERSION/base"

	__ok
}

##################################################################
#						MODULE / IOC
##################################################################

function __distclean_module() {
	__in

	for base_ver in $SHI_BASE_VERSIONS; do
		__distclean "$base_ver/$SHI_PKG_GROUP/$SHI_PKG_FULL_NAME"
	done

	__ok
}

function __config_module() {
	__in

	[ -z "$1" ] && __nok "missing argument"
	[ -z "$2" ] && __nok "missing argument"
	base_ver="$2"
	dir="$SHI_STAGE/$arg"
	[ ! -d "$dir" ] && __nok "src dir not found"
	basedir="$SHI_ROOT/$base_ver/base"
	[ ! -d "$dir" ] && __nok "base dir not found"

	__have_stamp "$dir/config_done.stamp" && return 0

	release="$dir/configure/RELEASE"
	[ ! -d "$dir/configure" ] && __nok "configure dir does not exist"

	echo "# Autogenerated by SHI on $(date)" > $release
	echo >> $release
	echo "## >>> dependencies from the recipe" >> $release
	for dep in $SHI_PKG_DEPENDS; do
		name=$(echo $dep | cut -d: -f1)
		rcp=$(echo $dep | cut -d: -f2)
		pkgdir="$SHI_ROOT/$base_ver/modules/${name}-${rcp}"
		key=$(echo $name | tr [:lower:] [:upper:])
		echo "$key=$pkgdir" >> $release
	done
	echo "## <<< dependencies from the recipe" >> $release
	echo >> $release
	echo "## >>> EPICS base from the recipe" >> $release
	echo "EPICS_BASE=$basedir" >> $release
	echo "## <<< EPICS base from the recipe" >> $release

	echo >> $release

	__create_stamp "$dir/config_done.stamp" || __nok "failed to create config_done.stamp"

	__ok
}

function __devel_module() {
	__in

	for base_ver in $SHI_BASE_VERSIONS; do
		__clone "$base_ver/$SHI_PKG_GROUP/$SHI_PKG_FULL_NAME"
	done

	__ok
}

function __build_module() {
	__in

	for base_ver in $SHI_BASE_VERSIONS; do
		__clone "$base_ver/$SHI_PKG_GROUP/$SHI_PKG_FULL_NAME"
		__checkout "$base_ver/$SHI_PKG_GROUP/$SHI_PKG_FULL_NAME"
		__config_module "$base_ver/$SHI_PKG_GROUP/$SHI_PKG_FULL_NAME" "$base_ver"
		__compile "$base_ver/$SHI_PKG_GROUP/$SHI_PKG_FULL_NAME"
		__deploy "$base_ver/$SHI_PKG_GROUP" "$SHI_PKG_FULL_NAME"
	done

	__ok
}

function __rebuild_module() {
	__in

	for base_ver in $SHI_BASE_VERSIONS; do
		__clone "$base_ver/$SHI_PKG_GROUP/$SHI_PKG_FULL_NAME"
		__checkout "$base_ver/$SHI_PKG_GROUP/$SHI_PKG_FULL_NAME"
		__config_module "$base_ver/$SHI_PKG_GROUP/$SHI_PKG_FULL_NAME" "$base_ver"
		__distclean "$base_ver/$SHI_PKG_GROUP/$SHI_PKG_FULL_NAME"
		__compile "$base_ver/$SHI_PKG_GROUP/$SHI_PKG_FULL_NAME"
		__deploy "$base_ver/$SHI_PKG_GROUP" "$SHI_PKG_FULL_NAME"
	done

	__ok
}

function __release_module() {
	__in

	for base_ver in $SHI_BASE_VERSIONS; do
 		__build_module
		__release "$base_ver/$SHI_PKG_GROUP" "$SHI_PKG_FULL_NAME"
	done

	__ok
}

function __remove_module() {
	__in

	for base_ver in $SHI_BASE_VERSIONS; do
		__remove "$base_ver/$SHI_PKG_GROUP/$SHI_PKG_FULL_NAME"
	done

	__ok
}

##################################################################
#							TOP
##################################################################

function shi_init() {
	__in
	__nok "not implemented"
}

function shi_clean() {
	__in

	case $SHI_PKG_GROUP in
		bases)
			__distclean_base ;;
		modules|iocs)
			__distclean_module ;;
		*)
			__nok "unknown package group" ;;
	esac

	__ok
}

function shi_devel() {
	__in

	case $SHI_PKG_GROUP in
		bases)
			__devel_base ;;
		modules|iocs)
			__devel_module ;;
		*)
			__nok "unknown package group" ;;
	esac

	__ok
}

function shi_build() {
	__in

	case $SHI_PKG_GROUP in
		bases)
			__build_base ;;
		modules|iocs)
			__build_module ;;
		*)
			__nok "unknown package group" ;;
	esac

	__ok
}

function shi_rebuild() {
	__in

	case $SHI_PKG_GROUP in
		bases)
			__rebuild_base ;;
		modules|iocs)
			__rebuild_module ;;
		*)
			__nok "unknown package group" ;;
	esac

	__ok
}

function shi_release() {
	__in

	case $SHI_PKG_GROUP in
		bases)
			__release_base ;;
		modules|iocs)
			__release_module ;;
		*)
			__nok "unknown package group" ;;
	esac

	__ok
}

function shi_remove() {
	__in

	case $SHI_PKG_GROUP in
		bases)
			__remove_base ;;
		modules|iocs)
			__remove_module ;;
		*)
			__nok "unknown package group" ;;
	esac

	__ok
}

##################################################################
#							MAIN
##################################################################

function usage() {
		echo ""
		echo "Usage:"
		echo ""
		if [ "$2" = "single" ]; then
			echo " bash $1 RECIPE COMMAND"
			echo ""
			echo "     RECIPE ....... path to recipe file (*.rcp)"
			echo ""
			echo "    COMMAND ....... one of the following"
			echo "      devel         fetch the source only"
			echo "      clean         clean the source tree"
			echo "      build         perform a build"
			echo "    rebuild         clean the source tree and perform a build"
			echo "    release         perform rebuild and package"
			echo "     remove         remove files from stage and root"
		elif [ "$2" = "batch" ]; then
			echo " bash $1 RECIPE"
			echo ""
			echo "     RECIPE ....... path to recipe file (*.rcp)"
		fi
		
		echo ""
		echo ""
		echo "List of known packages and versions:"
		echo ""
		pushd $SHI_PKGS >/dev/null
		printf "%20s ..... %s\n" "PACKAGE" "RECIPE(s)"
		echo "----------------------------------------------------------------------------------"
		pkgs=$(ls -1 -d */ | sed 's#/##')
		for pkg in $pkgs; do
			printf "%20s ..... %s\n" $pkg "$(ls $pkg | tr '\n' ' ')"
		done
		popd >/dev/null
		echo ""
}

function handle_recipe() {
	__in

	# show the environment and arguments
	__inf "SHI_TOP    : \"$SHI_TOP\""
	__inf "SHI_PKGS   : \"$SHI_PKGS\""
	__inf "SHI_STAGE  : \"$SHI_STAGE\""
	__inf "SHI_POOL   : \"$SHI_POOL\""
	__inf "SHI_ROOT   : \"$SHI_ROOT\""
	__inf "recipe      : \"$1\""
	__inf "command     : \"$2\""

	__init "$1"

	case $2 in
	"clean")
		shi_clean
		;;
	"devel")
		shi_devel
		;;
	"build")
		shi_build
		;;
	"rebuild")
		shi_rebuild
		;;
	"release")
		shi_release
		;;
	"remove")
		shi_remove
		;;
	*)
		__nok "unknown command"
		;;
	esac

	__ok
}
