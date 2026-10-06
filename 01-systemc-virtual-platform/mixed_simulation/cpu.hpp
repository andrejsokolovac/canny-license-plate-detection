#ifndef CPU_HPP
#define CPU_HPP

#include <systemc>
#include <tlm>
#include <tlm_utils/simple_initiator_socket.h>

#include <string>
#include <vector>
#include <cstdint>
#include <iostream>
#include <fstream>

#include "defines.hpp"
#include "utils.hpp"
#include "hard_tlm_bridge.hpp"

//class Hard;

class Cpu : public sc_core::sc_module
{
public:
    tlm_utils::simple_initiator_socket<Cpu> interconnect_socket;

    SC_HAS_PROCESS(Cpu);

    Cpu(sc_core::sc_module_name name, char** strings, int argv, Hard* hard_ptr);
    ~Cpu();

    Hard* hard;

    void process();

    sc_core::sc_event done_event;

private:
    std::string input_txt_path;
    std::string expected_txt_path;
    std::string output_txt_path;

    int image_rows;
    int image_cols;
    int ready;
    bool done;

    sc_core::sc_time offset;

    // TXT helper methods
    std::vector<unsigned char> load_txt_image(const std::string& path, int expected_size);
    void save_txt_image(const std::string& path, const unsigned char* data, int length);
    void compare_with_expected(const std::string& expected_path, const unsigned char* data, int length);

    // BRAM communication
    void send_to_bram(sc_dt::sc_uint<64> addr, unsigned char val);
    void receive_from_bram(sc_dt::sc_uint<64> addr, unsigned char* all_data, int length);

    // Hardware-module communication
    void write_hard(sc_dt::uint64 addr, int value);
    int read_hard(sc_dt::uint64 addr);

    void print_status();
};

#endif // CPU_HPP

