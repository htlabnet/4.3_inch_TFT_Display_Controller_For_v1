## Generated SDC file "SPI_TFT_Display_Controller.sdc"

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

## DATE    "Sun Sep 15 19:01:28 2019"

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
create_clock -name {spiclk} -period 12.500 -waveform { 0.000 6.250 } [get_ports {SPI_CLK}]
create_clock -name {clkout} -period 25.000 -waveform { 0.000 12.500 } 


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

set_input_delay -add_delay -max -clock [get_clocks {spiclk}]  3.000 [get_ports {DC}]
set_input_delay -add_delay -min -clock [get_clocks {spiclk}]  0.000 [get_ports {DC}]
set_input_delay -add_delay -max -clock [get_clocks {spiclk}]  3.000 [get_ports {SPI_CS}]
set_input_delay -add_delay -min -clock [get_clocks {spiclk}]  0.000 [get_ports {SPI_CS}]
set_input_delay -add_delay -max -clock [get_clocks {spiclk}]  3.000 [get_ports {SPI_MOSI}]
set_input_delay -add_delay -min -clock [get_clocks {spiclk}]  0.000 [get_ports {SPI_MOSI}]


#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[0]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[0]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[1]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[1]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[2]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[2]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[3]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[3]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[4]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[4]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[5]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[5]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[6]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[6]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[7]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[7]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[8]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[8]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[9]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[9]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[10]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[10]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[11]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[11]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[12]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[12]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[13]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[13]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[14]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[14]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[15]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[15]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[16]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[16]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[17]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[17]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[18]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[18]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[19]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[19]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[20]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[20]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[21]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[21]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[22]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[22]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {ioSRAMDataPort[23]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {ioSRAMDataPort[23]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oDispClockPort}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oDispClockPort}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oDispDataEnablePort}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oDispDataEnablePort}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oDispHsyncPort}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oDispHsyncPort}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oDispLedSHDNPort}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oDispLedSHDNPort}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oDispVsyncPort}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oDispVsyncPort}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oSRAMAddrPort[0]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oSRAMAddrPort[0]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oSRAMAddrPort[1]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oSRAMAddrPort[1]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oSRAMAddrPort[2]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oSRAMAddrPort[2]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oSRAMAddrPort[3]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oSRAMAddrPort[3]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oSRAMAddrPort[4]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oSRAMAddrPort[4]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oSRAMAddrPort[5]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oSRAMAddrPort[5]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oSRAMAddrPort[6]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oSRAMAddrPort[6]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oSRAMAddrPort[7]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oSRAMAddrPort[7]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oSRAMAddrPort[8]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oSRAMAddrPort[8]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oSRAMAddrPort[9]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oSRAMAddrPort[9]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oSRAMAddrPort[10]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oSRAMAddrPort[10]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oSRAMAddrPort[11]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oSRAMAddrPort[11]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oSRAMAddrPort[12]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oSRAMAddrPort[12]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oSRAMAddrPort[13]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oSRAMAddrPort[13]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oSRAMAddrPort[14]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oSRAMAddrPort[14]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oSRAMAddrPort[15]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oSRAMAddrPort[15]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oSRAMAddrPort[16]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oSRAMAddrPort[16]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oSRAMAddrPort[17]}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oSRAMAddrPort[17]}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oSRAMOutputEnablePort}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oSRAMOutputEnablePort}]
set_output_delay -add_delay -max -clock [get_clocks {clkout}]  3.000 [get_ports {oSRAMWriteEnablePort}]
set_output_delay -add_delay -min -clock [get_clocks {clkout}]  0.000 [get_ports {oSRAMWriteEnablePort}]


#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous -group {spiclk} -group {mco clkout}


#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from [get_ports {rst_n}] -to [all_registers]
set_false_path -to [get_ports {oDbgSig1}]


#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************

set_max_delay -from [get_registers {spi_slave:spi_slave_inst|r_mosi_8bit_rx_fin_ff[0]}] -to [get_registers {spi_slave:spi_slave_inst|r_mosi_8bit_rx_fin_ff[1]}] 2.000
set_max_delay -from [get_registers {spi_slave:spi_slave_inst|r_mosi_8bit_rx_fin_ff[1]}] -to [get_registers {spi_slave:spi_slave_inst|r_mosi_8bit_rx_fin_ff[2]}] 2.000

#**************************************************************
# Set Minimum Delay
#**************************************************************


#**************************************************************
# Set Input Transition
#**************************************************************

