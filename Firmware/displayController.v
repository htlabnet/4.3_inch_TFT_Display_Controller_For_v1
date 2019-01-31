module displayController(
										input wire iCLOCKA,
										input wire iCLOCKB,
										input wire iRESET,
										
										input wire [29:0] iGPIO0,
										input wire [17:0] iGPIO1,
										
										input wire [5:0] iModeSelectorPort,
										
										output reg oDispClockPort,
										output reg oDispHsyncPort,
										output reg oDispVsyncPort,
										output reg oDispDataEnablePort,
										output reg oDispDispPort,
										output reg oDispLedSHDNPort,
										
										output reg [17:0] oSRAMAddrPort,
										inout  reg [23:0] ioSRAMDataPort,
										output reg oSRAMWriteEnablePort,
										output reg oSRAMOutputEnablePort
									);

	reg [1:0] state;
	reg [16:0]displayCnt;
	reg [9:0] hPeriodCnt;
	reg [8:0] vPeriodCnt;
	
	reg page;
	
	reg hInVisibleArea;
	reg vInVisibleArea;
	
	reg writeChance;
	
	doubleFF#(.length(30)) gpio0DFF(.mco(iCLOCKA), .in(iGPIO0), .out(okgpio0));
	wire [29:0] okgpio0;
	
	doubleFF#(.length(18)) gpio1DFF(.mco(iCLOCKA), .in(iGPIO1), .out(okgpio1));
	wire [17:0] okgpio1;
	
	NegEdgeDetector writeClockNED(.clock(okgpio0[24:24]), .reset(writeClockNEDreset), .out(writeClockNEDout));
	reg writeClockNEDreset;
	wire writeClockNEDout;
	
	NegEdgeDetector writeHsyncPED(.clock(okgpio0[25:25]), .reset(writeHsyncNEDreset), .out(writeHsyncNEDout));
	reg writeHsyncNEDreset;
	wire writeHsyncNEDout;
	
	NegEdgeDetector writeVsyncPED(.clock(okgpio0[26:26]), .reset(writeVsyncNEDreset), .out(writeVsyncNEDout));
	reg writeVsyncNEDreset;
	wire writeVsyncNEDout;
	
	
	reg[8:0]HWritePtr;
	reg[8:0]VWritePtr;
	
	reg[16:0]addrBuff;
	
	localparam DispWidth = 480;
	localparam DispHeight = 272;
	localparam DispHBackPorch = 43;
	localparam DispHFrontPorch = DispWidth + DispHBackPorch;
	localparam DispVBackPorch = 11;
	localparam DispVFrontPorch = DispHeight + DispVBackPorch;
	localparam DispHPeriodTime = 531;
	localparam DispVPeriodTime = 288;
	
	initial begin
		oDispDispPort <= 1;
		oDispLedSHDNPort <= 1;
		oDispDataEnablePort <= 0;
		oSRAMOutputEnablePort <= 1;
		oSRAMWriteEnablePort <= 1;
	end
	
	
	always@(posedge iCLOCKA or negedge iRESET) begin

		if(iRESET == 1'b0)begin
		end
		else begin		
			case(state)
				2'b00: begin
					oSRAMOutputEnablePort <= 1;
				end

				2'b01: begin
					if(hPeriodCnt == DispHBackPorch) hInVisibleArea <= 1;
					if(hPeriodCnt == DispHFrontPorch) hInVisibleArea <= 0;
					
					if(vPeriodCnt == DispVBackPorch) vInVisibleArea <= 1;
					if(vPeriodCnt == DispVFrontPorch) vInVisibleArea <= 0;
					
					if(writeChance == 1'b1)begin
						oSRAMWriteEnablePort <= 0;
						HWritePtr <= HWritePtr + 9'b1;
					end
					
				end
				
				2'b10: begin
					if(hInVisibleArea == 1 && vInVisibleArea == 1)displayCnt <= displayCnt + 1;
					
					oSRAMWriteEnablePort <= 1;
					
					if(writeHsyncNEDout == 1)begin
						HWritePtr <= 0;
						VWritePtr <= VWritePtr + 9'b1;
						writeHsyncNEDreset <= 1;
					end
					else if(writeVsyncNEDout == 1)begin
						HWritePtr <= 0;
						VWritePtr <= 0;
						writeVsyncNEDreset <= 1;
					end
					
				end
				
				2'b11: begin
				
					addrBuff <= (VWritePtr * DispWidth) + HWritePtr;
					writeHsyncNEDreset <= 0;
					writeVsyncNEDreset <= 0;
				
					//同期信号を生成する
					if(hPeriodCnt == DispHPeriodTime)begin
						hPeriodCnt <= 0;
						oDispHsyncPort <= 0;
						if(vPeriodCnt == DispVPeriodTime)begin
							vPeriodCnt <= 0;
							displayCnt <= 0;
							oDispVsyncPort <= 0;
						end
						else begin
							vPeriodCnt <= vPeriodCnt + 9'b1;
							if(oDispVsyncPort == 0)oDispVsyncPort <= 1;
						end
					end
					else begin
						hPeriodCnt <= hPeriodCnt + 10'b1;
						if(oDispHsyncPort == 0)oDispHsyncPort <= 1;
					end
					oSRAMOutputEnablePort <= 0;
					
				end
			endcase
		end
	end
	
	always@(negedge iCLOCKA)begin
	
		case(state)
			2'b00: begin
				if(writeClockNEDout == 1)begin
					writeChance <= 1'b1;
					oSRAMAddrPort <= {page,addrBuff};
					ioSRAMDataPort <= {8'b0,okgpio0[15:0]};
					writeClockNEDreset <= 1;
				end
			
				state <= state + 2'b1;
			end
			2'b01: begin
				writeChance <= 0;
				oDispClockPort <= 1;
				writeClockNEDreset <= 0;
				state <= state + 2'b1;
			end
			2'b10: begin
				oSRAMAddrPort <= {page, displayCnt};
				ioSRAMDataPort <= 24'bzzzzzzzzzzzzzzzzzzzzzzzz;
				
				state <= state + 2'b1;
			end
			2'b11: begin
				oDispClockPort <= 0;
				state <= 0;
			end
		endcase
	end
									
endmodule

module NegEdgeDetector(
							input clock,
							input reset,
							output reg out
						);
						
	initial out <= 0;
	always@(negedge clock or posedge reset)begin
		if(reset == 1)begin
			out <= 0;
		end
		else begin
			out <= 1;
		end
	end
endmodule

module doubleFF#(
					parameter length = 1
					)(
					input mco,
					input [length-1:0] in,
					output reg [length-1:0] out
					);
					
	reg[length-1:0] ff;
	
	always@(posedge mco)begin
		ff <= in;
		out <= ff;
	end

endmodule

