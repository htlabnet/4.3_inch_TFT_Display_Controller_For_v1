/*************************************************************
 * Title : SPI Slave for RasPi SPI Display (ST7735R)
 * Date  : 2019/8/6
 *************************************************************/
module spi_slave (
    input   wire            i_clk,          // FPGA内部CLK
    input   wire            i_rst_n,        // RESET
    input   wire            i_spi_clk,      // SPI_CLK
    input   wire            i_spi_cs,       // SPI_CS
    input   wire            i_spi_mosi,     // SPI_MOSI
    input   wire            i_dc,           // DC(H:Data / L:Command)

    output  wire    [15:0]  o_pixel_data,   // 画素データ
    output  reg             o_pixel_en_pls, // 画素データ有効パルス出力
    output  reg     [ 7:0]  o_inst_data,    // Instruction Data
    output  reg             o_inst_en_pls,  // Instruction Data 有効パルス出力

    output  reg     [31:0]  o_col_addr,     // XS15:0[31:16], XE15:0[15:0]
    output  reg     [31:0]  o_row_addr,     // YS15:0[31:16], YE15:0[15:0]
    output  reg             o_row_addr_en_pls
);

    /**************************************************************
     * Instructionの検出
     *************************************************************/
    reg [ 7:0]  r_mosi_shift_8;     // 受信データ
    reg [ 2:0]  r_mosi_8bitCnt;     // 受信bit数検知用
    wire        w_mosi_8bit_rx_fin = &r_mosi_8bitCnt[2:0];
    reg [ 7:0]  r_mosi_8bit_fix;
    reg         r_mosi_8bit_dc_fix;
    reg         r_mosi_8bit_rx_done;   

    // SPI_CLKでデータ受信
    always @(posedge i_spi_clk or posedge i_spi_cs) begin
        if (i_spi_cs) begin
            r_mosi_8bitCnt[2:0] <= 3'd0;
            r_mosi_8bit_rx_done <= 1'b0;
        end else begin
            // データ受信
            r_mosi_shift_8[7:0] <= {r_mosi_shift_8[6:0], i_spi_mosi};

            // 受信bit数カウント
            if (w_mosi_8bit_rx_fin) begin
                r_mosi_8bitCnt[2:0] <= 3'd0;
            end else begin
                r_mosi_8bitCnt[2:0] <= r_mosi_8bitCnt[2:0] + 3'd1;
            end

            // 受信データとDC状態ラッチ
            if (w_mosi_8bit_rx_fin) begin
                r_mosi_8bit_fix[7:0] <= {r_mosi_shift_8[6:0], i_spi_mosi};
                r_mosi_8bit_dc_fix <= i_dc;
                r_mosi_8bit_rx_done <= 1'b1;
            end else if (r_mosi_8bitCnt[2:0] == 3'd3) begin
                r_mosi_8bit_rx_done <= 1'b0;
            end
        end
    end

    // r_mosi_8bit_rx_doneの立ち上がりで受信データクロック載せ替え
    reg [ 2:0]  r_mosi_8bit_rx_fin_ff;
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            r_mosi_8bit_rx_fin_ff[2:0] <= 3'd0;
        end else begin
            r_mosi_8bit_rx_fin_ff[2:0] <= {r_mosi_8bit_rx_fin_ff[1:0], r_mosi_8bit_rx_done};
        end
    end
    wire    w_mosi_8bit_fin_posedge_dt = (r_mosi_8bit_rx_fin_ff[2:1] == 2'b01);


    // 受信データ処理
    reg [15:0]  r_mosi_16_pixel_data;
    reg         r_pixel_data_fin;
    reg [1:0]   r_inst_byte_cnt;
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            o_inst_data[7:0] <= 8'd0;
            o_inst_en_pls <= 1'b0;
            r_pixel_data_fin <= 1'b0;
            o_col_addr[31:0] <= 32'd0;
            r_inst_byte_cnt[1:0] <= 2'd0;
            o_row_addr[31:0] <= 32'd0;
            o_row_addr_en_pls <= 1'b0;
            o_pixel_en_pls <= 1'b0;
        end else begin
            if (w_mosi_8bit_fin_posedge_dt) begin
                // dc:low = Command
                if (~r_mosi_8bit_dc_fix) begin
                    o_inst_data[7:0] <= r_mosi_8bit_fix[7:0];
                    o_inst_en_pls <= 1'b1;
                    r_pixel_data_fin <= 1'b0;
                    r_inst_byte_cnt[1:0] <= 2'd0;
                end else begin
                    // RAMWR
                    if (o_inst_data[7:0] == 8'h2C) begin
                        // ピクセルデータ取得
                        r_mosi_16_pixel_data[15:0] <= {r_mosi_16_pixel_data[7:0], r_mosi_8bit_fix[7:0]};
                        r_pixel_data_fin <= ~r_pixel_data_fin;

                        if (r_pixel_data_fin) begin
                            o_pixel_en_pls <= 1'b1;
                        end
                    end else if (o_inst_data[7:0] == 8'h2A) begin
                        // Column Address Set
                        o_col_addr [31:0] <= {o_col_addr[23:0], r_mosi_8bit_fix[7:0]};
                    end else if (o_inst_data[7:0] == 8'h2B) begin
                        // Row Address set
                        o_row_addr [31:0] <= {o_row_addr[23:0], r_mosi_8bit_fix[7:0]};
                        r_inst_byte_cnt[1:0] <= r_inst_byte_cnt[1:0] + 2'd1;
                        
                        if (r_inst_byte_cnt[1:0] == 2'd3) begin
                            o_row_addr_en_pls <= 1'b1;
                        end
                    end
                end
            end else begin
                o_inst_en_pls <= 1'b0;
                o_pixel_en_pls <= 1'b0;
                o_row_addr_en_pls <= 1'b0;
            end
        end
    end

    assign o_pixel_data[15:0] = r_mosi_16_pixel_data[15:0];

endmodule
