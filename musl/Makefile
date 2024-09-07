include ../config

O ?= $(CURDIR)/out

MCM_VER ?= e149c31c48b4f4a4c9349ddf7bc0027b90245afc
MIN_KERNEL_VER ?= 6.10.8

# make sure pc is first, because we need $(pc_TRIPLET) defined early
XTARGETS := pc $(filter-out pc,$(subst targets/,,$(wildcard targets/*)))
XTARGETS_DONE := $(patsubst %,$(O)/mk/%-cross.archived,$(XTARGETS))
XTARGETS_NATIVE := $(patsubst %,$(O)/mk/%-native.archived,$(XTARGETS))

COMMON_CONFIG :=
GCC_CONFIG :=
include common.mk

define targets_definition

$(1)_TRIPLET := $(shell cat targets/$(1)/triplet)

$(1): $(O)/mk/$(1)-cross.archived $(O)/mk/$(1)-native.archived

ifneq ($(strip $(GDB_VER)),)
$(O)/mk/$(1)-cross.archived: $(O)/mk/$(1)-gdb.done $(O)/mk/$(1)-gdbserver.done
endif

$(O)/mk/$(1)-cross.archived: $(O)/mk/$(1)-cross.done
	exec rm -f $(O)/cross/$$($(1)_TRIPLET)_$(1)-$(GCC_VER).tar.xz
	exec tar -c -C $(O)/cross -J -f $(O)/cross/$$($(1)_TRIPLET)_$(1)-$(GCC_VER).tar.xz $$($(1)_TRIPLET)_$(1)-$(GCC_VER)
	exec touch $$@

$(O)/mk/$(1)-native.archived: $(O)/mk/$(1)-native.done
	exec rm -f $(O)/native/$$($(1)_TRIPLET)_$(1)-$(GCC_VER).tar.xz
	exec tar -c -C $(O)/native -J -f $(O)/native/$$($(1)_TRIPLET)_$(1)-$(GCC_VER).tar.xz $$($(1)_TRIPLET)_$(1)-$(GCC_VER)
	exec touch $$@

$(O)/mk/$(1)-cross.done: $(O)/mk/mcm.done $(O)/mk/pc-native.done
	exec env O=$(O) PATH=$$(PATH) MAKE='$$(MAKE)' ./make-cross.sh $(1)
	exec touch $$@

ifneq ($(1),pc)
$(O)/mk/$(1)-native.done: $(O)/mk/$(1)-cross.done
endif

$(O)/mk/$(1)-native.done: $(O)/mk/mcm.done
	exec env O=$(O) PATH=$$(PATH) MAKE='$$(MAKE)' ./make-native.sh $(1)
	exec touch $$@

$(O)/mk/$(1)-gdb.configured: $(O)/mk/gdb.unpacked $(O)/mk/pc-native.done $(O)/mk/gmp.done $(O)/mk/mpfr.done $(O)/mk/mpc.done $(O)/mk/isl.done
	mkdir -p $(O)/build/$(1)/gdb
	rm -rf $(O)/build/$(1)/gdb/src
	cp -a $(O)/sources/gdb-$(GDB_VER) $(O)/build/$(1)/gdb/src
	cd $(O)/build/$(1)/gdb/src && \
	env \
	  PATH=$$(PATH) \
	  CC="$(O)/native/$$(pc_TRIPLET)_pc-$(GCC_VER)/bin/gcc -g0 -O2 -static --static" \
	  CXX="$(O)/native/$$(pc_TRIPLET)_pc-$(GCC_VER)/bin/g++ -g0 -O2 -static --static" \
	  CC_FOR_TARGET=$$($(1)_TRIPLET)-gcc \
	  CXX_FOR_TARGET=$$($(1)_TRIPLET)-g++ \
	  MAKEINFO=true \
	./configure \
	  --prefix=$(O)/build/$(1)/gdb \
	  --build=$(pc_TRIPLET) \
	  --host=$(pc_TRIPLET) \
	  --target=$$($(1)_TRIPLET) \
	  --enable-gold=no \
	  --disable-libquadmath \
	  --disable-libquadmath-support \
	  --disable-libstdcxx \
	  --disable-bootstrap \
	  --disable-gdbserver \
	  --enable-stage1-languages=c,c++ \
	  --with-gmp=$(O)/build/gmp \
	  --with-libgmp-prefix=$(O)/build/gmp \
	  --with-mpfr=$(O)/build/mpfr \
	  --with-libmpfr-prefix=$(O)/build/mpfr \
	  --with-mpc=$(O)/build/mpc \
	  --with-isl=$(O)/build/isl \
	  --disable-werror \
	  ac_c_werror_flag=
	exec touch $$@

$(O)/mk/$(1)-gdb.built: $(O)/mk/$(1)-gdb.configured
	cd $(O)/build/$(1)/gdb/src && $$(MAKE)
	exec touch $$@

$(O)/mk/$(1)-gdb.installed: $(O)/mk/$(1)-gdb.built
	cd $(O)/build/$(1)/gdb/src && $$(MAKE) install
	exec touch $$@

$(O)/cross/$$($(1)_TRIPLET)_$(1)/bin/$$($(1)_TRIPLET)-gdb: $(O)/mk/$(1)-gdb.installed $(O)/mk/$(1)-cross.done $(O)/mk/pc-native.done
	exec cp -f $(O)/build/$(1)/gdb/bin/$$($(1)_TRIPLET)-gdb $$@
	exec strip -R .note -R .comment $$@

$(O)/mk/$(1)-gdb.done: $(O)/cross/$$($(1)_TRIPLET)_$(1)/bin/$$($(1)_TRIPLET)-gdb
	exec touch $$@

$(O)/mk/$(1)-gdbserver.configured: $(O)/mk/gdb.unpacked $(O)/mk/$(1)-cross.done $(O)/mk/gmp.done $(O)/mk/mpfr.done $(O)/mk/mpc.done $(O)/mk/isl.done
	@mkdir -p $(O)/build/$(1)/gdbserver/build
	cd $(O)/build/$(1)/gdbserver/build && \
	env \
	  PATH=$(O)/cross/$$($(1)_TRIPLET)_$(1)/bin:$$(PATH) \
	  CC="$$($(1)_TRIPLET)-gcc -g0 -O2 -static --static" \
	  CXX="$$($(1)_TRIPLET)-g++ -g0 -O2 -static --static" \
	  MAKEINFO=true \
	  $(O)/sources/gdb-$(GDB_VER)/configure --prefix=$(O)/build/$(1)/gdbserver --host=$$($(1)_TRIPLET) \
	    --disable-gdb --with-gnu-ld \
	    --disable-inprocess-agent --enable-threading --without-libipt-prefix --without-xxhash
	exec touch $$@

$(O)/mk/$(1)-gdbserver.built: $(O)/mk/$(1)-gdbserver.configured
	cd $(O)/build/$(1)/gdbserver/build && env PATH=$(O)/cross/$$($(1)_TRIPLET)_$(1)/bin:$$(PATH) $$(MAKE) all-gdbserver MAKEINFO=true
	exec touch $$@

$(O)/mk/$(1)-gdbserver.installed: $(O)/mk/$(1)-gdbserver.built
	cd $(O)/build/$(1)/gdbserver/build && env PATH=$(O)/cross/$$($(1)_TRIPLET)_$(1)/bin:$$(PATH) $$(MAKE) install-gdbserver MAKEINFO=true
	exec touch $$@

$(O)/cross/$$($(1)_TRIPLET)_$(1)/$$($(1)_TRIPLET)/bin/gdbserver: $(O)/mk/$(1)-gdbserver.installed $(O)/mk/$(1)-cross.done
	exec mkdir -p $$(@D)
	exec cp -f $(O)/build/$(1)/gdbserver/bin/gdbserver $$@
	exec $(O)/cross/$$($(1)_TRIPLET)_$(1)/bin/$$($(1)_TRIPLET)-strip -R .note -R .comment $$@

$(O)/mk/$(1)-gdbserver.done: $(O)/cross/$$($(1)_TRIPLET)_$(1)/$$($(1)_TRIPLET)/bin/gdbserver
	exec touch $$@

endef

all: $(XTARGETS_DONE)

native: $(XTARGETS_NATIVE)

mclean:
	cd $(O)/musl-cross-make && $(MAKE) clean

clean:
	exec rm -rf $(patsubst %,$(O)/mk/%-*,$(XTARGETS)) $(O)/musl-cross-make/output $(O)/musl-cross-make/build

distclean:
	exec rm -rf $(O)

pc-bootstrap: $(O)/mk/pc-bootstrap.done

.PHONY: all native mclean clean distclean pc-bootstrap $(XTARGETS)

$(foreach target,$(XTARGETS),$(eval $(call targets_definition,$(target))))

PATH := $(O)/native/$(pc_TRIPLET)_pc/bin:$(PATH)

$(O)/mk/0:
	exec mkdir -p $(O)/mk $(O)/cross $(O)/native $(O)/sysroot
	exec touch $@

$(O)/mk/mcm.cloned: | $(O)/mk/0
	cd $(O) && git clone https://github.com/richfelker/musl-cross-make.git
	cd $(O)/musl-cross-make && git checkout $(MCM_VER)
	exec touch $@

$(O)/mk/mcm.done: $(O)/mk/mcm.cloned
	cd $(O)/musl-cross-make && for i in $(CURDIR)/patches-mcm/* ; do patch -p1 < $$i ; done
	exec cp -f hashes/* $(O)/musl-cross-make/hashes/
	exec touch $@

$(O)/mk/pc-native.done: $(O)/mk/pc-bootstrap.done

$(O)/mk/pc-bootstrap.done: $(O)/mk/mcm.done
	exec env O=$(O) MAKE='$(MAKE)' ./make-cross.sh pc
	exec rm -rf $(O)/cross/$(pc_TRIPLET)_pc $(O)/cross/$(pc_TRIPLET)_pc_bootstrap-$(GCC_VER)
	exec mv -f $(O)/cross/$(pc_TRIPLET)_pc-$(GCC_VER) $(O)/cross/$(pc_TRIPLET)_pc_bootstrap-$(GCC_VER)
	exec ln -sf $(pc_TRIPLET)_pc_bootstrap-$(GCC_VER) $(O)/cross/$(pc_TRIPLET)_pc
	exec touch $@

$(O)/mk/gdb.downloaded:
	exec mkdir -p $(O)/sources
	exec curl --no-progress-meter -o $(O)/sources/gdb-$(GDB_VER).tar.xz https://ftp.gnu.org/gnu/gdb/gdb-$(GDB_VER).tar.xz
	exec touch $@

$(O)/mk/gdb.unpacked: $(O)/mk/gdb.downloaded hashes/gdb-$(GDB_VER).tar.xz.sha1 $(O)/mk/mcm.done
	cd $(O)/sources && sha1sum gdb-$(GDB_VER).tar.xz | cmp - $(CURDIR)/hashes/gdb-$(GDB_VER).tar.xz.sha1
	cd $(O)/sources && rm -rf gdb-$(GDB_VER) && tar -Jxpvf gdb-$(GDB_VER).tar.xz
	if test -d $(CURDIR)/patches-others/gdb-$(GDB_VER) ; then cd $(O)/sources/gdb-$(GDB_VER) && for i in $(CURDIR)/patches-others/gdb-$(GDB_VER)/* ; do patch -p1 < $$i ; done ; fi
	exec touch $@

$(O)/mk/gmp.configured: $(O)/mk/pc-native.done
	@mkdir -p $(O)/build/gmp/build
	cd $(O)/build/gmp/build && env PATH=$(PATH) CC="gcc -static --static" CXX="g++ -static --static" ../../../musl-cross-make/gmp-$(GMP_VER)/configure --prefix=$(O)/build/gmp --disable-assembly --enable-cxx --disable-shared --with-gnu-ld
	exec touch $@

$(O)/mk/gmp.built: $(O)/mk/gmp.configured
	cd $(O)/build/gmp/build && env PATH=$(PATH) $(MAKE)
	exec touch $@

$(O)/mk/gmp.done: $(O)/mk/gmp.built
	cd $(O)/build/gmp/build && env PATH=$(PATH) $(MAKE) install
	exec touch $@

$(O)/mk/mpfr.configured: $(O)/mk/gmp.done $(O)/mk/pc-native.done
	@mkdir -p $(O)/build/mpfr/build
	cd $(O)/build/mpfr/build && env PATH=$(PATH) ../../../musl-cross-make/mpfr-$(MPFR_VER)/configure --prefix=$(O)/build/mpfr --enable-warnings --enable-shared-cache --disable-shared --disable-decimal-float --disable-float128 --with-gnu-ld --with-gmp=$(O)/build/gmp
	exec touch $@

$(O)/mk/mpfr.built: $(O)/mk/mpfr.configured
	cd $(O)/build/mpfr/build && env PATH=$(PATH) $(MAKE)
	exec touch $@

$(O)/mk/mpfr.done: $(O)/mk/mpfr.built
	cd $(O)/build/mpfr/build && env PATH=$(PATH) $(MAKE) install
	exec touch $@

$(O)/mk/mpc.configured: $(O)/mk/gmp.done $(O)/mk/mpfr.done $(O)/mk/pc-native.done
	@mkdir -p $(O)/build/mpc/build
	cd $(O)/build/mpc/build && env PATH=$(PATH) ../../../musl-cross-make/mpc-$(MPC_VER)/configure --prefix=$(O)/build/mpc --disable-shared --with-gnu-ld --with-gmp=$(O)/build/gmp --with-mpfr=$(O)/build/mpfr
	exec touch $@

$(O)/mk/mpc.built: $(O)/mk/mpc.configured
	cd $(O)/build/mpc/build && env PATH=$(PATH) $(MAKE)
	exec touch $@

$(O)/mk/mpc.done: $(O)/mk/mpc.built
	cd $(O)/build/mpc/build && env PATH=$(PATH) $(MAKE) install
	exec touch $@

$(O)/mk/isl.configured: $(O)/mk/gmp.done $(O)/mk/pc-native.done
	@mkdir -p $(O)/build/isl/build
	cd $(O)/build/isl/build && env PATH=$(PATH) CC="gcc -static --static" ../../../musl-cross-make/isl-$(ISL_VER)/configure --prefix=$(O)/build/isl --disable-shared --with-gnu-ld --with-gmp-prefix=$(O)/build/gmp
	exec touch $@

$(O)/mk/isl.built: $(O)/mk/isl.configured
	cd $(O)/build/isl/build && env PATH=$(PATH) $(MAKE)
	exec touch $@

$(O)/mk/isl.done: $(O)/mk/isl.built
	cd $(O)/build/isl/build && env PATH=$(PATH) $(MAKE) install
	exec touch $@

.NOTPARALLEL:
