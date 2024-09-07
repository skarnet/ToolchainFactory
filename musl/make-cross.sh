#!/bin/sh -e

WD=`realpath \`dirname "$0"\``
cd "$WD"

what="$1"
test -n "$what" || { echo "make-cross.sh: needs an argument" 1>&2 ; exit 100 ; }

if test -z "$O" ; then O="$WD/out" ; fi
if test -z "$MAKE" ; then MAKE=make ; fi

# If we already have a native musl toolchain for the build machine,
# use it. It should always be the case, except for the pc bootstrap.
pctriplet=`cat targets/pc/triplet`
if test -x "$O/native/${pctriplet}_pc/bin/gcc" ; then
  PATH="$O/native/${pctriplet}_pc/bin:$PATH"
  export PATH
fi

triplet="`cat targets/$what/triplet`"
if test "$what" = "$triplet" ; then
  name="$triplet"
else
  name="${triplet}_${what}"
fi

version=`grep ^GCC_VER < ../config | awk '{print $3;}'`
mystrip="strip -R .note -R .comment"

{
  echo "TARGET = $triplet"
  echo "OUTPUT = \$(CURDIR)/output/cross-$name"
  echo "BUILD_DIR = build/cross/$name"
  cat ../config
  echo 'COMMON_CONFIG += CC="gcc -static --static" CXX="g++ -static --static" CC_FOR_BUILD="gcc -static --static" CXX_FOR_BUILD="g++ -static --static"'
  cat common.mk
  if test "$what" = pc ; then
    realpctriplet=`gcc -dumpmachine`
    if test `echo $realpctriplet | sed 's/-/ /g' | wc -w` -le 3 ; then
      echo "GCC_CONFIG += --build=${realpctriplet%%-*}-skarnet-${realpctriplet#*-}"
    fi
  fi

  if test -r targets/$what/options ; then
    echo -n 'GCC_CONFIG += '
    cat targets/$what/options
  fi
} > "$O/musl-cross-make/config.mak"

cd "$O/musl-cross-make"
if test "$what" = pc ; then
  $MAKE clean
fi
$MAKE
$MAKE install

WO="$O/musl-cross-make/output/cross-$name"
targetstrip="$WO/bin/${triplet}-strip -R .note -R .comment"

for i in "$WO/bin/"* "$WO/libexec/gcc/$triplet/$version/install-tools/fixincl" ; do
  $mystrip "$i" || true
done
for i in `ls -1 "$WO/libexec/gcc/$triplet/$version" | grep -vF install-tools | grep -v '\.a$' | grep -v '\.la$'` ; do
  $mystrip "$WO/libexec/gcc/$triplet/$version/$i" || true
done
for i in "$WO/$triplet/lib/"*.[oa] "$WO/lib/gcc/$triplet/$version/"*.[oa] "$WO/libexec/gcc/$triplet/$version/"*.a ; do
  $targetstrip -x "$i" || true
done
for i in `ls -1 "$WO/$triplet/lib" | grep -F .so. | grep -v '\.py$'` ; do
  $targetstrip "$WO/$triplet/lib/$i" || true
done
find "$WO" -name '*.la' -exec rm '{}' ';'


rm -rf "$WO/share/man" "$O/cross/$name" "$O/cross/${name}-${version}"
mv "$WO" "$O/cross/${name}-${version}"
ln -sf "${name}-${version}" "$O/cross/$name"
