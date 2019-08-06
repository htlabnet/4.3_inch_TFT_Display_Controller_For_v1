## Generated SDC file "TFT_and_VGA_Display_Controller.sdc"

## Copyright (C) 2018  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 18.1.0 Build 625 09/12/2018 SJ Lite Edition"

## DATE    "Tue Aug 06 17:46:48 2019"

##
## DEVICE  "EPM570T144C5"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {mco} -period 25.000 -waveform { 0.000 12.500 } [get_ports {mco}]
create_clock -name {SPI_CLK} -period 25.000 -waveform { 0.000 12.500 } [get_ports {SPI_CLK}]
create_clock -name clkout -period 25.000

#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************
set_input_delay -clock SPI_CLK -max 8 [get_ports {SPI_CS}]
set_input_delay -clock SPI_CLK -min 1 [get_ports {SPI_CS}]
set_input_delay -clock SPI_CLK -max 8 [get_ports {SPI_MOSI}]
set_input_delay -clock SPI_CLK -min 1 [get_ports {SPI_MOSI}]

#**************************************************************
# Set Output Delay
#**************************************************************
set_output_delay -clock clkout -max 6  [get_ports {oSRAMAddrPort[*]}]
set_output_delay -clock clkout -min -2 [get_ports {oSRAMAddrPort[*]}]
set_output_delay -clock clkout -max 6  [get_ports {ioSRAMDataPort[*]}]
set_output_delay -clock clkout -max -2 [get_ports {ioSRAMDataPort[*]}]
set_output_delay -clock clkout -max 6  [get_ports {oDispClockPort}]
set_output_delay -clock clkout -max -2 [get_ports {oDispClockPort}]
set_output_delay -clock clkout -max 6  [get_ports {oDispDataEnablePort}]
set_output_delay -clock clkout -min -2 [get_ports {oDispDataEnablePort}]
set_output_delay -clock clkout -max 6  [get_ports {oDispHsyncPort}]
set_output_delay -clock clkout -min -2 [get_ports {oDispHsyncPort}]
set_output_delay -clock clkout -max 6  [get_ports {oDispVsyncPort}]
set_output_delay -clock clkout -min -2 [get_ports {oDispVsyncPort}]
set_output_delay -clock clkout -max 6  [get_ports {oSRAMOutputEnablePort}]
set_output_delay -clock clkout -min -2 [get_ports {oSRAMOutputEnablePort}]
set_output_delay -clock clkout -max 6  [get_ports {oSRAMWriteEnablePort}]
set_output_delay -clock clkout -min -2 [get_ports {oSRAMWriteEnablePort}]
set_output_delay -clock clkout -max 6  [get_ports {oDispLedSHDNPort}]
set_output_delay -clock clkout -min -2  [get_ports {oDispLedSHDNPort}]


#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from [get_ports {rst_n}] -to [all_registers]




#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

