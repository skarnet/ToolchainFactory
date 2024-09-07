#!/bin/sh -e

WD=`realpath \`dirname "$0"\``
cd "$WD"

what="$1"

triplet=`cat targets/$what/triplet`
version=`grep ^GCC_VER < ../config | awk '{print $3;}'`
name="${triplet}_${what}"
O="$WD/out/cross/$name"
WO="$WD/out/cross/${what}.tmp"
buildstrip="strip -R .note -R .comment"
targetstrip="$WO/bin/${triplet}-strip -R .note -R .comment"

for i in "$WO/bin/"* "$WO/libexec/gcc/$triplet/$version/install-tools/fixincl" "$WO/libexec/gcc/$triplet/$version/plugin/"* ; do
  $buildstrip "$i" || true
done
for i in `ls -1 "$WO/libexec/gcc/$triplet/$version" | grep -vF -e install-tools -e plugin | grep -v '\.a$' | grep -v '\.la$'` ; do
  $buildstrip "$WO/libexec/gcc/$triplet/$version/$i" || true
done
for i in "$WO/$triplet/lib/"*.[oa] "$WO/lib/gcc/$triplet/$version/"*.[oa] ; do
  $targetstrip -x "$i" || true
done
for i in `ls -1 "$WO/$triplet/lib" | grep -F .so. | grep -v '\.py$'` ; do
  $targetstrip "$WO/$triplet/lib/$i" || true
done

rm -rf "$WO/share/man" "$O" "${O}-${version}"
mv "$WO" "${O}-${version}"
ln -sf "${name}-${version}" "$O"
