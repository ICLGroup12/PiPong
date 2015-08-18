# PiPong

Baremetal assembly Pong for the Raspberry Pi

---

 # About
 
PiPong was developed as an extension to a 2 week long group project during the first year of the computing course at Imperial College London. It runs on the Raspberry Pi without an operating system (replacing the linux kernel kernel.img) and was designed for assembly using our own assembler also produced as part of the project.

---

# Assembly (using cross compiler toolchains)

Throughout the project PiPong was assembled using our own assembler
```sh
$ arm-linux-gnueabi-as -o main.o main.s 
$ arm-linux-gnueabi-ld -Ttext=0x8000 -o main.elf main.o 
$ arm-linux-gnueabi-objcopy -O binary main.elf kernel.img
```
---

# Installation

To install PiPong replace the kernel.img and config.txt files on the Pi's SD card with the config.txt file found in the repository and the kernel.img file generated in the assembly step.

---

# Authors

Oliver Brown
- Email: oliver.brown14@imperial.ac.uk
- Github: @obrown

Giacomo Guerci
- Email: giacomo.guerci14@imperial.ac.uk
- Github: @giacomoguerci

Dylan Gape
- Email: dylan.gape14@imperial.ac.uk

Frances Tibble
- Email: frances.tibble14@imperial.ac.uk
