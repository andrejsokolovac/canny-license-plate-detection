#include "hard_tlm_bridge.hpp"

#include <cstring>

using namespace sc_core;
using namespace sc_dt;
using namespace tlm;
using namespace std;

Hard::Hard(sc_core::sc_module_name name)
    : sc_module(name),
      interconnect_socket("interconnect_socket"),
      bram_socket("bram_socket"),
      rows(0),
      cols(0),
      ready(1),
      start(0),
      offset(SC_ZERO_TIME),
      dut("dut"),
      clk("clk", 5, SC_NS),
      gauss_mem(BRAM_SIZE, 0),
      mag_mem(BRAM_SIZE, 0),
      dir_mem(BRAM_SIZE, 0),
      nms_mem(BRAM_SIZE, 0),
      thresh_mem(BRAM_SIZE, 0),
      edge_mem(BRAM_SIZE,0)
{
    interconnect_socket.register_b_transport(this, &Hard::b_transport);

    // ------------------------------------------------------------
    // Povezivanje VHDL wrapper-a sa SystemC signalima
    // ------------------------------------------------------------

    dut.clk(clk);
    dut.reset(reset_s);
    dut.start(start_s);
    dut.ready(ready_s);
    dut.rows(rows_s);
    dut.cols(cols_s);

    // INPUT BRAM
    dut.input_ena(input_ena_s);
    dut.input_wea(input_wea_s);
    dut.input_addra(input_addra_s);
    dut.input_dia(input_dia_s);
    dut.input_doa(input_doa_s);

    // GAUSS BRAM
    dut.gauss_ena(gauss_ena_s);
    dut.gauss_wea(gauss_wea_s);
    dut.gauss_addra(gauss_addra_s);
    dut.gauss_dia(gauss_dia_s);
    dut.gauss_doa(gauss_doa_s);

    // MAG BRAM
    dut.mag_ena(mag_ena_s);
    dut.mag_wea(mag_wea_s);
    dut.mag_addra(mag_addra_s);
    dut.mag_dia(mag_dia_s);
    dut.mag_doa(mag_doa_s);

    // DIR BRAM
    dut.dir_ena(dir_ena_s);
    dut.dir_wea(dir_wea_s);
    dut.dir_addra(dir_addra_s);
    dut.dir_dia(dir_dia_s);
    dut.dir_doa(dir_doa_s);

    // NMS BRAM
    dut.nms_ena(nms_ena_s);
    dut.nms_wea(nms_wea_s);
    dut.nms_addra(nms_addra_s);
    dut.nms_dia(nms_dia_s);
    dut.nms_doa(nms_doa_s);

    // THRESH BRAM
    dut.thresh_ena(thresh_ena_s);
    dut.thresh_wea(thresh_wea_s);
    dut.thresh_addra(thresh_addra_s);
    dut.thresh_dia(thresh_dia_s);
    dut.thresh_doa(thresh_doa_s);

    // EDGE BRAM
    dut.edge_ena(edge_ena_s);
    dut.edge_wea(edge_wea_s);
    dut.edge_addra(edge_addra_s);
    dut.edge_dia(edge_dia_s);
    dut.edge_doa(edge_doa_s);

    // ------------------------------------------------------------
    // Početne vrednosti signala
    // ------------------------------------------------------------

    reset_s.write(SC_LOGIC_1);
    start_s.write(SC_LOGIC_0);

    rows_s.write(u16_to_lv9(0));
    cols_s.write(u16_to_lv10(0));

    input_doa_s.write(u8_to_lv8(0));
    gauss_doa_s.write(u8_to_lv8(0));
    mag_doa_s.write(u16_to_lv16(0));
    dir_doa_s.write(u8_to_lv8(0));
    nms_doa_s.write(u16_to_lv16(0));
    thresh_doa_s.write(u8_to_lv8(0));
    edge_doa_s.write(u8_to_lv8(0));

    // ------------------------------------------------------------
    // Procesi bridge-a
    // ------------------------------------------------------------

    SC_THREAD(reset_thread);
    SC_THREAD(start_pulse_thread);
    SC_THREAD(done_monitor_thread);

    SC_THREAD(input_bram_thread);
    SC_THREAD(gauss_bram_thread);
    SC_THREAD(mag_bram_thread);
    SC_THREAD(dir_bram_thread);
    SC_THREAD(nms_bram_thread);
    SC_THREAD(thresh_bram_thread);
    SC_THREAD(edge_bram_thread);

    SC_REPORT_INFO("Hard TLM Bridge", "Constructed.");
}

Hard::~Hard()
{
    SC_REPORT_INFO("Hard TLM Bridge", "Destroyed.");
}

// ------------------------------------------------------------
// TLM komunikacija sa CPU/Interconnect strane
// ------------------------------------------------------------

void Hard::b_transport(tlm::tlm_generic_payload& pl, sc_core::sc_time& offset)
{
    tlm_command cmd = pl.get_command();
    sc_dt::uint64 addr = pl.get_address();
    unsigned char* buf = pl.get_data_ptr();

    if (cmd == TLM_WRITE_COMMAND)
    {
        int value = toInt(buf);

        switch (addr)
        {
            case ADDR_ROWS:
            {
                rows = value;
                rows_s.write(u16_to_lv9((std::uint16_t)value));

                std::cout << "[HARD_BRIDGE] rows = " << rows << std::endl;
                pl.set_response_status(TLM_OK_RESPONSE);
                break;
            }

            case ADDR_COLS:
            {
                cols = value;
                cols_s.write(u16_to_lv10((std::uint16_t)value));

                std::cout << "[HARD_BRIDGE] cols = " << cols << std::endl;
                pl.set_response_status(TLM_OK_RESPONSE);
                break;
            }

            case ADDR_START:
            {
                start = value;

                if (start == 1 && ready == 1)
                {
                    ready = 0;

                    std::cout << "[HARD_BRIDGE] START primljen. Pokrecem VHDL Canny IP..."
                              << std::endl;

                    start_event.notify(SC_ZERO_TIME);
                }

                pl.set_response_status(TLM_OK_RESPONSE);
                break;
            }

            default:
            {
                std::cerr << "[HARD_BRIDGE] Pogresna adresa za WRITE: 0x"
                          << std::hex << addr << std::dec << std::endl;

                pl.set_response_status(TLM_ADDRESS_ERROR_RESPONSE);
                break;
            }
        }
    }
    else if (cmd == TLM_READ_COMMAND)
    {
        switch (addr)
        {
            case ADDR_READY:
            {
                if (is_logic_1(ready_s.read()))
                    ready = 1;
                else
                    ready = 0;

                toUchar(buf, ready);

                std::cout << "[HARD_BRIDGE] READ READY = " << ready << std::endl;

                pl.set_response_status(TLM_OK_RESPONSE);
                break;
            }

            default:
            {
                std::cerr << "[HARD_BRIDGE] Pogresna adresa za READ: 0x"
                          << std::hex << addr << std::dec << std::endl;

                pl.set_response_status(TLM_ADDRESS_ERROR_RESPONSE);
                break;
            }
        }
    }
    else
    {
        pl.set_response_status(TLM_COMMAND_ERROR_RESPONSE);
    }

    offset += sc_time(DELAY, SC_NS);
}

// ------------------------------------------------------------
// Reset / start / done procesi
// ------------------------------------------------------------

void Hard::reset_thread()
{
    reset_s.write(SC_LOGIC_1);
    start_s.write(SC_LOGIC_0);

    wait(5, SC_NS);
    wait(clk.posedge_event());
    wait(clk.posedge_event());
    wait(clk.posedge_event());

    reset_s.write(SC_LOGIC_0);

    std::cout << "[HARD_BRIDGE] Reset zavrsen." << std::endl;
}

void Hard::start_pulse_thread()
{
    while (true)
    {
        wait(start_event);
	
	for(int i=0;i<BRAM_SIZE;i++)
	{
		edge_mem[i]=0;
	}
        // Sacekaj pozitivan takt, pa digni start.
	while(reset_s.read() == SC_LOGIC_1)
	{
		wait(clk.posedge_event());
	}
	wait(clk.posedge_event());
        start_s.write(SC_LOGIC_1);

        // Start impuls traje jedan takt.
        wait(clk.posedge_event());
        start_s.write(SC_LOGIC_0);

        std::cout << "[HARD_BRIDGE] START impuls poslat ka VHDL IP-u." << std::endl;
    }
}

void Hard::done_monitor_thread()
{
    while (true)
    {
        wait(start_event);

        // VHDL ready je u IDLE stanju 1, a tokom obrade treba da padne na 0.
        do
        {
            wait(clk.posedge_event());
        }
        while (is_logic_1(ready_s.read()));

        std::cout << "[HARD_BRIDGE] VHDL IP je zapoceo obradu." << std::endl;

        // Cekamo da se ready vrati na 1.
        do
        {
            wait(clk.posedge_event());
        }
        while (!is_logic_1(ready_s.read()));

        ready = 1;
	
	std::cout<<"[HARD_BRIDGE] VHDL Canny zavrsen. Kopiram edge mem u system c bram.."<<std::endl;
	
	for(int i=0; i<BRAM_SIZE;i++)
	{
		write_bram(i,edge_mem[i]);
	}

	std::cout<<"[HARD_BRIDGE] edge mem kopiram u system c bram..."<<std::endl;

        wait(SC_ZERO_TIME);
        done_event.notify(SC_ZERO_TIME);

        std::cout << "[HARD_BRIDGE] VHDL Canny zavrsen. done_event poslat CPU-u."
                  << std::endl;
    }
}

// ------------------------------------------------------------
// TLM pristup postojecem SystemC BRAM-u
// ------------------------------------------------------------

void Hard::write_bram(sc_dt::uint64 addr, unsigned char val)
{
    tlm_generic_payload pl;
    sc_time delay = SC_ZERO_TIME;

    unsigned char buf = val;

    pl.set_address(addr);
    pl.set_data_length(1);
    pl.set_data_ptr(&buf);
    pl.set_command(TLM_WRITE_COMMAND);
    pl.set_response_status(TLM_INCOMPLETE_RESPONSE);

    bram_socket->b_transport(pl, delay);

    if (pl.get_response_status() != TLM_OK_RESPONSE)
    {
        std::cerr << "[HARD_BRIDGE] Greska pri pisanju u BRAM, addr = "
                  << addr << std::endl;
    }
}

unsigned char Hard::read_bram(sc_dt::uint64 addr)
{
    tlm_generic_payload pl;
    sc_time delay = SC_ZERO_TIME;

    unsigned char buf = 0;

    pl.set_address(addr);
    pl.set_data_length(1);
    pl.set_data_ptr(&buf);
    pl.set_command(TLM_READ_COMMAND);
    pl.set_response_status(TLM_INCOMPLETE_RESPONSE);

    bram_socket->b_transport(pl, delay);

    if (pl.get_response_status() != TLM_OK_RESPONSE)
    {
        std::cerr << "[HARD_BRIDGE] Greska pri citanju iz BRAM-a, addr = "
                  << addr << std::endl;
    }

    return buf;
}

// ------------------------------------------------------------
// BRAM thread-ovi
// Svi rade na pozitivnu ivicu clock-a i glume sinhroni BRAM.
// Logika je ista kao u tvom bram.vhd:
//   ako je EN = 1, prvo se cita memorija,
//   zatim ako je WE = 1, upisuje se nova vrednost.
// ------------------------------------------------------------

void Hard::input_bram_thread()
{
    while (true)
    {
        wait(clk.posedge_event());

        if (is_logic_1(input_ena_s.read()))
        {
            std::uint32_t addr = lv19_to_u32(input_addra_s.read());

            if (addr < BRAM_SIZE)
            {
                unsigned char old_val = read_bram(addr);
                input_doa_s.write(u8_to_lv8(old_val));

                if (is_logic_1(input_wea_s.read()))
                {
                    unsigned char new_val = lv8_to_u8(input_dia_s.read());
                    write_bram(addr, new_val);
                }
            }
            else
            {
                input_doa_s.write(u8_to_lv8(0));
            }
        }
    }
}

void Hard::gauss_bram_thread()
{
    while (true)
    {
        wait(clk.posedge_event());

        if (is_logic_1(gauss_ena_s.read()))
        {
            std::uint32_t addr = lv19_to_u32(gauss_addra_s.read());

            if (addr < gauss_mem.size())
            {
                std::uint8_t old_val = gauss_mem[addr];
                gauss_doa_s.write(u8_to_lv8(old_val));

                if (is_logic_1(gauss_wea_s.read()))
                {
                    gauss_mem[addr] = lv8_to_u8(gauss_dia_s.read());
                }
            }
            else
            {
                gauss_doa_s.write(u8_to_lv8(0));
            }
        }
    }
}

void Hard::mag_bram_thread()
{
    while (true)
    {
        wait(clk.posedge_event());

        if (is_logic_1(mag_ena_s.read()))
        {
            std::uint32_t addr = lv19_to_u32(mag_addra_s.read());

            if (addr < mag_mem.size())
            {
                std::uint16_t old_val = mag_mem[addr];
                mag_doa_s.write(u16_to_lv16(old_val));

                if (is_logic_1(mag_wea_s.read()))
                {
                    mag_mem[addr] = lv16_to_u16(mag_dia_s.read());
                }
            }
            else
            {
                mag_doa_s.write(u16_to_lv16(0));
            }
        }
    }
}

void Hard::dir_bram_thread()
{
    while (true)
    {
        wait(clk.posedge_event());

        if (is_logic_1(dir_ena_s.read()))
        {
            std::uint32_t addr = lv19_to_u32(dir_addra_s.read());

            if (addr < dir_mem.size())
            {
                std::uint8_t old_val = dir_mem[addr];
                dir_doa_s.write(u8_to_lv8(old_val));

                if (is_logic_1(dir_wea_s.read()))
                {
                    dir_mem[addr] = lv8_to_u8(dir_dia_s.read());
                }
            }
            else
            {
                dir_doa_s.write(u8_to_lv8(0));
            }
        }
    }
}

void Hard::nms_bram_thread()
{
    while (true)
    {
        wait(clk.posedge_event());

        if (is_logic_1(nms_ena_s.read()))
        {
            std::uint32_t addr = lv19_to_u32(nms_addra_s.read());

            if (addr < nms_mem.size())
            {
                std::uint16_t old_val = nms_mem[addr];
                nms_doa_s.write(u16_to_lv16(old_val));

                if (is_logic_1(nms_wea_s.read()))
                {
                    nms_mem[addr] = lv16_to_u16(nms_dia_s.read());
                }
            }
            else
            {
                nms_doa_s.write(u16_to_lv16(0));
            }
        }
    }
}

void Hard::thresh_bram_thread()
{
    while (true)
    {
        wait(clk.posedge_event());

        if (is_logic_1(thresh_ena_s.read()))
        {
            std::uint32_t addr = lv19_to_u32(thresh_addra_s.read());

            if (addr < thresh_mem.size())
            {
                std::uint8_t old_val = thresh_mem[addr];
                thresh_doa_s.write(u8_to_lv8(old_val));

                if (is_logic_1(thresh_wea_s.read()))
                {
                    thresh_mem[addr] = lv8_to_u8(thresh_dia_s.read());
                }
            }
            else
            {
                thresh_doa_s.write(u8_to_lv8(0));
            }
        }
    }
}

void Hard::edge_bram_thread()
{
    while (true)
    {
        wait(clk.posedge_event());

        if (is_logic_1(edge_ena_s.read()))
        {
            std::uint32_t addr = lv19_to_u32(edge_addra_s.read());

            if (addr < edge_mem.size())
            {
		std::uint8_t old_val = edge_mem[addr];
               // unsigned char old_val = read_bram(addr);
                edge_doa_s.write(u8_to_lv8(old_val));

                if (is_logic_1(edge_wea_s.read()))
                {
                   // unsigned char new_val = lv8_to_u8(edge_dia_s.read());
                   // write_bram(addr, new_val);
			edge_mem[addr]=lv8_to_u8(edge_dia_s.read());
                }
            }
            else
            {
                edge_doa_s.write(u8_to_lv8(0));
            }
        }
    }
}

// ------------------------------------------------------------
// Konverzije
// ------------------------------------------------------------

sc_dt::sc_lv<8> Hard::u8_to_lv8(std::uint8_t v)
{
    sc_dt::sc_lv<8> ret;
    ret = sc_dt::sc_uint<8>(v);
    return ret;
}

sc_dt::sc_lv<9> Hard::u16_to_lv9(std::uint16_t v)
{
    sc_dt::sc_lv<9> ret;
    ret = sc_dt::sc_uint<9>(v);
    return ret;
}

sc_dt::sc_lv<10> Hard::u16_to_lv10(std::uint16_t v)
{
    sc_dt::sc_lv<10> ret;
    ret = sc_dt::sc_uint<10>(v);
    return ret;
}

sc_dt::sc_lv<16> Hard::u16_to_lv16(std::uint16_t v)
{
    sc_dt::sc_lv<16> ret;
    ret = sc_dt::sc_uint<16>(v);
    return ret;
}

std::uint8_t Hard::lv8_to_u8(const sc_dt::sc_lv<8>& v)
{
    sc_dt::sc_uint<8> tmp;
    tmp = v;
    return (std::uint8_t)tmp.to_uint();
}

std::uint16_t Hard::lv16_to_u16(const sc_dt::sc_lv<16>& v)
{
    sc_dt::sc_uint<16> tmp;
    tmp = v;
    return (std::uint16_t)tmp.to_uint();
}

std::uint32_t Hard::lv19_to_u32(const sc_dt::sc_lv<19>& v)
{
    sc_dt::sc_uint<19> tmp;
    tmp = v;
    return (std::uint32_t)tmp.to_uint();
}

bool Hard::is_logic_1(const sc_dt::sc_logic& v)
{
    return v == sc_dt::SC_LOGIC_1;
}
