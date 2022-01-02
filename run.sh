#!/bin/bash

helpFunc() {
    echo "Parameters:"
    echo -e "    none -> build and run on qemu"
    echo -e "    -h               -> open this help menu"
    echo -e "    -i               -> build and create iso file"
    echo -e "    -b               -> only build bin file"
    echo -e "    -r               -> only run bin file"
    echo -e "    -u usb-stick-dir -> build and install on usb-stick"
    exit
}

build() {
    nasm -f bin tetris.asm -o tetris.bin
    nasm -f bin stage2.asm -o stage2.bin
    nasm -f bin boot.asm -o boot.bin
}

buildIso() {
    build

    dd if=/dev/zero of=tetris.img bs=1024 count=1440 status=none
    dd if=boot.bin of=tetris.img conv=notrunc status=none
    
    mkdir iso
    cp tetris.img iso/
    genisoimage -quiet -V 'TETRIS' -o tetris.iso \
        -b tetris.img iso/
    rm -r iso
    
    echo "tetris.iso was generated"
}

writeToUsb() {
    buildIso
    if [[ $usbDrive =~ /dev/sd[A-Z]?[a-z]$ ]]; then
        sudo umount $usbDrive
        sudo dd if=tetris.iso of=$usbDrive bs=1024 conv=notrunc \
            status=progress && sync
        echo "usb-stick is ready"
    else
        echo "Error: ${usbDrive} is not a drive"
        exit 1
    fi
}

run() {
    qemu-system-x86_64 boot.bin
}

while getopts "u:ibrh" opt; do
    case $opt in
        u )
            usbDrive=$OPTARG
            writeToUsb
            exit
            ;;
        i ) 
            buildIso
            exit
            ;;
        b ) 
            build
            exit
            ;;
        r )
            run
            exit
            ;;
        h | ? )
            helpFunc
            exit
            ;;
    esac
done

build
run
