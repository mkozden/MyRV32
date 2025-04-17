.section .text.startup
.global _start

_start:
addi x1, x0, 5              # Load 5 into register x1
addi x2, x0, 10             # Load 10 into register x2
addi x3, x0, 20             # Load 20 into register x3
addi x4, x0, 30             # Load 30 into register x4
addi x5, x0, 40             # Load 40 into register x5

nop
nop
nop
nop
nop

sw x1, 0(x0)          # Store x1 at address 0
sw x2, 4(x0)          # Store x2 at address 4
sw x3, 8(x0)          # Store x3 at address 8
sw x4, 12(x0)         # Store x4 at address 12
sw x5, 16(x0)         # Store x5 at address 16

nop
nop
nop
nop
nop

lw x6, 0(x0)          # Load the value at address 0 into x6
lw x7, 4(x0)          # Load the value at address 4 into x7
lw x8, 8(x0)          # Load the value at address 8 into x8
lw x9, 12(x0)         # Load the value at address 12 into x9
lw x10, 16(x0)        # Load the value at address 16 into x10

nop
nop
nop
nop
nop
