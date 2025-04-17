module register_file (
    input logic clk,
    input logic rst,
    input logic [4:0] rs1,          //Source register 1
    input logic [4:0] rs2,          //Source register 2
    input logic [4:0] rd,           //Destination register
    input logic we,                 //Write enable
    input logic [31:0] data_rd,     //Write data
    output logic [31:0] data_rs1,   //Read data 1
    output logic [31:0] data_rs2    //Read data 2
);
    logic [31:0] register_file [31:1];  //31 registers, each 32 bits wide (0th register is always 0)
    integer i;
    
    always_ff @(negedge clk or negedge rst) begin //Writing on negative edge of clock prevents pipeline hazard
        if(!rst) begin
            for(i = 1; i < 32; i++)
                register_file[i] <= 32'h0;
        end else if(we) begin
            register_file[rd] <= data_rd;   //Write to destination register, done synchronously
        end
    end
    always_comb begin
        if (!rst) begin
            data_rs1 = 32'h0;
            data_rs2 = 32'h0;
        end 
        else begin
            if(rs1 == 0) begin
                data_rs1 = 32'h0;           //Read data 1 is 0 if source register 1 is 0
            end else begin
                data_rs1 = register_file[rs1];  //Read data 1 is the value in source register 1
            end

            if(rs2 == 0) begin
                data_rs2 = 32'h0;           //Read data 2 is 0 if source register 2 is 0
            end else begin
                data_rs2 = register_file[rs2];  //Read data 2 is the value in source register 2
            end
        end
    end
endmodule
