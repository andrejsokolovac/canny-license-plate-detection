#ifndef DEFINES_HPP
#define DEFINES_HPP

#define SC_INCLUDE_FX

#include <systemc>
#include <tlm>
#include <sysc/datatypes/fx/sc_fixed.h>

typedef tlm::tlm_base_protocol_types::tlm_payload_type pl_t;
typedef tlm::tlm_base_protocol_types::tlm_phase_type ph_t;

// Adresni opseg BRAM memorije
#define VP_ADDR_BRAM_L 0x00000000
#define VP_ADDR_BRAM_H (0x00000000 + BRAM_SIZE)

#define VP_ADDR_IP_HARD_L 0x40000000
#define VP_ADDR_IP_HARD_H 0x4000000F

// Definisanje kašnjenja za TLM transakcije
#define DELAY 10

// Dimenzije slike koju koristimo u TXT simulaciji
#define MAX_IMAGE_WIDTH 512
#define MAX_IMAGE_HEIGHT 384

#define IMAGE_COLS 512
#define IMAGE_ROWS 384

// Definisanje velicine BRAM-a
#define BRAM_SIZE (IMAGE_COLS * IMAGE_ROWS)

// Registri u HARD
#define ADDR_ROWS 0x00
#define ADDR_COLS 0x01
#define ADDR_START 0x02
#define ADDR_READY 0x03

// TXT fajlovi za mixed simulaciju
#define INPUT_TXT_FILE "grayscale_full.txt"
#define EXPECTED_TXT_FILE "final_edge_full.txt"
#define OUTPUT_TXT_FILE "mixed_edge_output.txt"

#endif // DEFINES_HPP
