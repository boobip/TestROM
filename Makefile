TARGET=test
LINKCONFIG=./bbcbx.cfg
SDIRS = src src/common src/libc
IDIR=src/libc
BDIR=Debug
ODIR=bin
TARGET_PATH=$(ODIR)/$(TARGET).bin
ROMC=src/rom.c

CC=/mnt/c/Code/gcc6502/gcc8-6502-bits/prefix/bin/6502-gcc
AS=ca65
#OPTFLAGS=-O3 --param max-completely-peel-times=4 --param max-completely-peeled-insns=12  --param max-inline-insns-single=400 --param max-inline-insns-auto=40
#OPTFLAGS=-O2 --param max-completely-peel-times=4 --param max-completely-peeled-insns=12
OPTFLAGS=-Os
CFLAGS=-I $(IDIR) $(OPTFLAGS) -std=c17 -D ROM
LINKFLAGS= -mmach=bbcb -Wl,-m,$(BDIR)/$(TARGET).map,-vm -T $(LINKCONFIG) -ffreestanding -nostartfiles
#LINKFLAGS= -mmach=bbcb -Wl,-m,$(BDIR)/$(TARGET).map -T $(LINKCONFIG) -ffreestanding -nostartfiles
OUTPUT_OPTION=-o $@

AFLAGS=

#CSRCS_PATH = $(wildcard $(patsubst %,%/*.c,$(SDIRS)))
CSRCS_PATH = \
src/font.c	\
src/init.c	\
src/rom.c	\
src/hmi.c	\
src/menu.c	\
src/swrom.c \
src/main.c  \
src/keyboard.c \
src/hardware.c \
src/libc/vsprintf.c

CSRCS = $(notdir $(CSRCS_PATH))
COBJS = $(patsubst %.c,$(BDIR)/%.o,$(CSRCS))

CLSTS = $(COBJS:.o=.lst)

vpath %.c $(sort $(dir $(CSRCS_PATH)))

ASRCS_PATH = $(wildcard $(patsubst %,%/*.s,$(SDIRS)))
ASRCS = $(notdir $(ASRCS_PATH))
AOBJS = $(patsubst %.s,$(BDIR)/%.o,$(ASRCS))

vpath %.s $(sort $(dir $(ASRCS_PATH)))

AINCS_PATH = $(wildcard $(patsubst %,%/*.inc,$(SDIRS)))



.PHONY : all
all : ver listing asm $(TARGET_PATH) install


$(TARGET_PATH): $(COBJS) $(AOBJS)
	$(CC) -o $@ $(CFLAGS) $(LINKFLAGS) $^




$(BDIR)/%.o: %.s Makefile $(AINCS_PATH)
	$(AS) $(AFLAGS) -o $@ $< 
#	$(AS) $(AFLAGS) -o $@ -l $(@:.o=.lst) $< 


.PHONY: asm
asm: $(AOBJS)

#force version update
.PHONY: ver
ver:
	touch -m $(ROMC)
#	@echo touch -m $(ROMC)

.PHONY: listing
listing: $(CLSTS)
#	@echo l $(CLSTS)

.PHONY: install
install: $(TARGET_PATH)
	cp -rf $(ODIR)/* '$(DEPLOY)'

.PHONY: clean
clean:
	rm -f $(BDIR)/*.o
	rm -f $(BDIR)/*.lst
	rm -f $(BDIR)/*.map
	rm -f $(ODIR)/*.bin
	rm -f $(DEPDIR)/*.d



DEPDIR = .d
$(shell mkdir -p $(DEPDIR) >/dev/null)
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.Td

COMPILE.c = $(CC) $(DEPFLAGS) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c
POSTCOMPILE = mv -f $(DEPDIR)/$*.Td $(DEPDIR)/$*.d

$(BDIR)/%.o : %.c
$(BDIR)/%.o : %.c $(DEPDIR)/%.d
		$(COMPILE.c) $(OUTPUT_OPTION) $<
#		$(COMPILE.c) -o $@ $<
		$(POSTCOMPILE)

$(BDIR)/%.lst: %.c $(DEPDIR)/%.d Makefile
	$(CC) -c -S $(CFLAGS) -o $@ $< 


$(DEPDIR)/%.d: ;
.PRECIOUS: $(DEPDIR)/%.d

include $(wildcard $(patsubst %,$(DEPDIR)/%.d,$(basename $(CSRCS))))