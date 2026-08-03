#include <systemc>
#include <iostream>
#include "cpu.hpp"
#include "bram.hpp"
#include "interconnect.hpp"
//#include "hard.hpp"
#include "hard_tlm_bridge.hpp"

int sc_main(int argc, char* argv[])
{

    // Kreiranje modula
    BRAM bram("BRAM");
    Interconnect interconnect("INTERCONNECT");
    Hard hard("HARD");
    Cpu cpu("CPU", argv, argc, &hard);
    
    // Povezivanje CPU-a sa interconnect-om
    cpu.interconnect_socket.bind(interconnect.cpu_socket);

    // Povezivanje interconnect-a sa BRAM-om
    interconnect.bram_socket.bind(bram.cpu_socket);

    // Povezivanje interconnect-a sa HARD-om
    interconnect.hard_socket.bind(hard.interconnect_socket);

    // Povezivanje HARD modula direktno na BRAM
    hard.bram_socket.bind(bram.hard_socket);

    std::cout << "Starting SystemC simulation..." << std::endl;
    sc_start();
    std::cout << "SystemC simulation finished." << std::endl;

    return 0;
}



