@set toolchain="c:\Program Files (x86)\Arm GNU Toolchain arm-none-eabi\14.2 rel1\bin\arm-none-eabi"

%toolchain%-gcc -O2 -ffreestanding -nostdlib -c zx_screen.c -o zx_screen.o
%toolchain%-ld -T link.ld zx_screen.o -o kernel.elf
%toolchain%-objcopy -O binary kernel.elf kernel.img

@del zx_screen.o kernel.elf
@pause