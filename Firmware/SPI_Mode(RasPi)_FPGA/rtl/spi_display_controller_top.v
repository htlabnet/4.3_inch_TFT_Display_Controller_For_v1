/*************************************************************
 * Title : SPI TFT LCD Controller Top Module
 * Date  : 2019/8/6
 *************************************************************/
module spi_display_controller_top (
    input   wire            mco,
    input   wire            rst_n,

    // SPI I/F
    input   wire            SPI_CLK,
    input   wire            SPI_CS,
    input   wire            SPI_MOSI,

    // DIP SW
    input   wire    [ 5:0]  iModeSelectorPort,

    // TO LCD
    output  reg             oDispClockPort,
    output  wire            oDispHsyncPort,
    output  wire            oDispVsyncPort,
    output  wire            oDispDataEnablePort,
    output  reg             oDispDispPort,
    output  reg             oDispLedSHDNPort,

    // TO SRAM
    output  reg     [17:0]  oSRAMAddrPort,
    inout   reg     [23:0]  ioSRAMDataPort,
    output  wire            oSRAMWriteEnablePort,
    output  wire            oSRAMOutputEnablePort

    // debug
    //output  wire			oDbgSig1,
    //output  wire			oDbgSig2
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


    /**************************************************************
     *  SPI Slaveモジュール接続
     *************************************************************/
    wire [15:0] w_pixel_data;
    wire        w_pixel_en;
    wire        w_vsync_pls;
    spi_slave spi_slave_inst (
        .i_clk ( mco ),                         // FPGA内部CLK
        .i_rst_n ( rst_n ),                     // RESET
        .i_spi_clk ( SPI_CLK ),                 // SPI_CLK
        .i_spi_cs ( SPI_CS ),                   // SPI_CS
        .i_spi_mosi ( SPI_MOSI ),               // SPI_MOSI
        .o_pixel_data ( w_pixel_data[15:0] ),   // 受信データ
        .o_pixel_en_pls ( w_pixel_en ),         // 受信データ有効
        .o_vsync_pls ( w_vsync_pls )			// SRAM Write Addrリセット信号
    );

    assign oDbgSig1 = w_vsync_pls;
    assign oDbgSig2 = w_pixel_en;
    

    /**************************************************************
     *  垂直同期/データ書き込み要求処理
     *************************************************************/
    reg         r_sram_waddr_rst_req;       // SRAM書き込みアドレスリセット要求
    reg         r_sram_waddr_rst_req_fin;   // SRAM書き込みアドレスリセット要求完了
    reg         r_sram_write_req;           // SRAMデータ書き込み要求
    reg         r_sram_write_req_fin;       // SRAMデータ書き込み要求完了
    always @(posedge mco or negedge rst_n) begin
        if (~rst_n) begin
            r_sram_write_req <= 1'b0;
            r_sram_waddr_rst_req <= 1'b0;
        end else begin
            if (w_vsync_pls) begin	// 垂直同期優先
                r_sram_waddr_rst_req <= 1'b1;
            end else begin
                if (r_sram_waddr_rst_req_fin) begin
                    r_sram_waddr_rst_req <= 1'b0;
                end
                if (w_pixel_en) begin
                    r_sram_write_req <= 1'b1;
                end else begin
                    if (r_sram_write_req_fin) begin
                        r_sram_write_req <= 1'b0;
                    end
                end
            end
        end
    end


    /**************************************************************
     *  SRAM制御
     *************************************************************/
    reg [ 1:0]  r_state;
    reg [16:0]  r_sramWriteAddr;
    reg         r_sram_OE;
    reg         r_sram_WE;
    always @(posedge mco or negedge rst_n) begin
        if (~rst_n) begin
            r_state[1:0] <= 2'd0;
            r_sramWriteAddr[16:0] <= 17'd0;
            r_sram_OE <= 1'b0;
            r_sram_WE <= 1'b0;
            r_sram_write_req_fin <= 1'b0;
            r_sram_waddr_rst_req_fin <= 1'b0;
            ioSRAMDataPort[23:0] <= 24'bzzzzzzzzzzzzzzzzzzzzzzzz;
            oSRAMAddrPort[17:0] <= 18'd0;
            oDispDispPort <= 1'b1;
            oDispLedSHDNPort <= 1'b1;
        end else begin
            case (r_state[1:0])
                2'b00: begin
                    if (r_sram_write_req) begin
                        // SRAM書き込みアドレス設定
                        oSRAMAddrPort[17:0] <= {1'b0, r_sramWriteAddr[16:0]};
                        // 書き込み後アドレス自動インクリメント
                        r_sramWriteAddr[16:0] <= r_sramWriteAddr[16:0] + 17'd1;
                        // 書き込みデータ
                        //                        PAD,          B (5bit),           G (6bit),            R (5bit)
                        ioSRAMDataPort[23:0] <= {8'b0, w_pixel_data[4:0], w_pixel_data[10:5], w_pixel_data[15:11]};
                        r_sram_OE <= 1'b0;
                        r_sram_WE <= 1'b1;
                        r_sram_write_req_fin <= 1'b1;
                    end else if (r_sram_waddr_rst_req) begin
                        // アドレスリセット
                        r_sramWriteAddr[16:0] <= 17'd0;
                        r_sram_waddr_rst_req_fin <= 1'b1;
                    end else begin
                        r_sram_write_req_fin <= 1'b0;
                        r_sram_waddr_rst_req_fin <= 1'b0;
                    end
                    r_state[1:0] <= 2'b01;
                end

                2'b01: begin
                    r_state[1:0] <= 2'b10;
                end

                2'b10: begin
                    // SRAM Data Read Enable
                    oSRAMAddrPort[17:0] <= {1'b0, r_displayCnt[16:0]};      // SRAM読み出しアドレスセット(書き込みとは別のページを表示）
                    ioSRAMDataPort[23:0] <= 24'bzzzzzzzzzzzzzzzzzzzzzzzz;   // SRAM出力と衝突しないようにFPGAのIOをHi-Zに
                    r_sram_OE <= 1'b1;
                    r_sram_WE <= 1'b0;
                    r_state[1:0] <= 2'b11;
                end

                2'b11: begin
                    r_state[1:0] <= 2'b00;
                end
            endcase
        end
    end
    // SRAMの制御信号は負論理
    assign oSRAMWriteEnablePort  = ~r_sram_WE;
    assign oSRAMOutputEnablePort = ~r_sram_OE;


    /**************************************************************
     *  LCD制御信号生成
     *************************************************************/
    reg [16:0]  r_displayCnt;
    reg [ 9:0]  r_hPeriodCnt;
    reg [ 8:0]  r_vPeriodCnt;
    reg         r_hInVisibleArea;
    reg         r_vInVisibleArea;
    always @(posedge mco or negedge rst_n) begin
        if (~rst_n) begin
            r_displayCnt[16:0] <= 17'd0;
            r_hPeriodCnt[9:0] <= 10'd0;
            r_vPeriodCnt[8:0] <= 9'd0;
            r_hInVisibleArea <= 1'd0;
            r_vInVisibleArea <= 1'd0;
            oDispClockPort <= 1'b0;
        end else begin
            case (r_state[1:0])
                2'b01 : begin
                    // dclk立ち上げ
                    oDispClockPort <= 1'b1;

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
                    oDispClockPort <= 1'b0;

                    // 表示エリアのみSRAM Readアドレスをインクリメント
                    if (r_hInVisibleArea & r_vInVisibleArea) begin
                        r_displayCnt[16:0] <= r_displayCnt[16:0] + 17'd1;
                    end
                end
            endcase
        end
    end

    assign oDispHsyncPort = (r_hPeriodCnt[9:0] == 10'd0) ? 1'b0 : 1'b1;   // HSYNC信号生成
    assign oDispVsyncPort = (r_vPeriodCnt[8:0] <= 9'd9)  ? 1'b0 : 1'b1;   // VSYNC信号生成
    assign oDispDataEnablePort = 1'b0;    // Data Enableは常にLowで良さそう（SYNC mode時）

endmodule
