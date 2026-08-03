#ifndef HARD_HPP
#define HARD_HPP

#include <systemc>
#include <tlm>
#include <tlm_utils/simple_target_socket.h>
#include <tlm_utils/simple_initiator_socket.h>
#include "defines.hpp"
#include "utils.hpp"

class Hard : public sc_core::sc_module {
public:
    // Target socket za komunikaciju sa CPU-om
    tlm_utils::simple_target_socket<Hard> interconnect_socket;

    // Initiator socket za direktnu komunikaciju sa BRAM-om
    tlm_utils::simple_initiator_socket<Hard> bram_socket;

    // Promenljive za rad
    sc_dt::sc_uint<16> rows, cols;
    sc_dt::sc_uint<1> ready;
    sc_dt::sc_uint<1> start;

    SC_HAS_PROCESS(Hard);
    
    sc_core::sc_event start_event;
    sc_core::sc_event done_event;
    
    sc_time offset;
    
    Hard(sc_core::sc_module_name name);
    ~Hard();
  
    // TLM b_transport funkcija za obradu CPU zahteva
    void b_transport(tlm::tlm_generic_payload &pl, sc_core::sc_time &offset);

    // Funkcije za direktan rad sa BRAM-om
    void write_bram(sc_dt::uint64 addr, unsigned char val);
    unsigned char read_bram(sc_dt::uint64 addr);

    // Glavna funkcija obrade (Canny Edge Detection)
    void execute_canny();
    
    // Glavna nit
    void main_thread();
    
};

#endif // HARD_HPP

