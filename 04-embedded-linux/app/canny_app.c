#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>

#define CANNY_WIDTH       128U
#define CANNY_HEIGHT      96U
#define CANNY_PIXELS      (CANNY_WIDTH * CANNY_HEIGHT)
#define CANNY_VALID_MARGIN 5U

#define DEV_CANNY_CTRL    "/dev/canny_ctrl"
#define DEV_CANNY_INPUT   "/dev/canny_input"
#define DEV_CANNY_EDGE    "/dev/canny_edge"

static void print_usage(const char *program)
{
    fprintf(stderr,
            "Usage:\n"
            "  %s <input.txt> <output.txt> <low> <high> [reference.txt]\n\n"
            "Without reference:\n"
            "  %s ../data/grayscale_128x96.txt "
            "../data/edge_output.txt 50 100\n\n"
            "With reference:\n"
            "  %s ../data/grayscale_128x96.txt "
            "../data/edge_output.txt 50 100 "
            "../data/final_edge_128x96.txt\n",
            program, program, program);
}

static int parse_threshold(const char *text, uint32_t *value)
{
    char *end = NULL;
    unsigned long parsed;

    errno = 0;
    parsed = strtoul(text, &end, 10);

    if (errno != 0 ||
        end == text ||
        *end != '\0' ||
        parsed > 255UL) {
        return -1;
    }

    *value = (uint32_t)parsed;
    return 0;
}

static int load_text_image(const char *path, uint8_t *pixels)
{
    FILE *file;
    size_t i;
    int ch;

    file = fopen(path, "r");
    if (!file) {
        fprintf(stderr,
                "Cannot open image file '%s': %s\n",
                path,
                strerror(errno));
        return -1;
    }

    for (i = 0; i < CANNY_PIXELS; i++) {
        unsigned int value;

        if (fscanf(file, "%u", &value) != 1) {
            fprintf(stderr,
                    "File '%s' does not contain %u valid pixels. "
                    "Problem at pixel %zu.\n",
                    path,
                    CANNY_PIXELS,
                    i);
            fclose(file);
            return -1;
        }

        if (value > 255U) {
            fprintf(stderr,
                    "Pixel %zu in '%s' is outside range 0-255: %u\n",
                    i,
                    path,
                    value);
            fclose(file);
            return -1;
        }

        pixels[i] = (uint8_t)value;
    }

    while ((ch = fgetc(file)) != EOF) {
        if (!isspace((unsigned char)ch)) {
            fprintf(stderr,
                    "File '%s' contains additional data after "
                    "%u pixels.\n",
                    path,
                    CANNY_PIXELS);
            fclose(file);
            return -1;
        }
    }

    if (ferror(file)) {
        fprintf(stderr,
                "Error while reading image file '%s'.\n",
                path);
        fclose(file);
        return -1;
    }

    fclose(file);
    return 0;
}

static int save_text_image(const char *path, const uint8_t *pixels)
{
    FILE *file;
    size_t i;

    file = fopen(path, "w");
    if (!file) {
        fprintf(stderr,
                "Cannot create output file '%s': %s\n",
                path,
                strerror(errno));
        return -1;
    }

    for (i = 0; i < CANNY_PIXELS; i++) {
        if (fprintf(file, "%u\n",
                    (unsigned int)pixels[i]) < 0) {
            fprintf(stderr,
                    "Error while writing output file '%s'.\n",
                    path);
            fclose(file);
            return -1;
        }
    }

    if (fclose(file) != 0) {
        fprintf(stderr,
                "Cannot close output file '%s': %s\n",
                path,
                strerror(errno));
        return -1;
    }

    return 0;
}

static int write_exact_once(int fd,
                            const void *buffer,
                            size_t count,
                            const char *description)
{
    ssize_t written;

    do {
        written = write(fd, buffer, count);
    } while (written < 0 && errno == EINTR);

    if (written < 0) {
        fprintf(stderr,
                "Failed to write %s: %s\n",
                description,
                strerror(errno));
        return -1;
    }

    if ((size_t)written != count) {
        fprintf(stderr,
                "Incomplete write of %s: expected %zu, "
                "wrote %zd bytes.\n",
                description,
                count,
                written);
        return -1;
    }

    return 0;
}

static int read_full(int fd,
                     void *buffer,
                     size_t count,
                     const char *description)
{
    uint8_t *bytes = (uint8_t *)buffer;
    size_t total = 0;

    while (total < count) {
        ssize_t received;

        received = read(fd,
                        bytes + total,
                        count - total);

        if (received < 0) {
            if (errno == EINTR)
                continue;

            fprintf(stderr,
                    "Failed to read %s: %s\n",
                    description,
                    strerror(errno));
            return -1;
        }

        if (received == 0) {
            fprintf(stderr,
                    "Unexpected end while reading %s: "
                    "expected %zu, received %zu bytes.\n",
                    description,
                    count,
                    total);
            return -1;
        }

        total += (size_t)received;
    }

    return 0;
}

static size_t compare_images(const uint8_t *hardware,
                             const uint8_t *reference,
                             size_t *compared_pixels)
{
    size_t mismatches = 0;
    size_t row;
    size_t col;

    *compared_pixels = 0U;

    for (row = CANNY_VALID_MARGIN;
         row < CANNY_HEIGHT - CANNY_VALID_MARGIN;
         row++) {
        for (col = CANNY_VALID_MARGIN;
             col < CANNY_WIDTH - CANNY_VALID_MARGIN;
             col++) {
            size_t index = row * CANNY_WIDTH + col;

            (*compared_pixels)++;

            if (hardware[index] != reference[index]) {
                if (mismatches < 10U) {
                    printf("Mismatch %zu: row=%zu col=%zu "
                           "hardware=%u reference=%u\n",
                           mismatches + 1U,
                           row,
                           col,
                           (unsigned int)hardware[index],
                           (unsigned int)reference[index]);
                }

                mismatches++;
            }
        }
    }

    return mismatches;
}

static void print_edge_statistics(const uint8_t *pixels)
{
    size_t count_zero = 0;
    size_t count_weak = 0;
    size_t count_strong = 0;
    size_t count_other = 0;
    size_t i;

    for (i = 0; i < CANNY_PIXELS; i++) {
        switch (pixels[i]) {
        case 0U:
            count_zero++;
            break;

        case 127U:
            count_weak++;
            break;

        case 255U:
            count_strong++;
            break;

        default:
            count_other++;
            break;
        }
    }

    printf("Output statistics:\n");
    printf("  zero pixels:   %zu\n", count_zero);
    printf("  weak pixels:   %zu\n", count_weak);
    printf("  strong pixels: %zu\n", count_strong);
    printf("  other values:  %zu\n", count_other);
}

int main(int argc, char *argv[])
{
    const char *input_path;
    const char *output_path;
    const char *reference_path = NULL;

    uint32_t low_threshold;
    uint32_t high_threshold;

    uint8_t *input_pixels = NULL;
    uint8_t *edge_pixels = NULL;
    uint8_t *reference_pixels = NULL;

    int ctrl_fd = -1;
    int input_fd = -1;
    int edge_fd = -1;

    char config_command[64];
    int config_length;
    const char start_command[] = "start\n";

    bool use_reference = false;
    int exit_status = EXIT_FAILURE;

    if (argc != 5 && argc != 6) {
        print_usage(argv[0]);
        return EXIT_FAILURE;
    }

    input_path = argv[1];
    output_path = argv[2];

    if (parse_threshold(argv[3], &low_threshold) != 0) {
        fprintf(stderr,
                "Invalid LOW threshold '%s'. "
                "Expected value from 0 to 255.\n",
                argv[3]);
        return EXIT_FAILURE;
    }

    if (parse_threshold(argv[4], &high_threshold) != 0) {
        fprintf(stderr,
                "Invalid HIGH threshold '%s'. "
                "Expected value from 0 to 255.\n",
                argv[4]);
        return EXIT_FAILURE;
    }

    if (low_threshold > high_threshold) {
        fprintf(stderr,
                "LOW threshold (%u) must not be greater "
                "than HIGH threshold (%u).\n",
                low_threshold,
                high_threshold);
        return EXIT_FAILURE;
    }

    if (argc == 6) {
        use_reference = true;
        reference_path = argv[5];
    }

    input_pixels = malloc(CANNY_PIXELS);
    edge_pixels = malloc(CANNY_PIXELS);

    if (!input_pixels || !edge_pixels) {
        fprintf(stderr,
                "Failed to allocate memory for Canny images.\n");
        goto cleanup;
    }

    if (use_reference) {
        reference_pixels = malloc(CANNY_PIXELS);

        if (!reference_pixels) {
            fprintf(stderr,
                    "Failed to allocate memory for reference image.\n");
            goto cleanup;
        }
    }

    printf("Canny Edge Linux application\n");
    printf("Image dimensions: %u rows x %u columns\n",
           CANNY_HEIGHT,
           CANNY_WIDTH);
    printf("Image size: %u pixels\n", CANNY_PIXELS);
    printf("Thresholds: LOW=%u HIGH=%u\n",
           low_threshold,
           high_threshold);

    printf("Loading input image: %s\n", input_path);

    if (load_text_image(input_path, input_pixels) != 0)
        goto cleanup;

    if (use_reference) {
        printf("Loading reference image: %s\n",
               reference_path);

        if (load_text_image(reference_path,
                            reference_pixels) != 0) {
            goto cleanup;
        }
    }

    ctrl_fd = open(DEV_CANNY_CTRL, O_WRONLY);
    if (ctrl_fd < 0) {
        fprintf(stderr,
                "Cannot open %s: %s\n",
                DEV_CANNY_CTRL,
                strerror(errno));
        goto cleanup;
    }

    input_fd = open(DEV_CANNY_INPUT, O_WRONLY);
    if (input_fd < 0) {
        fprintf(stderr,
                "Cannot open %s: %s\n",
                DEV_CANNY_INPUT,
                strerror(errno));
        goto cleanup;
    }

    edge_fd = open(DEV_CANNY_EDGE, O_RDONLY);
    if (edge_fd < 0) {
        fprintf(stderr,
                "Cannot open %s: %s\n",
                DEV_CANNY_EDGE,
                strerror(errno));
        goto cleanup;
    }

    config_length = snprintf(config_command,
                             sizeof(config_command),
                             "config %u %u %u %u\n",
                             CANNY_HEIGHT,
                             CANNY_WIDTH,
                             low_threshold,
                             high_threshold);

    if (config_length < 0 ||
        (size_t)config_length >= sizeof(config_command)) {
        fprintf(stderr,
                "Failed to create configuration command.\n");
        goto cleanup;
    }

    printf("Sending configuration: %s", config_command);

    if (write_exact_once(ctrl_fd,
                         config_command,
                         (size_t)config_length,
                         "Canny configuration") != 0) {
        goto cleanup;
    }

    printf("Writing grayscale image to %s...\n",
           DEV_CANNY_INPUT);

    if (write_exact_once(input_fd,
                         input_pixels,
                         CANNY_PIXELS,
                         "input grayscale image") != 0) {
        goto cleanup;
    }

    printf("Starting Canny hardware...\n");

    if (write_exact_once(ctrl_fd,
                         start_command,
                         strlen(start_command),
                         "START command") != 0) {
        goto cleanup;
    }

    printf("Canny hardware finished.\n");
    printf("Reading edge image from %s...\n",
           DEV_CANNY_EDGE);

    if (read_full(edge_fd,
                  edge_pixels,
                  CANNY_PIXELS,
                  "edge image") != 0) {
        goto cleanup;
    }

    printf("Saving edge image: %s\n", output_path);

    if (save_text_image(output_path, edge_pixels) != 0)
        goto cleanup;

    print_edge_statistics(edge_pixels);

    if (use_reference) {
        size_t mismatches;
        size_t compared_pixels;

        printf("Comparing hardware output with reference "
               "in the valid zone...\n");

        mismatches = compare_images(edge_pixels,
                                    reference_pixels,
                                    &compared_pixels);

        printf("Comparison finished: %zu mismatches "
               "in %zu valid pixels.\n",
               mismatches,
               compared_pixels);

        if (mismatches == 0U)
            printf("Hardware output matches the reference "
                   "in the valid zone.\n");
        else
            printf("Hardware output does not match the reference "
                   "in the valid zone.\n");
    } else {
        printf("Reference image was not provided. "
               "Comparison was skipped.\n");
    }

    printf("Canny application completed successfully.\n");
    exit_status = EXIT_SUCCESS;

cleanup:
    if (edge_fd >= 0)
        close(edge_fd);

    if (input_fd >= 0)
        close(input_fd);

    if (ctrl_fd >= 0)
        close(ctrl_fd);

    free(reference_pixels);
    free(edge_pixels);
    free(input_pixels);

    return exit_status;
}
