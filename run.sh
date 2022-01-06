#!/bin/bash

helpFunc() {
    echo "Parameters:"
    echo -e "    none -> build and run on qemu"
    echo -e "    -h               -> open this help menu"
    echo -e "    -i               -> build and create iso file"
    echo -e "    -b               -> only build bin file"
    echo -e "    -r               -> only run bin file"
    echo -e "    -u usb-stick-dir -> build and install on usb-stick (not yet implemented)"
    exit
}

build() {
    nasm -f bin asmtris.asm -o asmtris.bin
    nasm -f bin stage2.asm -o stage2.bin
    nasm -f bin boot.asm -o boot.bin
}

buildIso() {
    build

    dd if=/dev/zero of=asmtris.img bs=1024 count=1440 status=none
    dd if=boot.bin of=asmtris.img conv=notrunc status=none
    
    mkdir iso
    cp asmtris.img iso/
    genisoimage -quiet -V 'ASMTRIS' -o asmtris.iso \
        -b asmtris.img iso/
    rm -r iso
    
    echo "asmtris.iso was generated"
}

writeToUsb() {
    echo "Error: Function not yet implemented"
    exit 1
#    buildIso
#    if [[ $usbDrive =~ /dev/sd[A-Z]?[a-z]$ ]]; then
#        sudo umount $usbDrive
#        sudo parted --script $usbDrive \
#            mklabel gpt \
#            mkpart primary fat32 1MiB 100%
#        sudo dd if=asmtris.iso of=$usbDrive bs=1024 conv=notrunc \
#            status=progress && sync
#        echo "usb-stick is ready"
#    else
#        echo "Error: ${usbDrive} is not a drive"
#        exit 1
#    fi
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
