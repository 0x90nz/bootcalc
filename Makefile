AS=nasm

%.bin: %.asm
	$(AS) -f bin $(ASFLAGS) $< -o $@

.PHONY: all
all: calc.bin

.PHONY: run
run: all
	qemu-system-i386 -drive format=raw,file=calc.bin -serial mon:stdio

.PHONY: clean
clean:
	rm -f calc.bin
