/*************************************************************
 * Title : SPI Slave
 * Date  : 2019/8/6
 *************************************************************/
module spi_slave (
    input   wire            i_clk,          // FPGA内部CLK
    input   wire            i_rst_n,        // RESET
    input   wire            i_spi_clk,      // SPI_CLK
    input   wire            i_spi_cs,       // SPI_CS
    input   wire            i_spi_mosi,     // SPI_MOSI
    output  reg     [23:0]  o_mosi_data,    // 受信データ
    output  reg             o_mosi_en_pls   // 受信データ有効パルス出力
);

    // SPI_CS同期化
    reg [2:0] r_ff_cs;
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            r_ff_cs[2:0] <= 3'b111;
        end else begin
            r_ff_cs[2:0] <= {r_ff_cs[1:0], i_spi_cs};
        end
    end
    // SPI_CS立ち上がりエッジ検出
    wire cs_posedge_dt = (r_ff_cs[2:1] == 2'b01);

    // データ受信
    reg [23:0] r_mosi_tmp;
    always @(posedge i_spi_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            r_mosi_tmp[23:0] <= 24'd0;
        end else begin
            r_mosi_tmp[23:0] <= {r_mosi_tmp[22:0], i_spi_mosi};
        end    
    end

    // 受信データ取得
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            o_mosi_data[23:0] <= 24'd0;
        end else begin
            if (cs_posedge_dt) begin
                o_mosi_data[23:0] <= r_mosi_tmp[23:0];
                o_mosi_en_pls <= 1'b1;
            end else begin
                o_mosi_en_pls <= 1'b0;
            end
        end
    end

endmodule
