it: all

include ../config

O ?= $(CURDIR)/out

MIN_KERNEL_VER := 4.14.86
LINUX_URL := https://cdn.kernel.org/pub/linux/kernel/v$(firstword $(subst ., ,$(LINUX_VER))).x
GLIBC_URL := https://ftp.gnu.org/pub/gnu/glibc
GMP_URL := https://gmplib.org/download/gmp
MPFR_URL := https://www.mpfr.org/mpfr-$(MPFR_VER)
MPC_URL := https://ftp.gnu.org/gnu/mpc
ISL_URL := http://isl.gforge.inria.fr
BINUTILS_URL := https://ftp.gnu.org/gnu/binutils
GCC_URL := https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VER)
GDB_URL := https://ftp.gnu.org/gnu/gdb

GMP_OPTIONS := --disable-assembly --enable-cxx
MPFR_OPTIONS := --enable-warnings --enable-shared-cache --disable-decimal-float --disable-float128 --with-gmp=$(O)/build/pc/BUILD
MPC_OPTIONS := --with-gmp=$(O)/build/pc/BUILD --with-mpfr=$(O)/build/pc/BUILD
ISL_OPTIONS := --with-gmp-prefix=$(O)/build/pc/BUILD

PACKAGES := LINUX GLIBC GMP MPFR MPC ISL BINUTILS GCC GDB
BPACKAGES := GMP MPFR MPC ISL
XTARGETS := pc $(filter-out pc,$(subst targets/,,$(wildcard targets/*)))
XTARGETS_DONE := $(patsubst %,$(O)/mk/%-deb.done,$(XTARGETS))
ALL_PACKAGES :=

MAKE += MULTILIB_OSDIRNAMES=
MAKE += ac_cv_prog_lex_root=lex.yy

PATH := $(O)/build/pc/ROOT/bin:$(PATH)

define sources_download_and_unpack

$(1)_NAME := $(shell echo $(1) | tr A-Z a-z)
ALL_PACKAGES += $$($(1)_NAME)

ifeq ($(1),MPC)
$(1)_EXT := gz
$(1)_J := z
else
$(1)_EXT := xz
$(1)_J := J
endif

$(O)/mk/$$($(1)_NAME).downloaded: $(O)/mk/pc-0
	exec curl -o $(O)/sources/$$($(1)_NAME)-$$($(1)_VER).tar.$$($(1)_EXT) $$($(1)_URL)/$$($(1)_NAME)-$$($(1)_VER).tar.$$($(1)_EXT)
	exec touch $$@

$(O)/mk/$$($(1)_NAME).unpacked: $(O)/mk/$$($(1)_NAME).downloaded hashes/$$($(1)_NAME)-$$($(1)_VER).tar.$$($(1)_EXT).sha1
	cd $(O)/sources && sha1sum $$($(1)_NAME)-$$($(1)_VER).tar.$$($(1)_EXT) | cmp - $(CURDIR)/hashes/$$($(1)_NAME)-$$($(1)_VER).tar.$$($(1)_EXT).sha1
	cd $(O)/sources && rm -rf $$($(1)_NAME)-$$($(1)_VER) && tar -$$($(1)_J) -xpvf $$($(1)_NAME)-$$($(1)_VER).tar.$$($(1)_EXT)
	if test -d $(CURDIR)/patches/$$($(1)_NAME)-$$($(1)_VER) ; then cd $(O)/sources/$$($(1)_NAME)-$$($(1)_VER) && for i in $(CURDIR)/patches/$$($(1)_NAME)-$$($(1)_VER)/* ; do patch -p1 < $$$$i ; done ; fi
	exec touch $$@

endef

$(foreach pkg,$(PACKAGES),$(eval $(call sources_download_and_unpack,$(pkg))))

define build_configure_make_install

$(O)/mk/$$($(1)_NAME).configured: $(O)/mk/$$($(1)_NAME).unpacked
	exec mkdir -p $(O)/build/pc/$$($(1)_NAME)
	cd $(O)/build/pc/$$($(1)_NAME) && \
	$(O)/sources/$$($(1)_NAME)-$$($(1)_VER)/configure --prefix=$(O)/build/pc/BUILD --disable-shared --with-gnu-ld --with-pic $$($(1)_OPTIONS)
	exec touch $$@

$(O)/mk/$$($(1)_NAME).built: $(O)/mk/$$($(1)_NAME).configured
	cd $(O)/build/pc/$$($(1)_NAME) && $$(MAKE)
	exec touch $$@

$(O)/mk/$$($(1)_NAME).installed: $(O)/mk/$$($(1)_NAME).built
	cd $(O)/build/pc/$$($(1)_NAME) && $$(MAKE) install
	exec touch $$@

endef

$(foreach pkg,$(BPACKAGES),$(eval $(call build_configure_make_install,$(pkg))))

define targets_definition

$(1)_TRIPLET := $(shell cat targets/$(1)/triplet)
$(1)_ARCH := $$(firstword $$(subst -, ,$$($(1)_TRIPLET)))
$(1)_KARCH := $$(patsubst i%86,x86,$$(patsubst powerpc%,powerpc,$$(patsubst mips%,mips,$$(subst aarch64,arm64,$$($(1)_ARCH)))))
$(1)_OPTIONS := $(shell cat targets/$(1)/options 2>/dev/null)
$(1)_SYSROOT := $(O)/build/$(1)/SYSROOT/$$($(1)_TRIPLET)
$(1)_OUTPUT := $(O)/cross/$(1).tmp
$(1)_FINAL := $(O)/cross/$$($(1)_TRIPLET)_$(1)-$(GCC_VER)
$(1)_PATH := $(O)/build/$(1)/SYSROOT/bin:$(PATH)

$(1): $(O)/mk/$(1)-deb.done

ifneq ($(strip $(GDB_VER)),)
$(O)/mk/$(1)-cross.done: $(O)/mk/$(1)-gdb.done $(O)/mk/$(1)-gdbserver.done
endif

$(O)/mk/$(1)-0: $(O)/mk/0
	exec mkdir -p $$($(1)_SYSROOT)/share $$($(1)_SYSROOT)/include $$($(1)_OUTPUT)/$$($(1)_TRIPLET)/share $$(patsubst %,$(O)/build/$(1)/%,$(ALL_PACKAGES) gdbserver)
	exec ln -sf . $$($(1)_SYSROOT)/usr
	exec ln -sf . $$($(1)_OUTPUT)/$$($(1)_TRIPLET)/usr
	exec touch $$@

$(O)/mk/$(1)-cross.archived: $(O)/mk/$(1)-cross.done
	exec rm -f $(O)/cross/$$($(1)_TRIPLET)_$(1)-$(GCC_VER).tar.xz
	exec tar --owner=0 --group=0 --numeric-owner -C $(O)/cross -Jcvf $$($(1)_FINAL).tar.xz $$($(1)_TRIPLET)_$(1)-$(GCC_VER)
	exec touch $$@

$(O)/mk/$(1)-cross.done: $(O)/mk/$(1)-binutils.done $(O)/mk/$(1)-gcc.done $(O)/mk/$(1)-glibc.done $(O)/mk/$(1)-linuxheaders.done
	exec $(CURDIR)/finalize.sh $(1)
	exec touch $$@

$(O)/mk/$(1)-deb.done: $(O)/mk/$(1)-cross.archived
	exec $(CURDIR)/../deb/builddeb.sh $(O) $(1) glibc $(PACKAGE_VER)
	exec touch $$@

# gdb

$(O)/mk/$(1)-gdb.configured: $(O)/mk/gdb.unpacked $(O)/mk/gmp.installed $(O)/mk/mpfr.installed $(O)/mk/mpc.installed $(O)/mk/isl.installed | $(O)/mk/$(1)-0
	cd $(O)/build/$(1)/gdb && \
	env PATH=$$(PATH) \
	$(O)/sources/gdb-$(GDB_VER)/configure \
	  --prefix= \
	  --build=$(pc_TRIPLET) \
	  --host=$(pc_TRIPLET) \
	  --target=$$($(1)_TRIPLET) \
	  --enable-gold=no \
	  --disable-nls \
	  --disable-libquadmath \
	  --disable-libquadmath-support \
	  --disable-bootstrap \
	  --disable-gdbserver \
	  --enable-stage1-languages=c,c++ \
	  --with-gmp=$(O)/build/pc/BUILD \
	  --with-mpfr=$(O)/build/pc/BUILD \
	  --with-mpc=$(O)/build/pc/BUILD \
	  --with-isl=$(O)/build/pc/BUILD
	exec touch $$@

$(O)/mk/$(1)-gdb.built: $(O)/mk/$(1)-gdb.configured | $(O)/mk/$(1)-0
	cd $(O)/build/$(1)/gdb && \
	env PATH=$$(PATH) \
	$$(MAKE) all-gdb
	exec touch $$@

$(O)/mk/$(1)-gdb.done: $(O)/mk/$(1)-gdb.built | $(O)/mk/$(1)-0
	cd $(O)/build/$(1)/gdb && \
	env PATH=$$(PATH) \
	$$(MAKE) install-gdb DESTDIR=$$($(1)_OUTPUT)
	exec touch $$@

$(O)/mk/$(1)-gdbserver.configured: $(O)/mk/gdb.unpacked $(O)/mk/$(1)-gcc.installed
	cd $(O)/build/$(1)/gdbserver && \
	env PATH=$$($(1)_PATH) \
	  $(O)/sources/gdb-$(GDB_VER)/gdb/gdbserver/configure \
	    --prefix= \
	    --host=$$($(1)_TRIPLET) \
	    --without-ust \
	    --disable-inprocess-agent
	exec touch $$@

$(O)/mk/$(1)-gdbserver.built: $(O)/mk/$(1)-gdbserver.configured
	cd $(O)/build/$(1)/gdbserver && \
	env PATH=$$($(1)_PATH) \
	$$(MAKE)
	exec touch $$@

$(O)/mk/$(1)-gdbserver.done: $(O)/mk/$(1)-gdbserver.built
	cd $(O)/build/$(1)/gdbserver && \
	env PATH=$$($(1)_PATH) \
	$$(MAKE) install DESTDIR=$$($(1)_OUTPUT)/$$($(1)_TRIPLET)
	exec $$($(1)_OUTPUT)/bin/$$($(1)_TRIPLET)-strip -R .note -R .comment $$($(1)_OUTPUT)/$$($(1)_TRIPLET)/bin/gdbserver
	exec touch $$@


# binutils

$(O)/mk/$(1)-binutils.configured: $(O)/mk/binutils.unpacked | $(O)/mk/$(1)-0
	cd $(O)/build/$(1)/binutils && \
	env PATH=$$(PATH) \
	$(O)/sources/binutils-$(BINUTILS_VER)/configure --disable-multilib --disable-werror --target=$$($(1)_TRIPLET) \
	  --prefix= \
	  --disable-nls \
	  --disable-separate-code \
	  --enable-deterministic-archives
	exec touch $$@

$(O)/mk/$(1)-binutils.built: $(O)/mk/$(1)-binutils.configured | $(O)/mk/$(1)-0
	cd $(O)/build/$(1)/binutils && \
	env PATH=$$(PATH) \
	$$(MAKE) all
	exec touch $$@

$(O)/mk/$(1)-binutils.installed: $(O)/mk/$(1)-binutils.built | $(O)/mk/$(1)-0
	cd $(O)/build/$(1)/binutils && \
	env PATH=$$(PATH) \
	$$(MAKE) install DESTDIR=$(O)/build/$(1)/SYSROOT
	exec touch $$@

$(O)/mk/$(1)-binutils.done: $(O)/mk/$(1)-binutils.built | $(O)/mk/$(1)-0
	cd $(O)/build/$(1)/binutils && \
	env PATH=$$(PATH) \
	$$(MAKE) install DESTDIR=$$($(1)_OUTPUT)
	exec touch $$@


# linux headers

$(O)/mk/$(1)-linuxheaders.built: $(O)/mk/linux.unpacked | $(O)/mk/$(1)-0
	exec mkdir -p $(O)/build/$(1)/linux-staging/build $(O)/build/$(1)/linux-staging/headers
	cd $(O)/sources/linux-$(LINUX_VER) && \
	env PATH=$$(PATH) \
	$$(MAKE) ARCH=$$($(1)_KARCH) O=$(O)/build/$(1)/linux-staging/build INSTALL_HDR_PATH=$(O)/build/$(1)/linux-staging/headers headers_install
	exec find $(O)/build/$(1)/linux-staging/headers/include '(' -name '*.cmd' -o -name '*.chk' ')' -exec rm {} +
	exec touch $$@

$(O)/mk/$(1)-linuxheaders.installed: $(O)/mk/$(1)-linuxheaders.built | $(O)/mk/$(1)-0
	exec cp -a $(O)/build/$(1)/linux-staging/headers/include $$($(1)_SYSROOT)
	exec touch $$@

$(O)/mk/$(1)-linuxheaders.done: $(O)/mk/$(1)-linuxheaders.built | $(O)/mk/$(1)-0
	exec cp -a $(O)/build/$(1)/linux-staging/headers/include $$($(1)_OUTPUT)/$$($(1)_TRIPLET)/
	exec touch $$@


# gcc and glibc, in several steps

$(O)/mk/$(1)-gcc.configured: $(O)/mk/gcc.ready $(O)/mk/pc-nativegcc.installed $(O)/mk/$(1)-binutils.installed | $(O)/mk/$(1)-0
	cd $(O)/build/$(1)/gcc && \
	env PATH=$$($(1)_PATH) \
	$(O)/sources/gcc/configure --prefix= --with-gnu-ld --with-gnu-as --target=$$($(1)_TRIPLET) \
	  --enable-languages=c,c++ \
	  --enable-c99 \
	  --disable-werror \
	  --libdir=/lib \
	  --disable-multilib \
	  --with-sysroot=/$$($(1)_TRIPLET) \
	  --with-build-sysroot=$$($(1)_SYSROOT) \
	  --enable-tls \
	  --disable-libmudflap \
	  --disable-libmpx \
	  --enable-libstdcxx-time \
	  --enable-clocale=gnu \
	  --enable-threads=posix \
	  --disable-libquadmath \
	  --disable-decimal-float \
	  --with-cloog=no \
	  --with-ppl=no \
	  --disable-libstdcxx-pch \
	  --enable-gnu-unique-object \
	  --enable-linker-build-id \
	  --disable-sjlj-exceptions \
	  --enable-libssp \
	  CFLAGS="-g0 -O2" CXXFLAGS="-g0 -O2" \
          $$($(1)_OPTIONS)
	exec touch $$@

$(O)/mk/$(1)-gcc.bootstrapped: $(O)/mk/$(1)-gcc.configured | $(O)/mk/$(1)-0
	env PATH=$$($(1)_PATH) \
	$(SHELL) -c 'cd $(O)/build/$(1)/gcc && \
	$$(MAKE) all-gcc LIMITS_H_TEST=true && \
	$$(MAKE) install-gcc LIMITS_H_TEST=true DESTDIR=$(O)/build/$(1)/SYSROOT'
	exec touch $$@

$(O)/mk/$(1)-glibc.configured: $(O)/mk/glibc.unpacked $(O)/mk/$(1)-gcc.bootstrapped $(O)/mk/$(1)-binutils.installed $(O)/mk/$(1)-linuxheaders.installed | $(O)/mk/$(1)-0
	cd $(O)/build/$(1)/glibc && \
	env \
	  PATH=$$($(1)_PATH) \
	  CFLAGS="-O2" \
	$(O)/sources/glibc-$(GLIBC_VER)/configure \
	  --build=$(pc_TRIPLET) \
	  --host=$$($(1)_TRIPLET) \
	  --target=$$($(1)_TRIPLET) \
	  --prefix= \
	  --enable-shared \
	  --disable-profile \
	  --enable-bind-now \
	  --enable-kernel=$(MIN_KERNEL_VER) \
	  --disable-werror \
	  --disable-experimental-malloc \
	  --disable-build-nscd \
	  --disable-nscd \
	  --disable-timezone-tools \
	  --enable-tunables=no \
	  --with-headers=$$($(1)_SYSROOT)/include \
	  libc_cv_forced_unwind=yes \
	  libc_cv_c_cleanup=yes \
	  libc_cv_ctors_header=no
	exec touch $$@

$(O)/mk/$(1)-glibc.bootstrapped: $(O)/mk/$(1)-linuxheaders.installed $(O)/mk/$(1)-glibc.configured $(O)/mk/$(1)-gcc.bootstrapped | $(O)/mk/$(1)-0
	env PATH=$$($(1)_PATH) \
	$(SHELL) -c 'cd $(O)/build/$(1)/glibc && \
	$$(MAKE) install-bootstrap-headers=yes install-headers DESTDIR=$$($(1)_SYSROOT) && \
	$$(MAKE) csu/subdir_lib && \
	$$($(1)_TRIPLET)-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $$($(1)_SYSROOT)/lib/libc.so'
	exec cp -f $(O)/build/$(1)/glibc/csu/crt1.o $(O)/build/$(1)/glibc/csu/crti.o $(O)/build/$(1)/glibc/csu/crtn.o $$($(1)_SYSROOT)/lib/
	exec mkdir -p $$($(1)_SYSROOT)/include/gnu
	exec touch $$($(1)_SYSROOT)/include/gnu/stubs.h
	exec touch $$@

$(O)/mk/$(1)-gcc.libbuilt: $(O)/mk/$(1)-gcc.bootstrapped $(O)/mk/$(1)-glibc.bootstrapped | $(O)/mk/$(1)-0
	env PATH=$$($(1)_PATH) \
 	$(SHELL) -c 'cd $(O)/build/$(1)/gcc && \
	$$(MAKE) MAKE="$$(MAKE) enable_shared=no" all-target-libgcc LIMITS_H_TEST=true && \
	$$(MAKE) MAKE="$$(MAKE) enable_shared=no" install-target-libgcc LIMITS_H_TEST=true DESTDIR=$(O)/build/$(1)/SYSROOT'
	exec ln -sf libgcc.a $(O)/build/$(1)/SYSROOT/lib/gcc/$$($(1)_TRIPLET)/$(GCC_VER)/libgcc_eh.a
	exec touch $$@

$(O)/mk/$(1)-glibc.built: $(O)/mk/$(1)-glibc.configured $(O)/mk/$(1)-gcc.libbuilt | $(O)/mk/$(1)-0
	cd $(O)/build/$(1)/glibc && \
	env PATH=$$($(1)_PATH) \
	$$(MAKE) MAKEINFO=
	exec touch $$@

# glibc's "make install" is buggy when parallelized
$(O)/mk/$(1)-glibc.installed: $(O)/mk/$(1)-glibc.built | $(O)/mk/$(1)-0
	cd $(O)/build/$(1)/glibc && \
	env PATH=$$($(1)_PATH) \
	$$(MAKE) -j1 install MAKEINFO= PERL=no DESTDIR=$$($(1)_SYSROOT)
	exec touch $$@

# You can't run two glibc installations at once.
$(O)/mk/$(1)-glibc.done: $(O)/mk/$(1)-glibc.installed | $(O)/mk/$(1)-0
	cd $(O)/build/$(1)/glibc && \
	env PATH=$$($(1)_PATH) \
	$$(MAKE) -j1 install MAKEINFO= PERL=no DESTDIR=$$($(1)_OUTPUT)/$$($(1)_TRIPLET)
	exec sed -i -e 's|/lib/l|=/lib/l|g' $$($(1)_OUTPUT)/$$($(1)_TRIPLET)/lib/libc.so  # Extra hack against Alchemy braindeadness
	exec touch $$@

$(O)/mk/$(1)-gcc.built: $(O)/mk/$(1)-gcc.bootstrapped $(O)/mk/$(1)-glibc.installed | $(O)/mk/$(1)-0
	cd $(O)/build/$(1)/gcc && \
	env PATH=$$($(1)_PATH) \
	$$(MAKE) MAKEINFO=true LIMITS_H_TEST=true
	exec touch $$@

$(O)/mk/$(1)-gcc.installed: $(O)/mk/$(1)-gcc.built | $(O)/mk/$(1)-0
	cd $(O)/build/$(1)/gcc && \
	env PATH=$$($(1)_PATH) \
	$$(MAKE) install MAKEINFO=true LIMITS_H_TEST=true DESTDIR=$(O)/build/$(1)/SYSROOT
	exec touch $$@

# You can't run two gcc installations at once.
$(O)/mk/$(1)-gcc.done: $(O)/mk/$(1)-gcc.installed | $(O)/mk/$(1)-0
	cd $(O)/build/$(1)/gcc && \
	env PATH=$$($(1)_PATH) \
	$$(MAKE) install MAKEINFO=true LIMITS_H_TEST=true DESTDIR=$$($(1)_OUTPUT)
	exec touch $$@

$(1)-gcc: $(O)/mk/$(1)-gcc.done
$(1)-glibc: $(O)/mk/$(1)-glibc.done

$(1)-clean:
	exec rm -rf $(O)/mk/$(1)-* $(O)/build/$(1) $$($(1)_OUTPUT)

.PHONY: $(1) $(1)-gcc $(1)-glibc $(1)-clean

endef

$(foreach target,$(XTARGETS),$(eval $(call targets_definition,$(target))))


all: $(XTARGETS)

clean:
	exec rm -rf $(patsubst %,$(O)/mk/%-*,$(XTARGETS)) $(O)/build/* $(O)/sources/gcc
	if test -d $(O)/mk ; then cd $(O)/mk && ls -1 . | grep -v -e '\.downloaded$$' -e '\.unpacked$$' | xargs rm -f ; fi

distclean:
	exec rm -rf $(O)

native: $(O)/mk/pc-nativegcc.installed

debcopy: $(XTARGETS_DONE)
	exec scp -P 4222 $(O)/deb/*.deb apt-parrot@canari.pfa.tds:deb/

.PHONY: it all mclean clean distclean native debcopy


$(O)/mk/0:
	@exec mkdir -p $(O)/mk $(O)/cross $(O)/build/pc/ROOT $(O)/build/pc/BUILD/gcc $(O)/build/pc/BUILD/glibc $(O)/sources
	exec touch $@

$(O)/mk/mpfr.configured: $(O)/mk/gmp.installed
$(O)/mk/mpc.configured: $(O)/mk/gmp.installed $(O)/mk/mpfr.installed
$(O)/mk/isl.configured: $(O)/mk/gmp.installed

$(O)/mk/gcc.ready: $(O)/mk/gcc.unpacked $(O)/mk/gmp.unpacked $(O)/mk/mpfr.unpacked $(O)/mk/mpc.unpacked $(O)/mk/isl.unpacked
	exec rm -rf $(O)/sources/gcc
	exec mkdir $(O)/sources/gcc
	cd $(O)/sources/gcc && ln -sf ../gcc-$(GCC_VER)/* .
	exec ln -sf ../gmp-$(GMP_VER) $(O)/sources/gcc/gmp
	exec ln -sf ../mpfr-$(MPFR_VER) $(O)/sources/gcc/mpfr
	exec ln -sf ../mpc-$(MPC_VER) $(O)/sources/gcc/mpc
	exec ln -sf ../isl-$(ISL_VER) $(O)/sources/gcc/isl
	exec touch $@

$(O)/mk/pc-nativegcc.configured: $(O)/mk/gcc.ready | $(O)/mk/pc-0
	cd $(O)/build/pc/BUILD/gcc && \
	$(O)/sources/gcc/configure --disable-nls --with-gnu-ld --with-gnu-as \
	  --prefix=$(O)/build/pc/ROOT \
	  --with-glibc-version=$(GLIBC_VER) \
	  --enable-languages=c,c++ \
	  --enable-c99 \
	  --disable-werror \
	  --disable-multilib \
	  --enable-tls \
	  --disable-libmudflap \
	  --disable-libmpx \
	  --enable-libstdcxx-time \
	  --enable-clocale=gnu \
	  --enable-threads=posix \
	  --disable-libquadmath --disable-libquadmath-support \
	  --disable-decimal-float \
	  --with-cloog=no \
	  --with-ppl=no \
	  --disable-libstdcxx-pch \
	  --enable-gnu-unique-object \
	  --enable-linker-build-id \
	  --disable-sjlj-exceptions \
	  --disable-gcov \
	  --disable-libssp \
	  --disable-libgomp \
	  --disable-libvtv \
	  --disable-libsanitizer \
	  CFLAGS='-g0 -O2' CXXFLAGS='-g0 -O2' \
          $(pc_OPTIONS)
	  exec touch $@

$(O)/mk/pc-nativegcc.built: $(O)/mk/pc-nativegcc.configured | $(O)/mk/pc-0
	cd $(O)/build/pc/BUILD/gcc && $(MAKE)
	exec touch $@

$(O)/mk/pc-nativegcc.installed: $(O)/mk/pc-nativegcc.built | $(O)/mk/pc-0
	cd $(O)/build/pc/BUILD/gcc && $(MAKE) install
	exec touch $@
