#include "exolon.h"

/* Объявления для секций */
extern unsigned int __bss_start[];
extern unsigned int __bss_end[];

/* Атрибуты для стартовой функции */
__attribute__((naked, section(".text.boot"))) void _start(void) {
    /* Установка стека */
    asm volatile(
        "ldr r0, =_start\n\t"
        "mov sp, r0\n\t"
    );
    
    /* Очистка BSS */
    unsigned int *bss_start = __bss_start;
    unsigned int *bss_end = __bss_end;
    while (bss_start < bss_end) {
        *bss_start++ = 0;
    }
    
    /* Переход к main */
    asm volatile(
        "bl main\n\t"
        
        /* Бесконечный цикл на случай, если main вернётся */
        "1: b 1b\n\t"
    );
}

/* Mailbox constants */
#define MBOX_REQUEST    0
#define MBOX_CH_PROPERTY  8
#define MBOX_TAG_LAST   0

/* Framebuffer tags */
#define ALLOCATE_BUFFER        0x40001
#define GET_PITCH              0x40008
#define SET_PHYSICAL_DISPLAY   0x48003
#define SET_VIRTUAL_BUFFER     0x48004
#define SET_DEPTH              0x48005
#define GET_PIXEL_ORDER        0x48006
#define GET_VIRTUAL_OFFSET     0x48009
#define SET_PALETTE            0x4800B

/* Display settings */
#define SCREEN_WIDTH    640
#define SCREEN_HEIGHT   480
#define SCREEN_DEPTH    8

/* MMIO registers */
#define MMIO_BASE       0x20000000
#define VIDEOCORE_MBOX  (MMIO_BASE + 0x0000B880)
#define MBOX_READ       ((volatile unsigned int*)(VIDEOCORE_MBOX + 0x0))
#define MBOX_STATUS     ((volatile unsigned int*)(VIDEOCORE_MBOX + 0x18))
#define MBOX_WRITE      ((volatile unsigned int*)(VIDEOCORE_MBOX + 0x20))
#define MBOX_RESPONSE   0x80000000
#define MBOX_FULL       0x80000000
#define MBOX_EMPTY      0x40000000

/* Framebuffer state structure */
typedef struct {
    unsigned int width;
    unsigned int height;
    unsigned int pitch;
    unsigned int is_rgb;
    unsigned char *buffer;
} framebuffer_state_t;

static framebuffer_state_t framebuffer;

/* Mailbox message buffer (16-byte aligned) */
static volatile unsigned int __attribute__((aligned(16))) mailbox_buffer[57];

/**
 * Make mailbox call
 * @param channel Mailbox channel to use
 * @return 1 on success, 0 on failure
 */
static int mailbox_call(unsigned char channel)
{
    unsigned int message = ((unsigned int)((unsigned long)&mailbox_buffer & ~0xF) | (channel & 0xF));
    
    /* Wait until mailbox is not full */
    while (*MBOX_STATUS & MBOX_FULL) {
        asm volatile("nop");
    }
    
    /* Write message address */
    *MBOX_WRITE = message;
    
    /* Wait for response */
    while (1) {
        /* Wait until mailbox is not empty */
        while (*MBOX_STATUS & MBOX_EMPTY) {
            asm volatile("nop");
        }
        
        /* Check if this is our response */
        if (message == *MBOX_READ) {
            return mailbox_buffer[1] == MBOX_RESPONSE;
        }
    }
}

/* ZX Spectrum color palette (BGR888) */
static const unsigned int zx_palette[16] = {
    0x000000,  // 00 Black
    0xCD0000,  // 01 Blue
    0x0000CD,  // 02 Red
    0xCD00CD,  // 03 Magenta
    0x00CD00,  // 04 Green
    0xCDCD00,  // 05 Cyan
    0x00CDCD,  // 06 Yellow
    0xCDCDCD,  // 07 White
    0x000000,  // 08 Black + Bright
    0xFF0000,  // 09 Blue + Bright
    0x0000FF,  // 0A Red + Bright
    0xFF00FF,  // 0B Magenta + Bright
    0x00FF00,  // 0C Green + Bright
    0xFFFF00,  // 0D Cyan + Bright
    0x00FFFF,  // 0E Yellow + Bright
    0xFFFFFF   // 0F White + Bright
};

/**
 * Initialize framebuffer
 */
static void initialize_framebuffer(void)
{
    volatile unsigned int *current_tag = &mailbox_buffer[2];
    unsigned int tags_size = 0;

    /* Macro to add mailbox tag */
    #define ADD_MAILBOX_TAG(tag_id, request_size, response_size, ...) do { \
        *current_tag++ = tag_id; \
        *current_tag++ = request_size; \
        *current_tag++ = response_size; \
        __VA_ARGS__ \
        tags_size += 3 + (request_size)/4; \
    } while (0)

    /* Set physical display dimensions */
    ADD_MAILBOX_TAG(SET_PHYSICAL_DISPLAY, 8, 8,
        *current_tag++ = SCREEN_WIDTH;
        *current_tag++ = SCREEN_HEIGHT;
    );

    /* Set virtual buffer dimensions */
    ADD_MAILBOX_TAG(SET_VIRTUAL_BUFFER, 8, 8,
        *current_tag++ = SCREEN_WIDTH;
        *current_tag++ = SCREEN_HEIGHT;
    );

    /* Set virtual offset */
    ADD_MAILBOX_TAG(GET_VIRTUAL_OFFSET, 8, 8,
        *current_tag++ = 0; /* x offset */
        *current_tag++ = 0; /* y offset */
    );

    /* Set color depth */
    ADD_MAILBOX_TAG(SET_DEPTH, 4, 4,
        *current_tag++ = SCREEN_DEPTH;
    );

    /* Set palette */
    ADD_MAILBOX_TAG(SET_PALETTE, 8 + 16 * 4, 8 + 16 * 4,
	*current_tag++ = 0; //Value Buffer (Offset: First Palette Index To Set (0-255))
        *current_tag++ = 16; //Value Buffer (Length: Number Of Palette Entries To Set (1-256))
        for (int i = 0; i < 16; i++) {
            *current_tag++ = zx_palette[i];
        }
    );

    /* Allocate framebuffer */
    ADD_MAILBOX_TAG(ALLOCATE_BUFFER, 8, 8,
        *current_tag++ = 0; /* alignment */
        *current_tag++ = 0;    /* size (will be filled) */
    );

    /* Get pitch */
    ADD_MAILBOX_TAG(GET_PITCH, 4, 4,
        *current_tag++ = 0; /* placeholder */
    );

    /* End tag */
    *current_tag++ = MBOX_TAG_LAST;
    tags_size++;

    /* Setup message header */
    mailbox_buffer[0] = (2 + tags_size) * 4; /* total message size */
    mailbox_buffer[1] = MBOX_REQUEST;

    /* Make mailbox call */
    if (mailbox_call(MBOX_CH_PROPERTY)) {
        /* Convert GPU address to ARM address */
        mailbox_buffer[28] &= 0x3FFFFFFF;
        
        /* Store framebuffer parameters */
        framebuffer.width = mailbox_buffer[5];
        framebuffer.height = mailbox_buffer[6];
        framebuffer.buffer = (unsigned char*)((unsigned long)mailbox_buffer[45]);
        framebuffer.pitch = mailbox_buffer[50];
    }

    #undef ADD_MAILBOX_TAG
}

/**
 * Fill screen with border color
 */
static void fill_border(int border_color)
{
    unsigned char *ptr = framebuffer.buffer;
    unsigned int total_pixels = framebuffer.pitch * framebuffer.height;
    
    for (unsigned int i = 0; i < total_pixels; i++) {
        *ptr++ = border_color;
    }
}

/**
 * Display ZX Spectrum picture (6912 bytes: 6144 pixels + 768 attributes)
 * Fixed color issues and optimized
 */
static void display_picture(void)
{
    // Center the 256x192 image on screen
    const unsigned int x_offset = (framebuffer.width - 256) / 2;
    const unsigned int y_offset = (framebuffer.height - 192) / 2;
    
    const unsigned char *pixels = exolon_scr;     // Pixel data (6144 bytes)
    const unsigned char *attrs = exolon_scr + 6144; // Attributes (768 bytes)
    
    // Process all 192 scanlines (organized in 3 thirds)
    for (int third = 0; third < 3; third++) {
        for (int char_row = 0; char_row < 8; char_row++) {
            for (int char_x = 0; char_x < 32; char_x++) {
                // Get and decode attributes
                const unsigned char attr = attrs[(third * 8 + char_row) * 32 + char_x];
                const unsigned char bright = (attr & 0x40) ? 0x08 : 0x00;
                const unsigned char paper = ((attr >> 3) & 0x07) | bright;
                const unsigned char ink = (attr & 0x07) | bright;
                
                // Process each of 8 pixel lines
                for (int line = 0; line < 8; line++) {
                    // Calculate memory addresses
                    const int y_pos = y_offset + third * 64 + char_row * 8 + line;
                    const int pix_addr = third * 2048 + line * 256 + char_row * 32 + char_x;
                    unsigned char *fb_ptr = framebuffer.buffer + y_pos * framebuffer.pitch + x_offset + char_x * 8;
                    
                    // Draw 8 pixels
                    const unsigned char pix_byte = pixels[pix_addr];
                    for (int bit = 0; bit < 8; bit++) {
                        fb_ptr[bit] = (pix_byte & (0x80 >> bit)) ? ink : paper;
                    }
                }
            }
        }
    }
}

/**
 * Main function
 */
void main(void)
{
    /* Initialize framebuffer */
    initialize_framebuffer();
    
    /* Fill screen with border color */
    fill_border(1);
    
    /* Display ZX Spectrum picture */
    display_picture();
    
    /* Halt */
    while(1);
}