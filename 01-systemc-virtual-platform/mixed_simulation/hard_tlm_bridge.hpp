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
 * Ovaj modul zamenjuje stari hard.cpp u mešanoj simulaciji.
 *
 * Spolja se ponaša isto kao stari SystemC Hard:
 *   - ima interconnect_socket kao TLM target socket
 *   - ima bram_socket kao TLM initiator socket
 *   - ima done_event koji CPU već koristi za čekanje kraja obrade
 *
 * Iznutra instancira VHDL entity "ip" preko hard_wrap klase.
 */
class Hard : public sc_core::sc_module
{
public:
    // Isto kao u starom Hard modulu:
    // CPU/Interconnect šalju registarske TLM transakcije ka ovom socket-u.
    tlm_utils::simple_target_socket<Hard> interconnect_socket;

    // Isto kao u starom Hard modulu:
    // Hard pristupa postojećem SystemC BRAM-u preko ovog initiator socket-a.
    tlm_utils::simple_initiator_socket<Hard> bram_socket;

    // Registri vidljivi CPU-u
    sc_dt::sc_uint<16> rows;
    sc_dt::sc_uint<16> cols;
    sc_dt::sc_uint<1> ready;
    sc_dt::sc_uint<1> start;

    // CPU kod već očekuje da Hard ima done_event.
    sc_core::sc_event done_event;

    // Ostavljamo i start_event zbog sličnosti sa starim hard.hpp/hard.cpp,
    // iako će se u bridge-u START pretvarati u RTL impuls.
    sc_core::sc_event start_event;

    sc_core::sc_time offset;

    SC_HAS_PROCESS(Hard);

    Hard(sc_core::sc_module_name name);
    ~Hard();

    // TLM funkcija koju poziva Interconnect.
    void b_transport(tlm::tlm_generic_payload& pl, sc_core::sc_time& offset);

private:
    // ------------------------------------------------------------
    // VHDL DUT wrapper
    // ------------------------------------------------------------
    hard_wrap dut;

    // ------------------------------------------------------------
    // Clock / reset / control signali za VHDL IP
    // ------------------------------------------------------------
    sc_core::sc_clock clk;

    sc_core::sc_signal<sc_dt::sc_logic> reset_s;
    sc_core::sc_signal<sc_dt::sc_logic> start_s;
    sc_core::sc_signal<sc_dt::sc_logic> ready_s;

    sc_core::sc_signal<sc_dt::sc_lv<9>> rows_s;
    sc_core::sc_signal<sc_dt::sc_lv<10>> cols_s;

    // ------------------------------------------------------------
    // INPUT BRAM signali
    // ------------------------------------------------------------
    sc_core::sc_signal<sc_dt::sc_logic> input_ena_s;
    sc_core::sc_signal<sc_dt::sc_logic> input_wea_s;
    sc_core::sc_signal<sc_dt::sc_lv<19>> input_addra_s;
    sc_core::sc_signal<sc_dt::sc_lv<8>> input_dia_s;
    sc_core::sc_signal<sc_dt::sc_lv<8>> input_doa_s;

    // ------------------------------------------------------------
    // GAUSS BRAM signali
    // ------------------------------------------------------------
    sc_core::sc_signal<sc_dt::sc_logic> gauss_ena_s;
    sc_core::sc_signal<sc_dt::sc_logic> gauss_wea_s;
    sc_core::sc_signal<sc_dt::sc_lv<19>> gauss_addra_s;
    sc_core::sc_signal<sc_dt::sc_lv<8>> gauss_dia_s;
    sc_core::sc_signal<sc_dt::sc_lv<8>> gauss_doa_s;

    // ------------------------------------------------------------
    // MAG BRAM signali
    // ------------------------------------------------------------
    sc_core::sc_signal<sc_dt::sc_logic> mag_ena_s;
    sc_core::sc_signal<sc_dt::sc_logic> mag_wea_s;
    sc_core::sc_signal<sc_dt::sc_lv<19>> mag_addra_s;
    sc_core::sc_signal<sc_dt::sc_lv<16>> mag_dia_s;
    sc_core::sc_signal<sc_dt::sc_lv<16>> mag_doa_s;

    // ------------------------------------------------------------
    // DIR BRAM signali
    // ------------------------------------------------------------
    sc_core::sc_signal<sc_dt::sc_logic> dir_ena_s;
    sc_core::sc_signal<sc_dt::sc_logic> dir_wea_s;
    sc_core::sc_signal<sc_dt::sc_lv<19>> dir_addra_s;
    sc_core::sc_signal<sc_dt::sc_lv<8>> dir_dia_s;
    sc_core::sc_signal<sc_dt::sc_lv<8>> dir_doa_s;

    // ------------------------------------------------------------
    // NMS BRAM signali
    // ------------------------------------------------------------
    sc_core::sc_signal<sc_dt::sc_logic> nms_ena_s;
    sc_core::sc_signal<sc_dt::sc_logic> nms_wea_s;
    sc_core::sc_signal<sc_dt::sc_lv<19>> nms_addra_s;
    sc_core::sc_signal<sc_dt::sc_lv<16>> nms_dia_s;
    sc_core::sc_signal<sc_dt::sc_lv<16>> nms_doa_s;

    // ------------------------------------------------------------
    // THRESH BRAM signali
    // ------------------------------------------------------------
    sc_core::sc_signal<sc_dt::sc_logic> thresh_ena_s;
    sc_core::sc_signal<sc_dt::sc_logic> thresh_wea_s;
    sc_core::sc_signal<sc_dt::sc_lv<19>> thresh_addra_s;
    sc_core::sc_signal<sc_dt::sc_lv<8>> thresh_dia_s;
    sc_core::sc_signal<sc_dt::sc_lv<8>> thresh_doa_s;

    // ------------------------------------------------------------
    // EDGE BRAM signali
    // ------------------------------------------------------------
    sc_core::sc_signal<sc_dt::sc_logic> edge_ena_s;
    sc_core::sc_signal<sc_dt::sc_logic> edge_wea_s;
    sc_core::sc_signal<sc_dt::sc_lv<19>> edge_addra_s;
    sc_core::sc_signal<sc_dt::sc_lv<8>> edge_dia_s;
    sc_core::sc_signal<sc_dt::sc_lv<8>> edge_doa_s;

    // ------------------------------------------------------------
    // Lokalne memorije za interne BRAM-ove
    // ------------------------------------------------------------
    // Input i edge mapiramo na postojeći SystemC BRAM preko TLM-a.
    // Ove memorije ispod su interne Canny memorije koje CPU ne vidi direktno.
    std::vector<std::uint8_t> gauss_mem;
    std::vector<std::uint16_t> mag_mem;
    std::vector<std::uint8_t> dir_mem;
    std::vector<std::uint16_t> nms_mem;
    std::vector<std::uint8_t> thresh_mem;
    std::vector<std::uint8_t> edge_mem;

    // ------------------------------------------------------------
    // Thread/process funkcije
    // ------------------------------------------------------------

    // Drži reset aktivnim nekoliko taktova na početku simulacije.
    void reset_thread();

    // Pravi jednotaktni START impuls ka VHDL IP-u.
    void start_pulse_thread();

    // Prati ready_s iz VHDL-a i obaveštava CPU preko done_event.
    void done_monitor_thread();

    // BRAM modeli / translatori
    void input_bram_thread();
    void gauss_bram_thread();
    void mag_bram_thread();
    void dir_bram_thread();
    void nms_bram_thread();
    void thresh_bram_thread();
    void edge_bram_thread();

    // ------------------------------------------------------------
    // TLM pomoćne funkcije za postojeći SystemC BRAM
    // ------------------------------------------------------------
    void write_bram(sc_dt::uint64 addr, unsigned char val);
    unsigned char read_bram(sc_dt::uint64 addr);

    // ------------------------------------------------------------
    // Konverzije između integer vrednosti i sc_lv signala
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
