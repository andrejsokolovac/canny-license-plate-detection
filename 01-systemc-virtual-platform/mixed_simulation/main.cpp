#include <systemc>
#include <iostream>
#include "cpu.hpp"
#include "bram.hpp"
#include "interconnect.hpp"
//#include "hard.hpp"
#include "hard_tlm_bridge.hpp"

int sc_main(int argc, char* argv[])
{

    // Create modules
    BRAM bram("BRAM");
    Interconnect interconnect("INTERCONNECT");
    Hard hard("HARD");
    Cpu cpu("CPU", argv, argc, &hard);
    
    // Connect the CPU to the interconnect
    cpu.interconnect_socket.bind(interconnect.cpu_socket);

    // Connect the interconnect to BRAM
    interconnect.bram_socket.bind(bram.cpu_socket);

    // Connect the interconnect to the hardware model
    interconnect.hard_socket.bind(hard.interconnect_socket);

    // Connect the hardware model directly to BRAM
    hard.bram_socket.bind(bram.hard_socket);

    std::cout << "Starting SystemC simulation..." << std::endl;
    sc_start();
    std::cout << "SystemC simulation finished." << std::endl;

    return 0;
}



