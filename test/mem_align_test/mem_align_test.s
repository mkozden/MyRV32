.section .text.startup
.global _start

_start:
addi x1, x0, 0x1
addi x2, x0, 0x2
addi x3, x0, 0x3
addi x4, x0, 0x4

sb x1, 0(x0)
sb x2, 1(x0)
sb x3, 2(x0)
sb x4, 3(x0)

lw x5, 0(x0) #We expect to see 0x04030201

addi x6, x0, 0x111
addi x7, x0, 0x222

sh x6, 4(x0)
sh x7, 6(x0)

lw x8, 4(x0) #We expect to see 0x02220111

nop
nop
nop
nop
nop

lui x9, 0x12345
addi x9, x9, 0x678
sw x9, 8(x0) #We expect to see 0x12345678

lb x10, 8(x0) #We expect to see 0x78
lb x11, 9(x0) #We expect to see 0x56
lb x12, 10(x0) #We expect to see 0x34
lb x13, 11(x0) #We expect to see 0x12
