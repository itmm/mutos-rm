SRCs = $(wildcard *.asm)
BINs = $(SRCs:.asm=.bin)

IMAGESIZE=1474560

.PHONY: all clean

all: run.img

payload.bin: boot.bin splash.bin interpreter.bin
	cat $^ >$@

run.img: boot.bin splash.bin interpreter.bin
	./padded-cat.sh $(IMAGESIZE) $^ >$@

%.asm: %.md
	mdp $^

%.bin: %.asm
	nasm -f bin $^ -o $@ -l $(@:.bin=.lst)

clean:
	rm -f $(BINs) run.img

