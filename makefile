TOOLSET = arm-none-eabi
CC := $(TOOLSET)-gcc
GDB := $(TOOLSET)-gdb
SIZE := $(TOOLSET)-size
OBJCOPY := $(TOOLSET)-objcopy

FLASH := st-flash

SRCDIR = src
INCDIR = inc
LIBDIR = lib
OBJDIR = .obj
DEPDIR = .deps

LIBCM3DIR := $(LIBDIR)/libopencm3
LIBCM3INC := $(LIBCM3DIR)/include
LIBCM3LIBDIR := $(LIBCM3DIR)/lib
LIBCM3LIBFILE := $(LIBCM3LIBDIR)/libopencm3_stm32g4.a

COMMON_CFLAGS = -Wall -std=c11 -g3 -Os

CPUFLAGS = -mcpu=cortex-m4 -mthumb
FPUFLAGS = -mfloat-abi=hard -mfpu=fpv4-sp-d16

CPPFLAGS := -DSTM32G4 -DLITTLE_BIT=400000 -I $(LIBCM3INC) -I $(INCDIR)
CFLAGS := $(CPUFLAGS) $(FPUFLAGS) $(COMMON_CFLAGS) -fno-common -ffunction-sections -fdata-sections
LDSCRIPT := ld.stm32.basic
LDFLAGS := --static -nostartfiles -L $(LIBCM3LIBDIR) -T $(LDSCRIPT) -Wl,--start-group -lc -lgcc -lnosys -Wl,--end-group -Wl,-Map=main.map,--cref
LDLIBS := -lopencm3_stm32g4
DEPFLAGS = -MT $@ -MMD -MP -MF $(@:$(OBJDIR)/%.o=$(DEPDIR)/%.d)

SRCS := $(wildcard $(SRCDIR)/*.c)
SRCOBJS := $(SRCS:%.c=$(OBJDIR)/%.o)
SRCDEPS := $(SRCS:%.c=$(DEPDIR)/%.d)

TARGET = stm32g4_main

TESTCC := gcc
TESTSIZE := size

TESTDIR = tests
TESTLIBDIR = lib/greatest
TESTOBJDIR = $(OBJDIR)/$(TESTDIR)
TESTCPPFLAGS := -DSTM32G4 -DLITTLE_BIT=400000 -I $(LIBCM3INC) -I $(INCDIR) -I $(TESTLIBDIR) -I $(TESTDIR)
TESTCFLAGS = $(COMMON_CFLAGS)

TESTSRCS := $(wildcard $(TESTDIR)/*.c)
TESTOBJS := $(TESTSRCS:%.c=$(TESTOBJDIR)/%.o)


.PHONY: all clean libopencm3_git_update cm3clean srcdepdir flash-erase flash-write flash-backup
all: $(TARGET).elf $(TARGET).bin
tests: all_tests.elf

flash-backup:
	$(FLASH) read BIN_BACKUP.bib 0x08000000 0x20000

flash-write: $(TARGET).bin
	$(FLASH) --flash=128k write $< 0x08000000

flash-erase:
	$(FLASH) erase

libopencm3_git_update:
	@echo "Initializing/updating libopencm3 submodule"
	git submodule update --init --remote $(LIBDIR)/libopencm3

$(LIBCM3LIBFILE): libopencm3_git_update
	make TARGETS=stm32/g4 -C $(LIBCM3DIR)


$(TARGET).bin: $(TARGET).elf
	@echo "Creating binary image"
	$(OBJCOPY) -O binary $^ $@

$(TARGET).elf: $(SRCOBJS) $(LIBCM3LIBFILE)
	@echo "Linking objects"
	$(CC) $(LDFLAGS) $(LDLIBS) $(CPUFLAGS) $(FPUFLAGS) $^ -o $@
	$(SIZE) $@

$(OBJDIR)/$(SRCDIR)/%.o: $(SRCDIR)/%.c | srcdepdir
	@echo "Creating objects"
	@mkdir -p $(@D)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(DEPFLAGS) -c $< -o $@

srcdepdir :
	@mkdir -p $(DEPDIR)/$(SRCDIR)

$(SRCDEPS):

test_modules_git_update:
	@echo "Initializing/updating greatest submodule"
	git submodule update --init --remote $(LIBDIR)/greatest

# Unit test builds
all_tests.elf: $(TESTOBJS) | test_modules_git_update
	@echo "Linking test objects"
	$(TESTCC) $(TESTLDFLAGS) $(TESTLDLIBS) $^ -o $@
	$(TESTSIZE) $@

$(TESTOBJDIR)/%.o: %.c
	@echo "Creating test objects"
	@mkdir -p $(@D)
	$(TESTCC) $(TESTCPPFLAGS) $(TESTCFLAGS) -c $< -o $@


clean:
	@echo "Cleaning build"
	-$(RM) $(TARGET).{elf,bin} all_tests.elf
	-$(RM) -rf $(OBJDIR) $(DEPDIR)

cm3clean:
	@echo "Cleaning libopencm3 build"
	make clean -C $(LIBCM3DIR)

-include $(wildcard $(SRCDEPS))
