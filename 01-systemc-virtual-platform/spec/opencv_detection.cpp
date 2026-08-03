#include <opencv2/opencv.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <iostream>
#include <vector>
#include <cmath>
#include <algorithm>
#include <filesystem>

using namespace std;



int main(int argc, char* argv[]) {
    if (argc < 2) {
        cout << "Greška: Niste prosledili putanju do slike kao argument!" << endl;
        return -1;
    }

    // Čitanje slike sa prosleđene putanje
    string imagePath = argv[1];
    cv::Mat img = cv::imread(imagePath);

    if (img.empty()) {
        cout << "Greška: Slika nije učitana. Proveri putanju i ime fajla." << endl;
        return -1;
    }

    cv::Mat gray;
    cv::cvtColor(img, gray, cv::COLOR_BGR2GRAY);
    cv::imshow("Grayscale", gray);
    cv::waitKey(0);

    cv::Mat edgeImg;
    cv::Canny(gray, edgeImg, 100, 200);
    cv::imshow("Edged", edgeImg);
    cv::waitKey(0);
    
    namespace fs = std::filesystem;
    std::string final_output = (fs::current_path() / "image_with_plate.png").string();
    cv::imwrite(final_output, edgeImg);
    
    // Nađi konture
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(edgeImg, contours, hierarchy, cv::RETR_TREE, cv::CHAIN_APPROX_SIMPLE);

    // Sortiraj konture
    std::sort(contours.begin(), contours.end(), [](const std::vector<cv::Point>& a, const std::vector<cv::Point>& b) {
        return cv::contourArea(a, false) > cv::contourArea(b, false);
    });
	
    double minArea = 0.0; // Minimalna povrsina za konturu tablice
    double maxArea = 30000.0; // Maksimalna povrsina za konturu tablice			
    std::vector<cv::Point> location;
    for (size_t i = 0; i < contours.size(); i++) {
        // Aproksimacija poligona
        std::vector<cv::Point> approx;
        cv::approxPolyDP(contours[i], approx, 10, true);
        // Dodatni kriterijumi : kontura sa 4 tacke i odgovarajuce velicine
        double area = cv::contourArea(approx);
        if (approx.size() == 4 && area > minArea && area < maxArea) {
            location = approx;
            break;
        }
    }
	
    // Ako je tablica pronađena
    if (!location.empty()) {

        // Izreži područje sa tablicom
        cv::Rect boundingBox = cv::boundingRect(location);

        // Uokvirivanje tablice u originalnoj slici
        cv::rectangle(img, boundingBox, cv::Scalar(0, 255, 0), 3);

        // Prikazi originalnu sliku sa uokvirenom tablicom
        cv::imshow("Original sa Uokvirenom Tablicom", img);
        cv::waitKey(0);
    } else {
        cout << "Greška: Tablica nije pronađena." << endl;
    }

    return 0;
}    

