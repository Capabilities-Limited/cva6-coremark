# Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Original Author: Shay Gal-on

#File : core_portme.mak

PORT_DIR = cva6-metal

ifeq ($(CHERI),1)
TOOLCHAIN:=LLVM
endif

CCDIR   ?= /Users/jonathanwoodruff/cheri/output/sdk/bin/
ifeq ($(TOOLCHAIN),LLVM)
CC      := $(CCDIR)/clang
LD      := $(CCDIR)/ld.lld
OBJDUMP := $(CCDIR)/llvm-objdump
OBJCOPY := $(CCDIR)/llvm-objcopy

RISCV_FLAGS += -mcmodel=medium -mno-relax
LIBS := 
else # GCC
CC      := riscv64-unknown-elf-gcc
LD      := riscv64-unknown-elf-ld
OBJDUMP := riscv64-unknown-elf-objdump
OBJCOPY := riscv64-unknown-elf-objcopy
RISCV_FLAGS += -mcmodel=medany
LIBS := -lgcc
endif

ifeq ($(TOOLCHAIN),LLVM)
ifeq ($(CHERI),1)
  RISCV_FLAGS += -target riscv64-unknown-elf -march=rv64imafdzcherihybrid -mabi=l64pc128d
else
  RISCV_FLAGS += -target riscv64-unknown-elf -march=rv64imafdc -mabi=lp64
endif
else
  RISCV_FLAGS += -march=rv64imafdc -mabi=lp64d
endif

# Define sources and compilation outputs.
COMMON_DIR := ../Toooba-mibench2
LINKER_SCRIPT := $(COMMON_DIR)/test.ld
COMMON_ASM_SRCS := \
	$(COMMON_DIR)/crt.S
COMMON_C_SRCS := \
	$(COMMON_DIR)/syscalls.c \
	$(COMMON_DIR)/util.c \
	$(COMMON_DIR)/cvt.c
COMMON_OBJS := \
	$(patsubst %.c,%.o,$(notdir $(COMMON_C_SRCS))) \
	$(patsubst %.S,%.o,$(notdir $(COMMON_ASM_SRCS)))
PORT_OBJS := $(COMMON_OBJS)

# Define compile and load/link flags.
CFLAGS := \
	$(RISCV_FLAGS) \
	-DBARE_METAL \
	-DCLOCKS_PER_SEC=$(CLOCKS_PER_SEC) \
	-DHAS_FLOAT=1 \
	-DRUNS=$(RUNS) \
	-O2 \
	-Wall \
	-static \
	-std=gnu99 \
	-ffast-math \
	-fno-common \
	-fno-builtin-printf \
	-I$(COMMON_DIR)
ASFLAGS := $(CFLAGS)
LDFLAGS := \
	-v \
	-static \
	-nostdlib \
	-nodefaultlibs \
	-nostartfiles \
	$(LIBS) \
	-T $(LINKER_SCRIPT)

# Flag : OUTFLAG
#	Use this flag to define how to to get an executable (e.g -o)
OUTFLAG= -o
# Flag : CC
#	Use this flag to define compiler to use
#CC 		= gcc
# Flag : LD
#	Use this flag to define compiler to use
#LD		=
# Flag : AS
#	Use this flag to define compiler to use
#AS		= gas
# Flag : CFLAGS
#	Use this flag to define compiler options. Note, you can add compiler options from the command line using XCFLAGS="other flags"
PORT_CFLAGS = -O3 -DPERFORMANCE_RUN=1 -DMAIN_HAS_NOARGC=1 -DHAS_FLOAT=1

# Turn of the maybe-unitialized warning to pacify -Wall -Wextra -Wpedantic -Werror on code we can't control
PORT_CFLAGS += -Wno-maybe-uninitialized

FLAGS_STR = "$(PORT_CFLAGS) $(XCFLAGS) $(XLFLAGS) $(LFLAGS_END)"
CFLAGS += $(PORT_CFLAGS) -I$(PORT_DIR) -I. -DFLAGS_STR=\"$(FLAGS_STR)\" -Xlinker --defsym=__stack_size=0x1000
#Flag : LFLAGS_END
#	Define any libraries needed for linking or other flags that should come at the end of the link line (e.g. linker scripts).
#	Note : On certain platforms, the default clock_gettime implementation is supported but requires linking of librt.
SEPARATE_COMPILE =
# Flag : SEPARATE_COMPILE
# You must also define below how to create an object file, and how to link.
OBJOUT 	= -o
LFLAGS 	=
ASFLAGS =
OFLAG 	= -o
COUT 	= -c

LFLAGS_END = $(LDFLAGS) $(LDLIBS)
# Flag : PORT_SRCS
# 	Port specific source files can be added here
#	You may also need cvt.c if the fcvt functions are not provided as intrinsics by your compiler!
PORT_SRCS = $(PORT_DIR)/core_portme.c $(COMMON_C_SRCS) $(COMMON_ASM_SRCS)
vpath %.c $(PORT_DIR)
vpath %.s $(PORT_DIR)

# Flag : LOAD
#	For a simple port, we assume self hosted compile and run, no load needed.

# Flag : RUN
#	For a simple port, we assume self hosted compile and run, simple invocation of the executable

LOAD = echo "Please set LOAD to the process of loading the executable to the flash"
RUN = echo "Please set LOAD to the process of running the executable (e.g. via jtag, or board reset)"

OEXT = .o
EXE =

$(OPATH)$(PORT_DIR)/%$(OEXT) : %.c
	$(CC) $(CFLAGS) $(XCFLAGS) $(COUT) $< $(OBJOUT) $@

$(OPATH)%$(OEXT) : %.c
	$(CC) $(CFLAGS) $(XCFLAGS) $(COUT) $< $(OBJOUT) $@

$(OPATH)$(PORT_DIR)/%$(OEXT) : %.s
	$(AS) $(ASFLAGS) $< $(OBJOUT) $@

# Target : port_pre% and port_post%
# For the purpose of this simple port, no pre or post steps needed.

.PHONY : port_prebuild port_postbuild port_prerun port_postrun port_preload port_postload
port_pre% port_post% :

# FLAG : OPATH
# Path to the output folder. Default - current folder.
OPATH =
MKDIR = mkdir -p

