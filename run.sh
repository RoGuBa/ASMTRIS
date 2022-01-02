#!/bin/bash

helpFunc() {
    echo "Parameters:"
    echo -e "    none -> build and run on qemu"
    echo -e "    -h   -> open this help menu"
    echo -e "    -i   -> build and create iso file"    
    exit
}

build() {
    nasm -f bin stage2.asm -o stage2.bin
    nasm -f bin boot.asm -o boot.bin
}

buildIso() {
    dd if=/dev/zero of=tetris.img bs=1024 count=1440 status=none
    dd if=boot.bin of=tetris.img seek=0 count=1 conv=notrunc status=none
    
    mkdir iso
    cp tetris.img iso/
    genisoimage -quiet -V 'TETRIS' -input-charset iso8859-1 -o tetris.iso \
        -b tetris.img -hide tetris.img iso/
    rm -r iso
    
    echo "tetris.iso was generated"
    exit 0
}

run() {
    qemu-system-x86_64 boot.bin
}

while getopts "hi" opt; do
    case $opt in
        i ) build
            buildIso
            ;;
        h | ? ) helpFunc
            ;;
    esac
done

build
run
