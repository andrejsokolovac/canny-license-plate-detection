#ifndef HARD_TLM_BRIDGE_HPP
#define HARD_TLM_BRIDGE_HPP

#include <systemc>
#include <tlm>
#include <tlm_utils/simple_target_socket.h>
#include <tlm_utils/simple_initiator_socket.h>

#include <vector>
#include <cstdint>
#include <iostream>

#include "defines.hpp"
#include "utils.hpp"
#include "hard_wrap.hpp"

/*
 * TLM bridge between the SystemC virtual platform and the VHDL Canny IP.
 * Register accesses arrive through interconnect_socket, while BRAM accesses
 * are issued through bram_socket. Completion is reported through done_event.
 */
class Hard : public sc_core::sc_module
{
public:
    // Target socket for CPU/interconnect register transactions.
    tlm_utils::simple_target_socket<Hard> interconnect_socket;

    // Initiator socket for accesses to the SystemC BRAM.
    tlm_utils::simple_initiator_socket<Hard> bram_socket;

    // Registers visible to the CPU
    sc_dt::sc_uint<16> rows;
    sc_dt::sc_uint<16> cols;
    sc_dt::sc_uint<1> ready;
    sc_dt::sc_uint<1> start;

    // Signals VHDL processing completion to the CPU model.
    sc_core::sc_event done_event;

    // Triggers generation of the RTL START pulse.
    sc_core::sc_event start_event;

    sc_core::sc_time offset;

    SC_HAS_PROCESS(Hard);

    Hard(sc_core::sc_module_name name);
    ~Hard();

    // TLM callback invoked by the interconnect.
    void b_transport(tlm::tlm_generic_payload& pl, sc_core::sc_time& offset);

private:
    // ------------------------------------------------------------
    // VHDL DUT wrapper
    // ------------------------------------------------------------
    hard_wrap dut;

    // ------------------------------------------------------------
    // Clock / reset / control signals for the VHDL IP
    // ------------------------------------------------------------
    sc_core::sc_clock clk;

    sc_core::sc_signal<sc_dt::sc_logic> reset_s;
    sc_core::sc_signal<sc_dt::sc_logic> start_s;
    sc_core::sc_signal<sc_dt::sc_logic> ready_s;

    sc_core::sc_signal<sc_dt::sc_lv<9>> rows_s;
    sc_core::sc_signal<sc_dt::sc_lv<10>> cols_s;

    // ------------------------------------------------------------
    // INPUT BRAM signals
    // ------------------------------------------------------------
    sc_core::sc_signal<sc_dt::sc_logic> input_ena_s;
    sc_core::sc_signal<sc_dt::sc_logic> input_wea_s;
    sc_core::sc_signal<sc_dt::sc_lv<19>> input_addra_s;
    sc_core::sc_signal<sc_dt::sc_lv<8>> input_dia_s;
    sc_core::sc_signal<sc_dt::sc_lv<8>> input_doa_s;

    // ------------------------------------------------------------
    // GAUSS BRAM signals
    // ------------------------------------------------------------
    sc_core::sc_signal<sc_dt::sc_logic> gauss_ena_s;
    sc_core::sc_signal<sc_dt::sc_logic> gauss_wea_s;
    sc_core::sc_signal<sc_dt::sc_lv<19>> gauss_addra_s;
    sc_core::sc_signal<sc_dt::sc_lv<8>> gauss_dia_s;
    sc_core::sc_signal<sc_dt::sc_lv<8>> gauss_doa_s;

    // ------------------------------------------------------------
    // MAG BRAM signals
    // ------------------------------------------------------------
    sc_core::sc_signal<sc_dt::sc_logic> mag_ena_s;
    sc_core::sc_signal<sc_dt::sc_logic> mag_wea_s;
    sc_core::sc_signal<sc_dt::sc_lv<19>> mag_addra_s;
    sc_core::sc_signal<sc_dt::sc_lv<16>> mag_dia_s;
    sc_core::sc_signal<sc_dt::sc_lv<16>> mag_doa_s;

    // ------------------------------------------------------------
    // DIR BRAM signals
    // ------------------------------------------------------------
    sc_core::sc_signal<sc_dt::sc_logic> dir_ena_s;
    sc_core::sc_signal<sc_dt::sc_logic> dir_wea_s;
    sc_core::sc_signal<sc_dt::sc_lv<19>> dir_addra_s;
    sc_core::sc_signal<sc_dt::sc_lv<8>> dir_dia_s;
    sc_core::sc_signal<sc_dt::sc_lv<8>> dir_doa_s;

    // ------------------------------------------------------------
    // NMS BRAM signals
    // ------------------------------------------------------------
    sc_core::sc_signal<sc_dt::sc_logic> nms_ena_s;
    sc_core::sc_signal<sc_dt::sc_logic> nms_wea_s;
    sc_core::sc_signal<sc_dt::sc_lv<19>> nms_addra_s;
    sc_core::sc_signal<sc_dt::sc_lv<16>> nms_dia_s;
    sc_core::sc_signal<sc_dt::sc_lv<16>> nms_doa_s;

    // ------------------------------------------------------------
    // THRESH BRAM signals
    // ------------------------------------------------------------
    sc_core::sc_signal<sc_dt::sc_logic> thresh_ena_s;
    sc_core::sc_signal<sc_dt::sc_logic> thresh_wea_s;
    sc_core::sc_signal<sc_dt::sc_lv<19>> thresh_addra_s;
    sc_core::sc_signal<sc_dt::sc_lv<8>> thresh_dia_s;
    sc_core::sc_signal<sc_dt::sc_lv<8>> thresh_doa_s;

    // ------------------------------------------------------------
    // EDGE BRAM signals
    // ------------------------------------------------------------
    sc_core::sc_signal<sc_dt::sc_logic> edge_ena_s;
    sc_core::sc_signal<sc_dt::sc_logic> edge_wea_s;
    sc_core::sc_signal<sc_dt::sc_lv<19>> edge_addra_s;
    sc_core::sc_signal<sc_dt::sc_lv<8>> edge_dia_s;
    sc_core::sc_signal<sc_dt::sc_lv<8>> edge_doa_s;

    // ------------------------------------------------------------
    // Local memories for internal BRAMs
    // ------------------------------------------------------------
    // Input and edge data are mapped to the SystemC BRAM through TLM.
    // The memories below are internal Canny memories not directly visible to the CPU.
    std::vector<std::uint8_t> gauss_mem;
    std::vector<std::uint16_t> mag_mem;
    std::vector<std::uint8_t> dir_mem;
    std::vector<std::uint16_t> nms_mem;
    std::vector<std::uint8_t> thresh_mem;
    std::vector<std::uint8_t> edge_mem;

    // ------------------------------------------------------------
    // Thread/process functions
    // ------------------------------------------------------------

    // Keep reset asserted for several cycles at simulation start.
    void reset_thread();

    // Generate a one-cycle START pulse for the VHDL IP.
    void start_pulse_thread();

    // Monitor VHDL ready_s and notify the CPU through done_event.
    void done_monitor_thread();

    // BRAM models / translators
    void input_bram_thread();
    void gauss_bram_thread();
    void mag_bram_thread();
    void dir_bram_thread();
    void nms_bram_thread();
    void thresh_bram_thread();
    void edge_bram_thread();

    // ------------------------------------------------------------
    // TLM helper functions for the SystemC BRAM
    // ------------------------------------------------------------
    void write_bram(sc_dt::uint64 addr, unsigned char val);
    unsigned char read_bram(sc_dt::uint64 addr);

    // ------------------------------------------------------------
    // Conversions between integer values and sc_lv signals
    // ------------------------------------------------------------
    static sc_dt::sc_lv<8>  u8_to_lv8(std::uint8_t v);
    static sc_dt::sc_lv<9>  u16_to_lv9(std::uint16_t v);
    static sc_dt::sc_lv<10> u16_to_lv10(std::uint16_t v);
    static sc_dt::sc_lv<16> u16_to_lv16(std::uint16_t v);

    static std::uint8_t  lv8_to_u8(const sc_dt::sc_lv<8>& v);
    static std::uint16_t lv16_to_u16(const sc_dt::sc_lv<16>& v);
    static std::uint32_t lv19_to_u32(const sc_dt::sc_lv<19>& v);

    static bool is_logic_1(const sc_dt::sc_logic& v);
};

#endif // HARD_TLM_BRIDGE_HPP
