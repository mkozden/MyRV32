//Allows read/writes to memory of different data sizes, like word, halfword, and byte
module dmem #(
    parameter MEM_SIZE = 1024
)(
    input logic clk,
    input logic rst,
    input logic [31:0] addr,                //Address input
    input logic [31:0] data_in,             //Data input
    input logic [3:0] data_wmask,           //Data write mask
    input logic we,                         //Write enable
    output logic [31:0] data_out            //Data going out
);
    logic [31:0] memory [MEM_SIZE-1:0]; //1024 words of memory

    always_ff @(posedge clk) begin  //Synchronous write
        if (we) begin
            if (data_wmask[0])
                memory[addr][7:0] <= data_in[7:0];
            if (data_wmask[1])
                memory[addr][15:8] <= data_in[15:8];
            if (data_wmask[2])
                memory[addr][23:16] <= data_in[23:16];
            if (data_wmask[3])
                memory[addr][31:24] <= data_in[31:24];
        end
    end
    always_comb begin   //Asynchronous read
        if (!we) begin
            data_out = memory[addr];
        end
        else begin
            data_out = 32'b0; //If we are writing, we don't care about the output
        end
    end
endmodule
