#!/bin/bash

#nasm -f bin boot.asm -o boot.bin
#qemu-system-x86_64 boot.bin

### stage 2 ###
nasm -f bin stage2.asm -o stage2.bin

nasm -f bin boot.asm -o boot.bin

qemu-system-x86_64 boot.bin
