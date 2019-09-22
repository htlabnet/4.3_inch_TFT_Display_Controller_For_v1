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
    output  wire            oDispClockPort,
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
     *  Wire定義
     *************************************************************/
    wire        w_rst_n_sync;
    wire [ 7:0] w_spi_mosi_data;
    wire        w_spi_dc;
    wire        w_spi_rxdone;
    wire [15:0] w_pixel_data;
    wire [31:0] w_col_addr;
    wire [31:0] w_row_addr;
    wire        w_sram_clr_req;
    wire        w_sram_write_req;
    wire        w_sram_waddr_set_req;
    wire        w_dispOn;
    wire [ 7:0] w_pwm_duty;
    wire [16:0] w_sram_raddr;
    wire [16:0] w_sram_raddr_max;
    wire [15:0] w_disp_width;

    /**************************************************************
     *  リセット信号のmco同期化
     *************************************************************/
    synchronizer sync_reset_inst (
        .i_clk ( mco ),                             // CLK
        .i_sig ( rst_n ),                           // 同期化対象信号
        .o_sig ( w_rst_n_sync ),                    // i_clkで同期化された出力信号
	);

    /**************************************************************
     *  SPI Slaveモジュール
     *************************************************************/
    spi_slave spi_slave_inst (
        .i_clk ( mco ),                             // CLK
        .i_rst_n ( w_rst_n_sync ),                  // RESET
        .i_spi_clk ( SPI_CLK ),                     // SPI_CLK
        .i_spi_cs ( SPI_CS ),                       // SPI_CS
        .i_spi_mosi ( SPI_MOSI ),                   // SPI_MOSI
        .i_dc ( DC ),                               // DC(H:Data / L:Command)

        // To Instruction Decoder and Register
        .o_data ( w_spi_mosi_data[7:0] ),           // SPI受信データ
        .o_dc ( w_spi_dc ),                         // データ/コマンド識別(H:Data / L:Command)
        .o_rxdone ( w_spi_rxdone )                  // 受信完了パルス(i_clk幅)
    );

    /**************************************************************
     *  SPI命令デコーダ、レジスタ
     *************************************************************/
    inst_dec_reg inst_dec_reg_inst (
        .i_clk ( mco ),                             // CLK
        .i_rst_n ( w_rst_n_sync ),                  // RESET

        // From SPI Slave
        .i_spi_data ( w_spi_mosi_data[7:0] ),       // SPI受信データ
        .i_spi_dc ( w_spi_dc ),                     // データ/コマンド識別(H:Data / L:Command)
        .i_spi_rxdone ( w_spi_rxdone ),             // 受信完了パルス(i_clk幅)

        // To SRAM Controller
        .o_pixel_data ( w_pixel_data[15:0] ),       // 画素データ(RGB:565)
        .o_col_addr ( w_col_addr[31:0] ),           // XS15:0[31:16], XE15:0[15:0]
        .o_row_addr ( w_row_addr[31:0] ),           // YS15:0[31:16], YE15:0[15:0]
        .o_sram_clr_req ( w_sram_clr_req ),             // SRAMゼロクリア要求(4 x i_clk幅)
        .o_sram_write_req ( w_sram_write_req ),         // 画素データ書き込み要求(4 x i_clk幅)
        .o_sram_waddr_set_req ( w_sram_waddr_set_req ), // SRAM書き込みアドレス設定要求(4 x i_clk幅)
        .o_dispOn ( w_dispOn ),                     // ディスプレイON/OFF状態

        // To PWM Controller
        .o_pwm_duty ( w_pwm_duty[7:0] )             // PWM Duty(0:MIN / 255:MAX)
    );

    /**************************************************************
     *  LCDバックライトPWM調光
     *************************************************************/
    pwm pwm_lcd_inst (
        .i_clk ( mco ),                             // CLK
        .i_rst_n ( w_rst_n_sync ),                  // RESET
        .i_duty ( w_pwm_duty[7:0] ),                // PWM Duty(0:MIN / 255:MAX)
        .o_pwm ( oDispLedSHDNPort )                 // PWM信号出力
    );

    /**************************************************************
     *  LCD制御
     *************************************************************/
    lcd_controller lcd_controller_inst (
        .i_clk ( mco ),                             // CLK
        .i_rst_n ( w_rst_n_sync ),                  // RESET

        // To SRAM Controller
        .o_sram_raddr ( w_sram_raddr[16:0] ),       // SRAM Readアドレス
        .o_sram_raddr_max ( w_sram_raddr_max[16:0] ),   // SRAM Readアドレス最大値
        .o_disp_width ( w_disp_width[15:0] ),       // ディスプレイ幅
        
        // To LCD
        .o_DispClockPort ( oDispClockPort ),        // LCD クロック信号
        .o_DispHsyncPort ( oDispHsyncPort ),        // LCD 水平同期信号
        .o_DispVsyncPort ( oDispVsyncPort ),        // LCD 垂直同期信号
        .o_DispDataEnablePort ( oDispDataEnablePort ),  // LCD Enable信号
        .o_DispDispPort ( oDispDispPort )           // LCD Disp信号
    );

    /**************************************************************
     *  SRAM制御
     *************************************************************/
    sram_controller sram_controller_inst (
        .i_clk ( mco ),                             // CLK
        .i_rst_n ( w_rst_n_sync ),                  // RESET
        .i_height_is_270 ( iModeSelectorPort[0] ),  // 画面高さ指定信号(H:270pixel / L:272pixel)

        // From Instruction Decoder and Register
        .i_pixel_data ( w_pixel_data[15:0] ),       // 画素データ(RGB:565)
        .i_col_addr ( w_col_addr[31:0] ),           // XS15:0[31:16], XE15:0[15:0]
        .i_row_addr ( w_row_addr[31:0] ),           // YS15:0[31:16], YE15:0[15:0]
        .i_sram_clr_req ( w_sram_clr_req ),         // SRAMゼロクリア要求(4 x i_clk幅)
        .i_sram_write_req ( w_sram_write_req ),     // 画素データ書き込み要求(4 x i_clk幅)
        .i_sram_waddr_set_req ( w_sram_waddr_set_req ), // SRAM書き込みアドレス設定要求(4 x i_clk幅)
        .i_dispOn ( w_dispOn ),                     // ディスプレイON/OFF状態

        // From LCD Controller
        .i_sram_raddr ( w_sram_raddr[16:0] ),       // SRAM Readアドレス
        .i_sram_raddr_max ( w_sram_raddr_max[16:0] ),   // SRAM Readアドレス最大値
        .i_disp_width ( w_disp_width[15:0] ),       // ディスプレイ幅

        // To SRAM
        .o_SRAMWriteEnablePort ( oSRAMWriteEnablePort ),    // SRAM Write Enable
        .o_SRAMOutputEnablePort ( oSRAMOutputEnablePort ),  // SRAM Out Enable
        .io_SRAMDataPort ( ioSRAMDataPort ),                // SRAM Data
        .o_SRAMAddrPort ( oSRAMAddrPort )                   // SRAM Address
    );

endmodule
