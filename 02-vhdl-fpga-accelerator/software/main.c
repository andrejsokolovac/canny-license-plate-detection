#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xil_cache.h"
#include "xil_types.h"
#include "xtime_l.h"
#include "grayscale_image.h"

/*
 * Addresses from Vivado Address Editor
 */
#define CANNY_BASE 0x43C00000U   // S00_AXI - AXI-Lite registers
#define CANNY_MEM  0x43C80000U   // S01_AXI - AXI-Full memory space

/*
 * AXI-Lite register map
 */
#define REG_ROWS      0x00U
#define REG_COLS      0x04U
#define REG_LOW_TH    0x08U
#define REG_HIGH_TH   0x0CU
#define REG_START     0x10U
#define REG_READY     0x14U

/*
 * AXI-Full memory map
 */
#define INPUT_OFF     0x00000U
#define EDGE_OFF      0x40000U

/*
 * Current implementation parameters
 */
#define ROWS_RUN      96U
#define COLS_RUN      128U
#define IMG_PIXELS    (ROWS_RUN * COLS_RUN)
#define IMG_WORDS     (IMG_PIXELS / 4U)

#define LOW_TH_RUN    50U
#define HIGH_TH_RUN   100U

static u32 ticks_to_us(XTime ticks)
{
    return (u32)((ticks * 1000000ULL) / COUNTS_PER_SECOND);
}

static void print_fps_from_us(const char *label, u32 time_us)
{
    if (time_us == 0U) {
        xil_printf("%s FPS: invalid, time_us=0\r\n", label);
        return;
    }

    u32 fps_x10 = (u32)(10000000ULL / time_us);

    xil_printf("%s FPS = %lu.%lu\r\n",
               label,
               (unsigned long)(fps_x10 / 10U),
               (unsigned long)(fps_x10 % 10U));
}

static void print_throughput_from_us(const char *label, u32 time_us)
{
    if (time_us == 0U) {
        xil_printf("%s throughput: invalid, time_us=0\r\n", label);
        return;
    }

    u32 pixels_per_sec = (u32)(((u64)IMG_PIXELS * 1000000ULL) / time_us);

    xil_printf("%s throughput = %lu pixels/s\r\n",
               label,
               (unsigned long)pixels_per_sec);
}

/*
 * Pack 4 consecutive 8-bit pixels into one 32-bit AXI word.
 */
static inline u32 pack4(u32 i, const unsigned char *img)
{
    u32 p0 = (u32)img[4U * i + 0U] & 0xFFU;
    u32 p1 = (u32)img[4U * i + 1U] & 0xFFU;
    u32 p2 = (u32)img[4U * i + 2U] & 0xFFU;
    u32 p3 = (u32)img[4U * i + 3U] & 0xFFU;

    return p0 | (p1 << 8) | (p2 << 16) | (p3 << 24);
}

static void write_grayscale_image(void)
{
    for (u32 i = 0; i < IMG_WORDS; i++) {
        Xil_Out32(CANNY_MEM + INPUT_OFF + i * 4U, pack4(i, grayscale_image));
    }
}

static int readback_input_check_simple(void)
{
    int errors = 0;

    for (u32 i = 0; i < 16U; i++) {
        u32 got = Xil_In32(CANNY_MEM + INPUT_OFF + i * 4U);
        u32 exp = pack4(i, grayscale_image);

        if (got != exp) {
            errors++;
        }
    }

    if (errors == 0) {
        return 0;
    } else {
        return -1;
    }
}

static inline u32 canny_ready(void)
{
    return Xil_In32(CANNY_BASE + REG_READY) & 0x1U;
}

static int wait_ready_value(u32 wanted)
{
    volatile u32 timeout = 0;

    while (canny_ready() != wanted) {
        timeout++;

        if (timeout == 200000000U) {
            return -1;
        }
    }

    return 0;
}

static void configure_canny(void)
{
    Xil_Out32(CANNY_BASE + REG_START, 0U);

    Xil_Out32(CANNY_BASE + REG_ROWS, ROWS_RUN);
    Xil_Out32(CANNY_BASE + REG_COLS, COLS_RUN);
    Xil_Out32(CANNY_BASE + REG_LOW_TH, LOW_TH_RUN);
    Xil_Out32(CANNY_BASE + REG_HIGH_TH, HIGH_TH_RUN);
}

static int start_canny_and_wait(void)
{
    u32 ready_before;

    xil_printf("\r\n--- IP START AND READY HANDSHAKE ---\r\n");

    ready_before = canny_ready();
    xil_printf("READY before start = %lu\r\n", (unsigned long)ready_before);

    Xil_Out32(CANNY_BASE + REG_START, 1U);
    Xil_Out32(CANNY_BASE + REG_START, 0U);

    if (wait_ready_value(0U) < 0) {
        xil_printf("READY did not go to 0. IP start failed.\r\n");
        return -1;
    }

    xil_printf("READY went to 0 -> IP running\r\n");

    if (wait_ready_value(1U) < 0) {
        xil_printf("READY did not return to 1. IP did not finish.\r\n");
        return -1;
    }

    xil_printf("READY returned to 1 -> IP finished\r\n");

    return 0;
}

static void count_edge_pixels(u32 *nonzero_out, u32 *edge255_out)
{
    u32 nonzero_count = 0U;
    u32 edge_255_count = 0U;

    for (u32 i = 0; i < IMG_WORDS; i++) {
        u32 word = Xil_In32(CANNY_MEM + EDGE_OFF + i * 4U);

        for (u32 b = 0; b < 4U; b++) {
            u32 pix = (word >> (8U * b)) & 0xFFU;

            if (pix != 0U) {
                nonzero_count++;
            }

            if (pix == 255U) {
                edge_255_count++;
            }
        }
    }

    *nonzero_out = nonzero_count;
    *edge255_out = edge_255_count;
}

int main(void)
{
    XTime t_write_start, t_write_end;
    XTime t_ip_start, t_ip_end;
    XTime t_read_start, t_read_end;

    u32 write_us = 0U;
    u32 ip_us = 0U;
    u32 read_us = 0U;
    u32 total_us = 0U;

    u32 edge_nonzero = 0U;
    u32 edge_255 = 0U;

    init_platform();

    /*
     * Disable caches for simple memory-mapped AXI testing.
     */
    Xil_DCacheDisable();
    Xil_ICacheDisable();

    xil_printf("\r\n");
    xil_printf("========================================\r\n");
    xil_printf("CANNY AXI HARDWARE RUN\r\n");
    xil_printf("========================================\r\n");

    xil_printf("CANNY_BASE = 0x%08lx\r\n", (unsigned long)CANNY_BASE);
    xil_printf("CANNY_MEM  = 0x%08lx\r\n", (unsigned long)CANNY_MEM);

    xil_printf("\r\n--- IP CONFIGURATION ---\r\n");
    xil_printf("Low threshold  = %lu\r\n", (unsigned long)LOW_TH_RUN);
    xil_printf("High threshold = %lu\r\n", (unsigned long)HIGH_TH_RUN);

    /*
     * 1) Write input image
     */
    xil_printf("\r\n--- WRITE INPUT IMAGE ---\r\n");
    xil_printf("Writing input image to IP memory...\r\n");

    XTime_GetTime(&t_write_start);
    write_grayscale_image();
    XTime_GetTime(&t_write_end);

    write_us = ticks_to_us(t_write_end - t_write_start);

    xil_printf("Input image write: DONE\r\n");

    /*
     * Short AXI-Full readback check.
     * This is only a hardware communication check.
     */
    xil_printf("\r\n--- AXI-FULL CHECK ---\r\n");

    if (readback_input_check_simple() < 0) {
        xil_printf("AXI-Full input readback: FAILED\r\n");
        xil_printf("TEST FAILED\r\n");
        cleanup_platform();
        return 0;
    }

    xil_printf("AXI-Full input readback: PASSED\r\n");

    /*
     * 2) Configure IP through AXI-Lite
     */
    xil_printf("\r\n--- AXI-LITE CONFIGURATION ---\r\n");

    configure_canny();

    xil_printf("AXI-Lite register configuration: DONE\r\n");

    /*
     * 3) Start IP and measure processing time
     */
    XTime_GetTime(&t_ip_start);

    if (start_canny_and_wait() < 0) {
        xil_printf("\r\nTEST FAILED: READY handshake failed.\r\n");
        cleanup_platform();
        return 0;
    }

    XTime_GetTime(&t_ip_end);

    ip_us = ticks_to_us(t_ip_end - t_ip_start);

    /*
     * 4) Read/count output edge image
     */
    xil_printf("\r\n--- READ EDGE OUTPUT ---\r\n");
    xil_printf("Reading output data from IP memory...\r\n");

    XTime_GetTime(&t_read_start);
    count_edge_pixels(&edge_nonzero, &edge_255);
    XTime_GetTime(&t_read_end);

    read_us = ticks_to_us(t_read_end - t_read_start);

    xil_printf("Output read/count: DONE\r\n");

    /*
     * Total system time = input write + IP processing + output read/count.
     */
    total_us = write_us + ip_us + read_us;

    xil_printf("\r\n");
    xil_printf("========================================\r\n");
    xil_printf("TIMING RESULTS\r\n");
    xil_printf("========================================\r\n");

    xil_printf("Write input image time = %lu us\r\n", (unsigned long)write_us);
    xil_printf("IP processing time     = %lu us\r\n", (unsigned long)ip_us);
    xil_printf("Read/count edge time   = %lu us\r\n", (unsigned long)read_us);
    xil_printf("Total system time      = %lu us\r\n", (unsigned long)total_us);

    xil_printf("\r\n--- IP-ONLY PERFORMANCE ---\r\n");
    print_fps_from_us("IP-only", ip_us);
    print_throughput_from_us("IP-only", ip_us);

    xil_printf("\r\n--- END-TO-END SYSTEM PERFORMANCE ---\r\n");
    print_fps_from_us("System", total_us);
    print_throughput_from_us("System", total_us);

    xil_printf("\r\n");
    xil_printf("========================================\r\n");
    xil_printf("CANNY HARDWARE TEST COMPLETED\r\n");
    xil_printf("========================================\r\n");

    cleanup_platform();
    return 0;
}
