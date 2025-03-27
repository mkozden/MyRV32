`include "riscv_pkg.sv"

module control_unit (
    input logic [31:0] instr,
    
    output logic B, J,                  //Branch control signals
    output logic [3:0] ALUControl,      //ALU control signals
    output logic [4:0] rs1, rs2, rd,    //Register file select signals
    output logic we, rf_we,             //Write enable signals
    output logic ALU_sel_A, ALU_sel_B,  //ALU operand select signals
    output logic [2:0] data_size,       //Data size signal
    output logic WB_sel,                //Register file writeback select signal
    output logic [31:0] imm             //Immediate value (extended)
);
    
    import riscv_pkg::*;                //Importing the riscv package for opcode definitions

    logic [6:0] opcode;
    logic [6:0] funct7;
    logic [2:0] funct3;

    assign opcode   = instr[6:0];   //Extract various fixed fields from instruction 
    assign funct7   = instr[31:25];
    assign funct3   = instr[14:12];
    assign rd       = instr[11:7];
    assign rs1      = instr[19:15];
    assign rs2      = instr[24:20];

    always_comb begin
        case(opcode)
        OpcodeOpImm:begin
            B = 1'b0;           //No branching
            J = 1'b0;           //No jumping
            ALU_sel_A = 1'b0;   //ALU operand A is from register file
            ALU_sel_B = 1'b1;   //ALU operand B is from immediate field
            we = 1'b0;          //No memory writes
            rf_we = 1'b1;       //Write to register file
            WB_sel = 1'b0;      //Write from ALU result
            data_size = 3'b000; //No memory writes or reads so data size is irrelevant
            imm = {{20{instr[31]}}, instr[31:20]}; //Sign extend immediate field
            case(funct3)
                F3_ADDI: ALUControl = 4'b0000;
                F3_SLTI: ALUControl = 4'b1000;
                F3_SLTIU:ALUControl = 4'b1001;
                F3_ANDI: ALUControl = 4'b0010;
                F3_ORI:  ALUControl = 4'b0011;
                F3_XORI: ALUControl = 4'b0100;
                F3_SLLI: ALUControl = 4'b0101;
                F3_SRLI: ALUControl = 4'b0110;
                F3_SRAI: ALUControl = 4'b0111;
            endcase
        end
        OpcodeLui:begin
            B = 1'b0;                               //No branching
            J = 1'b0;                               //No jumping
            ALU_sel_A = 1'b0;                       //ALU operand A is not used, so irrelevant
            ALU_sel_B = 1'b1;                       //ALU operand B is from immediate field
            we = 1'b0;                              //No memory writes
            rf_we = 1'b1;                           //Write to register file
            WB_sel = 1'b0;                          //Write from ALU result
            data_size = 3'b000;                     //No memory writes or reads so data size is irrelevant
            imm = {instr[31:12], 12'b0};            //Use upper 20-bits as immediate, 0 for lower 12-bits
            ALUControl = 4'b1111;                   //Directly use B as ALU result
        end
        OpcodeAuipc:begin
            B = 1'b0;                               //No branching
            J = 1'b0;                               //No jumping
            ALU_sel_A = 1'b1;                       //ALU operand A is pc
            ALU_sel_B = 1'b1;                       //ALU operand B is from immediate field
            we = 1'b0;                              //No memory writes
            rf_we = 1'b1;                           //Write to register file
            WB_sel = 1'b0;                          //Write from ALU result
            data_size = 3'b000;                     //No memory writes or reads so data size is irrelevant
            imm = {instr[31:12], 12'b0};            //Use upper 20-bits as immediate, 0 for lower 12-bits
            ALUControl = 4'b0000;                   //Add immediate to pc
        end
        OpcodeOp:begin
            B = 1'b0;           //No branching
            J = 1'b0;           //No jumping
            ALU_sel_A = 1'b0;   //ALU operand A is from register file
            ALU_sel_B = 1'b0;   //ALU operand B is from register file
            we = 1'b0;          //No memory writes
            rf_we = 1'b1;       //Write to register file
            WB_sel = 1'b0;      //Write from ALU result
            data_size = 3'b000; //No memory writes or reads so data size is irrelevant
            imm = 32'b0;        //Immediate not used
            case(funct3)
                F3_ADD: if(funct7 == F7_ADD) ALUControl = 4'b0000; else if (funct7 == F7_SUB) ALUControl = 4'b0001;
                F3_SLT: ALUControl = 4'b1000;
                F3_SLTU:ALUControl = 4'b1001;
                F3_AND: ALUControl = 4'b0010;
                F3_OR:  ALUControl = 4'b0011;
                F3_XOR: ALUControl = 4'b0100;
                F3_SLL: ALUControl = 4'b0101;
                F3_SRL: if(funct7 == F7_SRL) ALUControl = 4'b0110; else if (funct7 == F7_SRA) ALUControl = 4'b0111;
            endcase
        end
        OpcodeJal:begin
            B = 1'b0;                               //No branching
            J = 1'b1;                               //jumping
            ALU_sel_A = 1'b1;                       //ALU operand A is pc
            ALU_sel_B = 1'b0;                       //ALU operand B is not used, so irrelevant
            we = 1'b0;                              //No memory writes
            rf_we = 1'b1;                           //Write to register file
            WB_sel = 1'b0;                          //Write from ALU result
            data_size = 3'b000;                     //No memory writes or reads so data size is irrelevant
            imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; //Immediate not used in ALU, but for target address calculation
            ALUControl = 4'b0000;                   //PC + 4
        end
        endcase
    end
endmodule