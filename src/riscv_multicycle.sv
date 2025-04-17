//`include "pkg/riscv_pkg.sv"
/* verilator lint_off IMPORTSTAR */
import riscv_pkg::*;

module riscv_multicycle #(
    parameter DMemInitFile  = "dmem.mem",       // data memory initialization file
    parameter IMemInitFile  = "imem.mem"       // instruction memory initialization file
)(
    input  logic             clk_i,       // system clock
    input  logic             rstn_i,      // system reset
    input  logic  [XLEN-1:0] addr_i,      // memory adddres input for reading
    output logic  [XLEN-1:0] data_o,      // memory data output for reading
    output logic             update_o,    // retire signal
    output logic  [XLEN-1:0] pc_o,        // retired program counter
    output logic  [XLEN-1:0] instr_o,     // retired instruction
    output logic  [     4:0] reg_addr_o,  // retired register address
    output logic  [XLEN-1:0] reg_data_o,  // retired register data
    output logic  [XLEN-1:0] mem_addr_o,  // retired memory address
    output logic  [XLEN-1:0] mem_data_o,  // retired memory data
    output logic             mem_wrt_o   // retired memory write enable signal
);
    parameter START_ADDR = 32'h8000_0000;
    parameter MEM_SIZE = 2048;



// INSTRUCTION FETCH (IF) STAGE
    //Stage internal signals, instantiations and assignments
    logic [31:0]     imem [MEM_SIZE-1:0];
    logic [31:0]     instr_i;
    logic take_branch;
    logic [31:0] branch_target;                 //Branch target address
    logic [31:0] pc_in, pc_out;                 //Program counter signals

    PC #(.START_ADDR(START_ADDR)) programcounter ( //So that the program counter starts at 0x8000_0000
        .clk(clk_i),
        .rst(rstn_i),
        .PC_in(pc_in),
        .PC_out(pc_out)
    );

    initial $readmemh(IMemInitFile, imem, 0, MEM_SIZE-1); //Must be in the root directory, which is where the makefile is
    
    assign instr_i          = imem[pc_out >> 2]; //Since the instruction memory is word-addressed, we need to shift the PC by 2 to get the correct index

    //Will be modified with the appropriate pipelined signals, then moved to the proper stage (Branch target is calculated in EX stage for example)
    assign take_branch      = (EX_B & EX_alu_out[0]) | EX_J;
    assign branch_target    = (EX_JALR_sel) ? EX_data_rs1 + EX_imm : EX_pc + EX_imm;
    assign pc_in            = (take_branch) ? branch_target : pc_out + 4; //This is kept the same?

    //Pipeline registers
    reg [31:0] IF_ID_reg_pc;
    reg [31:0] IF_ID_reg_instr;

    logic IF_ID_flush;
    logic IF_ID_stall;

    //Pipeline register assignments
    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            IF_ID_reg_pc        <= 0;
            IF_ID_reg_instr     <= 0;
        end else if (IF_ID_flush) begin
            IF_ID_reg_pc        <= 32'h0;
            IF_ID_reg_instr     <= 32'h0000_0013; //NOP instruction
        end else if (IF_ID_stall) begin
            IF_ID_reg_pc        <= IF_ID_reg_pc; //Hold the previous value (is this synthesizable?)    ***MIGHT NEED TO COMBINE FLUSH AND STALL LOGIC, AND JUST FLUSH***
            IF_ID_reg_instr     <= IF_ID_reg_instr;
        end else begin
            IF_ID_reg_pc        <= pc_out;
            IF_ID_reg_instr     <= instr_i;
        end
    end

// INSTRUCTION DECODE (ID) STAGE
    //Stage internal signals, instantiations and assignments (and those that come from the previous stage)
    logic B, J;                                 //Branch control signals
    logic [4:0] ctrl_ALUControl;                //ALU control signals
    logic [4:0] ctrl_rs1, ctrl_rs2, ctrl_rd;    //Register file select signals
    logic ctrl_we, ctrl_rf_we;                  //Write enable signals
    logic ctrl_ALU_sel_A, ctrl_ALU_sel_B;       //ALU operand select signals
    logic [2:0] ctrl_data_size;                 //Data size signal
    logic ctrl_WB_sel;                          //Register file writeback select signal
    logic ctrl_JALR_sel;                        //Select between PC+imm and rs1+imm for JAL/JALR/Branches
    logic [31:0] ctrl_imm;
    logic [31:0] data_rs1, data_rs2;   //Register file data signals

    //Signals from the WB stage
    logic [31:0] WB_data_rd;
    logic [4:0] WB_rd;
    logic WB_rf_we;

    logic [31:0] ID_instr;
    assign ID_instr     = IF_ID_reg_instr;

    control_unit ctrl (
        .instr_i(ID_instr),
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
        .rd(WB_rd),
        .we(WB_rf_we),
        .data_rd(WB_data_rd),
        .data_rs1(data_rs1),
        .data_rs2(data_rs2)
    );

    //Pipeline registers
    reg [31:0] ID_EX_reg_instr; //To obtain the retired instruction at the end of the pipeline
    reg [31:0] ID_EX_reg_pc;
    reg [4:0] ID_EX_reg_rs1;
    reg [4:0] ID_EX_reg_rs2;
    reg [4:0] ID_EX_reg_rd;
    reg [31:0] ID_EX_reg_imm;
    reg [31:0] ID_EX_reg_data_rs1;
    reg [31:0] ID_EX_reg_data_rs2;
    reg [4:0] ID_EX_reg_ALUControl;
    reg ID_EX_reg_B;    //Not sure if this is needed
    reg ID_EX_reg_J;    //Not sure if this is needed
    reg ID_EX_reg_we;
    reg ID_EX_reg_rf_we;
    reg ID_EX_reg_ALU_sel_A;
    reg ID_EX_reg_ALU_sel_B;
    reg [2:0] ID_EX_reg_data_size;
    reg ID_EX_reg_WB_sel;
    reg ID_EX_reg_JALR_sel;   //Not sure if this is needed
    
    logic ID_EX_flush;
    logic ID_EX_stall;

    //Pipeline register assignments
    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            ID_EX_reg_instr         <= 32'h0000_0013; //NOP
            ID_EX_reg_pc            <= 0;
            ID_EX_reg_rs1           <= 0;
            ID_EX_reg_rs2           <= 0;
            ID_EX_reg_rd            <= 0;
            ID_EX_reg_imm           <= 0;
            ID_EX_reg_data_rs1      <= 0;
            ID_EX_reg_data_rs2      <= 0;
            ID_EX_reg_ALUControl    <= 0;
            ID_EX_reg_B             <= 0;
            ID_EX_reg_J             <= 0;
            ID_EX_reg_we            <= 0;
            ID_EX_reg_rf_we         <= 0;
            ID_EX_reg_ALU_sel_A     <= 0;
            ID_EX_reg_ALU_sel_B     <= 0;
            ID_EX_reg_data_size     <= 0;
            ID_EX_reg_WB_sel        <= 0;
            ID_EX_reg_JALR_sel      <= 0; //Not sure if this is needed
        end else if (ID_EX_flush) begin //Basically the same as reset, let's still keep it
            ID_EX_reg_instr         <= 32'h0000_0013; //NOP
            ID_EX_reg_pc            <= 0;
            ID_EX_reg_rs1           <= 0;
            ID_EX_reg_rs2           <= 0;
            ID_EX_reg_rd            <= 0;
            ID_EX_reg_imm           <= 0;
            ID_EX_reg_data_rs1      <= 0;
            ID_EX_reg_data_rs2      <= 0;
            ID_EX_reg_ALUControl    <= 0;
            ID_EX_reg_B             <= 0;
            ID_EX_reg_J             <= 0;
            ID_EX_reg_we            <= 0;
            ID_EX_reg_rf_we         <= 0;
            ID_EX_reg_ALU_sel_A     <= 0;
            ID_EX_reg_ALU_sel_B     <= 0;
            ID_EX_reg_data_size     <= 0;
            ID_EX_reg_WB_sel        <= 0;
            ID_EX_reg_JALR_sel      <= 0; //Not sure if this is needed
        end else if (ID_EX_stall) begin
            ID_EX_reg_instr         <= ID_EX_reg_instr; //Hold the previous value (is this synthesizable?)
            ID_EX_reg_pc            <= ID_EX_reg_pc;
            ID_EX_reg_rs1           <= ID_EX_reg_rs1;
            ID_EX_reg_rs2           <= ID_EX_reg_rs2;
            ID_EX_reg_rd            <= ID_EX_reg_rd;
            ID_EX_reg_imm           <= ID_EX_reg_imm;
            ID_EX_reg_data_rs1      <= ID_EX_reg_data_rs1;
            ID_EX_reg_data_rs2      <= ID_EX_reg_data_rs2;
            ID_EX_reg_ALUControl    <= ID_EX_reg_ALUControl;
            ID_EX_reg_B             <= ID_EX_reg_B;    //Not sure if this is needed
            ID_EX_reg_J             <= ID_EX_reg_J;    //Not sure if this is needed
            ID_EX_reg_we            <= ID_EX_reg_we;
            ID_EX_reg_rf_we         <= ID_EX_reg_rf_we;
            ID_EX_reg_ALU_sel_A     <= ID_EX_reg_ALU_sel_A;
            ID_EX_reg_ALU_sel_B     <= ID_EX_reg_ALU_sel_B;
            ID_EX_reg_data_size     <= ID_EX_reg_data_size;
            ID_EX_reg_WB_sel        <= ID_EX_reg_WB_sel;
            ID_EX_reg_JALR_sel      <= ID_EX_reg_JALR_sel; //Not sure if this is needed
        end else begin
            ID_EX_reg_instr         <= ID_instr;
            ID_EX_reg_pc            <= IF_ID_reg_pc;
            ID_EX_reg_rs1           <= ctrl_rs1;
            ID_EX_reg_rs2           <= ctrl_rs2;
            ID_EX_reg_rd            <= ctrl_rd;
            ID_EX_reg_imm           <= ctrl_imm;
            ID_EX_reg_data_rs1      <= data_rs1;
            ID_EX_reg_data_rs2      <= data_rs2;
            ID_EX_reg_ALUControl    <= ctrl_ALUControl;
            ID_EX_reg_B             <= B;    //Not sure if this is needed
            ID_EX_reg_J             <= J;    //Not sure if this is needed
            ID_EX_reg_we            <= ctrl_we;
            ID_EX_reg_rf_we         <= ctrl_rf_we;
            ID_EX_reg_ALU_sel_A     <= ctrl_ALU_sel_A;
            ID_EX_reg_ALU_sel_B     <= ctrl_ALU_sel_B;
            ID_EX_reg_data_size     <= ctrl_data_size;
            ID_EX_reg_WB_sel        <= ctrl_WB_sel;
        end
    end
// EXECUTE (EX) STAGE
    //Stage internal signals, instantiations and assignments (and those that come from the previous stage)
    logic [31:0] alu_in_A, alu_in_B;                //ALU operand signals
    logic [31:0] EX_data_rs1, EX_data_rs2;          //Data signals from the previous stage
    logic [31:0] EX_imm;
    logic [31:0] EX_pc;
    logic [31:0] EX_alu_out;                        //ALU output
    logic [4:0] EX_ALUControl;
    logic [2:0] EX_data_size;                       //Data size signal
    logic EX_we;                                   //Write enable signal

    logic EX_ALU_sel_A, EX_ALU_sel_B;               //ALU operand select signals
    logic EX_B, EX_J, EX_JALR_sel;                  //Branch control signals

    assign EX_data_rs1     = ID_EX_reg_data_rs1;
    assign EX_data_rs2     = ID_EX_reg_data_rs2;
    assign EX_ALUControl   = ID_EX_reg_ALUControl;
    assign EX_ALU_sel_A    = ID_EX_reg_ALU_sel_A;
    assign EX_ALU_sel_B    = ID_EX_reg_ALU_sel_B;
    assign EX_imm          = ID_EX_reg_imm;
    assign EX_pc           = ID_EX_reg_pc;
    assign EX_B            = ID_EX_reg_B;
    assign EX_J            = ID_EX_reg_J;
    assign EX_JALR_sel     = ID_EX_reg_JALR_sel;
    assign EX_we           = ID_EX_reg_we;
    assign EX_data_size    = ID_EX_reg_data_size;

    ALU ALU (
        .A(alu_in_A),
        .B(alu_in_B),
        .ALUControl(EX_ALUControl),
        .ALUResult(EX_alu_out)
    );

    assign alu_in_A     = (EX_ALU_sel_A) ? EX_pc : EX_data_rs1;
    assign alu_in_B     = (EX_ALU_sel_B) ? EX_imm : EX_data_rs2;

    //Pipeline registers
    reg [31:0] EX_MEM_reg_instr; //To obtain the retired instruction at the end of the pipeline
    reg [31:0] EX_MEM_reg_pc;
    reg [4:0] EX_MEM_reg_rd;
    reg [31:0] EX_MEM_reg_alu_out;
    reg [31:0] EX_MEM_reg_data_rs2;
    reg EX_MEM_reg_we;
    reg EX_MEM_reg_rf_we;
    reg [2:0] EX_MEM_reg_data_size;
    reg EX_MEM_reg_WB_sel;
    //reg EX_MEM_reg_JALR_sel; //Not sure if this is needed
    //reg EX_MEM_reg_B;    //Not sure if this is needed
    //reg EX_MEM_reg_J;    //Not sure if this is needed

    logic EX_MEM_flush;
    logic EX_MEM_stall;

    //Pipeline register assignments
    always_ff @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            EX_MEM_reg_instr         <= 32'h0000_0013; //NOP
            EX_MEM_reg_pc            <= 0;
            EX_MEM_reg_rd            <= 0;
            EX_MEM_reg_alu_out       <= 0;
            EX_MEM_reg_data_rs2      <= 0;
            EX_MEM_reg_we            <= 0;
            EX_MEM_reg_rf_we         <= 0;
            EX_MEM_reg_data_size     <= 0;
            EX_MEM_reg_WB_sel        <= 0;
        end else if (EX_MEM_flush) begin //Basically the same as reset, let's still keep it
            EX_MEM_reg_instr         <= 32'h0000_0013; //NOP
            EX_MEM_reg_pc            <= 0;
            EX_MEM_reg_rd            <= 0;
            EX_MEM_reg_alu_out       <= 0;
            EX_MEM_reg_data_rs2      <= 0;
            EX_MEM_reg_we            <= 0;
            EX_MEM_reg_rf_we         <= 0;
            EX_MEM_reg_data_size     <= 0;
            EX_MEM_reg_WB_sel        <= 0;
        end else if (EX_MEM_stall) begin
            EX_MEM_reg_instr         <= EX_MEM_reg_instr; //Hold the previous value (is this synthesizable?)
            EX_MEM_reg_pc            <= EX_MEM_reg_pc;
            EX_MEM_reg_rd            <= EX_MEM_reg_rd;
            EX_MEM_reg_alu_out       <= EX_MEM_reg_alu_out;
            EX_MEM_reg_data_rs2      <= EX_MEM_reg_data_rs2;
            EX_MEM_reg_we            <= EX_MEM_reg_we;
            EX_MEM_reg_rf_we         <= EX_MEM_reg_rf_we;
            EX_MEM_reg_data_size     <= ID_EX_reg_data_size;
            EX_MEM_reg_WB_sel        <= ID_EX_reg_WB_sel;
        end else begin
            EX_MEM_reg_instr         <= ID_EX_reg_instr; 
            EX_MEM_reg_pc            <= ID_EX_reg_pc;
            EX_MEM_reg_rd            <= ID_EX_reg_rd;
            EX_MEM_reg_alu_out       <= EX_alu_out;
            EX_MEM_reg_data_rs2      <= EX_data_rs2;
            EX_MEM_reg_we            <= ID_EX_reg_we;
            EX_MEM_reg_rf_we         <= ID_EX_reg_rf_we;
            EX_MEM_reg_data_size     <= ID_EX_reg_data_size;
            EX_MEM_reg_WB_sel        <= ID_EX_reg_WB_sel;
        end
    end
// MEMORY (MEM) STAGE
    //Stage internal signals, instantiations and assignments (and those that come from the previous stage)
    logic [31:0] MEM_alu_out;
    logic [31:0] MEM_data_rs2;
    logic MEM_we;
    logic [2:0] MEM_data_size;
    // Memory data signals
    logic [31:0] data_in_mem;                   //Data from memory
    logic [31:0] data_out_rf, data_out_mem;     //Data going to register file and memory
    logic [3:0]  wmask_out;                     //Write mask signal

    assign MEM_alu_out          = EX_MEM_reg_alu_out;
    assign MEM_data_rs2         = EX_MEM_reg_data_rs2;
    assign MEM_we               = EX_MEM_reg_we;
    assign MEM_data_size        = EX_MEM_reg_data_size;

    LS_Unit LS (
        .data_in(MEM_data_rs2),
        .data_in_mem(data_in_mem),
        .data_size(MEM_data_size),
        .data_out_rf(data_out_rf),
        .data_out_mem(data_out_mem),
        .wmask_out(wmask_out)
    );

    dmem #(.MEM_SIZE(MEM_SIZE)) dmem (
        .clk(clk_i),
        .rst(rstn_i),
        .addr(MEM_alu_out),
        .we(MEM_we),
        .data_in(data_out_mem),
        .data_out(data_in_mem),
        .data_wmask(wmask_out)
    );
    initial $readmemh(DMemInitFile, dmem.memory, 0, MEM_SIZE-1); //Must be in the root directory, which is where the makefile is

    //Pipeline registers
    reg [31:0] MEM_WB_instr; //To obtain the retired instruction at the end of the pipeline
    reg [31:0] MEM_WB_reg_pc;
    reg [4:0] MEM_WB_reg_rd;
    reg [31:0] MEM_WB_reg_data_out_rf;
    reg [31:0] MEM_WB_reg_alu_out;
    reg MEM_WB_reg_we;
    reg MEM_WB_reg_rf_we;
    reg MEM_WB_reg_WB_sel;

    logic MEM_WB_flush;
    logic MEM_WB_stall;

    //Pipeline register assignments
    always_ff @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i)begin
            MEM_WB_instr            <= 32'h0000_0013; //NOP
            MEM_WB_reg_pc           <= 0;
            MEM_WB_reg_rd           <= 0;
            MEM_WB_reg_data_out_rf  <= 0;
            MEM_WB_reg_alu_out      <= 0;
            MEM_WB_reg_we           <= 0;
            MEM_WB_reg_rf_we        <= 0;
            MEM_WB_reg_WB_sel       <= 0;
        end else if (MEM_WB_flush) begin //Basically the same as reset, let's still keep it
            MEM_WB_instr            <= 32'h0000_0013; //NOP
            MEM_WB_reg_pc           <= 0;
            MEM_WB_reg_rd           <= 0;
            MEM_WB_reg_data_out_rf  <= 0;
            MEM_WB_reg_alu_out      <= 0;
            MEM_WB_reg_we           <= 0;
            MEM_WB_reg_rf_we        <= 0;
            MEM_WB_reg_WB_sel       <= 0;
        end else if (MEM_WB_stall) begin
            MEM_WB_instr            <= MEM_WB_instr; //Hold the previous value (is this synthesizable?)
            MEM_WB_reg_pc           <= MEM_WB_reg_pc;
            MEM_WB_reg_rd           <= MEM_WB_reg_rd;
            MEM_WB_reg_data_out_rf  <= MEM_WB_reg_data_out_rf;
            MEM_WB_reg_alu_out      <= MEM_WB_reg_alu_out;
            MEM_WB_reg_we           <= MEM_WB_reg_we;
            MEM_WB_reg_rf_we        <= MEM_WB_reg_rf_we;
            MEM_WB_reg_WB_sel       <= EX_MEM_reg_WB_sel;
        end else begin
            MEM_WB_instr            <= EX_MEM_reg_instr; 
            MEM_WB_reg_pc           <= EX_MEM_reg_pc;
            MEM_WB_reg_rd           <= EX_MEM_reg_rd;
            MEM_WB_reg_data_out_rf  <= data_out_rf; 
            MEM_WB_reg_alu_out      <= MEM_alu_out;
            MEM_WB_reg_we           <= MEM_we;
            MEM_WB_reg_rf_we        <= EX_MEM_reg_rf_we;
            MEM_WB_reg_WB_sel       <= EX_MEM_reg_WB_sel;
        end 
    end
// WRITE BACK (WB) STAGE
    //Stage internal signals, instantiations and assignments (and those that come from the previous stage)
    logic [31:0] WB_alu_out;
    logic [31:0] WB_data_out_rf;
    logic WB_WB_sel;

    logic [31:0] WB_instr, WB_pc;

    assign WB_alu_out               = MEM_WB_reg_alu_out;
    assign WB_data_out_rf           = MEM_WB_reg_data_out_rf;
    assign WB_WB_sel                = MEM_WB_reg_WB_sel;
    assign WB_rd                    = MEM_WB_reg_rd;
    assign WB_rf_we                 = MEM_WB_reg_rf_we;

    assign WB_data_rd               = (WB_WB_sel) ? WB_data_out_rf : WB_alu_out; //TO THE REGISTER FILE, MODIFY SIGNALS ACCORDINGLY

    assign WB_instr                 = MEM_WB_instr;
    assign WB_pc                    = MEM_WB_reg_pc;

//INSTANTIATION OF THE PIPELINE CONTROL UNIT (HAZARD/FORWARDING)

//Temporarily, let's give 0 for all flush and stall signals
    assign IF_ID_flush          = 0;
    assign IF_ID_stall          = 0;
    assign ID_EX_flush          = 0;
    assign ID_EX_stall          = 0;
    assign EX_MEM_flush         = 0;
    assign EX_MEM_stall         = 0;
    assign MEM_WB_flush         = 0;
    assign MEM_WB_stall         = 0;


//OUTPUT SIGNAL ASSIGNMENTS

    assign mem_data_o = {32{MEM_we}} & data_out_mem; //Return this only if memory is being written to
    assign mem_addr_o = {32{MEM_we}} & MEM_alu_out;
    assign mem_wrt_o = MEM_we;
    assign reg_data_o = {32{WB_rf_we}} & WB_data_rd; //Return this only if the register file is being written to
    assign reg_addr_o = {5{WB_rf_we}} & WB_rd;
    assign pc_o = WB_pc;
    assign instr_o = WB_instr;

    assign data_o = dmem.memory[addr_i>>2]; //I believe this is what the testbench does

    assign update_o = ~clk_i; //I don't know how correct this is, might need to replace with a signal that travels through the pipeline, maybe use a "dummy" signal for pipelines that get flushed

endmodule
