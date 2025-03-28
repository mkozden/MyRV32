//`include "pkg/riscv_pkg.sv"
import riscv_pkg::*;

module riscv_singlecycle #(
    parameter DMemInitFile  = "dmem.mem",       // data memory initialization file
    parameter IMemInitFile  = "imem.mem"       // instruction memory initialization file
)(
    input  logic             clk_i,       // system clock
    input  logic             rstn_i,      // system reset
    input  logic  [XLEN-1:0] addr_i,      // instruction memory ??? adddres input for reading
    output logic  [XLEN-1:0] data_o,      // instruction memory ??? data output for reading
    output logic             update_o,    // retire signal
    output logic  [XLEN-1:0] pc_o,        // retired program counter
    output logic  [XLEN-1:0] instr_o,     // retired instruction
    output logic  [     4:0] reg_addr_o,  // retired register address
    output logic  [XLEN-1:0] reg_data_o,  // retired register data
    output logic  [XLEN-1:0] mem_addr_o,  // retired memory address
    output logic  [XLEN-1:0] mem_data_o  // retired memory data
);
    parameter MEM_SIZE = 2048;
    logic [31:0]     imem [MEM_SIZE-1:0];
    initial $readmemh("../test/test.hex", imem, 0, MEM_SIZE);
    logic [31:0]     instr_i;

    assign instr_i = imem[addr_i];
    //assign addr_i = pc_o; //I don't know what to do with this
    assign data_o = instr_i;
    assign instr_o = instr_i; //Since this is single cycle and in-order, the instruction is retired in the same cycle it is fetched
    
    // Internal control signals
    logic B, J;                                 //Branch control signals
    logic [3:0] ctrl_ALUControl;                //ALU control signals
    logic [4:0] ctrl_rs1, ctrl_rs2, ctrl_rd;    //Register file select signals
    logic ctrl_we, ctrl_rf_we;                  //Write enable signals
    logic ctrl_ALU_sel_A, ctrl_ALU_sel_B;       //ALU operand select signals
    logic [2:0] ctrl_data_size;                 //Data size signal
    logic ctrl_WB_sel;                          //Register file writeback select signal
    logic ctrl_JALR_sel;                        //Select between PC+imm and rs1+imm for JAL/JALR/Branches
    logic [31:0] ctrl_imm;

    logic take_branch;

    // Data signals
    logic [31:0] data_rd, data_rs1, data_rs2;   //Register file data signals
    logic [31:0] data_in_mem;                   //Data from memory
    logic [31:0] data_out_rf, data_out_mem;     //Data going to register file and memory
    logic [31:0] alu_in_A, alu_in_B;            //ALU input signals
    logic [31:0] alu_out;                       //ALU output
    logic [31:0] branch_target;                 //Branch target address
    logic [31:0] pc_in, pc_out;                 //Program counter signals
    logic [3:0]  wmask_out;                     //Write mask signal

    control_unit ctrl (
        .instr_i(instr_i),
        .B(B),
        .J(J),
        .ALUControl(ctrl_ALUControl),
        .rs1(ctrl_rs1),
        .rs2(ctrl_rs2),
        .rd(ctrl_rd),
        .we(ctrl_we),
        .rf_we(ctrl_rf_we),
        .ALU_sel_A(ctrl_ALU_sel_A),
        .ALU_sel_B(ctrl_ALU_sel_B),
        .data_size(ctrl_data_size),
        .WB_sel(ctrl_WB_sel),
        .JALR_sel(ctrl_JALR_sel),
        .imm(ctrl_imm)
    );

    register_file RF (
        .clk(clk_i),
        .rst(rstn_i),
        .rs1(ctrl_rs1),
        .rs2(ctrl_rs2),
        .rd(ctrl_rd),
        .we(ctrl_rf_we),
        .data_rd(data_rd),
        .data_rs1(data_rs1),
        .data_rs2(data_rs2)
    );

    assign data_rd = (ctrl_WB_sel) ? data_out_rf : alu_out;

    ALU ALU (
        .A(alu_in_A),
        .B(alu_in_B),
        .ALUControl(ctrl_ALUControl),
        .ALUResult(alu_out)
    );

    assign alu_in_A = (ctrl_ALU_sel_A) ? pc_out : data_rs1;
    assign alu_in_B = (ctrl_ALU_sel_B) ? ctrl_imm : data_rs2;

    PC programcounter (
        .clk(clk_i),
        .rst(rstn_i),
        .PC_in(pc_in),
        .PC_out(pc_out)
    );

    assign take_branch = (B & alu_out[0]) | J;
    assign branch_target = (ctrl_JALR_sel) ? data_rs1 + ctrl_imm : pc_out + ctrl_imm;
    assign pc_in = (take_branch) ? branch_target : pc_out + 4;

    LS_Unit LS (
        .data_in(data_rs2),
        .data_in_mem(data_in_mem),
        .data_size(ctrl_data_size),
        .data_out_rf(data_out_rf),
        .data_out_mem(data_out_mem),
        .wmask_out(wmask_out)
    );

    dmem #(.MEM_SIZE(MEM_SIZE)) dmem (
        .clk(clk_i),
        .rst(rstn_i),
        .addr(mem_addr_o),
        .we(ctrl_we),
        .data_in(data_out_mem),
        .data_out(data_in_mem),
        .data_wmask(wmask_out)
    );
    
    assign mem_data_o = data_out_mem;
    assign mem_addr_o = alu_out;
    assign reg_data_o = data_rd;
    assign reg_addr_o = ctrl_rd;
    assign pc_o = pc_out;

    initial
        $readmemh(DMemInitFile, dmem.memory, 0, MEM_SIZE);

    assign update_o = ~clk_i; //I don't know how correct this is
endmodule
