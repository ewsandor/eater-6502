#!/bin/bash
rm -f a.out bios.o bios_eeprom.bin
ca65 --cpu 65C02 bios.s
#ar65 r bios.lib bios.o
ld65 -C bios.cfg bios.o -Ln bios.lbl