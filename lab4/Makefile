AS = nasm
CC = gcc

ASFLAGS = -g -f elf64
LDFLAGS = -static -no-pie

SRCS = lab4.s
OBJS = $(SRCS:.s=.o)
EXE = lab4

all: $(EXE)

clean:
	rm -f $(EXE) $(OBJS)

$(EXE): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^ -lm

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

