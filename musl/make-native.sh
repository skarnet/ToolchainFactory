#!/bin/sh -e

WD=`realpath \`dirname "$0"\``
cd "$WD"

what="$1"
test -n "$what" || { echo "make-native.sh: needs an argument" 1>&2 ; exit 100 ; }

if test -z "$O" ; then O="$WD/out" ; fi
if test -z "$MAKE" ; then MAKE=make ; fi

pctriplet="`cat targets/pc/triplet`"
triplet="`cat targets/$what/triplet`"
if test "$what" = "$triplet" ; then
  name="$triplet"
else
  name="${triplet}_${what}"
fi

if ! test -x "$O/cross/$name/bin/${triplet}-gcc" ; then
  echo "make-native.sh: needs a cross-toolchain for the same target first"
  exit 100
fi

PATH="$O/cross/$name/bin:$PATH"
export PATH

version=`grep -F GCC_VER < ../config | awk '{print $3;}'`
targetstrip="$O/cross/$name/bin/${triplet}-strip -R .note -R .comment"

{
  echo "TARGET = $triplet"
  echo "OUTPUT = \$(CURDIR)/output/native-$name"
  echo "BUILD_DIR = build/native/$name"
  echo 'NATIVE = y'

  cat ../config
  echo "COMMON_CONFIG += CC=\"$O/cross/$name/bin/${triplet}-gcc -static --static\" CXX=\"$O/cross/$name/bin/${triplet}-g++ -static --static\""
  if test "$what" = pc ; then
    bpref=${pctriplet}-
  else
    bpref=
    echo "GCC_CONFIG += --build=${pctriplet}"
  fi
  echo "COMMON_CONFIG += CC_FOR_BUILD=\"${bpref}gcc -static --static\" CXX_FOR_BUILD=\"${bpref}g++ -static --static\""
  cat common.mk
  if test -r targets/$what/options ; then
    echo -n "GCC_CONFIG += "
    cat targets/$what/options
  fi
} > "$O/musl-cross-make/config.mak"

cd "$O/musl-cross-make"
$MAKE
$MAKE install

WO="$O/musl-cross-make/output/native-$name"
rm -f "$WO/bin/${triplet}-"* "$WO/lib/ld-musl-"*

for i in "$WO/lib/"*.a "$WO/lib/gcc/$triplet/$version/"*.[oa] "$WO/libexec/gcc/$triplet/$version/"*.a ; do
  $targetstrip -x "$i" || true
done
for i in "$WO/bin/"* "$WO/libexec/gcc/$triplet/$version/install-tools/fixincl" ; do
  $targetstrip "$i" || true
done
for i in `ls -1 "$WO/lib" | grep -F .so. | grep -v '\.py$'` ; do
  $targetstrip "$WO/lib/$i" || true
done
for i in `ls -1 "$WO/libexec/gcc/$triplet/$version" | grep -vF install-tools | grep -v '\.a$' | grep -v '\.la$'` ; do
  $targetstrip "$WO/libexec/gcc/$triplet/$version/$i" || true
done
find "$WO" -name '*.la' -exec rm '{}' ';'

ln -s . "$WO/usr"
ln -s lib "$WO/lib64"
ln -s gcc "$WO/bin/cc"
ln -s libc.so "$WO/lib/ld-musl-${triplet%%-*}.so.1"

cat > "$WO/bin/ldd" <<EOF
#!/bin/sh -e
p=\$(realpath \$(dirname "\$0"))
exec "\$p/../lib/ld-musl-${triplet%%-*}.so.1" --list "\$@"
EOF
chmod 0755 "$WO/bin/ldd"

rm -rf "$WO/share/man" "$O/native/$name" "$O/native/${name}-${version}"
mv "$WO" "$O/native/${name}-${version}"
ln -sf "${name}-${version}" "$O/native/$name"
