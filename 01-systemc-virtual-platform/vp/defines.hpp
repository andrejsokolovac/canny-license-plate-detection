#ifndef DEFINES_HPP
#define DEFINES_HPP

#define int64 opencv_int64
#define uint64 opencv_uint64

#include <opencv2/core.hpp>
#undef int64
#undef uint64

#define SC_INCLUDE_FX

#include <systemc>
#include <tlm>
#include <sysc/datatypes/fx/sc_fixed.h>



typedef tlm::tlm_base_protocol_types::tlm_payload_type pl_t;
typedef tlm::tlm_base_protocol_types::tlm_phase_type ph_t;


// BRAM address range
#define VP_ADDR_BRAM_L 0x00000000  // Početna adresa BRAM memorije
#define VP_ADDR_BRAM_H 0x00000000 + BRAM_SIZE   // Krajnja adresa BRAM memorije 

#define VP_ADDR_IP_HARD_L 0x40000000
#define VP_ADDR_IP_HARD_H 0x4000000F


// TLM transaction delay
#define DELAY 10 // 10 ns kašnjenja u simulaciji

// BRAM size
#define BRAM_SIZE (512 * 384) 

#define MAX_IMAGE_WIDTH 512
#define MAX_IMAGE_HEIGHT 384

// Hardware registers
#define ADDR_ROWS 0x00
#define ADDR_COLS 0x01
#define ADDR_START 0x02
#define ADDR_READY 0x03


#endif // DEFINES_HPP
