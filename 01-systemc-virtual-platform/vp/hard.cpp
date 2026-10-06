#include "hard.hpp"
#include <iostream>
#include <stdio.h>

using namespace sc_core;
using namespace std;

Hard::Hard(sc_core::sc_module_name name) : sc_module(name), ready(1), start(0) {
    interconnect_socket.register_b_transport(this, &Hard::b_transport);
    
    SC_THREAD(main_thread);   // Glavna nit
    sensitive << start_event; // Biće pokrenuta kada se desi start_event
    
    SC_REPORT_INFO("Hard", "Constructed.");
}

Hard::~Hard() {
    SC_REPORT_INFO("Hard", "Destroyed.");
}

void Hard::b_transport(tlm::tlm_generic_payload &pl, sc_core::sc_time &offset) {
    tlm::tlm_command cmd = pl.get_command();
    sc_dt::uint64 addr = pl.get_address();
    unsigned char *buf = pl.get_data_ptr();
    
    if (cmd == tlm::TLM_WRITE_COMMAND) {
        switch (addr) {
            case ADDR_ROWS:    	
                rows = toInt(buf);
                std::cout << "[HARD] rows = " << rows << std::endl;
                break;
            case ADDR_COLS:
                cols = toInt(buf);
                std::cout << "[HARD] cols = " << cols << std::endl;
                break;
            case ADDR_START:
                start = toInt(buf);
                if (start == 1 && ready == 1) {
        		ready = 0;
        		std::cout << "[HARD] START primljen. Pokrećem Canny..." << std::endl;
        		start_event.notify(SC_ZERO_TIME); // Pokreće glavnu nit
                }
                cout << "[HARD] Processing started..." << endl;
                std::cout << "[HARD] start = " << start << std::endl;
                break;
            default:
                pl.set_response_status(tlm::TLM_ADDRESS_ERROR_RESPONSE);
                std::cerr << "[HARD] Wrong address" << std::endl;
        }
    } else if (cmd == tlm::TLM_READ_COMMAND) {
        if (addr == ADDR_READY) {
            toUchar(buf, ready); 
        } else {
            pl.set_response_status(tlm::TLM_ADDRESS_ERROR_RESPONSE);
        }
    } else {
        pl.set_response_status(tlm::TLM_COMMAND_ERROR_RESPONSE);
    }
    }

void Hard::main_thread() {
    while (true) {
        wait(start_event); // Čekaj START
        
	wait(sc_time(10, SC_NS));  // testna pauza
        std::cout << "[HARD] Canny započet iz glavne niti." << std::endl;
        execute_canny(); // Poziv glavne funkcije

        ready = 1; // Gotovo
        wait(SC_ZERO_TIME);
        done_event.notify(SC_ZERO_TIME); // dodato
        std::cout << "[HARD] Canny završen." << std::endl;
    }
}

void Hard::write_bram(sc_dt::uint64 addr, unsigned char val) {
    tlm::tlm_generic_payload pl;

    unsigned char buf = val;
    pl.set_address(addr);
    pl.set_data_length(1);
    pl.set_data_ptr(&buf);
    pl.set_command(tlm::TLM_WRITE_COMMAND);
    pl.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

    bram_socket->b_transport(pl, offset);

}

unsigned char Hard::read_bram(sc_dt::uint64 addr) {
    tlm::tlm_generic_payload pl;
    
    unsigned char buf = 0;
    pl.set_address(addr);
    pl.set_data_length(1);
    pl.set_data_ptr(&buf);
    pl.set_command(tlm::TLM_READ_COMMAND);
    pl.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

    bram_socket->b_transport(pl, offset);

    return buf;
}

sc_uint<16> isqrt(sc_uint<32> num) {
    sc_uint<32> res = 0;
    sc_uint<32> bit = 1 << 30;

    while (bit > num)
        bit >>= 2;

    while (bit != 0) {
        if (num >= res + bit) {
            num -= res + bit;
            res = (res >> 1) + bit;
        } else {
            res >>= 1;
        }
        bit >>= 2;
    }

    return res;
}

void Hard::execute_canny() {
    ready = 0;

    if (rows <= 0 || cols <= 0 || rows > 480 || cols > 640) {
        printf("[HARD] Invalid dimensions: rows=%d, cols=%d\n", rows, cols);
        return;
    }
    
    static sc_uint<16> input_image[MAX_IMAGE_HEIGHT][MAX_IMAGE_WIDTH] = {}; // Da li je ovo dobro ?
    static sc_uint<16> edges[MAX_IMAGE_HEIGHT][MAX_IMAGE_WIDTH] = {};
    static sc_uint<16> gradient_direction[MAX_IMAGE_HEIGHT][MAX_IMAGE_WIDTH]= {};
    static sc_uint<16> magnitude[MAX_IMAGE_HEIGHT][MAX_IMAGE_WIDTH] = {};
    static sc_uint<16> blurred[MAX_IMAGE_HEIGHT][MAX_IMAGE_WIDTH] = {};
    
    // Read from BRAM
    for (int i = 0; i < rows; ++i)
        for (int j = 0; j < cols; ++j)
            input_image[i][j] = read_bram(i * cols + j);

    // Gaussian filtering
    const sc_uint<8> kernel[5][5] = {
        {1, 4, 6, 4, 1},
        {4, 16, 24, 16, 4},
        {6, 24, 36, 24, 6},
        {4, 16, 24, 16, 4},
        {1, 4, 6, 4, 1}
    };
    
    for (int i = 2; i < rows - 2; ++i)
        for (int j = 2; j < cols - 2; ++j) {
            sc_uint<16> sum = 0; //int
            for (int k = -2; k <= 2; ++k)
                for (int l = -2; l <= 2; ++l)
                    sum += input_image[i + k][j + l] * kernel[k + 2][l + 2];
            blurred[i][j] = sum / 256;
        }

    // Sobel operator
    const sc_int<8> sobelX[3][3] = {
        {-1, 0, 1},
        {-2, 0, 2},
        {-1, 0, 1}
    };
    
    const sc_int<8> sobelY[3][3] = {
        {1, 2, 1},
        {0, 0, 0},
        {-1, -2, -1}
    };
    
    for (int i = 1; i < rows - 1; ++i)
        for (int j = 1; j < cols - 1; ++j) {
            sc_int<32> gx=0, gy=0;
            for (int k = -1; k <= 1; ++k)
                for (int l = -1; l <= 1; ++l) {
                    gx += blurred[i + k][j + l] * sobelX[k + 1][l + 1];
                    gy += blurred[i + k][j + l] * sobelY[k + 1][l + 1];
                }
            //magnitude[i][j] = sqrt((float)(gx * gx + gy * gy));
            sc_uint<32> grad_squared = gx * gx + gy * gy;
            magnitude[i][j] = isqrt(grad_squared);
	    
	    // atan2 replacement using four discrete directions
	    sc_int<32> abs_gx = (gx >= sc_int<1>(0)) ? gx : sc_int<32>(-gx);
	    sc_int<32> abs_gy = (gy >= sc_int<1>(0)) ? gy : sc_int<32>(-gy);


        	if (abs_gx > abs_gy) {
            		gradient_direction[i][j] = 0; // horizontalno
        	} else if (abs_gy > abs_gx) {
            		gradient_direction[i][j] = 90; // vertikalno
        	} else {
            		if ((gx > 0 && gy > 0) || (gx < 0 && gy < 0))
                	gradient_direction[i][j] = 45;
		  else
                gradient_direction[i][j] = 135;
        }
    }
    
    // Non-maximum suppression	
    for (int i = 1; i < rows - 1; ++i)
        for (int j = 1; j < cols - 1; ++j) {
            sc_uint<16> q = 0, r = 0;
            if (gradient_direction[i][j] == 0) {
                q = magnitude[i][j + 1];
                r = magnitude[i][j - 1];
            } else if (gradient_direction[i][j] == 45) {
                q = magnitude[i + 1][j - 1];
                r = magnitude[i - 1][j + 1];
            } else if (gradient_direction[i][j] == 90) {
                q = magnitude[i + 1][j];
                r = magnitude[i - 1][j];
            } else {
                q = magnitude[i - 1][j - 1];
                r = magnitude[i + 1][j + 1];
            }

            edges[i][j] = (magnitude[i][j] >= q && magnitude[i][j] >= r) ? (sc_uint<16>)magnitude[i][j] : sc_uint<16>(0);
        }

    // Thresholding	
    sc_uint<8> STRONG_EDGE = 255;
    sc_uint<8> WEAK_EDGE = 127;
    sc_uint<8> LOW_THRESHOLD = 50;
    sc_uint<8> HIGH_THRESHOLD = 100;
    
    for (int i = 0; i < rows; ++i)
        for (int j = 0; j < cols; ++j) {
            if (edges[i][j] >= HIGH_THRESHOLD)
                edges[i][j] = STRONG_EDGE;
            else if (edges[i][j] >= LOW_THRESHOLD)
                edges[i][j] = WEAK_EDGE;
            else
                edges[i][j] = 0;
        }

    // Hysteresis
    for (int i = 1; i < rows - 1; ++i)
        for (int j = 1; j < cols - 1; ++j) {
            if (edges[i][j] == WEAK_EDGE) {
                sc_uint<1> connected = 0;
                for (int k = -1; k <= 1; ++k)
                    for (int l = -1; l <= 1; ++l)
                        if (edges[i + k][j + l] == STRONG_EDGE)
                            connected = 1;
                edges[i][j] = connected ? STRONG_EDGE : sc_uint<8>(0);
            }
        }
    
    // Write the result back to BRAM
    for (int i = 0; i < rows; ++i)
        for (int j = 0; j < cols; ++j)
            write_bram(i * cols + j, edges[i][j]);

    ready = 1;
    printf("[HARD] Canny Edge Detection finished!\n");
} 




