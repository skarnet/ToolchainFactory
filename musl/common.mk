# CONFIG_SUB_REV = 1912ca50411bb77fb2c610ef55dd91e332663de9
COMMON_CONFIG += --disable-nls --disable-assembly
GCC_CONFIG += --enable-languages=c,c++ --enable-c99 --enable-clocale=gnu --enable-threads=posix
GCC_CONFIG += --disable-libquadmath --disable-decimal-float --disable-multilib
GCC_CONFIG += --disable-nls --with-cloog=no --with-ppl=no --disable-libstdcxx-pch
GCC_CONFIG += --disable-sjlj-exceptions --enable-gnu-unique-object --enable-linker-build-id
GCC_CONFIG += CFLAGS='-g0 -O2' CXXFLAGS='-g0 -O2'
BINUTILS_CONFIG += --disable-gprofng

ISL_SITE = https://libisl.sourceforge.io/
GNU_SITE = https://ftp.gnu.org/pub/gnu

DL_CMD = curl --no-progress-meter -o
# MAKE += LIMITS_H_TEST=true
