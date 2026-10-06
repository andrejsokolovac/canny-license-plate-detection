#include "canny_edge.h"
#include <cmath>
#include <vector>
#include <algorithm>

std::vector<std::vector<int>> CannyEdge(const std::vector<std::vector<int>>& src, int lowThreshold, int highThreshold) {
    // Gaussian filtering
    std::vector<std::vector<int>> blurred(src.size(), std::vector<int>(src[0].size(), 0));
    const double kernel[5][5] = {
        {1, 4, 6, 4, 1},
        {4, 16, 24, 16, 4},
        {6, 24, 36, 24, 6},
        {4, 16, 24, 16, 4},
        {1, 4, 6, 4, 1}
    };

    for (size_t i = 2; i < src.size() - 2; i++) {
        for (size_t j = 2; j < src[0].size() - 2; j++) {
            double sum = 0;
            for (int k = -2; k <= 2; k++) {
                for (int l = -2; l <= 2; l++) {
                    sum += src[i + k][j + l] * kernel[k + 2][l + 2];
                }
            }
            blurred[i][j] = static_cast<int>(sum / 256);
        }
    }

    // Sobel gradient operator
    std::vector<std::vector<int>> gradX(blurred.size(), std::vector<int>(blurred[0].size(), 0));
    std::vector<std::vector<int>> gradY(blurred.size(), std::vector<int>(blurred[0].size(), 0));
    const int sobelX[3][3] = {
        {-1, 0, 1},
        {-2, 0, 2},
        {-1, 0, 1}
    };

    const int sobelY[3][3] = {
        {1, 2, 1},
        {0, 0, 0},
        {-1, -2, -1}
    };

    for (size_t i = 1; i < blurred.size() - 1; i++) {
        for (size_t j = 1; j < blurred[0].size() - 1; j++) {
            int gx = 0, gy = 0;
            for (int k = -1; k <= 1; k++) {
                for (int l = -1; l <= 1; l++) {
                    gx += blurred[i + k][j + l] * sobelX[k + 1][l + 1];
                    gy += blurred[i + k][j + l] * sobelY[k + 1][l + 1];
                }
            }
            gradX[i][j] = gx;
            gradY[i][j] = gy;
        }
    }

    // Calculate gradient magnitude
    std::vector<std::vector<double>> magnitude(gradX.size(), std::vector<double>(gradX[0].size(), 0));
    for (size_t i = 0; i < gradX.size(); i++) {
        for (size_t j = 0; j < gradX[0].size(); j++) {
            magnitude[i][j] = std::sqrt(gradX[i][j] * gradX[i][j] + gradY[i][j] * gradY[i][j]);
        }
    }

    // Non-maximum suppression
    std::vector<std::vector<int>> suppressed(magnitude.size(), std::vector<int>(magnitude[0].size(), 0));
    for (size_t i = 1; i < magnitude.size() - 1; i++) {
        for (size_t j = 1; j < magnitude[0].size() - 1; j++) {
            double angle = std::atan2(gradY[i][j], gradX[i][j]) * 180 / M_PI;
            angle = angle < 0 ? angle + 180 : angle;

            if ((angle >= 0 && angle < 22.5) || (angle >= 157.5 && angle <= 180)) {
                if (magnitude[i][j] >= magnitude[i][j - 1] && magnitude[i][j] >= magnitude[i][j + 1]) {
                    suppressed[i][j] = static_cast<int>(magnitude[i][j]);
                }
            } else if (angle >= 22.5 && angle < 67.5) {
                if (magnitude[i][j] >= magnitude[i - 1][j + 1] && magnitude[i][j] >= magnitude[i + 1][j - 1]) {
                    suppressed[i][j] = static_cast<int>(magnitude[i][j]);
                }
            } else if (angle >= 67.5 && angle < 112.5) {
                if (magnitude[i][j] >= magnitude[i - 1][j] && magnitude[i][j] >= magnitude[i + 1][j]) {
                    suppressed[i][j] = static_cast<int>(magnitude[i][j]);
                }
            } else {
                if (magnitude[i][j] >= magnitude[i - 1][j - 1] && magnitude[i][j] >= magnitude[i + 1][j + 1]) {
                    suppressed[i][j] = static_cast<int>(magnitude[i][j]);
                }
            }
        }
    }

    // Double thresholding
    std::vector<std::vector<int>> thresholded(suppressed.size(), std::vector<int>(suppressed[0].size(), 0));
    for (size_t i = 0; i < suppressed.size(); i++) {
        for (size_t j = 0; j < suppressed[0].size(); j++) {
            if (suppressed[i][j] >= highThreshold) {
                thresholded[i][j] = 255;
            } else if (suppressed[i][j] >= lowThreshold) {
                thresholded[i][j] = 75;
            }
        }
    }

    // Hysteresis
    std::vector<std::vector<int>> edges(thresholded.size(), std::vector<int>(thresholded[0].size(), 0));
    for (size_t i = 1; i < thresholded.size() - 1; i++) {
        for (size_t j = 1; j < thresholded[0].size() - 1; j++) {
            if (thresholded[i][j] == 255) {
                edges[i][j] = 255;
            } else if (thresholded[i][j] == 75) {
                bool connected = false;
                for (int k = -1; k <= 1; k++) {
                    for (int l = -1; l <= 1; l++) {
                        if (thresholded[i + k][j + l] == 255) {
                            connected = true;
                        }
                    }
                }
                edges[i][j] = connected ? 255 : 0;
            }
        }
    }

    return edges;
}
