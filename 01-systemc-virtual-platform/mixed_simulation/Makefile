XMSC_RUN = xmsc_run

SRCS_CPP = \
main.cpp \
cpu.cpp \
interconnect.cpp \
bram.cpp \
utils.cpp \
hard_tlm_bridge.cpp

SRCS_VHDL = \
hard.vhd

XMSC_OPTS = \
-gui \
-V93 \
-NOEDG \
-DSC_INCLUDE_DYNAMIC_PROCESSES \
-DSC_INCLUDE_FX \
-top sc_main \
-sv_lib systemc \
+access+rwc

all:
	$(XMSC_RUN) $(XMSC_OPTS) $(SRCS_CPP) $(SRCS_VHDL)

clean:
	rm -rf xcelium.d xrun.history xrun.log xmsc_run.log *.log *.key *.shm waves.shm

