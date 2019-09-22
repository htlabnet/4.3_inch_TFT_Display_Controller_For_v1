/*************************************************************
 * Title : Synchronizer
 * Date  : 2019/9/22
 *************************************************************/
module synchronizer (
    input   wire            i_clk,
    input   wire            i_sig,
    output	wire			o_sig
    );

    reg	[1:0]	r_ff;
    
    always @(posedge i_clk) begin
        r_ff[1:0] <= {r_ff[0] , i_sig};
    end
    assign o_sig = r_ff[1];

endmodule
