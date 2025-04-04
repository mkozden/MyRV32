module ALU (
    input logic [31:0] A,
    input logic [31:0] B,
    input logic [4:0] ALUControl,
    output logic [31:0] ALUResult
);
    logic [4:0] shamt; //For shift operations, only lower 5 bits are used
    assign shamt = B[4:0];

    //Used for counting leading/trailing zeros
    logic[15:0] val16_t;
    logic[7:0] val8_t;
    logic[3:0] val4_t;
    logic[15:0] val16_l;
    logic[7:0] val8_l;
    logic[3:0] val4_l;
    
    //Used for counting 1s
    logic [1:0] sum2 [15:0];  // 16 groups of 2-bit sums
    logic [2:0] sum4 [7:0];   // 8 groups of 3-bit sums
    logic [3:0] sum8 [3:0];   // 4 groups of 4-bit sums
    logic [4:0] sum16 [1:0];  // 2 groups of 5-bit sums
    logic [5:0] sum32;        // Final 6-bit result
    genvar i;

    // Bit summing tree

    // First level: Count bits in groups of 2
    generate
        for (i = 0; i < 16; i = i + 1) begin
            assign sum2[i] = A[2*i] + A[2*i+1];
        end
    endgenerate

    // Second level: Count bits in groups of 4
    generate
        for (i = 0; i < 8; i = i + 1) begin
            assign sum4[i] = sum2[2*i] + sum2[2*i+1];
        end
    endgenerate

    // Third level: Count bits in groups of 8
    generate
        for (i = 0; i < 4; i = i + 1) begin
            assign sum8[i] = sum4[2*i] + sum4[2*i+1];
        end
    endgenerate

    // Fourth level: Count bits in groups of 16
    generate
        for (i = 0; i < 2; i = i + 1) begin
            assign sum16[i] = sum8[2*i] + sum8[2*i+1];
        end
    endgenerate

    // Fifth level: Final sum
    assign sum32 = sum16[0] + sum16[1];

    always_comb begin
        // Default values to prevent latch inference
        val16_l = 16'b0;
        val8_l = 8'b0;
        val4_l = 4'b0;
        val16_t = 16'b0;
        val8_t = 8'b0;
        val4_t = 4'b0;

        case(ALUControl)
        5'b00000: ALUResult = A + B; // ADD
        5'b00001: ALUResult = A - B; // SUB
        5'b00010: ALUResult = A & B; // AND
        5'b00011: ALUResult = A | B; // OR
        5'b00100: ALUResult = A ^ B; // XOR
        5'b00101: ALUResult = A << shamt; // SLL
        5'b00110: ALUResult = A >> shamt; // SRL
        5'b00111: ALUResult = $signed(A) >>> shamt; // SRA - signed input since the msb is preserved
        5'b01000: ALUResult = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0; // SLT
        5'b01001: ALUResult = (A < B) ? 32'b1 : 32'b0; // SLTU
        5'b01010: ALUResult = (A == B) ? 32'b1 : 32'b0; // for BEQ
        5'b01011: ALUResult = (A != B) ? 32'b1 : 32'b0; // for BNE
        5'b01100: ALUResult = ($signed(A) >= $signed(B)) ? 32'b1 : 32'b0; // for BGE
        5'b01101: ALUResult = (A >= B) ? 32'b1 : 32'b0; // for BGEU
        5'b01110: ALUResult = A + 4; // Increment by 4 for PC+4 (JAL/R)
        5'b01111: ALUResult = B; // Pass through B, for LUI

        5'b10000: ALUResult = {26'b0, sum32}; //Count 1s
        5'b10001: begin //Count leading zeros
            ALUResult[31:6] = 26'b0; //The count can't exceed 32

            if (A == 0) begin
                ALUResult[5:0] = 6'b100000; //If A is 0, all bits (32) are leading zeros
            end else begin
                ALUResult[5] = 1'b0;
                ALUResult[4] = (A[31:16] == 16'b0); //If the upper half is 0, then there's at least 16 leading zeros
                val16_l    = ALUResult[4] ? A[15:0] : A[31:16]; //If the upper half is 0, we take the lower half
                ALUResult[3] = (val16_l[15:8] == 8'b0); //If the upper half of val16 is 0, then there's at least 8 more leading zeros
                val8_l     = ALUResult[3] ? val16_l[7:0] : val16_l[15:8];
                ALUResult[2] = (val8_l[7:4] == 4'b0);
                val4_l     = ALUResult[2] ? val8_l[3:0] : val8_l[7:4];
                ALUResult[1] = (val4_l[3:2] == 2'b0);
                ALUResult[0] = ALUResult[1] ? ~val4_l[1] : ~val4_l[3]; //If the upper half of val4 is 0, then 1st bit determines the count, else the 3rd bit
            end
        end
        5'b10010: begin //Count trailing zeros, similar to above (not 100% sure tho)
            ALUResult[31:6] = 26'b0; //The count can't exceed 32
            if (A == 0) begin
                ALUResult[5:0] = 6'b100000; //If A is 0, all bits (32) are trailing zeros
            end else begin
                ALUResult[5] = 1'b0;
                ALUResult[4] = (A[15:0] == 16'b0); //If the lower half is 0, then there's at least 16 trailing zeros
                val16_t    = ALUResult[4] ? A[31:16] : A[15:0]; //If the lower half is 0, we take the upper half
                ALUResult[3] = (val16_t[7:0] == 8'b0); //If the lower half of val16 is 0, then there's at least 8 more trailing zeros
                val8_t     = ALUResult[3] ? val16_t[15:8] : val16_t[7:0];
                ALUResult[2] = (val8_t[3:0] == 4'b0);
                val4_t     = ALUResult[2] ? val8_t[7:4] : val8_t[3:0];
                ALUResult[1] = (val4_t[1:0] == 2'b0);
                ALUResult[0] = ALUResult[1] ? ~val4_t[3] : ~val4_t[1]; //If the lower half of val4 is 0, then 1st bit determines the count, else the 3rd bit
            end
        end

        default: ALUResult = 32'b0; //Default case, shouldn't happen for legal instructions
        endcase
    end
endmodule
