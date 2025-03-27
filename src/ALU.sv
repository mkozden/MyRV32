module ALU (
    input logic [31:0] A,
    input logic [31:0] B,
    input logic [3:0] ALUControl,
    output logic [31:0] ALUResult
);
    logic [4:0] shamt; //For shift operations, only lower 5 bits are used
    assign shamt = B[4:0];

    always_comb begin
        case(ALUControl)
        4'b0000: ALUResult = A + B; // ADD
        4'b0001: ALUResult = A - B; // SUB
        4'b0010: ALUResult = A & B; // AND
        4'b0011: ALUResult = A | B; // OR
        4'b0100: ALUResult = A ^ B; // XOR
        4'b0101: ALUResult = A << shamt; // SLL
        4'b0110: ALUResult = A >> shamt; // SRL
        4'b0111: ALUResult = $signed(A) >>> shamt; // SRA - signed input since the msb is preserved
        4'b1000: ALUResult = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0; // SLT
        4'b1001: ALUResult = (A < B) ? 32'b1 : 32'b0; // SLTU
        4'b1010: ALUResult = (A == B) ? 32'b1 : 32'b0; // for BEQ
        4'b1011: ALUResult = (A != B) ? 32'b1 : 32'b0; // for BNE
        4'b1100: ALUResult = ($signed(A) >= $signed(B)) ? 32'b1 : 32'b0; // for BGT
        4'b1101: ALUResult = (A >= B) ? 32'b1 : 32'b0; // for BGTU
        4'b1110: ALUResult = A + 4; // Increment by 4 for PC+4 (JALR)
        4'b1111: ALUResult = B; // Pass through B, for LUI
        endcase
    end
endmodule