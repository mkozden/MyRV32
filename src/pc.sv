module PC (
    input logic clk,
    input logic rst,
    input logic [31:0] PC_in,
    output logic [31:0] PC_out
);
    //Increment, and offset additions are done in the ALU
    logic [31:0] PC;

    always_ff @(posedge clk, negedge rst) begin
        if(!rst) begin
            PC <= 32'h0;
        end else begin
            PC <= PC_in;
        end
    end
    assign PC_out = PC;
endmodule
