#ifndef CANNY_EDGE_H
#define CANNY_EDGE_H

#include <vector>

// Deklaracija funkcije za Canny edge detekciju
std::vector<std::vector<int>> CannyEdge(const std::vector<std::vector<int>>& src, int lowThreshold, int highThreshold);

#endif // CANNY_EDGE_H
