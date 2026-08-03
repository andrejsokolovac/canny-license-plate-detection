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
    // Inicijator socket za komunikaciju sa interkonektom
    tlm_utils::simple_initiator_socket<Cpu> interconnect_socket;
    
    SC_HAS_PROCESS(Cpu);

    // Konstruktor i destruktor
    Cpu(sc_core::sc_module_name name, char** strings,int argv, Hard* hard_ptr);

    ~Cpu();
    
    Hard* hard;

    // Glavna funkcija procesa
    void process();
    
    // **SC_EVENTS za sinhronizaciju između CPU-a i IP-a**
    sc_event done_event; 

private:
    std::string input_image_path;
    std::string output_image_path;

    int image_rows, image_cols;
    int ready;  // Indikator spremnosti HARD-a
    bool done;  // Indikator završenosti obrade u HARD modulu

    sc_core::sc_time offset;

    // Metode za učitavanje i čuvanje slike
    cv::Mat load_image();
    cv::Mat load_original();
    void save_image(const cv::Mat& output_image);

    // Metode za komunikaciju sa BRAM-om
    void send_to_bram(sc_uint<64> addr, unsigned char val);
    void receive_from_bram(sc_uint<64> addr, unsigned char *all_data, int length);

    // Metode za komunikaciju sa HARD modulom
    void write_hard(sc_dt::uint64 addr, int value);
    int read_hard(sc_dt::uint64 addr);

    // Debug metode
    void print_status();

};

#endif // CPU_HPP



