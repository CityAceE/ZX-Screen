@set file=kernel

"c:\Program Files\qemu\qemu-system-arm.exe" -M raspi1ap -serial stdio -kernel %file%.img
