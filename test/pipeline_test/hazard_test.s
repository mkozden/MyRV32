.section .text.startup
.global _start

_start:
addi x1, x0, 0x1
addi x2, x0, 0x2
addi x3, x0, 0x3
addi x4, x0, 0x4
addi x5, x0, 0x5

sw x1, 0(x0)
sw x2, 4(x0)
sw x3, 8(x0)
sw x4, 12(x0)
sw x5, 16(x0)

lw x6, 0(x0)
sll x7, x6, 1 #Should give 2
lw x8, 4(x0)
sll x9, x8, 1 #Should give 4
beq x9, x4, is_equal
addi x10, x0, 0x0 #If not equal, set x10 to 0
j done
is_equal:
addi x10, x0, 0x1 #If equal, set x10 to 1 (SHOULD BE EXECUTED)
done:
nop
nop
nop
lw x11, 0(x0) #Loading 1 from memory
bne x11, x1, isnot_equal2 #Should stall because of load-use, but also flush because branch (?)
lw x12, 20(x0)
addi x12, x12, 0x1 #If not equal, set x12 to 1 (Doing it in this roundabout way to create a hazard)
j done2
isnot_equal2:
addi x12, x0, 0x1 #We don't expect this result
done2:
nop
nop
nop

