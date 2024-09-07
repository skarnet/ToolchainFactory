#!/bin/bash -e

WD=`realpath \`dirname "$0"\``
cd "$WD"

output="$1"
name="$2"
libc_name="$3"
version="$4"

if test "$libc_name" = musl ; then
  pc_libc_required="static binaries, no libc required"
  pc_libc=
else
  pc_libc_required="glibc required"
  pc_libc=libc6
fi

verkeys="gcc_ver gmp_ver mpfr_ver mpc_ver isl_ver ${libc_name}_ver binutils_ver gdb_ver"
allkeys="name libc_name package version maintainer triplet pc debpc pc_libc_required pc_libc size libc_ver $verkeys"

for k in $verkeys ; do
  key=`echo "$k" | tr a-z A-Z`
  v=`grep "^$key" < "$WD/../config" | awk '{print $3;}'`
  eval "$k=\"$v\""
done

if test $"libc_name" = musl ; then
  libc_ver="$musl_ver"
else
  libc_ver="$glibc_ver"
fi

triplet=`cat "$WD/../$libc_name/targets/$name/triplet"`
pc=`cat "$WD/../$libc_name/targets/pc/triplet"`
debpc=`echo "$pc" | cut -d- -f1 | sed 's/x86_64/amd64/'`
package="fce-toolchain-${name}-${gcc_ver}-${libc_name}"
maintainer='Laurent Bercot <laurent.bercot-ext@faurecia.com>'
pkgname="${package}_${version}_${debpc}"

fullname="${triplet}_${name}-${gcc_ver}"
size=`du -s "$output/cross/$fullname" | cut -f1`

sedex=""

for k in $allkeys ; do
  sedex="$sedex s/@@$k@@/${!k}/;"
done

mkdir -p "$output/deb/$pkgname/opt/fce-toolchains" "$output/deb/$pkgname/DEBIAN"
cp -a "$output/cross/$fullname" "$output/deb/$pkgname/opt/fce-toolchains/$fullname"
sed -e "$sedex" < "$WD/skel/control" > "$output/deb/$pkgname/DEBIAN/control"
cd "$output/deb"
dpkg-deb -b -Zgzip --root-owner-group -- "$pkgname"
