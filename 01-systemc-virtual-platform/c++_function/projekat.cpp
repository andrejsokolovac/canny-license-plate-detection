#include <opencv2/opencv.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include "canny_edge.h"
#include <iostream>
#include <vector>
#include <cmath>
#include <algorithm>
#include <filesystem>

using namespace std;



int main() {
    // Load image
    
    namespace fs = std::filesystem;
    std::string imagePath = (fs::current_path().parent_path() / "data/image1.png").string();
    cv::Mat img = cv::imread(imagePath);
    
    if (img.empty()) {
        std::cerr << "Greška: Slika nije učitana. Putanja: " << imagePath << std::endl;
        return -1;
    }
    
    /*cv::Mat img = cv::imread("/Data/image9.png");

    if (img.empty()) {
        cout << "Greška: Slika nije učitana. Proveri putanju i ime fajla." << endl;
        return -1;
    }*/

    cv::Mat gray;
    cv::cvtColor(img, gray, cv::COLOR_BGR2GRAY);
    cv::imshow("Grayscale", gray);
    cv::waitKey(0);

    vector<vector<int>> grayVec(gray.rows, vector<int>(gray.cols, 0));
    for (int i = 0; i < gray.rows; ++i) {
        for (int j = 0; j < gray.cols; ++j) {
            grayVec[i][j] = gray.at<uchar>(i, j);
        }
    }

    vector<vector<int>> edged = CannyEdge(grayVec, 50, 150);
    cv::Mat edgeImg(edged.size(), edged[0].size(), CV_8U);
    for (size_t i = 0; i < edged.size(); ++i) {
        for (size_t j = 0; j < edged[i].size(); ++j) {
            edgeImg.at<uchar>(i, j) = edged[i][j];
        }
    }

    cv::imshow("Edged", edgeImg);
    cv::waitKey(0);
    
    // Find contours
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(edgeImg, contours, hierarchy, cv::RETR_TREE, cv::CHAIN_APPROX_SIMPLE);

    // Sort contours
    std::sort(contours.begin(), contours.end(), [](const std::vector<cv::Point>& a, const std::vector<cv::Point>& b) {
        return cv::contourArea(a, false) > cv::contourArea(b, false);
    });
	
    double minArea = 0.0; // Minimalna povrsina za konturu tablice
    double maxArea = 30000.0; // Maksimalna povrsina za konturu tablice			
    std::vector<cv::Point> location;
    for (size_t i = 0; i < contours.size(); i++) {
        // Polygon approximation
        std::vector<cv::Point> approx;
        cv::approxPolyDP(contours[i], approx, 10, true);
        // Additional criteria: four-point contour with suitable dimensions
        double area = cv::contourArea(approx);
        if (approx.size() == 4 && area > minArea && area < maxArea) {
            location = approx;
            break;
        }
    }
	
    // If a license plate is found
    if (!location.empty()) {

        // Crop the license-plate region
        cv::Rect boundingBox = cv::boundingRect(location);

        // Draw the license-plate bounding box on the original image
        cv::rectangle(img, boundingBox, cv::Scalar(0, 255, 0), 3);

        // Display the original image with the detected license plate
        cv::imshow("Original sa Uokvirenom Tablicom", img);
        cv::waitKey(0);
    } else {
        cout << "Greška: Tablica nije pronađena." << endl;
    }

    return 0;
}    
