FLASH := stm8flash
FLASH_OPTS := -p $(MCU) -c stlinkv2

INCLUDES := -I ../../lib/stm8-asm-lib/include

NAKEN := naken_asm
NAKEN_OPTS := -l $(INCLUDES)

all: $(TARGET).hex

bin: $(TARGET).bin
elf: $(TARGET).elf
hex: $(TARGET).hex
srec: $(TARGET).srec

%.bin: %.asm
	@echo "NAKEN $? -> $@"
	@$(NAKEN) $(NAKEN_OPTS) -type bin -o $@ $<

%.elf: %.asm
	@echo "NAKEN $? -> $@"
	@$(NAKEN) $(NAKEN_OPTS) -type elf -o $@ $<

%.hex: %.asm
	@echo "NAKEN $? -> $@"
	@$(NAKEN) $(NAKEN_OPTS) -type hex -o $@ $<

%.srec: %.asm
	@echo "NAKEN $? -> $@"
	@$(NAKEN) $(NAKEN_OPTS) -type srec -o $@ $<

clean:
	@echo "CLEAN"
	@rm -f $(TARGET).{hex,bin,elf,srec,lst}

flash: $(TARGET).hex
	@echo "FLASH $?"
	$(FLASH) $(FLASH_OPTS) -w $<

.PHONY: all clean flash

