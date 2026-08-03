#include "interconnect.hpp"
#include <string>

Interconnect::Interconnect(sc_core::sc_module_name name)
  : sc_module(name), offset(sc_core::SC_ZERO_TIME)
{
    cpu_socket.register_b_transport(this, &Interconnect::b_transport);
    SC_REPORT_INFO("Interconnect", "Constructed.");
}

Interconnect::~Interconnect()
{
    SC_REPORT_INFO("Interconnect", "Destroyed.");
}

void Interconnect::b_transport(pl_t &pl, sc_core::sc_time &offset)
{
    sc_dt::uint64 addr = pl.get_address();
    sc_dt::uint64 taddr = addr & 0x00FFFFFF; // Maskiranje adrese
    
    std::cout << "[INTERCONNECT] Received transaction: Address = 0x" << std::hex << addr << std::endl;

    if (addr >= VP_ADDR_BRAM_L && addr <= VP_ADDR_BRAM_H)
    {
        std::cout << "[INTERCONNECT] Forwarding to BRAM..." << std::endl;
        pl.set_address(taddr); // Prilagođavanje adrese za BRAM
        bram_socket->b_transport(pl, offset);
        pl.set_address(addr);
    }
    else if (addr >= VP_ADDR_IP_HARD_L && addr <= VP_ADDR_IP_HARD_H)
    {
        std::cout << "[INTERCONNECT] Forwarding to HARD..." << std::endl;
        pl.set_address(taddr); // Prilagođavanje adrese za HARD
        hard_socket->b_transport(pl, offset);
        pl.set_address(addr);
        offset += sc_core::sc_time(5 * DELAY, sc_core::SC_NS); // Simulacija kašnjenja
    }
    else
    { 
        std::cerr << "[INTERCONNECT] ERROR: Invalid address 0x" << std::hex << addr << std::endl;
        SC_REPORT_ERROR("Interconnect", "Wrong address.");
        pl.set_response_status(tlm::TLM_ADDRESS_ERROR_RESPONSE);
        offset += sc_core::sc_time(5 * DELAY, sc_core::SC_NS);
    }
}


