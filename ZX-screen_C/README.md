В этой папке собраны файлы для компиляции и запуска программы на языке Си.

Для компиляции нужно скачать и установить Arm GNU Toolchain с официального сайта (https://developer.arm.com/downloads/).

Для запуска понадобится эмулятор QEMU, который также можно скачать с официального сайта (https://www.qemu.org/download/).

Программа компилируется с помощью файла zx_screen_compile.bat. Возможно, вам придется изменить путь к компилятору в этом файле, так как он может различаться в зависимости от версии.

Запуск производится с помощью файла zx_screen_run.bat.

Если вам нужно скомпилировать программу для Raspberry Pi, отредактируйте адрес в файле link.ld.

Для использования другой картинки воспользуйтесь скриптом bin2c.py, чтобы преобразовать бинарный файл изображения в последовательность данных.

=================================================================

This folder contains files for compiling and running a C program.

To compile, you need to download and install Arm GNU Toolchain from the official site (https://developer.arm.com/downloads/).

To run it, you will need the QEMU emulator, which can also be downloaded from the official site (https://www.qemu.org/download/).

The program is compiled using the zx_screen_compile.bat file. You may have to change the compiler path in this file, as it may vary from version to version.

Run is done with the zx_screen_run.bat file.

If you need to compile the program for the Raspberry Pi, edit the address in the link.ld file.

To use a different image, use the bin2c.py script to convert the image binary to a data sequence.

Translated with DeepL.com (free version)
