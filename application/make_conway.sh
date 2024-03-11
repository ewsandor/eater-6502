#!/bin/bash
rm -f a.out conway.o conway_ram.bin
ca65 --cpu 65C02 conway.s -I ../bios
ld65 -C app.cfg conway.o -Ln conway.lbl -m conway.map