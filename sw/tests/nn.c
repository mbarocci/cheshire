#include <stdio.h>
#include <stdlib.h>
// #include <time.h>

#include "regs/cheshire.h"
#include "dif/clint.h"
#include "dif/uart.h"
#include "params.h"
#include "util.h"
#include "printf.h"

#define max(a,b) ((a) > (b) ? (a) : (b))

// Function to perform 2D convolution
void conv2d(int input_height, int input_width, int filter_height, int filter_width,
            int input[input_height][input_width], int filter[filter_height][filter_width],
            int bias, int stride, int padding, int output_height, int output_width,
            int output[output_height][output_width]) {
    
    // Apply padding to the input (optional)
    int padded_height = input_height + 2 * padding;
    int padded_width = input_width + 2 * padding;
    int padded_input[padded_height][padded_width];
    
    for (int i = 0; i < padded_height; i++) {
        for (int j = 0; j < padded_width; j++) {
            if (i < padding || i >= padded_height - padding || j < padding || j >= padded_width - padding) {
                padded_input[i][j] = 0; // Padding with zeros
            } else {
                padded_input[i][j] = input[i - padding][j - padding];
            }
        }
    }
    
    // Initialize the output
    for (int i = 0; i < output_height; i++) {
        for (int j = 0; j < output_width; j++) {
            output[i][j] = 0;
        }
    }

    // Perform the convolution
    for (int i = 0; i <= padded_height - filter_height; i += stride) {
        for (int j = 0; j <= padded_width - filter_width; j += stride) {
            int conv_sum = 0;
            for (int fi = 0; fi < filter_height; fi++) {
                for (int fj = 0; fj < filter_width; fj++) {
                    conv_sum += padded_input[i + fi][j + fj] * filter[fi][fj];
                }
            }
            output[i / stride][j / stride] = conv_sum + bias;
        }
    }
}

// Function to apply ReLU activation
void relu(int output_height, int output_width, int output[output_height][output_width]) {
    for (int i = 0; i < output_height; i++) {
        for (int j = 0; j < output_width; j++) {
            output[i][j] = max(0, output[i][j]);
        }
    }
}

int main() {
    char str[] = "Hello World!\r\n"; 
    uint32_t rtc_freq = *reg32(&__base_regs, CHESHIRE_RTC_FREQ_REG_OFFSET);
    uint64_t reset_freq = clint_get_core_freq(rtc_freq, 2500);
    uart_init(&__base_uart, reset_freq, __BOOT_BAUDRATE);
    uart_write_str(&__base_uart, str, sizeof(str));
    uart_write_flush(&__base_uart);
    srand(0);
    
    int input[5][5] = {
        {4, 0, 3, 3, 3},
        {1, 3, 2, 4, 0},
        {0, 4, 2, 1, 0},
        {1, 1, 0, 1, 4},
        {3, 0, 3, 0, 2}
    };
    int filter[3][3] = {
        {0, 1, 1},
        {2, 0, 1},
        {1, 1, 0}
    };

    int bias = 0; // Bias value

    // Generate random input and filter
    // for (int i = 0; i < 5; i++) {
    //     for (int j = 0; j < 5; j++) {
    //         input[i][j] = rand() % 5;
    //     }
    // }

    // for (int i = 0; i < 3; i++) {
    //     for (int j = 0; j < 3; j++) {
    //         filter[i][j] = rand() % 3;
    //     }
    // }

    int stride = 1;
    int padding = 0;

    // Output dimensions
    int output_height = (5 - 3 + 2 * padding) / stride + 1;
    int output_width = (5 - 3 + 2 * padding) / stride + 1;
    int output[output_height][output_width];

    // Perform convolution
    conv2d(5, 5, 3, 3, input, filter, bias, stride, padding, output_height, output_width, output);

    // Apply ReLU activation
    relu(output_height, output_width, output);

    // Print the input
    printf("Input:\n");
    for (int i = 0; i < 5; i++) {
        for (int j = 0; j < 5; j++) {
            printf("%d ", input[i][j]);
        }
        printf("\n");
    }

    // Print the filter
    printf("Filter:\n");
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            printf("%d ", filter[i][j]);
        }
        printf("\n");
    }

    // Print the bias
    printf("Bias:\n%d\n", bias);

    // Print the convolution output
    printf("Convolution output:\n");
    for (int i = 0; i < output_height; i++) {
        for (int j = 0; j < output_width; j++) {
            printf("%d ", output[i][j]);
        }
        printf("\n");
    }

    // Print the ReLU output
    printf("ReLU output:\n");
    for (int i = 0; i < output_height; i++) {
        for (int j = 0; j < output_width; j++) {
            printf("%d ", output[i][j]);
        }
        printf("\n");
    }

    return 0;
}
