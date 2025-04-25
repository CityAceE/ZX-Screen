ENTRY(_start)

/* Явное определение сегментов с разными правами доступа */
PHDRS {
    text PT_LOAD FLAGS(5); /* RX (Read + Execute) */
    data PT_LOAD FLAGS(6); /* RW (Read + Write) */
}

SECTIONS {
    /* 0x10000 - адрес для запуска в QEMU*/
    /* 0x08000 - адрес для запуска на реальной Raspberry Pi*/
    . = 0x10000;
    
    /* Текстовая секция (только для исполнения) */
    .text : {
        KEEP(*(.text.boot))    /* Стартовый код должен быть первым */
        *(.text .text.* .gnu.linkonce.t*)
    } :text                    /* Относится к сегменту text */
    
    /* Read-only данные */
    .rodata : {
        *(.rodata .rodata.* .gnu.linkonce.r*)
    } :text                    /* Тот же сегмент, что и код */
    
    /* Инициализированные данные */
    .data : {
        *(.data .data.* .gnu.linkonce.d*)
    } :data                    /* Относится к сегменту data */
    
    /* Неинициализированные данные (BSS) */
    .bss (NOLOAD) : {
        . = ALIGN(16);
        __bss_start = .;
        *(.bss .bss.*)
        *(COMMON)
        __bss_end = .;
    } :data                    /* Тоже сегмент data */
    
    /* Конец ядра */
    _end = .;
    
    /* Отбрасываем ненужные секции */
    /DISCARD/ : {
        *(.comment)
        *(.gnu*)
        *(.note*)
        *(.eh_frame*)
    }
}

/* Символы для очистки BSS */
__bss_size = (__bss_end - __bss_start) >> 3;