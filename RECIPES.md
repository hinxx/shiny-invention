# Recipe file definitions

Author: Hinko Kocevar <hinkocevar@gmail.com>

Updated: 2017-11-01

## Introduction

Recipe is a collection of key=value lines that define package name, version, GIT repository and some other properties.

Keys start with _SHI_PKG__.

Values can be enclosed with double-quotes ("); double-quotes are mandatory if value contains spaces.

Here is an example of recipe for package named _foo_, with GIT repository tag _R1-0_:

	SHI_PKG_NAME="foo"
	SHI_PKG_TAG="R1-0"
	SHI_PKG_BRANCH=
	SHI_PKG_SOURCE="https://github.com/hinxx/foo"
	SHI_PKG_UPSTREAM="https://github.com/another/foo"
	SHI_PKG_GROUP="modules"
	SHI_PKG_DEPEND="baz:R1-2"

Package will be placed into folder _foo-R1-0_ and packaged into tarball _foo-R1-0.tar.bz2_.

## Explanation of the keys

### SHI_PKG_NAME

Defines package name.
Name can contain [a-zA-Z0-9_-] characters.
Name does not have to match GIT repository name.

### SHI_PKG_TAG

Defines GIT repository _tag_ that will be checked out before build process.
If __SHI_PKG_TAG__ is empty (or undefined) then build script will look for __SHI_PKG_BRANCH__ variable.
If __SHI_PKG_BRANCH__ is also empty (or undefined) build process will abort. 
See also __SHI_PKG_BRANCH__.

### SHI_PKG_BRANCH

Defines GIT repository _branch_ that will be checked out before build process.
It is used only if __SHI_PKG_TAG__ is empty (or undefined), otherwise __SHI_PKG_BRANCH__ is ignored.
See also __SHI_PKG_TAG__.

### SHI_PKG_SOURCE

Defines URL of GIT repository containig package sources.
GIT repository will be automatically checked out before build process.

### SHI_PKG_UPSTREAM

Define upstream URL of GIT repository, if any.
If set it shall be used to sync the forked GIT repository in order to get upstream updates.

### SHI_PKG_GROUP

Defines a group that the package belongs to.
Currently _base_ and _modules_ group can be set.

### SHI_PKG_NEED_LIBS

Defines space separated list of packages that this package needs at build time.
A dependency package definition looks like __package_name:package_version__.
Only first level of dependencies is required, the rest are recursively added.
List can be empty.
See also __SHI_PKG_NEED_PRODS__.

### SHI_PKG_NEED_PRODS

Defines space separated list of packages that this package needs at (build and) runtime time.
A dependency package definition looks like __package_name:package_version__.
Only first level of dependencies is required, the rest are recursively added.
If a dependency is listed in __SHI_PKG_NEED_LIBS__ it does not need to be listed here.
List can be empty.
See also __SHI_PKG_NEED_LIBS__.
