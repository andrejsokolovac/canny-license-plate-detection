#include "cpu.hpp"	
#include <filesystem> 

SC_HAS_PROCESS(Cpu);

char** data_string;
int argc;

using namespace sc_core;
namespace fs = std::filesystem;


Cpu::Cpu(sc_core::sc_module_name name, char** strings, int argv, Hard* hard_ptr)
    : sc_module(name), hard(hard_ptr), interconnect_socket("interconnect_socket")
{
    if (argv > 1)
    {
        input_image_path = strings[1];
        
        // Izvlačenje imena fajla iz putanje
        std::string filename = fs::path(input_image_path).filename().string();

        // Kreiranje putanje za izlaznu sliku
        output_image_path = (fs::current_path() / filename).string();
    }
    else
    {
        std::cerr << "Error: Missing command-line argument for the input file path." << std::endl;
        input_image_path = (fs::current_path().parent_path() / "input" / "image1.png").string();
        output_image_path = (fs::current_path() / "image1.png").string();  
    }

    SC_THREAD(process);
    SC_REPORT_INFO("Cpu", "Constructed.");

    data_string = strings;
    argc = argv;
}

Cpu::~Cpu()
{
    SC_REPORT_INFO("Cpu", "Destroyed.");
}


void Cpu::process()
{
    wait(SC_ZERO_TIME);

    // Učitavanje slike
    Mat img = load_image();
    
    // Ispisujemo ulaznu grayscale sliku u 1D formatu
    /*std::ofstream input_file("/home/andrej/output/input_image.txt");
	for (int i = 0; i < image_rows; ++i) {
    		for (int j = 0; j < image_cols; ++j) {
        		input_file << (int)img.at<uchar>(i, j) << std::endl;
    	}
    }	
    input_file.close();
    std::cout << "[CPU] Ulazna grayscale slika sačuvana kao 1D niz u input_image.txt" << std::endl;*/

    unsigned char* img_data = new unsigned char[image_rows * image_cols];
    int index = 0;
    for (int i = 0; i < image_rows; ++i)
    for (int j = 0; j < image_cols; ++j)
    img_data[index++] = img.at<uchar>(i, j);
        
    for (int i = 0; i < image_rows * image_cols; ++i)
    send_to_bram(i, img_data[i]);
    
    // Slanje broja redova HARD-u
    write_hard(ADDR_ROWS, image_rows);
    std::cout << "[CPU] Sent image_rows (" << image_rows << ") to HARD." << std::endl;

    // Slanje broja kolona HARD-u
    write_hard(ADDR_COLS, image_cols);
    std::cout << "[CPU] Sent image_cols (" << image_cols << ") to HARD." << std::endl;

    // Slanje komande START HARD-u
    write_hard(ADDR_START, 1);
    std::cout << "[CPU] Sent START signal to HARD." << std::endl;
       
    // Cekanje da HARD zavrsi obradu
    ready = read_hard(ADDR_READY);
    std::cout << "[CPU] Waiting for HARD to complete processing... READY = " << ready << std::endl;
    wait(hard->done_event);
      
    std::cout << "[CPU] HARD processing done. Reading processed image..." << std::endl;

    unsigned char* result = new unsigned char[image_rows * image_cols];
    receive_from_bram(0, result, image_rows * image_cols);

    cv::Mat output_img(image_rows, image_cols, CV_8UC1);
    for (int i = 0; i < image_rows; ++i)
    for (int j = 0; j < image_cols; ++j)
    output_img.at<uchar>(i, j) = result[i * image_cols + j];
    
    // Ispisujemo izlaznu Canny edge sliku u 1D formatu
    /*std::ofstream output_file("/home/andrej/output/canny_output.txt");
	for (int i = 0; i < image_rows; ++i) {
    		for (int j = 0; j < image_cols; ++j) {
        		output_file << (int)output_img.at<uchar>(i, j) << std::endl;
    	}
    }
    output_file.close();
    std::cout << "[CPU] Izlazna Canny edge slika sačuvana kao 1D niz u canny_output.txt" << std::endl;*/

    // Čuvanje rezultata
    save_image(output_img);

    std::cout << "CPU: Canny edge detection finished." << std::endl;	
    
    // Prepoznavanje tablice i čuvanje slike sa uokvirenom tablicom

    // 1. Pronađi konture na Canny edge slici
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(output_img, contours, hierarchy, cv::RETR_TREE, cv::CHAIN_APPROX_SIMPLE);

    // 2. Sortiraj konture po površini (najveća prva)
    std::sort(contours.begin(), contours.end(), [](const std::vector<cv::Point>& a, const std::vector<cv::Point>& b) {
        return cv::contourArea(a, false) > cv::contourArea(b, false);
    });

    // 3. Pronađi konturu tablice
    double minArea = 0.0;
    double maxArea = 10000.0;
    std::vector<cv::Point> plateContour;
    for (const auto& c : contours) {
        std::vector<cv::Point> approx;
        cv::approxPolyDP(c, approx, 10, true);
        double area = cv::contourArea(approx);
        if (approx.size() == 4 && area > minArea && area < maxArea) {
            plateContour = approx;
            break;
        }
    }

    // 4. Učitaj originalnu sliku i uokviri tablicu
    cv::Mat original = load_original();
    if (!plateContour.empty() && !original.empty()) {
        cv::Rect box = cv::boundingRect(plateContour);
        cv::rectangle(original, box, cv::Scalar(0, 255, 0), 3);
        
        // 5. Čuvanje slike sa uokvirenom tablicom
        std::string final_output = (fs::current_path() / "image_with_plate.png").string();
        cv::imwrite(final_output, original);
        std::cout << "[CPU] Tablica pronađena i slika sačuvana kao " << final_output << std::endl;
    } else {
        std::cout << "[CPU] Tablica nije pronađena ili originalna slika nije učitana!" << std::endl;
    }

    std::cout << "CPU: Canny edge detection and plate detection finished." << std::endl;
    std::cout << "UKUPNO SIMULACIONO VREME (CPU offset): " << offset.to_string() << std::endl;

}


cv::Mat Cpu::load_image()
{
    cv::Mat img = cv::imread(input_image_path, cv::IMREAD_GRAYSCALE);

    if (img.empty())
    {
        std::cerr << "Error: Could not open or find the image!" << std::endl;
        exit(EXIT_FAILURE);
    }
    
    std::cout << "Loaded image size: " << img.cols << "x" << img.rows << std::endl;

    // Ako je slika veća od maksimalnih dimenzija BRAM-a, smanjujemo je
    if (img.cols > MAX_IMAGE_WIDTH || img.rows > MAX_IMAGE_HEIGHT)
    {
        std::cout << "Resizing image to " << MAX_IMAGE_WIDTH << "x" << MAX_IMAGE_HEIGHT << std::endl;
        cv::resize(img, img, cv::Size(MAX_IMAGE_WIDTH, MAX_IMAGE_HEIGHT));
    }
    
    //Postavljamo `image_rows` i `image_cols`
    image_cols = img.cols;
    image_rows = img.rows;
    
    //Dodajemo provere pre vraćanja slike
    if (img.cols <= 0 || img.rows <= 0)
    {
        std::cerr << "Error: Image has invalid dimensions after resizing!" << std::endl;
        exit(EXIT_FAILURE);
    }

    return img;
}


cv::Mat Cpu::load_original()
{
    cv::Mat img = cv::imread(input_image_path);

    if (img.empty())
    {
        std::cerr << "Error: Could not open or find the image!" << std::endl;
        exit(EXIT_FAILURE);
    }
    
    std::cout << "Loaded image size: " << img.cols << "x" << img.rows << std::endl;

    // Ako je slika veća od maksimalnih dimenzija BRAM-a, smanjujemo je
    if (img.cols > MAX_IMAGE_WIDTH || img.rows > MAX_IMAGE_HEIGHT)
    {
        std::cout << "Resizing image to " << MAX_IMAGE_WIDTH << "x" << MAX_IMAGE_HEIGHT << std::endl;
        cv::resize(img, img, cv::Size(MAX_IMAGE_WIDTH, MAX_IMAGE_HEIGHT));
    }
    
    //Postavljamo `image_rows` i `image_cols`
    image_cols = img.cols;
    image_rows = img.rows;
    
    //Dodajemo provere pre vraćanja slike
    if (img.cols <= 0 || img.rows <= 0)
    {
        std::cerr << "Error: Image has invalid dimensions after resizing!" << std::endl;
        exit(EXIT_FAILURE);
    }

    return img;
}


void Cpu::save_image(const cv::Mat& output_image) {
    if (output_image.empty()) {
        std::cerr << "[CPU] Error: Output image is empty!" << std::endl;
        return;
    }

    // Sačuvaj PNG sliku
    cv::imwrite(output_image_path, output_image);
    std::cout << "[CPU] Slika sačuvana" << std::endl;
    
}


int Cpu::read_hard(sc_dt::uint64 addr)
{
    	pl_t pl;
    	unsigned char buf[4];
    	pl.set_address(VP_ADDR_IP_HARD_L + addr);
    	pl.set_data_length(4);
    	pl.set_data_ptr(buf);
    	pl.set_command(tlm::TLM_READ_COMMAND);

	interconnect_socket->b_transport(pl, offset);

    	return toInt(buf);
}


void Cpu::write_hard(sc_dt::uint64 addr,int val)
{
    pl_t pl;
    unsigned char buf[4];
    toUchar(buf,val);
    pl.set_address(VP_ADDR_IP_HARD_L + addr);
    pl.set_data_length(4);
    pl.set_data_ptr(buf);
    pl.set_command(tlm::TLM_WRITE_COMMAND);
    pl.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

    interconnect_socket->b_transport(pl, offset);

}


void Cpu::send_to_bram(sc_uint<64> addr, unsigned char val)
{
    pl_t pl;
    unsigned char buf = val;
    pl.set_address(VP_ADDR_BRAM_L + addr);
    pl.set_data_length(1);
    pl.set_data_ptr(&buf);
    pl.set_command(tlm::TLM_WRITE_COMMAND);
    pl.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

    interconnect_socket->b_transport(pl, offset);
}


void Cpu::receive_from_bram(sc_uint<64> addr, unsigned char *all_data, int length)
{
    pl_t pl;
    unsigned char buf;
    int n = 0;

    for (int i = 0; i < length; i++) {
        pl.set_address(VP_ADDR_BRAM_L + addr + i);
        pl.set_data_length(1);
        pl.set_data_ptr(&buf);
        pl.set_command(tlm::TLM_READ_COMMAND);
        pl.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

        interconnect_socket->b_transport(pl, offset);

        all_data[n++] = buf;  // Kopiramo sadržaj bafera u izlazni niz
    }
    
}


	








	




