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

    parameter ADDR_WIDTH = $clog2(MEM_SIZE); //Address width in bits
    logic [ADDR_WIDTH-1:0] addr_internal; //Address integer for indexing
    assign addr_internal = addr[ADDR_WIDTH+1:2]; //Since the memory is word-addressed, we need to shift the address by 2 to get the correct index

    always_ff @(posedge clk) begin  //Synchronous write
        if (we) begin
            if (data_wmask[0])
                memory[addr_internal][7:0] <= data_in[7:0];
            if (data_wmask[1])
                memory[addr_internal][15:8] <= data_in[15:8];
            if (data_wmask[2])
                memory[addr_internal][23:16] <= data_in[23:16];
            if (data_wmask[3])
                memory[addr_internal][31:24] <= data_in[31:24];
        end
    end
    always_comb begin   //Asynchronous read
        if (!we) begin
            data_out = memory[addr_internal];
        end
        else begin
            data_out = 32'b0; //If we are writing, we don't care about the output
        end
    end
    logic [31:0] a0,a4,a8,aA,aC,a10,a14; //Debug memory signals
    assign a0 = memory[0];
    assign a4 = memory[1];
    assign a8 = memory[2];
    assign aA = memory[3];
    assign aC = memory[4];
    assign a10 = memory[5];
    assign a14 = memory[6];

endmodule
