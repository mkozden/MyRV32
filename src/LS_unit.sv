//Allows read/writes to memory of different data sizes, like word, halfword, and byte
module LS_Unit (
    //input logic clk,                      //Clock signal (not needed for now)
    //input logic rst,                      //Reset signal (not needed for now)
    input logic [31:0] addr,              //Address to read/write from/to
    input logic [31:0] data_in,             //Data from core
    input logic [31:0] data_in_mem,         //Data from memory
    input logic [2:0] data_size,            //Data size to read/write
    output logic [31:0] data_out_rf,        //Data going to register file
    output logic [31:0] data_out_mem,       //Data going to memory
    output logic [3:0] wmask_out            //Write mask going to memory
);
    logic [1:0] addr_alignment;

    assign addr_alignment = addr[1:0]; //Get the last two bits of the address to check for alignment

    always_comb begin
        case(data_size)
        3'b000: begin //Byte (signed)
            if(addr_alignment == 2'h0) begin
                data_out_rf = {{24{data_in_mem[7]}}, data_in_mem[7:0]};
                data_out_mem = {{24{1'b0}}, data_in[7:0]}; //The sign bit doesn't really matter for writes, since they're masked out anyways
                wmask_out = 4'b0001;
            end 
            else if(addr_alignment == 2'h1) begin
                data_out_rf = {{24{data_in_mem[15]}}, data_in_mem[15:8]};
                data_out_mem = {{16{1'b0}}, data_in[7:0], 8'b0};
                wmask_out = 4'b0010;
            end
            else if(addr_alignment == 2'h2) begin
                data_out_rf = {{24{data_in_mem[23]}}, data_in_mem[23:16]};
                data_out_mem = {{8{1'b0}}, data_in[7:0], 16'b0};
                wmask_out = 4'b0100;
            end
            else if(addr_alignment == 2'h3) begin
                data_out_rf = {{24{data_in_mem[31]}}, data_in_mem[31:24]};
                data_out_mem = {data_in[7:0], 24'b0};
                wmask_out = 4'b1000;
            end
            else begin  //Shouldn't occur for byte access
                data_out_rf = 32'h0; //Invalid address, return 0
                data_out_mem = 32'h0; //Invalid address, return 0
                wmask_out = 4'b0000; //Invalid address, return 0
            end
        end
        3'b001: begin //Halfword (signed)
            if(addr_alignment == 2'h0) begin
                data_out_rf = {{16{data_in_mem[15]}}, data_in_mem[15:0]};
                data_out_mem = {{16{1'b0}}, data_in[15:0]};
                wmask_out = 4'b0011;
            end
            else if(addr_alignment == 2'h2) begin
                data_out_rf = {{16{data_in_mem[31]}}, data_in_mem[31:16]};
                data_out_mem = {data_in[15:0], {16{1'b0}}};
                wmask_out = 4'b1100;
            end
            else begin  //Misaligned access
                data_out_rf = 32'h0; //Invalid address, return 0
                data_out_mem = 32'h0; //Invalid address, return 0
                wmask_out = 4'b0000; //Invalid address, return 0
            end
        end
        3'b010: begin //Word (signed)
            data_out_rf = data_in_mem;
            data_out_mem = data_in;
            wmask_out = 4'b1111;
        end
        3'b100: begin //Byte (unsigned)
            if(addr_alignment == 2'h0) begin
                data_out_rf = {{24{1'b0}}, data_in_mem[7:0]};
                data_out_mem = {{24{1'b0}}, data_in[7:0]};
                wmask_out = 4'b0001;
            end 
            else if(addr_alignment == 2'h1) begin
                data_out_rf = {{24{1'b0}}, data_in_mem[15:8]};
                data_out_mem = {{16{1'b0}}, data_in[7:0], 8'b0};
                wmask_out = 4'b0010;
            end
            else if(addr_alignment == 2'h2) begin
                data_out_rf = {{24{1'b0}}, data_in_mem[23:16]};
                data_out_mem = {{8{1'b0}}, data_in[7:0], 16'b0};
                wmask_out = 4'b0100;
            end
            else if(addr_alignment == 2'h3) begin
                data_out_rf = {{24{1'b0}}, data_in_mem[31:24]};
                data_out_mem = {data_in[7:0], 24'b0};
                wmask_out = 4'b1000;
            end
            else begin  //Shouldn't occur for byte access
                data_out_rf = 32'h0; //Invalid address, return 0
                data_out_mem = 32'h0; //Invalid address, return 0
                wmask_out = 4'b0000; //Invalid address, return 0
            end
        end
        3'b101: begin //Halfword (unsigned)
            if(addr_alignment == 2'h0) begin
                data_out_rf = {{16{1'b0}}, data_in_mem[15:0]};
                data_out_mem = {{16{1'b0}}, data_in[15:0]};
                wmask_out = 4'b0011;
            end
            else if(addr_alignment == 2'h2) begin
                data_out_rf = {{16{1'b0}}, data_in_mem[31:16]};
                data_out_mem = {data_in[15:0], {16{1'b0}}};
                wmask_out = 4'b1100;
            end
            else begin  //Misaligned access
                data_out_rf = 32'h0; //Invalid address, return 0
                data_out_mem = 32'h0; //Invalid address, return 0
                wmask_out = 4'b0000; //Invalid address, return 0
            end
        end
        default: begin
            data_out_rf = data_in_mem;
            data_out_mem = data_in;
            wmask_out = 4'b1111;
        end
        endcase
    end

endmodule
