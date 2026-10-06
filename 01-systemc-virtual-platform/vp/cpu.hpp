#ifndef CPU_HPP
#define CPU_HPP

#include <systemc>
#include <tlm>
#include <tlm_utils/simple_initiator_socket.h>
#include <opencv2/opencv.hpp>
#include "defines.hpp"
#include "utils.hpp"
#include "hard.hpp"

using namespace sc_core;
using namespace cv;

class Cpu : public sc_core::sc_module
{
public:
    // Initiator socket for communication with the interconnect
    tlm_utils::simple_initiator_socket<Cpu> interconnect_socket;
    
    SC_HAS_PROCESS(Cpu);

    // Constructor and destructor
    Cpu(sc_core::sc_module_name name, char** strings,int argv, Hard* hard_ptr);

    ~Cpu();
    
    Hard* hard;

    // Main process function
    void process();
    
    // SC events for synchronization between the CPU and IP
    sc_event done_event; 

private:
    std::string input_image_path;
    std::string output_image_path;

    int image_rows, image_cols;
    int ready;  // Indikator spremnosti HARD-a
    bool done;  // Indikator završenosti obrade u HARD modulu

    sc_core::sc_time offset;

    // Image load/save methods
    cv::Mat load_image();
    cv::Mat load_original();
    void save_image(const cv::Mat& output_image);

    // BRAM communication methods
    void send_to_bram(sc_uint<64> addr, unsigned char val);
    void receive_from_bram(sc_uint<64> addr, unsigned char *all_data, int length);

    // Hardware-module communication methods
    void write_hard(sc_dt::uint64 addr, int value);
    int read_hard(sc_dt::uint64 addr);

    // Debug methods
    void print_status();

};

#endif // CPU_HPP



