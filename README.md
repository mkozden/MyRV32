# MTH410E – RISC-V Architecture and Processor Design

## Single Cycle RISC-V Processor

Write a SystemVerilog code of a single cycle RISC-V processor. The designed micro-architecture should include all the instructions in RV32I (It is in the [riscv-spec](https://github.com/riscv/riscv-isa-manual/releases/download/riscv-isa-release-bb8b912-2025-03-21/riscv-privileged.pdf)). The processor should work as in-order and single-issue. There is no need for FENCE, FENCE.TSO, PAUSE, ECALL, EBREAK instruction implementation. Additional to the RV32I, [CTZ](https://riscv-software-src.github.io/riscv-unified-db/manual/html/isa/isa_20240411/insts/ctz.html), [CLZ](https://riscv-software-src.github.io/riscv-unified-db/manual/html/isa/isa_20240411/insts/clz.html), and [CPOP](https://riscv-software-src.github.io/riscv-unified-db/manual/html/isa/isa_20240411/insts/cpop.html) must be implemented too.

The top file of the processor should be as follows;

```
module riscv_singlecycle
  import riscv_pkg::*;
(
    parameter DMemInitFile  = “dmem.mem”;       // data memory initialization file
    parameter IMemInitFile  = “imem.mem”;       // instruction memory initialization file
)   (
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
);
  // module body
  // use other modules according to the need.

endmodule
```

The data and instruction memories of the processor should be initialized by DMemInitFile and  IMemInitFile respectively (i.e., use $readmemh in the initial block of the memories).

To trace the processor state, RF write and DMEM write operations should be logged to LogFile. Therefore, following two functions should be used in RF and DMEM modules to track the written values. You can change the signal names (e.g., rf_idx_dec) with respect to your signal names.

```
$fwrite(LogFile, "x%0d 0x%16h", rf_idx_dec, rf_data_hex); // log the register file writes
$fwrite(LogFile, "mem 0x%h 0x%h", dmem_idx_dec, dmem_data_hex); // log the data memory writes
```
Some resources:
- [RISC-V: An Overview of the Instruction Set Architecture](https://web.cecs.pdx.edu/~harry/riscv/RISCV-Summary.pdf)
- [RISC-V Specification](https://github.com/riscv/riscv-isa-manual/releases/download/riscv-isa-release-bb8b912-2025-03-21/riscv-privileged.pdf)


Tasks:

1. Complete your RTL in SystemVerilog.
2. Clean all lint problems.
3. Run the example in the test folder.
4. Find other test and check (there will be other test cases to check).
