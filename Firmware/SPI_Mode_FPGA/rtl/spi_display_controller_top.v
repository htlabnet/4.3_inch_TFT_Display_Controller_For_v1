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
    );

    
    // LCDパラメータ
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
    wire [23:0] spi_rcv_data;
    wire        spi_rcv_en;
    spi_slave spi_slave_inst (
        .i_clk ( mco ),                         // FPGA内部CLK
        .i_rst_n ( rst_n ),                     // RESET
        .i_spi_clk ( SPI_CLK ),                 // SPI_CLK
        .i_spi_cs ( SPI_CS ),                   // SPI_CS
        .i_spi_mosi ( SPI_MOSI ),               // SPI_MOSI
        .o_mosi_data ( spi_rcv_data[23:0] ),    // 受信データ
        .o_mosi_en_pls ( spi_rcv_en )           // 受信データ有効
    );


    /**************************************************************
     *  SPI コマンド解析
     *************************************************************/
    reg         sram_write_req;         // SRAMデータ書き込み要求
    reg         sram_page_change_req;   // SRAMページ切り替え要求
    reg         sram_addr_set_req;      // SRAMアドレス設定要求
    reg [17:0]  sram_write_data;        // SRAM書き込みデータ
    reg         spi_command_req_fin;    // SPIコマンド要求処理完了
    always @(posedge mco or negedge rst_n) begin
        if (~rst_n) begin
            sram_write_req <= 1'b0;
            sram_page_change_req <= 1'b0;
            sram_write_data[17:0] <= 18'd0;
            sram_addr_set_req <= 1'b0;
        end else begin
            if (spi_rcv_en) begin
                if (spi_rcv_data[23:20] == 4'b0000) begin           // Data Write
                    sram_write_req <= 1'b1;
                    sram_write_data[17:0] <= spi_rcv_data[17:0];
                end else if (spi_rcv_data[23:20] == 4'b1000) begin  // Addr Write
                    sram_addr_set_req <= 1'b1;
                end else if (spi_rcv_data[23:20] == 4'b1001) begin  // Page Change
                    sram_page_change_req <= 1'b1;
                end
            end else begin
                // コマンド要求実行完了
                if (spi_command_req_fin) begin
                    sram_write_req <= 1'b0;
                    sram_page_change_req <= 1'b0;
                    sram_addr_set_req <= 1'b0;
                end
            end
        end
    end


    /**************************************************************
     *  SRAM制御
     *************************************************************/
    reg [ 1:0]  state;
    reg         page;
    reg [17:0]  sramWriteAddr;
    reg         sram_OE;
    reg         sram_WE;
    always @(posedge mco or negedge rst_n) begin
        if (~rst_n) begin
            state[1:0] <= 2'd0;
            page <= 1'b0;
            sramWriteAddr[17:0] <= 18'd0;
            ioSRAMDataPort[23:0] <= 24'bzzzzzzzzzzzzzzzzzzzzzzzz;
            oSRAMAddrPort[17:0] <= 18'd0;
            sram_OE <= 1'b0;
            sram_WE <= 1'b0;
            spi_command_req_fin <= 1'b0;
            oDispDispPort <= 1'b1;
            oDispLedSHDNPort <= 1'b0;
        end else begin
            case (state[1:0])
                2'b00: begin
                    if (sram_write_req) begin
                        // SRAMへのデータ書き込み
                        oSRAMAddrPort[17:0] <= {page, sramWriteAddr[16:0]};
                        sramWriteAddr[17:0] <= sramWriteAddr[17:0] + 18'd1;    // 書き込み後アドレス自動インクリメント
                        ioSRAMDataPort[23:0] <= {8'b0, sram_write_data[5:1], sram_write_data[11:6], sram_write_data[17:13]};
                        //                        PAD,             B (5bit),              G (6bit),               R (5bit)
                        sram_OE <= 1'b0;
                        sram_WE <= 1'b1;
                        spi_command_req_fin <= 1'b1;
                    end else if (sram_page_change_req) begin
                        // ページ切り替え
                        page <= ~page;
                        spi_command_req_fin <= 1'b1;
                        // 初回のページ切り替え後表示有効
                        oDispDispPort <= 1'b1;
                        oDispLedSHDNPort <= 1'b1;
                    end else if (sram_addr_set_req) begin
                        // アドレス設定
                        sramWriteAddr[17:0] <= spi_rcv_data[17:0];
                        spi_command_req_fin <= 1'b1;
                    end else begin
                        spi_command_req_fin <= 1'b0;
                    end
                    state[1:0] <= 2'b01;
                end

                2'b01: begin
                    state[1:0] <= 2'b10;
                end

                2'b10: begin
                    // SRAM Data Read Enable
                    oSRAMAddrPort[17:0] <= {~page, displayCnt[16:0]};        // SRAM読み出しアドレスセット(書き込みとは別のページを表示）
                    ioSRAMDataPort[23:0] <= 24'bzzzzzzzzzzzzzzzzzzzzzzzz;    // SRAM出力と衝突しないようにFPGAのIOをHi-Zに
                    sram_OE <= 1'b1;
                    sram_WE <= 1'b0;
                    state[1:0] <= 2'b11;
                end

                2'b11: begin
                    state[1:0] <= 2'b00;
                end
            endcase
        end
    end
    // SRAMの制御信号は負論理
    assign oSRAMWriteEnablePort  = ~sram_WE;
    assign oSRAMOutputEnablePort = ~sram_OE;


    /**************************************************************
     *  LCD制御信号生成
     *************************************************************/
    reg [16:0] displayCnt;
    reg [ 9:0] hPeriodCnt;
    reg [ 8:0] vPeriodCnt;
    reg hInVisibleArea;
    reg vInVisibleArea;
    always @(posedge mco or negedge rst_n) begin
        if (~rst_n) begin
            displayCnt[16:0] <= 17'd0;
            hPeriodCnt[9:0] <= 10'd0;
            vPeriodCnt[8:0] <= 9'd0;
            oDispClockPort <= 1'b0;
            hInVisibleArea <= 1'd0;
            vInVisibleArea <= 1'd0;
        end else begin
            case (state[1:0])
                2'b01 : begin
                    // dclk立ち上げ
                    oDispClockPort <= 1'b1;

                    // 水平同期信号生成
                    if (hPeriodCnt[9:0] == (DispHPeriodTime - 10'd1)) begin
                        hPeriodCnt[9:0] <= 10'd0;
                    end else begin
                        hPeriodCnt[9:0] <= hPeriodCnt[9:0] + 10'b1;
                    end

                    // 垂直同期信号生成
                    if (hPeriodCnt[9:0] == (DispHPeriodTime - 10'd1)) begin
                        if (vPeriodCnt[8:0] == (DispVPeriodTime - 9'd1)) begin
                            vPeriodCnt[8:0] <= 9'd0;
                            displayCnt[16:0] <= 17'd0;
                        end else begin
                            vPeriodCnt[8:0] <= vPeriodCnt[8:0] + 9'b1;
                        end
                    end
                end

                2'b10 : begin
                    // 書き込み領域判定
                    hInVisibleArea <=   (hPeriodCnt[9:0] == DispHBackPorch)  ? 1'b1 :
                                        (hPeriodCnt[9:0] == DispHFrontPorch) ? 1'b0 : hInVisibleArea;
                    vInVisibleArea <=   (vPeriodCnt[8:0] == DispVBackPorch)  ? 1'b1 :
                                        (vPeriodCnt[8:0] == DispVFrontPorch) ? 1'b0 : vInVisibleArea;
                end

                2'b11 : begin
                    // dclk立ち下げでデータラッチ
                    oDispClockPort <= 1'b0;

                    // 表示エリアのみSRAM Readアドレスをインクリメント
                    if (hInVisibleArea & vInVisibleArea) begin
                        displayCnt[16:0] <= displayCnt[16:0] + 17'd1;
                    end
                end
            endcase
        end
    end

    assign oDispHsyncPort = (hPeriodCnt[9:0] == 10'd0) ? 1'b0 : 1'b1;   // HSYNC信号生成
    assign oDispVsyncPort = (vPeriodCnt[8:0] <= 9'd9)  ? 1'b0 : 1'b1;   // VSYNC信号生成
    assign oDispDataEnablePort = 1'b0;    // Data Enableは常にLowで良さそう（SYNC mode時）

endmodule
