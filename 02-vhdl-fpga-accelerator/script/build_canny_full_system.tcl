# ============================================================
# CANNY AXI FULL SYSTEM BUILD SCRIPT
# Automated IP packaging and system integration,
# synthesis, implementation, bitstream generation, and .xsa export
# Target board: Zybo, xc7z010clg400-1
# Vivado 2020.2
# ============================================================

# ------------------------------------------------------------
# USER SETTINGS
# ------------------------------------------------------------
set src_dir      "C:/Users/Machi/Desktop/src"
set work_dir     "C:/Users/Machi/Desktop/canny_tcl_auto"
set ip_repo_dir  "$work_dir/ip_repo"
set ip_dir       "$ip_repo_dir/canny_axi_v1_0"
set project_name "canny_system_auto"
set project_dir  "$work_dir/vivado_project"
set release_dir  "$work_dir/release"

set part_name    "xc7z010clg400-1"
set board_part   "digilentinc.com:zybo:part0:2.0"

set top_name     "canny_axi_v1_0"
set bd_name      "design_1"
set ip_vlnv      "user.org:user:canny_axi:1.0"

# Address map used by the Vitis software
set CANNY_S00_BASE 0x43C00000
set CANNY_S00_RANGE 0x00010000

set CANNY_S01_BASE 0x43C80000
set CANNY_S01_RANGE 0x00080000

# ------------------------------------------------------------
# CLEAN OLD BUILD
# ------------------------------------------------------------
puts "============================================================"
puts "CANNY AXI FULL SYSTEM BUILD STARTED"
puts "============================================================"
puts "Source folder : $src_dir"
puts "Work folder   : $work_dir"
puts "Project folder: $project_dir"
puts "IP repo       : $ip_repo_dir"
puts "Part          : $part_name"
puts "Board         : $board_part"
puts "============================================================"

if {[llength [get_projects -quiet]] > 0} {
    close_project
}

file delete -force $work_dir
file mkdir $work_dir
file mkdir $ip_repo_dir
file mkdir $release_dir

# ============================================================
# STEP 1: PACKAGE CANNY IP
# ============================================================

puts ""
puts "============================================================"
puts "STEP 1: PACKAGING CANNY AXI IP"
puts "============================================================"

set pack_proj_dir "$work_dir/ip_pack_project"

create_project canny_ip_pack_project $pack_proj_dir -part $part_name -force

# Try to set board part, if board files are installed
if {[catch {set_property board_part $board_part [current_project]} msg]} {
    puts "WARNING: Board part could not be set. Continuing with FPGA part only."
    puts $msg
}

# Add VHDL source files
add_files -norecurse [file join $src_dir "bram.vhd"]
add_files -norecurse [file join $src_dir "hard.vhd"]
add_files -norecurse [file join $src_dir "mem_subsystem.vhd"]
add_files -norecurse [file join $src_dir "canny_axi_v1_0_S00_AXI.vhd"]
add_files -norecurse [file join $src_dir "canny_axi_v1_0_S01_AXI.vhd"]
add_files -norecurse [file join $src_dir "canny_axi_v1_0.vhd"]

set_property top $top_name [current_fileset]
update_compile_order -fileset sources_1

# Package IP
ipx::package_project \
    -root_dir $ip_dir \
    -vendor user.org \
    -library user \
    -taxonomy /UserIP \
    -import_files \
    -set_current true \
    -force

# Basic metadata
set_property name canny_axi [ipx::current_core]
set_property display_name {Canny AXI IP} [ipx::current_core]
set_property description {Canny edge detection accelerator with AXI-Lite control and AXI-Full image memory interface} [ipx::current_core]
set_property vendor_display_name {User} [ipx::current_core]
set_property company_url {https://example.com} [ipx::current_core]
set_property version 1.0 [ipx::current_core]

# Associate clocks and resets with AXI interfaces
catch {ipx::associate_bus_interfaces -busif s00_axi -clock s00_axi_aclk [ipx::current_core]}
catch {ipx::associate_bus_interfaces -busif s01_axi -clock s01_axi_aclk [ipx::current_core]}

ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]

puts "IP packaging finished."
puts "Generated IP folder: $ip_dir"

close_project

# ============================================================
# STEP 2: CREATE MAIN PROJECT
# ============================================================

puts ""
puts "============================================================"
puts "STEP 2: CREATING MAIN VIVADO PROJECT"
puts "============================================================"

create_project $project_name $project_dir -part $part_name -force

# Try to set Zybo board part
if {[catch {set_property board_part $board_part [current_project]} msg]} {
    puts "WARNING: Board part could not be set. Continuing with FPGA part only."
    puts $msg
}

# Add generated IP repository
set_property ip_repo_paths $ip_repo_dir [current_project]
update_ip_catalog

# ============================================================
# STEP 3: CREATE BLOCK DESIGN
# ============================================================

puts ""
puts "============================================================"
puts "STEP 3: CREATING BLOCK DESIGN"
puts "============================================================"

create_bd_design $bd_name

# Add Zynq Processing System
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0

# Apply board automation for DDR/FIXED_IO if possible
if {[catch {
    apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
        -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable"} \
        [get_bd_cells processing_system7_0]
} msg]} {
    puts "WARNING: PS7 board automation failed. Applying minimal PS7 configuration."
    puts $msg

    set_property -dict [list \
        CONFIG.PCW_USE_M_AXI_GP0 {1} \
        CONFIG.PCW_EN_CLK0_PORT {1} \
        CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {50.0} \
    ] [get_bd_cells processing_system7_0]

    make_bd_intf_pins_external [get_bd_intf_pins processing_system7_0/DDR]
    make_bd_intf_pins_external [get_bd_intf_pins processing_system7_0/FIXED_IO]
}

# Add Canny IP
create_bd_cell -type ip -vlnv $ip_vlnv canny_axi_0

# ------------------------------------------------------------
# AXI ID width compatibility:
# PS7 AXI interconnect can generate 12-bit AXI ID width.
# The S01 AXI-Full interface uses ID width 1.
# Set the interface width before validate_bd_design to keep the connection compatible.
# ------------------------------------------------------------
if {[catch {
    set_property -dict [list CONFIG.C_S01_AXI_ID_WIDTH {12}] [get_bd_cells canny_axi_0]
} msg]} {
    puts "WARNING: Could not set C_S01_AXI_ID_WIDTH to 12."
    puts $msg
}

# Connect AXI interfaces using Vivado automation
puts "Connecting Canny s00_axi to PS M_AXI_GP0..."
apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto"} \
    [get_bd_intf_pins canny_axi_0/s00_axi]

puts "Connecting Canny s01_axi to PS M_AXI_GP0..."
apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto"} \
    [get_bd_intf_pins canny_axi_0/s01_axi]

# Make sure clock/reset are connected
# Automation usually does this, but these catches keep the script robust.
catch {connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins canny_axi_0/s00_axi_aclk]}
catch {connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins canny_axi_0/s01_axi_aclk]}

catch {connect_bd_net [get_bd_pins rst_ps7_0_50M/peripheral_aresetn] [get_bd_pins canny_axi_0/s00_axi_aresetn]}
catch {connect_bd_net [get_bd_pins rst_ps7_0_50M/peripheral_aresetn] [get_bd_pins canny_axi_0/s01_axi_aresetn]}

# ============================================================
# STEP 4: ASSIGN ADDRESSES
# ============================================================

puts ""
puts "============================================================"
puts "STEP 4: ASSIGNING ADDRESSES"
puts "============================================================"

# Explicit address assignment matching the Vitis software
assign_bd_address -offset $CANNY_S00_BASE -range $CANNY_S00_RANGE \
    -target_address_space [get_bd_addr_spaces processing_system7_0/Data] \
    [get_bd_addr_segs canny_axi_0/s00_axi/reg0] -force

assign_bd_address -offset $CANNY_S01_BASE -range $CANNY_S01_RANGE \
    -target_address_space [get_bd_addr_spaces processing_system7_0/Data] \
    [get_bd_addr_segs canny_axi_0/s01_axi/reg0] -force

puts "Assigned addresses:"
puts "s00_axi base = $CANNY_S00_BASE, range = $CANNY_S00_RANGE"
puts "s01_axi base = $CANNY_S01_BASE, range = $CANNY_S01_RANGE"

# Validate and save BD
validate_bd_design
save_bd_design

# ============================================================
# STEP 5: GENERATE WRAPPER
# ============================================================

puts ""
puts "============================================================"
puts "STEP 5: GENERATING HDL WRAPPER"
puts "============================================================"

set bd_file [get_files "$project_dir/$project_name.srcs/sources_1/bd/$bd_name/$bd_name.bd"]

generate_target all $bd_file

set wrapper_file [make_wrapper -files $bd_file -top]
add_files -norecurse $wrapper_file

set_property top ${bd_name}_wrapper [current_fileset]
update_compile_order -fileset sources_1

# ============================================================
# STEP 6: SYNTHESIS
# ============================================================

puts ""
puts "============================================================"
puts "STEP 6: RUNNING SYNTHESIS"
puts "============================================================"

launch_runs synth_1 -jobs 4
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
puts "Synthesis status: $synth_status"

if {![string match "*Complete*" $synth_status]} {
    error "Synthesis failed. Check synthesis log."
}

# ============================================================
# STEP 7: IMPLEMENTATION AND BITSTREAM
# ============================================================

puts ""
puts "============================================================"
puts "STEP 7: RUNNING IMPLEMENTATION AND BITSTREAM"
puts "============================================================"

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
puts "Implementation status: $impl_status"

if {![string match "*Complete*" $impl_status]} {
    error "Implementation or bitstream failed. Check implementation log."
}

# ============================================================
# STEP 8: EXPORT XSA
# ============================================================

puts ""
puts "============================================================"
puts "STEP 8: EXPORTING XSA"
puts "============================================================"

set xsa_file "$release_dir/${bd_name}_wrapper.xsa"

write_hw_platform -fixed -include_bit -force -file $xsa_file

puts ""
puts "============================================================"
puts "CANNY AXI FULL SYSTEM BUILD FINISHED SUCCESSFULLY"
puts "============================================================"
puts "Generated XSA:"
puts "$xsa_file"
puts "============================================================"
