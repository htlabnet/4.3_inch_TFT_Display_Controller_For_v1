/*************************************************************
 * Title : LCD Controller
 * Date  : 2019/9/22
 *************************************************************/
module lcd_controller (
    input   wire            i_clk,          // FPGA内部CLK
    input   wire            i_rst_n,        // RESET

	// To SRAM Controller
	output	wire	[16:0]	o_sram_raddr,
	output	wire	[16:0]	o_sram_raddr_max,
	output  wire	[15:0]	o_disp_width,

    // To LCD
	output  reg             o_DispClockPort,
    output  wire            o_DispHsyncPort,
    output  wire            o_DispVsyncPort,
    output  wire            o_DispDataEnablePort,
    output  wire            o_DispDispPort
	);


	/**************************************************************
     *  LCDパラメータ
     *************************************************************/
    localparam DispWidth        = 480;
    localparam DispHeight       = 272;
    localparam DispHBackPorch   = 43;
    localparam DispHFrontPorch  = DispWidth + DispHBackPorch;
    localparam DispVBackPorch   = 12;
    localparam DispVFrontPorch  = DispHeight + DispVBackPorch;
    localparam DispHPeriodTime  = 531;
    localparam DispVPeriodTime  = 288;
    localparam DispSramMaxAddr  = DispWidth * DispHeight;

	assign o_DispDispPort        = 1'b1;
    assign o_DispDataEnablePort  = 1'b0;    // Data Enableは常にLowで良さそう（SYNC mode時）


	reg [ 1:0]  r_state;
	always @(posedge i_clk or negedge i_rst_n) begin
		if (~i_rst_n) begin
			r_state[1:0] <= 2'd0;
		end else begin
			r_state[1:0] <= r_state[1:0] + 2'd1;
		end
	end

    reg [16:0]  r_displayCnt;
    reg [ 9:0]  r_hPeriodCnt;
    reg [ 8:0]  r_vPeriodCnt;
    reg         r_hInVisibleArea;
    reg         r_vInVisibleArea;
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            r_displayCnt[16:0] <= 17'd0;
            r_hPeriodCnt[9:0] <= 10'd0;
            r_vPeriodCnt[8:0] <= 9'd0;
            r_hInVisibleArea <= 1'd0;
            r_vInVisibleArea <= 1'd0;
            o_DispClockPort <= 1'b0;
        end else begin
            case (r_state[1:0])
                2'b01 : begin
                    // dclk立ち上げ
                    o_DispClockPort <= 1'b1;

                    // 水平同期信号生成
                    if (r_hPeriodCnt[9:0] == (DispHPeriodTime - 10'd1)) begin
                        r_hPeriodCnt[9:0] <= 10'd0;
                    end else begin
                        r_hPeriodCnt[9:0] <= r_hPeriodCnt[9:0] + 10'b1;
                    end

                    // 垂直同期信号生成
                    if (r_hPeriodCnt[9:0] == (DispHPeriodTime - 10'd1)) begin
                        if (r_vPeriodCnt[8:0] == (DispVPeriodTime - 9'd1)) begin
                            r_vPeriodCnt[8:0] <= 9'd0;
                            r_displayCnt[16:0] <= 17'd0;
                        end else begin
                            r_vPeriodCnt[8:0] <= r_vPeriodCnt[8:0] + 9'b1;
                        end
                    end
                end

                2'b10 : begin
                    // 書き込み領域判定
                    r_hInVisibleArea <= (r_hPeriodCnt[9:0] == DispHBackPorch)  ? 1'b1 :
                                        (r_hPeriodCnt[9:0] == DispHFrontPorch) ? 1'b0 : r_hInVisibleArea;
                    r_vInVisibleArea <= (r_vPeriodCnt[8:0] == DispVBackPorch)  ? 1'b1 :
                                        (r_vPeriodCnt[8:0] == DispVFrontPorch) ? 1'b0 : r_vInVisibleArea;
                end

                2'b11 : begin
                    // dclk立ち下げでデータラッチ
                    o_DispClockPort <= 1'b0;

                    // 表示エリアのみSRAM Readアドレスをインクリメント
                    if (r_hInVisibleArea & r_vInVisibleArea) begin
                        r_displayCnt[16:0] <= r_displayCnt[16:0] + 17'd1;
                    end
                end
            endcase
        end
    end
    assign o_DispHsyncPort 			= (r_hPeriodCnt[9:0] == 10'd0) ? 1'b0 : 1'b1;   // HSYNC信号生成
    assign o_DispVsyncPort 			= (r_vPeriodCnt[8:0] <= 9'd9)  ? 1'b0 : 1'b1;   // VSYNC信号生成
	assign o_sram_raddr[16:0]		= r_displayCnt[16:0];
	assign o_sram_raddr_max[16:0]	= DispSramMaxAddr;
	assign o_disp_width[15:0]		= DispWidth;

endmodule
