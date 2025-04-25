В этой папке собраны все файлы, необходимые для сборки и запуска программы, написанной на языке ассемблера.

Для компиляции нужно скачать ассемблер FASMARM с официального сайта (https://arm.flatassembler.net/) и поместить исполняемый файл рядом с остальными. Компиляция запускается через файл zx-screen_compile.bat.

Для запуска нужно скачать и установить эмулятор QEMU (https://www.qemu.org/download/). Запустить скомпилированную программу можно с помощью файла zx-screen_run.bat.

В программе можно изменить следующие параметры:

QEMU: 1 для запуска под эмулятором QEMU, любое другое значение — для реальной Raspberry Pi.

MODEL: 1 для Raspberry Pi 1 или Zero 1; 2 для Raspberry Pi 2 или 3.

SCREEN_X, SCREEN_Y: разрешение экрана Raspberry Pi. Используйте только стандартные значения, например, 800x600, 1024x768 и другие.

COLOR: цвет предварительной заливки экрана (бордюр). Можно выбрать любой цвет из диапазона от 0 до 15. По умолчанию установлен синий цвет — 1.




This folder contains all files necessary to build and run a program written in assembly language.

To compile, you need to download the FASMARM assembler from the official site (https://arm.flatassembler.net/) and place the executable file next to the others. The compilation is started via the zx-screen_compile.bat file.

To run it you need to download and install the QEMU emulator (https://www.qemu.org/download/). You can run the compiled program using the zx-screen_run.bat file.

The following parameters can be changed in the program:

QEMU: 1 to run under the QEMU emulator, any other value for the real Raspberry Pi.

MODEL: 1 for Raspberry Pi 1 or Zero 1; 2 for Raspberry Pi 2 or 3.

SCREEN_X, SCREEN_Y: the screen resolution of the Raspberry Pi. Use only standard values such as 800x600, 1024x768 and others.

COLOR: screen pre-fill color (border). You can select any color from the range of 0 to 15. The default setting is blue color - 1.

