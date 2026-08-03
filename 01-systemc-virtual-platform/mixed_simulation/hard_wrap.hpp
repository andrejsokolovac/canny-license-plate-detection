#ifndef HARD_WRAP_HPP
#define HARD_WRAP_HPP

#include <systemc>

/*
 * hard_wrap predstavlja VHDL entity "ip" iz fajla hard.vhd kao SystemC modul.
 *
 * Ovo je direktan pandan koleginom ip_wrap.hpp fajlu.
 * Ovaj fajl NE sadrži Canny algoritam i NE radi TLM komunikaciju.
 * Njegova jedina uloga je da Xcelium poveže SystemC signale sa VHDL portovima.
 */

class hard_wrap : public sc_core::sc_foreign_module
{
public:
    hard_wrap(sc_core::sc_module_name name)
        : sc_core::sc_foreign_module(name),

          // Clock / reset / control
          clk("clk"),
          reset("reset"),
          start("start"),
          ready("ready"),
          rows("rows"),
          cols("cols"),

          // INPUT BRAM
          input_ena("input_ena"),
          input_wea("input_wea"),
          input_addra("input_addra"),
          input_dia("input_dia"),
          input_doa("input_doa"),

          // GAUSS BRAM
          gauss_ena("gauss_ena"),
          gauss_wea("gauss_wea"),
          gauss_addra("gauss_addra"),
          gauss_dia("gauss_dia"),
          gauss_doa("gauss_doa"),

          // MAG BRAM
          mag_ena("mag_ena"),
          mag_wea("mag_wea"),
          mag_addra("mag_addra"),
          mag_dia("mag_dia"),
          mag_doa("mag_doa"),

          // DIR BRAM
          dir_ena("dir_ena"),
          dir_wea("dir_wea"),
          dir_addra("dir_addra"),
          dir_dia("dir_dia"),
          dir_doa("dir_doa"),

          // NMS BRAM
          nms_ena("nms_ena"),
          nms_wea("nms_wea"),
          nms_addra("nms_addra"),
          nms_dia("nms_dia"),
          nms_doa("nms_doa"),

          // THRESH BRAM
          thresh_ena("thresh_ena"),
          thresh_wea("thresh_wea"),
          thresh_addra("thresh_addra"),
          thresh_dia("thresh_dia"),
          thresh_doa("thresh_doa"),

          // EDGE BRAM
          edge_ena("edge_ena"),
          edge_wea("edge_wea"),
          edge_addra("edge_addra"),
          edge_dia("edge_dia"),
          edge_doa("edge_doa")
    {
    }

    /*
     * Ime mora da se poklopi sa imenom VHDL entiteta:
     *
     * entity ip is
     *
     * Zato ovde vraćamo "ip".
     */
    const char* hdl_name() const
    {
        return "ip";
    }

    // ------------------------------------------------------------
    // Clock / reset / control
    // ------------------------------------------------------------

    // VHDL: clk : in std_logic;
    sc_core::sc_in<bool> clk;

    // VHDL: reset : in std_logic;
    sc_core::sc_in<sc_dt::sc_logic> reset;

    // VHDL: start : in std_logic;
    sc_core::sc_in<sc_dt::sc_logic> start;

    // VHDL: ready : out std_logic;
    sc_core::sc_out<sc_dt::sc_logic> ready;

    // VHDL: rows : in std_logic_vector(8 downto 0);
    sc_core::sc_in<sc_dt::sc_lv<9>> rows;

    // VHDL: cols : in std_logic_vector(9 downto 0);
    sc_core::sc_in<sc_dt::sc_lv<10>> cols;

    // ------------------------------------------------------------
    // INPUT BRAM
    // ------------------------------------------------------------

    // VHDL: input_ena : out std_logic;
    sc_core::sc_out<sc_dt::sc_logic> input_ena;

    // VHDL: input_wea : out std_logic;
    sc_core::sc_out<sc_dt::sc_logic> input_wea;

    // VHDL: input_addra : out std_logic_vector(18 downto 0);
    sc_core::sc_out<sc_dt::sc_lv<19>> input_addra;

    // VHDL: input_dia : out std_logic_vector(7 downto 0);
    sc_core::sc_out<sc_dt::sc_lv<8>> input_dia;

    // VHDL: input_doa : in std_logic_vector(7 downto 0);
    sc_core::sc_in<sc_dt::sc_lv<8>> input_doa;

    // ------------------------------------------------------------
    // GAUSS BRAM
    // ------------------------------------------------------------

    sc_core::sc_out<sc_dt::sc_logic> gauss_ena;
    sc_core::sc_out<sc_dt::sc_logic> gauss_wea;
    sc_core::sc_out<sc_dt::sc_lv<19>> gauss_addra;
    sc_core::sc_out<sc_dt::sc_lv<8>> gauss_dia;
    sc_core::sc_in<sc_dt::sc_lv<8>> gauss_doa;

    // ------------------------------------------------------------
    // MAG BRAM
    // ------------------------------------------------------------

    sc_core::sc_out<sc_dt::sc_logic> mag_ena;
    sc_core::sc_out<sc_dt::sc_logic> mag_wea;
    sc_core::sc_out<sc_dt::sc_lv<19>> mag_addra;
    sc_core::sc_out<sc_dt::sc_lv<16>> mag_dia;
    sc_core::sc_in<sc_dt::sc_lv<16>> mag_doa;

    // ------------------------------------------------------------
    // DIR BRAM
    // ------------------------------------------------------------

    sc_core::sc_out<sc_dt::sc_logic> dir_ena;
    sc_core::sc_out<sc_dt::sc_logic> dir_wea;
    sc_core::sc_out<sc_dt::sc_lv<19>> dir_addra;
    sc_core::sc_out<sc_dt::sc_lv<8>> dir_dia;
    sc_core::sc_in<sc_dt::sc_lv<8>> dir_doa;

    // ------------------------------------------------------------
    // NMS BRAM
    // ------------------------------------------------------------

    sc_core::sc_out<sc_dt::sc_logic> nms_ena;
    sc_core::sc_out<sc_dt::sc_logic> nms_wea;
    sc_core::sc_out<sc_dt::sc_lv<19>> nms_addra;
    sc_core::sc_out<sc_dt::sc_lv<16>> nms_dia;
    sc_core::sc_in<sc_dt::sc_lv<16>> nms_doa;

    // ------------------------------------------------------------
    // THRESH BRAM
    // ------------------------------------------------------------

    sc_core::sc_out<sc_dt::sc_logic> thresh_ena;
    sc_core::sc_out<sc_dt::sc_logic> thresh_wea;
    sc_core::sc_out<sc_dt::sc_lv<19>> thresh_addra;
    sc_core::sc_out<sc_dt::sc_lv<8>> thresh_dia;
    sc_core::sc_in<sc_dt::sc_lv<8>> thresh_doa;

    // ------------------------------------------------------------
    // EDGE BRAM
    // ------------------------------------------------------------

    sc_core::sc_out<sc_dt::sc_logic> edge_ena;
    sc_core::sc_out<sc_dt::sc_logic> edge_wea;
    sc_core::sc_out<sc_dt::sc_lv<19>> edge_addra;
    sc_core::sc_out<sc_dt::sc_lv<8>> edge_dia;
    sc_core::sc_in<sc_dt::sc_lv<8>> edge_doa;
};

#endif // HARD_WRAP_HPP
