SRCs = $(wildcard *.asm)
BINs = $(SRCs:.asm=.bin)
FLOPPYs =$(SRCs:.asm=.img)

IMAGESIZE=1474560

.PHONY: all clean mds srcs

all: run.img

payload.bin: boot.bin splash.bin interpreter.bin
	cat $^ >$@

run.img: boot.bin splash.bin interpreter.bin
	./padded-cat.sh $(IMAGESIZE) $^ >$@
	
%.bin: %.asm
	nasm -f bin $^ -o $@

clean:
	rm -f $(BINs) run.img

