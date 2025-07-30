AS = /usr/bin/nasm
LD = /usr/bin/ld

ASFLAGS = -g -f elf64
LDFLAGS = -static

SRCS = lab2.s
OBJS = $(SRCS:.s=.o)

EXE = lab2

FILEFLAGS = $(FILEOUTPUTFLAG) $(FILEINPUTFLAG)

all: $(EXE)

clean:
	rm -rf $(EXE) $(OBJS)

%.o: %.s
	$(AS) $(ASFLAGS) $(FILEFLAGS) -o $@ $<

$(EXE): $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -o $@
