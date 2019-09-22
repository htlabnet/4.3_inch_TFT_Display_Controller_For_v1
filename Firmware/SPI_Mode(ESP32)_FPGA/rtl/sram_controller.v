/*************************************************************
 * Title : SRAM Controller
 * Date  : 2019/9/22
 *************************************************************/
module sram_controller (
    input   wire            i_clk,          // FPGA内部CLK
    input   wire            i_rst_n,        // RESET

    input   wire            i_height_is_270,

    // From Instruction Decoder and Register
    input   wire    [15:0]  i_pixel_data,   // 画素データ
    input   wire    [31:0]  i_col_addr,     // XS15:0[31:16], XE15:0[15:0]
    input   wire    [31:0]  i_row_addr,     // YS15:0[31:16], YE15:0[15:0]
    input   wire            i_sram_clr_req,
    input   wire            i_sram_write_req,
    input   wire            i_sram_waddr_set_req,
    input   wire            i_dispOn,

    // From LCD Controller
    input   wire    [16:0]  i_sram_raddr,
    input   wire    [16:0]  i_sram_raddr_max,
    input   wire    [15:0]  i_disp_width,

    // To SRAM
    output  wire            o_SRAMWriteEnablePort,
    output  wire            o_SRAMOutputEnablePort,
    inout   wire    [23:0]  io_SRAMDataPort,
    output  wire    [17:0]  o_SRAMAddrPort
    );


    reg [ 1:0]  r_state;
	always @(posedge i_clk or negedge i_rst_n) begin
		if (~i_rst_n) begin
			r_state[1:0] <= 2'd0;
		end else begin
			r_state[1:0] <= r_state[1:0] + 2'd1;
		end
	end


    reg     [16:0]  r_sramWriteAddr;
    reg             r_sram_OE;
    reg             r_sram_WE;
    reg             r_sram_clr_busy;
    reg     [8:0]   r_pos_win_x;
    reg     [8:0]   r_pos_win_y;
    wire    [23:0]  w_sram_wdata;
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            r_sramWriteAddr[16:0] <= 17'd0;
            r_sram_OE <= 1'b0;
            r_sram_WE <= 1'b0;
            r_sram_clr_busy <= 1'b0;
            r_pos_win_x[8:0] <= 9'd0;
            r_pos_win_y[8:0] <= 9'd0;
        end else begin
            case (r_state[1:0])
                2'b00: begin
                    if (i_sram_clr_req & ~r_sram_clr_busy) begin
                        // SRAM書き込みアドレスクリア
                        r_sramWriteAddr[16:0] <= 17'd0;
                        r_sram_clr_busy <= 1'b1;
                        r_sram_OE <= 1'b0;
                        r_sram_WE <= 1'b1;
                    end if (r_sram_clr_busy) begin
                        // 末端まで書き込み完了でfin
                        if (r_sramWriteAddr[16:0] == i_sram_raddr_max[16:0]) begin
                            r_sram_clr_busy <= 1'b0;
                        end else begin
                            r_sramWriteAddr[16:0] <= r_sramWriteAddr[16:0] + 17'd1;
                            r_sram_OE <= 1'b0;
                            r_sram_WE <= 1'b1;
                        end
                    end else if (i_sram_write_req) begin
                        // ポジション更新
                        r_pos_win_x[8:0] <= r_pos_win_x[8:0] + 9'd1;
                        if (r_pos_win_x[8:0] >= i_col_addr[8:0]) begin  // 右端
                            r_pos_win_x[8:0] <= i_col_addr[24:16];      // Xポジションを開始位置に

                            r_pos_win_y[8:0] <= r_pos_win_y[8:0] + 9'd1;
                            if (r_pos_win_y[8:0] >= i_row_addr[8:0]) begin
                                r_pos_win_y[8:0] <= i_row_addr[24:16];  // Yポジションを開始位置に
                            end
                        end

                        // SRAM Writeアドレス計算
                        r_sramWriteAddr[16:0] <= ({8'd0, r_pos_win_y[8:0]} * i_disp_width[15:0]) + {8'd0, r_pos_win_x[8:0]} + 
                                                 (i_height_is_270 ? 17'd480 : 17'd0);

                        r_sram_OE <= 1'b0;
                        r_sram_WE <= 1'b1;
                    end else if (i_sram_waddr_set_req) begin
                        r_pos_win_x[8:0] <= i_col_addr[24:16];    // Xポジションを開始位置に
                        r_pos_win_y[8:0] <= i_row_addr[24:16];    // Yポジションを開始位置に
                    end 
                end

                2'b01: ;

                2'b10: begin
                    // SRAM Data Read Enable
                    r_sram_OE <= i_dispOn;
                    r_sram_WE <= 1'b0;
                end

                2'b11: ;
            endcase
        end
    end

    // SRAMの制御信号は負論理
    assign o_SRAMWriteEnablePort  = ~r_sram_WE;
    assign o_SRAMOutputEnablePort = ~r_sram_OE;
    // 書き込みデータ
    assign w_sram_wdata[23:0]    = (i_sram_clr_req | r_sram_clr_busy) ? 24'd0 :
    //                              PAD,          B (5bit),           G (6bit),            R (5bit)
                                  {8'b0, i_pixel_data[4:0], i_pixel_data[10:5], i_pixel_data[15:11]};
    // SRAMデータポート制御
    assign io_SRAMDataPort[23:0]  = r_sram_WE ? w_sram_wdata[23:0] : 
                                    ~i_dispOn ? 24'd0              : 24'bzzzzzzzzzzzzzzzzzzzzzzzz;

    // SRAMアドレスポート制御
    assign o_SRAMAddrPort  = r_sram_OE ? {1'b0, i_sram_raddr[16:0]} :
                                         {1'b0, r_sramWriteAddr[16:0]};


endmodule
