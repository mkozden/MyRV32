//Allows read/writes to memory of different data sizes, like word, halfword, and byte
module LS_Unit (
    //input logic clk,                      //Clock signal (not needed for now)
    //input logic rst,                      //Reset signal (not needed for now)
    //input logic [31:0] addr,              //Address to read/write from/to (not needed for now)
    input logic [31:0] data_in,             //Data from core
    input logic [31:0] data_in_mem,         //Data from memory
    input logic [2:0] data_size,            //Data size to read/write
    output logic [31:0] data_out_rf,        //Data going to register file
    output logic [31:0] data_out_mem,       //Data going to memory
    output logic [3:0] wmask_out            //Write mask going to memory
);

    always_comb begin
        case(data_size)
        3'b000: begin //Byte (signed)
            data_out_rf = {{24{data_in_mem[7]}}, data_in_mem[7:0]};
            data_out_mem = {{24{data_in[7]}}, data_in[7:0]};
            wmask_out = 4'b1;
        end
        3'b001: begin //Halfword (signed)
            data_out_rf = {{16{data_in_mem[15]}}, data_in_mem[15:0]};
            data_out_mem = {{16{data_in[15]}}, data_in[15:0]};
            wmask_out = 4'b11;
        end
        3'b010: begin //Word (signed)
            data_out_rf = data_in_mem;
            data_out_mem = data_in;
            wmask_out = 4'b1111;
        end
        3'b100: begin //Byte (unsigned)
            data_out_rf = {{24{1'b0}}, data_in_mem[7:0]};
            data_out_mem = {{24{1'b0}}, data_in[7:0]};
            wmask_out = 4'b1;
        end
        3'b101: begin //Halfword (unsigned)
            data_out_rf = {{16{1'b0}}, data_in_mem[15:0]};
            data_out_mem = {{16{1'b0}}, data_in[15:0]};
            wmask_out = 4'b11;
        end
        default: begin
            data_out_rf = data_in_mem;
            data_out_mem = data_in;
            wmask_out = 4'b1111;
        end
        endcase
    end

endmodule
