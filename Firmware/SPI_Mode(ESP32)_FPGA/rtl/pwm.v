/*************************************************************
 * Title : PWM Generator
 * Date  : 2019/9/20
 *************************************************************/
module pwm (
    input   wire            i_clk,
    input   wire            i_rst_n,
    input   wire    [7:0]   i_duty,
    output  wire            o_pwm
);

    /**************************************************************
     *  40MHz / 128 = 312.5kHzのイネーブルパルス生成
     *************************************************************/
    reg [6:0]   r_prsc;
    wire        w_prsc_pls = &r_prsc[6:0];
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            r_prsc[6:0] <= 7'd0;
        end else begin
            r_prsc[6:0] <= r_prsc[6:0] + 7'd1;
        end
    end

    /**************************************************************
     *  PWM波形生成
     *************************************************************/
    reg [7:0]  r_pwm_cmp;
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            r_pwm_cmp[7:0] <= 8'd0;
        end else if (w_prsc_pls) begin
            r_pwm_cmp[7:0] <= r_pwm_cmp[7:0] + 8'd1;
        end
    end
    assign o_pwm = (r_pwm_cmp[7:0] < i_duty) ? 1'b1 : 1'b0;

endmodule
