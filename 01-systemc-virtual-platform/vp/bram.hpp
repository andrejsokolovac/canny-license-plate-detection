#ifndef BRAM_HPP
#define BRAM_HPP

#include <systemc>
#include <tlm>
#include <tlm_utils/simple_target_socket.h>
#include <vector>
#include "defines.hpp" // Uključujemo BRAM_SIZE i DELAY konstante

class BRAM : public sc_core::sc_module {
public:
    // Constructors and destructor
    BRAM(sc_core::sc_module_name name);
    ~BRAM();

    // TLM target sockets used by the CPU and hardware model
    tlm_utils::simple_target_socket<BRAM> cpu_socket;
    tlm_utils::simple_target_socket<BRAM> hard_socket;

    // TLM transaction handler for reads and writes
    //void b_transport(tlm::tlm_generic_payload& trans, sc_core::sc_time& delay);
    void b_transport(tlm::tlm_generic_payload& trans, sc_core::sc_time& offset);

private:
    unsigned char memory[BRAM_SIZE]; // Interna memorija BRAM-a
};

#endif // BRAM_HPP

