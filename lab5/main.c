#define _POSIX_C_SOURCE 199309L
#include <time.h>
#include <stdio.h>
#include <stdlib.h>

#define STB_IMAGE_IMPLEMENTATION
#include "Libraries/stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "Libraries/stb_image_write.h"

#ifndef JPEG_QUALITY
  #define JPEG_QUALITY 100
#endif

void grayscale_asm(unsigned char *img, int width, int height, int channels, int x1, int y1, int x2, int y2);
void grayscale_c(unsigned char *img, int width, int height, int channels) {
    int pixels = width * height;
    for (int i = 0; i < pixels; i++) {
        unsigned char *p = img + i * channels;
        unsigned char r = p[0], g = p[1], b = p[2];
        unsigned char mx = r > g ? (r > b ? r : b) : (g > b ? g : b);
        unsigned char mn = r < g ? (r < b ? r : b) : (g < b ? g : b);
        unsigned char grey = (mx + mn) / 2;
        p[0] = p[1] = p[2] = grey;
    }
}

static double diff_time(const struct timespec *start, const struct timespec *end) {
    return (end->tv_sec  - start->tv_sec)
         + (end->tv_nsec - start->tv_nsec) * 1e-9;
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <input.jpg> <output.jpg>\n", argv[0]);
        return EXIT_FAILURE;
    }
    const char *infile  = argv[1];
    const char *outfile = argv[2];

    int width, height, channels;
    unsigned char *img = stbi_load(infile, &width, &height, &channels, 0);
    if (!img) {
        fprintf(stderr, "Error: cannot load image '%s'\n", infile);
        return EXIT_FAILURE;
    }
    if (channels < 3) {
        fprintf(stderr, "Error: image must have at least 3 channels (RGB)\n");
        stbi_image_free(img);
        return EXIT_FAILURE;
    }

    struct timespec t_start, t_end;
    if (clock_gettime(CLOCK_MONOTONIC, &t_start) != 0) {
        perror("clock_gettime");
        stbi_image_free(img);
        return EXIT_FAILURE;
    }

    grayscale_asm(img, width, height, channels, 0, 0, 100, 100);
    //grayscale_c(img, width, height, channels);

    if (clock_gettime(CLOCK_MONOTONIC, &t_end) != 0) {
        perror("clock_gettime");
        stbi_image_free(img);
        return EXIT_FAILURE;
    }

    double elapsed = diff_time(&t_start, &t_end);
    fprintf(stderr, "Elapsed time: %.6f seconds\n", elapsed);

    if (!stbi_write_jpg(outfile, width, height, channels, img, JPEG_QUALITY)) {
        fprintf(stderr, "Error: cannot write image '%s'\n", outfile);
        stbi_image_free(img);
        return EXIT_FAILURE;
    }

    stbi_image_free(img);
    return EXIT_SUCCESS;
}
