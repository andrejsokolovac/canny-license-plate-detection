#include "bram.hpp"
#include <iostream>

BRAM::BRAM(sc_core::sc_module_name name) : sc_module(name) {
    // Registracija b_transport metode za oba socketa
    cpu_socket.register_b_transport(this, &BRAM::b_transport);
    hard_socket.register_b_transport(this, &BRAM::b_transport);
    
    SC_REPORT_INFO("BRAM", "Constructed.");
}

BRAM::~BRAM() {
    SC_REPORT_INFO("BRAM", "Destroyed.");
}

void BRAM::b_transport(tlm::tlm_generic_payload &trans, sc_core::sc_time &offset) {
    tlm::tlm_command cmd = trans.get_command();
    sc_dt::uint64 addr = trans.get_address();
    unsigned char* data_ptr = trans.get_data_ptr();
    unsigned int len = trans.get_data_length();

    // Provera da li adresa prelazi dozvoljene granice
    if (addr >= BRAM_SIZE) {
        SC_REPORT_ERROR("BRAM", "Out of bounds memory access");
        trans.set_response_status(tlm::TLM_ADDRESS_ERROR_RESPONSE);
        return;
    }

    switch (cmd) {
        case tlm::TLM_WRITE_COMMAND:
            for (unsigned int i = 0; i < len; i++) {
                memory[addr + i] = data_ptr[i];
            }
            std::cout << "[BRAM WRITE] Address: 0x" << std::hex << addr 
                      << " <- Value: " << std::hex << (int)*data_ptr << std::endl;
                      
            trans.set_response_status(tlm::TLM_OK_RESPONSE);
            offset += sc_core::sc_time(DELAY, sc_core::SC_NS);                      
            break;

        case tlm::TLM_READ_COMMAND:
            for (unsigned int i = 0; i < len; i++) {
                data_ptr[i] = memory[addr + i];
            }
            std::cout << "[BRAM READ] Address: 0x" << std::hex << addr 
                      << " -> Value: " << std::hex << (int)*data_ptr << std::endl;
                      
            trans.set_response_status(tlm::TLM_OK_RESPONSE);
            offset += sc_core::sc_time(DELAY, sc_core::SC_NS);          
            break;

        default:
            SC_REPORT_ERROR("BRAM", "Unsupported TLM command");
            trans.set_response_status(tlm::TLM_COMMAND_ERROR_RESPONSE);
            offset += sc_core::sc_time(DELAY, sc_core::SC_NS);

    }

}






