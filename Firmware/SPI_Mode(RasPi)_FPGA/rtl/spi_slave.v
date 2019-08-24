/*************************************************************
 * Title : SPI Slave for RasPi SPI Display (ST7789VW)
 * Date  : 2019/8/6
 *************************************************************/
module spi_slave (
    input   wire            i_clk,          // FPGA内部CLK
    input   wire            i_rst_n,        // RESET
    input   wire            i_spi_clk,      // SPI_CLK
    input   wire            i_spi_cs,       // SPI_CS
    input   wire            i_spi_mosi,     // SPI_MOSI

    output  wire    [15:0]  o_pixel_data,   // 画素データ
    output  reg             o_pixel_en_pls, // 画素データ有効パルス出力
    output  reg             o_vsync_pls     // 垂直同期用パルス
);

    /**************************************************************
     *  ST7789VW Instruction
     *************************************************************/
    localparam CMD_RAMWR    = 8'h2C;    // Memory Write


    /**************************************************************
     * RAMWR Instructionを検出して、垂直同期用パルスを生成する。
     *************************************************************/
    reg [7:0] r_mosi_shift_8;   // 受信データ
    reg [7:0] r_mosi_8bitCnt;   // 受信bit数検知用
    reg       r_mosi_8bit_ok;   // 受信bit数 = 8bitでアサート
    always @(posedge i_spi_clk or posedge i_spi_cs) begin
        if (i_spi_cs) begin
            r_mosi_8bitCnt[7:0] <= 8'd1;
        end else begin
            r_mosi_shift_8[7:0] <= {r_mosi_shift_8[6:0], i_spi_mosi};
            r_mosi_8bitCnt[7:0] <= {r_mosi_8bitCnt[6:0], 1'b0};
            r_mosi_8bit_ok      <= r_mosi_8bitCnt[7];
        end
    end

    // SPI_CS信号の同期化と立ち上がりエッジ検出
    reg [2:0] r_cs_ff;
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            r_cs_ff[2:0] <= 3'b111;
        end else begin
            r_cs_ff[2:0] <= {r_cs_ff[1:0], i_spi_cs};
        end
    end
    wire    w_cs_posedge_dt = (r_cs_ff[2:1] == 2'b01);

    // SPI_CS信号の立ち上がりエッジ検出で受信データ確定
    // 垂直同期を取るためにRAMWRコマンドを検出する
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            o_vsync_pls <= 1'b0;
        end else begin
            if (w_cs_posedge_dt) begin
                // 受信bit数 = 8bit かつ RAMWR Instruction
                if (r_mosi_8bit_ok && r_mosi_shift_8[7:0] == CMD_RAMWR) begin
                    o_vsync_pls <= 1'b1;
                end
            end else begin
                o_vsync_pls <= 1'b0;
            end
        end
    end


    /**************************************************************
     *  ピクセルデータの取得16bit単位でデータ取得
     *************************************************************/
    reg [15:0]  r_mosi_shift_16;
    reg [15:0]  r_mosi_16;
    reg [3:0]   r_mosi_16_bitCnt;
    reg [1:0]   r_mosi_16_fin_flg;
    always @(posedge i_spi_clk or posedge i_spi_cs) begin
        if (i_spi_cs) begin
            r_mosi_shift_16[15:0] <= 16'd0;
            r_mosi_16_bitCnt[3:0] <= 4'd0;
        end else begin
            r_mosi_shift_16[15:0] <= {r_mosi_shift_16[14:0], i_spi_mosi};
            r_mosi_16_bitCnt[3:0] <= r_mosi_16_bitCnt[3:0] + 4'd1;
            
            if (r_mosi_16_bitCnt[3:0] == 4'd15) begin
                r_mosi_16[15:0] <= {r_mosi_shift_16[14:0], i_spi_mosi};
                r_mosi_16_fin_flg[1:0] <= 2'b11;
            end else begin
                r_mosi_16_fin_flg[1:0] <= {r_mosi_16_fin_flg[0], 1'b0};
            end
        end
    end
    // i_clkで拾えるようにパルス幅を延長する
    wire    w_mosi_16_fin = (|r_mosi_16_fin_flg[1:0]);

    // w_mosi_16_finの立ち上がりエッジ検出
    reg [2:0]   r_mosi_16_fin_ff;
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            r_mosi_16_fin_ff[2:0] <= 3'd0;
        end else begin
            r_mosi_16_fin_ff[2:0] <= {r_mosi_16_fin_ff[1:0], w_mosi_16_fin};
        end
    end
    wire    w_mosi_16_fin_posedge_dt = (r_mosi_16_fin_ff[2:1] == 2'b01);

    // ピクセルデータ確定
    reg [15:0]  r_mosi_16_sync;
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            r_mosi_16_sync[15:0] <= 16'd0;
            o_pixel_en_pls <= 1'b0;
        end else begin
            if (w_mosi_16_fin_posedge_dt) begin
                r_mosi_16_sync[15:0] <= r_mosi_16[15:0];
                o_pixel_en_pls <= 1'b1;
            end else begin
                o_pixel_en_pls <= 1'b0;
            end
        end
    end
    assign o_pixel_data[15:0] = r_mosi_16_sync[15:0];

endmodule
