#!/bin/bash
rm -f a.out *.o *.bin
ca65 --cpu 65C02 bios.s
ca65 --cpu 65C02 system.s
ca65 --cpu 65C02 wozmon.s
#ar65 r bios.lib bios.o
ld65 -C bios.cfg bios.o system.o wozmon.o -Ln bios.lbl -m bios.map