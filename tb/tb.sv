//`include "../src/pkg/riscv_pkg.sv"
module tb ();
  logic [riscv_pkg::XLEN-1:0] addr;
  logic [riscv_pkg::XLEN-1:0] data;
  logic [riscv_pkg::XLEN-1:0] pc;
  logic [riscv_pkg::XLEN-1:0] instr;
  logic [                4:0] reg_addr;
  logic [riscv_pkg::XLEN-1:0] reg_data;
  logic                       update;
  logic                       clk;
  logic                       rstn;

  logic [31:0] mem_addr, mem_data;

  riscv_singlecycle i_core_model (
      .clk_i(clk),
      .rstn_i(rstn),
      .addr_i(addr),
      .data_o(data),
      .update_o(update),
      .pc_o(pc),
      .instr_o(instr),
      .reg_addr_o(reg_addr),
      .reg_data_o(reg_data),
      .mem_addr_o(mem_addr),
      .mem_data_o(mem_data)


  );

  integer file_pointer;
  initial begin
    file_pointer = $fopen("model.log", "w");
    #4
    // forever begin
    //   if (update) begin
    //     if (reg_addr == 0) begin
    //       $fdisplay(file_pointer, "0x%8h (0x%8h)", pc, instr);
    //     end else begin
    //       if (reg_addr > 9) begin
    //         $fdisplay(file_pointer, "0x%8h (0x%8h) x%0d 0x%8h", pc, instr, reg_addr, reg_data);
    //       end else begin
    //         $fdisplay(file_pointer, "0x%8h (0x%8h) x%0d  0x%8h", pc, instr, reg_addr, reg_data);
    //       end
    //     end
    //     if (memaddr != 0 && memdata != 0) begin
    //       $fdisplay(file_pointer, "mem 0x%h 0x%h", mem_addr, mem_data);
    //     end
    //     #2;
    //   end
    // end
    forever begin
      if (update) begin
        $fdisplay(file_pointer, "x%0d 0x%16h", reg_addr, reg_data); // log the register file writes
        $fdisplay(file_pointer, "mem 0x%h 0x%h", mem_addr, mem_data); // log the data memory writes
        #2;
        end
      end
  end
  initial
    forever begin
      clk = 0;
      #1;
      clk = 1;
      #1;
    end
  initial begin
    rstn = 0;
    #4;
    rstn = 1;
    #10000;
    for (int i = 0; i < 10; i++) begin
      addr = i;
      $display("data @ mem[0x%8h] = %8h", addr, data);
    end
    $finish;
  end


  initial begin
    $dumpfile("dump.vcd");
    $dumpvars();
  end

endmodule
