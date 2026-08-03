#ifndef BRAM_HPP
#define BRAM_HPP

#include <systemc>
#include <tlm>
#include <tlm_utils/simple_target_socket.h>
#include <vector>
#include "defines.hpp" // Uključujemo BRAM_SIZE i DELAY konstante

class BRAM : public sc_core::sc_module {
public:
    // Konstruktori i destruktor
    BRAM(sc_core::sc_module_name name);
    ~BRAM();

    // TLM Target Socketi - BRAM prima podatke od CPU-a i Hard modula
    tlm_utils::simple_target_socket<BRAM> cpu_socket;
    tlm_utils::simple_target_socket<BRAM> hard_socket;

    // Metoda za obradu TLM transakcija (čitanje/pisanje)
    //void b_transport(tlm::tlm_generic_payload& trans, sc_core::sc_time& delay);
    void b_transport(tlm::tlm_generic_payload& trans, sc_core::sc_time& offset);

private:
    unsigned char memory[BRAM_SIZE]; // Interna memorija BRAM-a
};

#endif // BRAM_HPP

