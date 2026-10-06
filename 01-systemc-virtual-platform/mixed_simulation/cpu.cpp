#include "cpu.hpp"
//#include "hard_tlm_bridge.hpp"
SC_HAS_PROCESS(Cpu);

using namespace sc_core;

char** data_string;
int argc;

Cpu::Cpu(sc_core::sc_module_name name, char** strings, int argv, Hard* hard_ptr)
    : sc_module(name),
      interconnect_socket("interconnect_socket"),
      hard(hard_ptr),
      input_txt_path(INPUT_TXT_FILE),
      expected_txt_path(EXPECTED_TXT_FILE),
      output_txt_path(OUTPUT_TXT_FILE),
      image_rows(IMAGE_ROWS),
      image_cols(IMAGE_COLS),
      ready(0),
      done(false),
      offset(SC_ZERO_TIME)
{
    // Use the input TXT file provided as an argument when available.
    // Otherwise use grayscale_full.txt from the current directory.
    if (argv > 1)
    {
        input_txt_path = strings[1];
    }

    SC_THREAD(process);
    SC_REPORT_INFO("Cpu", "Constructed.");

    data_string = strings;
    argc = argv;
}

Cpu::~Cpu()
{
    SC_REPORT_INFO("Cpu", "Destroyed.");
}

void Cpu::process()
{
    wait(SC_ZERO_TIME);

    const int image_size = image_rows * image_cols;

    std::cout << "[CPU] Mixed simulation bez OpenCV-a." << std::endl;
    std::cout << "[CPU] Ulazni TXT: " << input_txt_path << std::endl;
    std::cout << "[CPU] Dimenzije slike: " << image_cols << "x" << image_rows << std::endl;

    // 1. Load grayscale image from TXT
    std::vector<unsigned char> img_data = load_txt_image(input_txt_path, image_size);

    // 2. Write the input image to SystemC BRAM
    std::cout << "[CPU] Upisujem ulaznu sliku u BRAM..." << std::endl;

    for (int i = 0; i < image_size; ++i)
    {
        send_to_bram(i, img_data[i]);
    }

    std::cout << "[CPU] Ulazna slika upisana u BRAM." << std::endl;

    // 3. Send rows/cols registers to the hardware model
    write_hard(ADDR_ROWS, image_rows);
    std::cout << "[CPU] Sent image_rows (" << image_rows << ") to HARD." << std::endl;

    write_hard(ADDR_COLS, image_cols);
    std::cout << "[CPU] Sent image_cols (" << image_cols << ") to HARD." << std::endl;

    // 4. START
    write_hard(ADDR_START, 1);
    std::cout << "[CPU] Sent START signal to HARD." << std::endl;

    // 5. Wait for the VHDL IP to finish processing
    ready = read_hard(ADDR_READY);
    std::cout << "[CPU] Waiting for HARD to complete processing... READY = "
              << ready << std::endl;

    wait(hard->done_event);

    std::cout << "[CPU] HARD processing done. Reading processed image..." << std::endl;

    // 6. Read the result from BRAM
    unsigned char* result = new unsigned char[image_size];
    receive_from_bram(0, result, image_size);

    // 7. Save the result to TXT
    save_txt_image(output_txt_path, result, image_size);
    std::cout << "[CPU] Rezultat sacuvan u: " << output_txt_path << std::endl;

    // 8. Compare against final_edge_full.txt when the reference file is available
    compare_with_expected(expected_txt_path, result, image_size);

    std::cout << "CPU: Canny edge detection finished." << std::endl;
    std::cout << "UKUPNO SIMULACIONO VREME (CPU offset): "
              << offset.to_string() << std::endl;

    delete[] result;

    sc_stop();
}

std::vector<unsigned char> Cpu::load_txt_image(const std::string& path, int expected_size)
{
    std::ifstream file(path.c_str());

    if (!file.is_open())
    {
        std::cerr << "[CPU] Error: Ne mogu da otvorim ulazni TXT fajl: "
                  << path << std::endl;
        exit(EXIT_FAILURE);
    }

    std::vector<unsigned char> data;
    data.reserve(expected_size);

    int value;
    int line = 0;

    while (file >> value)
    {
        ++line;

        if (value < 0 || value > 255)
        {
            std::cerr << "[CPU] Error: Vrednost van opsega 0-255 u fajlu "
                      << path << ", linija " << line
                      << ", vrednost = " << value << std::endl;
            exit(EXIT_FAILURE);
        }

        data.push_back(static_cast<unsigned char>(value));
    }

    file.close();

    if ((int)data.size() != expected_size)
    {
        std::cerr << "[CPU] Error: TXT fajl " << path << " ima "
                  << data.size() << " vrednosti, a ocekivano je "
                  << expected_size << "." << std::endl;
        exit(EXIT_FAILURE);
    }

    std::cout << "[CPU] Ucitano " << data.size()
              << " piksela iz " << path << std::endl;

    return data;
}

void Cpu::save_txt_image(const std::string& path, const unsigned char* data, int length)
{
    std::ofstream file(path.c_str());

    if (!file.is_open())
    {
        std::cerr << "[CPU] Error: Ne mogu da otvorim izlazni TXT fajl: "
                  << path << std::endl;
        return;
    }

    for (int i = 0; i < length; ++i)
    {
        file << static_cast<int>(data[i]) << std::endl;
    }

    file.close();
}

/*void Cpu::compare_with_expected(const std::string& expected_path,
                                const unsigned char* data,
                                int length)
{
    std::ifstream file(expected_path.c_str());

    if (!file.is_open())
    {
        std::cout << "[CPU] Expected fajl nije pronadjen: "
                  << expected_path
                  << " — preskacem poredjenje." << std::endl;
        return;
    }

    int matches = 0;
    int mismatches = 0;
    int value;
    int index = 0;

    while (file >> value)
    {
        if (index >= length)
        {
            ++mismatches;
            continue;
        }

        unsigned char expected = static_cast<unsigned char>(value);

        if (data[index] == expected)
            ++matches;
        else
            ++mismatches;

        ++index;
    }

    if (index != length)
    {
        std::cout << "[CPU] Upozorenje: expected fajl ima "
                  << index << " vrednosti, a rezultat ima "
                  << length << "." << std::endl;
    }

    file.close();

    std::cout << "[CPU] Poredjenje sa " << expected_path << " zavrseno." << std::endl;
    std::cout << "[CPU] MATCHES    = " << matches << std::endl;
    std::cout << "[CPU] MISMATCHES = " << mismatches << std::endl;
}*/
void Cpu::compare_with_expected(const std::string& expected_path,
                                const unsigned char* data,
                                int length)
{
    std::ifstream file(expected_path.c_str());

    if (!file.is_open())
    {
        std::cout << "[CPU] Expected fajl nije pronadjen: "
                  << expected_path
                  << " — preskacem poredjenje." << std::endl;
        return;
    }

    const int total_size = image_rows * image_cols;

    std::vector<unsigned char> expected_data;
    expected_data.reserve(total_size);

    int value;
    int index = 0;

    while (file >> value)
    {
        if (value < 0 || value > 255)
        {
            std::cerr << "[CPU] Error: Expected fajl ima vrednost van opsega 0-255, index = "
                      << index << ", value = " << value << std::endl;
            file.close();
            return;
        }

        expected_data.push_back(static_cast<unsigned char>(value));
        index++;
    }

    file.close();

    if ((int)expected_data.size() != total_size)
    {
        std::cerr << "[CPU] Error: Expected fajl ima "
                  << expected_data.size()
                  << " vrednosti, a ocekivano je "
                  << total_size << "." << std::endl;
        return;
    }

    int matches = 0;
    int mismatches = 0;

    /*
     * Use the same valid comparison region as the VHDL testbench:
     *
     * for i in 4 to TEST_ROWS - 5 loop
     *     for j in 4 to TEST_COLS - 5 loop
     *
     * For a 384x512 image:
     * row = 4..379
     * col = 4..507
     *
     * Total valid pixels:
     * 376 * 504 = 189504
     */
    for (int r = 4; r <= image_rows - 5; r++)
    {
        for (int c = 4; c <= image_cols - 5; c++)
        {
            int addr = r * image_cols + c;

            if (data[addr] == expected_data[addr])
            {
                matches++;
            }
            else
            {
                mismatches++;

                if (mismatches <= 50)
                {
                    std::cout << "[CPU] MISMATCH addr=" << addr
                              << " row=" << r
                              << " col=" << c
                              << " got=" << static_cast<int>(data[addr])
                              << " expected=" << static_cast<int>(expected_data[addr])
                              << std::endl;
                }
            }
        }
    }

    std::cout << "[CPU] Poredjenje sa " << expected_path << " zavrseno." << std::endl;
    std::cout << "[CPU] VALID ZONE: rows 4.." << image_rows - 5
              << ", cols 4.." << image_cols - 5 << std::endl;
    std::cout << "[CPU] VALID PIXELS = " << matches + mismatches << std::endl;
    std::cout << "[CPU] MATCHES      = " << matches << std::endl;
    std::cout << "[CPU] MISMATCHES   = " << mismatches << std::endl;
}
int Cpu::read_hard(sc_dt::uint64 addr)
{
    pl_t pl;
    unsigned char buf[4];

    pl.set_address(VP_ADDR_IP_HARD_L + addr);
    pl.set_data_length(4);
    pl.set_data_ptr(buf);
    pl.set_command(tlm::TLM_READ_COMMAND);
    pl.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

    interconnect_socket->b_transport(pl, offset);

    return toInt(buf);
}

void Cpu::write_hard(sc_dt::uint64 addr, int val)
{
    pl_t pl;
    unsigned char buf[4];

    toUchar(buf, val);

    pl.set_address(VP_ADDR_IP_HARD_L + addr);
    pl.set_data_length(4);
    pl.set_data_ptr(buf);
    pl.set_command(tlm::TLM_WRITE_COMMAND);
    pl.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

    interconnect_socket->b_transport(pl, offset);
}

void Cpu::send_to_bram(sc_dt::sc_uint<64> addr, unsigned char val)
{
    pl_t pl;
    unsigned char buf = val;

    pl.set_address(VP_ADDR_BRAM_L + addr);
    pl.set_data_length(1);
    pl.set_data_ptr(&buf);
    pl.set_command(tlm::TLM_WRITE_COMMAND);
    pl.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

    interconnect_socket->b_transport(pl, offset);
}

void Cpu::receive_from_bram(sc_dt::sc_uint<64> addr, unsigned char* all_data, int length)
{
    pl_t pl;
    unsigned char buf;
    int n = 0;

    for (int i = 0; i < length; i++)
    {
        pl.set_address(VP_ADDR_BRAM_L + addr + i);
        pl.set_data_length(1);
        pl.set_data_ptr(&buf);
        pl.set_command(tlm::TLM_READ_COMMAND);
        pl.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

        interconnect_socket->b_transport(pl, offset);

        all_data[n++] = buf;
    }
}

void Cpu::print_status()
{
    std::cout << "[CPU] READY = " << ready << std::endl;
}






	




