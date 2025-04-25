format binary as 'img'
processor CPU32_V1 + CPU32_V6

; Конфигурация
; Режим компиляции программы:
; 0 - real Raspberry Pi
; 1 - emulator
QEMU = 1

; Модель Raspberry Pi (только для реального устройства)
; 0 - Raspberry Pi 1, Zero
; 1 - Raspberry Pi 2, 3
MODEL = 0

if QEMU = 1
MODEL = 0
end if

; Константы
if MODEL = 0
PERIPHERAL_BASE 	= 0x20000000
else
PERIPHERAL_BASE		= 0x3F000000
end if

MAIL_TAGS		= 0x8
MAIL_BASE		= 0xB880
MAIL_WRITE		= 0x20

; Mailbox команды
Set_Physical_Display	= 0x00048003
Set_Virtual_Buffer	= 0x00048004
Set_Depth		= 0x00048005
Set_Virtual_Offset	= 0x00048009
Set_Palette		= 0x0004800B
Allocate_Buffer		= 0x00040001

SCREEN_X		= 640	; Разрешение экрана по горизонтали
SCREEN_Y		= 480	; Разрешение экрана по вертикали
BITS_PER_PIXEL		= 8	; Глубина цвета экрана
COLOR			= 1	; Цвет бордюра (1 - синий)

; Начало программы
if QEMU = 1
	org	0x10000
else
	org	0x8000
end if

_start:
	mov	sp, _start

if MODEL = 1
	mrc	p15, 0, r0, c0, c0, 5
	ands	r0, 3
	bne	dead_loop
end if

; Инициализация framebuffer
; Установка разрешения дисплея, глубины цветности и палитры
fb_init:
	ldr	r0, [message_address]	; fb_struct + MAIL_TAGS
	ldr	r1, [mail_box_address]	; PERIPHERAL_BASE + MAIL_BASE + MAIL_WRITE + MAIL_TAGS
	str	r0, [r1]		; Mail Box Write
	ldr	r0, [fb_pointer]	; R0 = Frame Buffer Pointer
	cmp	r0, 0			; Compare Frame Buffer Pointer To Zero
	beq	fb_init			; IF Zero Re-Initialize Frame Buffer
	and	r0, 0x3FFFFFFF		; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address (0xCXXXXXXX -> 0x3XXXXXXX)
	str	r0, [fb_pointer]	; Store Frame Buffer Pointer Physical Address

; Заливка фона
	ldr	r1, [border_color]
	mov	r2, r1
	mov	r3, r1
	mov	r4, r1
	ldr	r5, [fb_pointer]
	mov	r6, SCREEN_X * SCREEN_Y / 16
border_fill:
	stmia	r5!, {r1, r2, r3, r4}	; Записываем 16 байт за раз
	subs	r6, 1
	bne	border_fill

;==================================================
; Основной цикл рисования экрана ZX Spectrum с цветами
	adr	r1, fb_pointer
	ldr	r2, [r1]	; r2 = базовый адрес framebuffer
	adr	r1, zx_begin
	ldr	r0, [r1]	; r0 = смещение для центра экрана
	add	r0, r2		; r0 = начальный адрес на экране
	adr	r3, zx_screen	; r3 = данные пикселей
	add	r7, r3, 0x1800	; r7 = данные атрибутов
	mov	r9, 3		; 3 трети экрана

next_third:
	mov	r8, 8		; 8 строк в знакоместе
	mov	r10, r0		; сохраняем начальный адрес трети

next_zx_line:
	push	{r7}
	mov	r6, 8		; 8 знакомест по вертикали
	mov	r11, r10	; сохраняем адрес начала строки

next_zx_row:
	mov	r5, 32		; 32 знакоместа по горизонтали

next_column:
	ldrb	r1, [r7], 1	; загружаем атрибут
	mov	r2, r1, lsr 3	; цвет бумаги
	and	r2, 1111b

	and	r4, r1, 111b	; цвет чернил
	lsr	r1, 3
	and	r1, 1000b
	orr	r4, r1		; r4 = цвет чернил

;================================
	ldrb	r1, [r3], 1	; загружаем байт пикселей
	mov	r12, 8		; 8 пикселей в байте
	add	r0, 7		; рисуем справа налево
next_pixel:
	lsrs	r1, 1		; проверяем бит
	movcc	r14, r2		; если 0 - цвет бумаги
	movcs	r14, r4		; если 1 - цвет чернил
	strb	r14, [r0], -1	; записываем пиксель
	subs	r12, 1
	bne	next_pixel
;================================

	add	r0, 9		; переходим к следующему знакоместу
	subs	r5, 1
	bne	next_column

	; Переход к следующей строке знакомест
	add	r11, SCREEN_X * 8; следующая строка в framebuffer
	mov	r0, r11
	subs	r6, 1
	bne	next_zx_row

	; Переход к следующей линии в знакоместе
	pop	{r7}
	add	r10, SCREEN_X	; следующая линия внутри знакоместа
	mov	r0, r10
	subs	r8, 1
	bne	next_zx_line

	; Переход к следующей трети экрана
	add	r7, 256
	add	r10, SCREEN_X * (64 - 8) ; между третями 64 линии всего
	mov	r0, r10
	subs	r9, 1
	bne	next_third
;==================================================

dead_loop:
if MODEL = 1
	wfe
end if
	b	dead_loop

; Данные
	align	16
fb_struct:
	dw	fb_struct_end - fb_struct
	dw	0
	; Set Physical Display
	dw	Set_Physical_Display, 8, 8
	dw	SCREEN_X, SCREEN_Y
	; Set Virtual Buffer
	dw	Set_Virtual_Buffer, 8, 8
	dw	SCREEN_X, SCREEN_Y
	; Set Depth
	dw	Set_Depth, 4, 4
	dw	BITS_PER_PIXEL
	; Set Virtual Offset
	dw	Set_Virtual_Offset, 8, 8
	dw	0, 0
	; Set Palette
	dw	Set_Palette, 72, 72
	dw	0, 16
	; Палитра цветов (16 цветов ZX Spectrum)
	;	R     G     B     Alpha
	db	0x00, 0x00, 0x00, 0x00	; Black
	db	0x00, 0x00, 0xCD, 0x00	; Blue
	db	0xCD, 0x00, 0x00, 0x00	; Red
	db	0xCD, 0x00, 0xCD, 0x00	; Magenta
	db	0x00, 0xCD, 0x00, 0x00	; Green
	db	0x00, 0xCD, 0xCD, 0x00	; Cyan
	db	0xCD, 0xCD, 0x00, 0x00	; Yellow
	db	0xCD, 0xCD, 0xCD, 0x00	; White
	db	0x00, 0x00, 0x00, 0x00	; Bright Black
	db	0x00, 0x00, 0xFF, 0x00	; Bright Blue
	db	0xFF, 0x00, 0x00, 0x00	; Bright Red
	db	0xFF, 0x00, 0xFF, 0x00	; Bright Magenta
	db	0x00, 0xFF, 0x00, 0x00	; Bright Green
	db	0x00, 0xFF, 0xFF, 0x00	; Bright Cyan
	db	0xFF, 0xFF, 0x00, 0x00	; Bright Yellow
	db	0xFF, 0xFF, 0xFF, 0x00	; Bright White
	; Allocate Buffer
	dw	Allocate_Buffer, 8, 8
fb_pointer:
	dw	0, 0
	; End Tag
	dw	0
fb_struct_end:

zx_begin:
	dw	(SCREEN_Y - 192) / 2 * SCREEN_X + (SCREEN_X - 256) / 2

message_address:
	dw	fb_struct + MAIL_TAGS
mail_box_address:
	dw	PERIPHERAL_BASE + MAIL_BASE + MAIL_WRITE + MAIL_TAGS

border_color:
	db	COLOR, COLOR, COLOR, COLOR

zx_screen:
	file	"exolon.scr"
