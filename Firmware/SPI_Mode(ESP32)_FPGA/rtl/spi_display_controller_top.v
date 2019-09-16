/*************************************************************
 * Title : SPI TFT LCD Controller Top Module (ST7735R)
 * Date  : 2019/8/6
 *************************************************************/
module spi_display_controller_top (
    input   wire            mco,
    input   wire            rst_n,

    // SPI I/F
    input   wire            SPI_CLK,
    input   wire            SPI_CS,
    input   wire            SPI_MOSI,
    input   wire            DC,

    // DIP SW
    input   wire    [ 5:0]  iModeSelectorPort,

    // TO LCD
    output  reg             oDispClockPort,
    output  wire            oDispHsyncPort,
    output  wire            oDispVsyncPort,
    output  wire            oDispDataEnablePort,
    output  wire            oDispDispPort,
    output  wire            oDispLedSHDNPort,

    // TO SRAM
    output  wire    [17:0]  oSRAMAddrPort,
    inout   wire    [23:0]  ioSRAMDataPort,
    output  wire            oSRAMWriteEnablePort,
    output  wire            oSRAMOutputEnablePort
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

    assign oDispDispPort        = 1'b1;
    assign oDispLedSHDNPort     = 1'b1;
    assign oDispDataEnablePort  = 1'b0;    // Data Enableは常にLowで良さそう（SYNC mode時）


    /**************************************************************
     *  ST7735R Instruction
     *************************************************************/
    localparam CMD_NOP      = 8'h00;    // No Operation
    localparam CMD_SWRESET  = 8'h01;    // Software reset
    localparam CMD_DISPOFF  = 8'h28;    // Display Off
    localparam CMD_DISPON   = 8'h29;    // Display On
    localparam CMD_CASET    = 8'h2A;    // Column Address Set
    localparam CMD_RASET    = 8'h2B;    // Row Address Set
    localparam CMD_RAMWR    = 8'h2C;    // Memory Write


    /**************************************************************
     *  SPI Slaveモジュール接続
     *************************************************************/
    wire [15:0] w_pixel_data;
    wire        w_pixel_en;
    wire [ 7:0] w_inst_data;
    wire        w_inst_en;
    wire [31:0] w_row_addr;
    wire        w_row_addr_en;
    wire [31:0] w_col_addr;
    wire        w_col_addr_en;
    spi_slave spi_slave_inst (
        .i_clk ( mco ),                         // FPGA内部CLK
        .i_rst_n ( rst_n ),                     // RESET
        .i_spi_clk ( SPI_CLK ),                 // SPI_CLK
        .i_spi_cs ( SPI_CS ),                   // SPI_CS
        .i_spi_mosi ( SPI_MOSI ),               // SPI_MOSI
        .i_dc ( DC ),                           // DC(H:Data / L:Command)
        .o_pixel_data ( w_pixel_data[15:0] ),   // 画素データ
        .o_pixel_en_pls ( w_pixel_en ),         // 画素データ有効
        .o_inst_data ( w_inst_data[7:0] ),      // 命令データ
        .o_inst_en_pls ( w_inst_en ),           // 命令データ有効

        .o_row_addr ( w_row_addr[31:0] ),       // Row Address
        .o_row_addr_en_pls ( w_row_addr_en ),   // Row Address enable
        .o_col_addr ( w_col_addr[31:0] )        // Column Address
    );    

    /**************************************************************
     *  Instrucion分岐 / データ書き込み要求処理
     *************************************************************/
    reg         r_sram_clr_req;             // SRAM ALLクリア要求
    reg         r_sram_clr_req_fin;         // SRAM ALLクリア要求完了
    reg         r_sram_write_req;           // SRAMデータ書き込み要求
    reg         r_sram_write_req_fin;       // SRAMデータ書き込み要求完了
    reg         r_sram_waddr_set_req;       // SRAM書き込みアドレスセット要求
    reg         r_sram_waddr_set_req_fin;   // SRAM書き込みアドレスセット要求完了
    reg         r_dispOn;                   // Display ON

    always @(posedge mco or negedge rst_n) begin
        if (~rst_n) begin
            r_sram_write_req <= 1'b0;
            r_dispOn <= 1'b0;
        end else begin
            if (w_inst_en) begin
                // Instruction分岐
                case (w_inst_data[7:0])
                    CMD_NOP     : ;                                 // NOP
                    CMD_SWRESET : begin
                                  r_sram_clr_req <= 1'b1;           // SRAMクリア
                                  r_dispOn <= 1'b0;                 // Display OFF
                    end
                    CMD_DISPOFF : r_dispOn <= 1'b0;
                    CMD_DISPON  : r_dispOn <= 1'b1;
                    CMD_RAMWR   : ;
                    CMD_RASET   : ;
                    default     : ;                                 // NOP
                endcase
            end else if (w_row_addr_en) begin
                // RAM Addr Re Setting
                r_sram_waddr_set_req <= 1'b1;
            end else begin
                if (r_sram_waddr_set_req_fin) begin
                    r_sram_waddr_set_req <= 1'b0;
                end
                if (r_sram_clr_req_fin) begin
                    r_sram_clr_req <= 1'b0;
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
    reg     [ 1:0]  r_state;
    reg     [16:0]  r_sramWriteAddr;
    reg             r_sram_OE;
    reg             r_sram_WE;
    reg             r_sram_clr_busy;
    reg     [8:0]   r_pos_win_x;
    reg     [8:0]   r_pos_win_y;
    wire    [23:0]  w_sram_wdata;
    always @(posedge mco or negedge rst_n) begin
        if (~rst_n) begin
            r_state[1:0] <= 2'd0;
            r_sramWriteAddr[16:0] <= 17'd0;
            r_sram_OE <= 1'b0;
            r_sram_WE <= 1'b0;
            r_sram_clr_busy <= 1'b0;
            r_sram_write_req_fin <= 1'b0;
            r_sram_waddr_set_req_fin <= 1'b0;
            r_sram_clr_req_fin <= 1'b0;
            r_pos_win_x[8:0] <= 9'd0;
            r_pos_win_y[8:0] <= 9'd0;
        end else begin
            case (r_state[1:0])
                2'b00: begin
                    if (r_sram_clr_req & ~r_sram_clr_busy) begin
                        // SRAM書き込みアドレスクリア
                        r_sramWriteAddr[16:0] <= 17'd0;
                        r_sram_clr_busy <= 1'b1;
                        r_sram_OE <= 1'b0;
                        r_sram_WE <= 1'b1;
                    end if (r_sram_clr_busy) begin
                        // 末端まで書き込み完了でfin
                        if (r_sramWriteAddr[16:0] == DispSramMaxAddr) begin
                            r_sram_clr_busy <= 1'b0;
                            r_sram_clr_req_fin <= 1'b1;
                        end else begin
                            r_sramWriteAddr[16:0] <= r_sramWriteAddr[16:0] + 17'd1;
                            r_sram_OE <= 1'b0;
                            r_sram_WE <= 1'b1;
                        end
                    end else if (r_sram_write_req) begin
                        // ポジション更新
                        r_pos_win_x[8:0] <= r_pos_win_x[8:0] + 9'd1;
                        if (r_pos_win_x[8:0] >= w_col_addr[8:0]) begin  // 右端
                            r_pos_win_x[8:0] <= w_col_addr[24:16];      // Xポジションを開始位置に

                            r_pos_win_y[8:0] <= r_pos_win_y[8:0] + 9'd1;
                            if (r_pos_win_y[8:0] >= w_row_addr[8:0]) begin
                                r_pos_win_y[8:0] <= w_row_addr[24:16];  // Yポジションを開始位置に
                            end
                        end

                        // SRAM Writeアドレス計算
                        r_sramWriteAddr[16:0] <= ({8'd0, r_pos_win_y[8:0]} * DispWidth) + {8'd0, r_pos_win_x[8:0]} + 
                                                 (iModeSelectorPort[0] ? 17'd480 : 17'd0);

                        r_sram_OE <= 1'b0;
                        r_sram_WE <= 1'b1;
                        r_sram_write_req_fin <= 1'b1;
                    end else if (r_sram_waddr_set_req) begin
                        r_sram_waddr_set_req_fin <= 1'b1;
                        r_pos_win_x[8:0] <= w_col_addr[24:16];    // Xポジションを開始位置に
                        r_pos_win_y[8:0] <= w_row_addr[24:16];    // Yポジションを開始位置に
                    end else begin
                        r_sram_write_req_fin <= 1'b0;
                        r_sram_waddr_set_req_fin <= 1'b0;
                        r_sram_clr_req_fin <= 1'b0;
                    end
                    r_state[1:0] <= 2'b01;
                end

                2'b01: begin
                    r_state[1:0] <= 2'b10;
                end

                2'b10: begin
                    // SRAM Data Read Enable
                    r_sram_OE <= r_dispOn;
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
    // 書き込みデータ
    assign w_sram_wdata[23:0]    = (r_sram_clr_req | r_sram_clr_busy) ? 24'd0 :
    //                               PAD,          B (5bit),           G (6bit),            R (5bit)
                                  {8'b0, w_pixel_data[4:0], w_pixel_data[10:5], w_pixel_data[15:11]};
    // SRAMデータポート制御
    assign ioSRAMDataPort[23:0]  = r_sram_WE ? w_sram_wdata[23:0] : 
                                   ~r_dispOn ? 24'd0              : 24'bzzzzzzzzzzzzzzzzzzzzzzzz;
    

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

    // SRAMアドレスポート制御
    assign oSRAMAddrPort  = r_sram_OE ? {1'b0, r_displayCnt[16:0]} :
                                        {1'b0, r_sramWriteAddr[16:0]};

endmodule
