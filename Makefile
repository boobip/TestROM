TARGET=test
LINKCONFIG=./bbcbx.cfg
SDIRS = src src/common src/libc src/3rdparty
IDIR=src/libc
BDIR=Debug
ODIR=bin
EXODIR=exo
NOOVL_PATH=$(ODIR)/$(TARGET).noovl.bin
TARGET_PATH=$(ODIR)/$(TARGET).bin
ROMC=src/rom.c

CC=/mnt/c/Code/gcc6502/gcc8-6502-bits/prefix/bin/6502-gcc
AS=ca65
#OPTFLAGS=-O3 --param max-completely-peel-times=4 --param max-completely-peeled-insns=12  --param max-inline-insns-single=400 --param max-inline-insns-auto=40
#OPTFLAGS=-O2 --param max-completely-peel-times=4 --param max-completely-peeled-insns=12
OPTFLAGS=-Os
#CFLAGS=-I $(IDIR) $(OPTFLAGS) -std=c17 -D ROM
CFLAGS=-I $(IDIR) $(OPTFLAGS) -std=c17 -Wall
LINKFLAGS= -mmach=bbcb -Wl,-m,$(BDIR)/$(TARGET).map,-vm -T $(LINKCONFIG) -ffreestanding -nostartfiles
#LINKFLAGS= -mmach=bbcb -Wl,-m,$(BDIR)/$(TARGET).map -T $(LINKCONFIG) -ffreestanding -nostartfiles
OUTPUT_OPTION=-o $@

AFLAGS=

EXO=exomizer
EXOFLAGS=raw -q
EXOSTART=`awk '/__ADDRLUTHI_RUN__/{print $$2; exit;}' $(BDIR)/test.map`


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
src/zeropage.c \
src/libc/vsprintf.c

CSRCS = $(notdir $(CSRCS_PATH))
COBJS = $(patsubst %.c,$(BDIR)/%.o,$(CSRCS))

CLSTS = $(COBJS:.o=.s)

vpath %.c $(sort $(dir $(CSRCS_PATH)))

ASRCS_PATH = $(wildcard $(patsubst %,%/*.s,$(SDIRS)))
ASRCS = $(notdir $(ASRCS_PATH))
AOBJS = $(patsubst %.s,$(BDIR)/%.o,$(ASRCS))

vpath %.s $(sort $(dir $(ASRCS_PATH)))

AINCS_PATH = $(wildcard $(patsubst %,%/*.inc,$(SDIRS)))

OVERLAYS_PATH = \
bin/ovl_init.bin \
bin/ovl_menu.bin \
bin/test_ovl2.bin
OVLSRCS = $(notdir $(OVERLAYS_PATH))
OVLEXOS = $(patsubst %.bin,$(ODIR)/%.exo,$(OVLSRCS))
OVLSUMS = $(patsubst %.bin,$(ODIR)/%.md5,$(OVLSRCS))

.PHONY : all
all : ver $(TARGET_PATH) install
#all : ver asm $(NOOVL_PATH)  $(TARGET_PATH) install


$(NOOVL_PATH): $(COBJS) $(AOBJS)
	$(CC) -o $@ $(CFLAGS) $(LINKFLAGS) $^


$(BDIR)/%.o: %.s Makefile $(AINCS_PATH)
#	$(AS) $(AFLAGS) -o $@ $< 
	$(AS) $(AFLAGS) -o $@ -l $(@:.o=.lst) $< 

$(ODIR)/%.exo: $(ODIR)/%.md5
	$(EXO) $(EXOFLAGS) $(<:.md5=.bin) -o $@

$(OVLSUMS): %.md5: %.bin
	@md5sum $< > $@.tmp; cmp -s $@ $@.tmp || cp $@.tmp $@; rm -f $@.tmp


$(ODIR)/%.bin: $(NOOVL_PATH) ;


$(TARGET_PATH): $(NOOVL_PATH) $(OVLEXOS) src/overlays.6502
	$(eval SADDR:=$(shell awk 'match($$0,/__OVERLAYS_LOAD__\s+([[:xdigit:]]+)/,arr){print arr[1]; exit}' $(BDIR)/test.map))
	beebasm -vc -D EXOSTARTADDR=0x$(SADDR) -o $(TARGET_PATH) -i src/overlays.6502
#	awk 'match($$0,/__OVERLAYS_LOAD__\s+([[:xdigit:]]+)/,arr){print arr[1]; exit}' $(BDIR)/test.map | xargs -I {} beebasm -vc -D EXOSTARTADDR=0x{} -o $(TARGET_PATH) -i src/overlays.6502

.PHONY: asm
asm: $(AOBJS)

#force version update
.PHONY: ver
ver:
	touch -m $(ROMC)
#	@echo touch -m $(ROMC)


.PHONY: install
install: $(TARGET_PATH)
#	cp -rf $(ODIR)/* '$(DEPLOY)'
	cp -rf $(TARGET_PATH) '$(DEPLOY)'

.PHONY: clean
clean:
	rm -f $(BDIR)/*.o
	rm -f $(BDIR)/*.s
	rm -f $(BDIR)/*.lst
	rm -f $(BDIR)/*.map
	rm -f $(ODIR)/*.md5
	rm -f $(ODIR)/*.exo
	rm -f $(ODIR)/*.bin
	rm -f $(DEPDIR)/*.d



DEPDIR = .d
$(shell mkdir -p $(DEPDIR) >/dev/null)
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.Td

COMPILE.c = $(CC) $(DEPFLAGS) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c
POSTCOMPILE = mv -f $(DEPDIR)/$*.Td $(DEPDIR)/$*.d && touch $@

$(BDIR)/%.s : %.c
$(BDIR)/%.s : %.c $(DEPDIR)/%.d 
	$(COMPILE.c) -S -o $@ $<
	$(POSTCOMPILE)
	awk 'match($$0,/;overlay=(\w+)/,arr){print arr[1]; exit}' $@ | xargs -r -I {} sed -i -E 's/(.segment\s+)"(DATA|RODATA)"/\1 "{}\2"/g' $@

.PRECIOUS: $(BDIR)/%.s

$(DEPDIR)/%.d: ;
.PRECIOUS: $(DEPDIR)/%.d



include $(wildcard $(patsubst %,$(DEPDIR)/%.d,$(basename $(CSRCS))))