import riscv_pkg::*;

module pipeline_controller (
    input logic MEM_rf_we, WB_rf_we, //Write enable signals from EX, MEM, and WB stages
    input logic [4:0] ID_rs1, EX_rs1, //Source register 1
    input logic [4:0] ID_rs2, EX_rs2, //Source register 2
    input logic [4:0] EX_rd, MEM_rd, WB_rd,   //Destination register from EX, MEM, and WB stages
    input logic EX_B,//Branch signal from EX
    input logic EX_J, //Jump signal from EX
    input logic alu_out_zero, //ALU output first bit, to check for branch
    input logic [6:0] ID_opcode, EX_opcode, //Opcode from EX stage, to check for load
    output logic IF_ID_flush, IF_ID_stall,
    output logic ID_EX_stall, ID_EX_flush,
    output logic EX_MEM_stall, EX_MEM_flush,
    output logic MEM_WB_stall, MEM_WB_flush,
    output logic [1:0] alu_in_A_fwd, alu_in_B_fwd //Forwarding signals for ALU inputs
);

    logic take_branch;
    assign take_branch = (EX_B & alu_out_zero) | EX_J;

    //Stalls are necessary when the instruction in EX is a load and the instruction in ID is a use of the same register
    logic is_load;
    assign is_load = (EX_opcode == OpcodeLoad); //Load opcode declared in riscv_pkg.sv

    //When rs1 or rs2 is not used in the instrcution format, we ignored it, but that can cause false positives here and cause the pipeline to stall when it shouldn't. So we should check opcode in ID as well
    //Some instructions only use rs1, some only use rs2, and some use both. We should check for all these cases
    logic rs1_used, rs2_used;
    assign rs1_used = (ID_opcode == OpcodeOpImm) || (ID_opcode == OpcodeOp) || (ID_opcode == OpcodeJalr) || (ID_opcode == OpcodeBranch) || (ID_opcode == OpcodeStore) || (ID_opcode == OpcodeLoad);
    assign rs2_used = (ID_opcode == OpcodeOp) || (ID_opcode == OpcodeBranch) || (ID_opcode == OpcodeStore);

always_comb begin
    //Forwarding signals
    //For 00: No forwarding
    //For 01: Forward from MEM stage
    //For 10: Forward from WB stage

    //We check MEM first, since it's the most recent instruction. Only if MEM is not a valid source, we check WB

    if(MEM_rf_we) begin                                                         //If instruction in MEM writes to reg. file, it's a valid source for forwarding
        //rs1
        if((MEM_rd == EX_rs1) && (EX_rs1 != 0)) alu_in_A_fwd = 2'b01;           //Forward from MEM stage

        else if(WB_rf_we) begin                                                 //If MEM stage is not a valid source, check WB stage
            if((WB_rd == EX_rs1) && (EX_rs1 != 0)) alu_in_A_fwd = 2'b10;        //Forward from WB stage
            else alu_in_A_fwd = 2'b00;                                          //No forwarding
        end

        else alu_in_A_fwd = 2'b00;                                              //No forwarding

        //rs2
        if((MEM_rd == EX_rs2) && (EX_rs2 != 0)) alu_in_B_fwd = 2'b01;           //Forward from MEM stage

        else if(WB_rf_we) begin                                                 //If MEM stage is not a valid source, check WB stage
            if((WB_rd == EX_rs2) && (EX_rs2 != 0)) alu_in_B_fwd = 2'b10;        //Forward from WB stage
            else alu_in_B_fwd = 2'b00;                                          //No forwarding
        end

        else alu_in_B_fwd = 2'b00;                                              //No forwarding
    end 

    else if(WB_rf_we) begin                                                     //If instruction in WB writes to reg. file, it's a valid source for forwarding
        //rs1
        if((WB_rd == EX_rs1) && (EX_rs1 != 0)) alu_in_A_fwd = 2'b10;            //Forward from WB stage
        else alu_in_A_fwd = 2'b00;                                              //No forwarding

        //rs2
        if((WB_rd == EX_rs2) && (EX_rs2 != 0)) alu_in_B_fwd = 2'b10;            //Forward from WB stage
        else alu_in_B_fwd = 2'b00;                                              //No forwarding
    end 

    else begin
        alu_in_A_fwd = 2'b00;                                                   //No forwarding
        alu_in_B_fwd = 2'b00;                                                   //No forwarding
    end

    //Flush signals
    EX_MEM_flush = 1'b0; //As far as I know, these pipeline registers are not flushed (except when we have branch prediction ?)
    MEM_WB_flush = 1'b0;

    if(take_branch) begin
        IF_ID_flush = 1'b1; //Flush the IF/ID pipeline register
        ID_EX_flush = 1'b1; //Flush the ID/EX pipeline register
    end
    else begin
        IF_ID_flush = 1'b0;
        ID_EX_flush = 1'b0;
    end

    //Stall signals (Also check for whether forwarding can be done, if so don't stall) (BEWARE OF LOAD-USE HAZARD, IF LOAD IN MEM AND USE IN EX, STALL AND FORWARD FROM WB IN THE NEXT CYCLE, (WHEN YOU DO THIS, MAKE SURE THE CORRECT DATA IS FORWARDED))
    EX_MEM_stall = 1'b0; //As far as I know, these pipeline registers are not stalled
    MEM_WB_stall = 1'b0;

    
    if(is_load) begin
        if((EX_rd == ID_rs1) && (ID_rs1 != 0) && rs1_used) begin
            ID_EX_stall = 1'b1; //Stall the ID/EX pipeline register
            IF_ID_stall = 1'b1; //Stall the IF/ID pipeline register
        end
        else if((EX_rd == ID_rs2) && (ID_rs2 != 0) && rs2_used) begin
            ID_EX_stall = 1'b1; //Stall the ID/EX pipeline register
            IF_ID_stall = 1'b1; //Stall the IF/ID pipeline register
        end
        else begin
            ID_EX_stall = 1'b0;
            IF_ID_stall = 1'b0;
        end
    end
    else begin
        ID_EX_stall = 1'b0;
        IF_ID_stall = 1'b0;
    end
end
endmodule
