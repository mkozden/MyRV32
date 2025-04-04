.section .text
.global _start

_start:
li t0, 5              # Load 5 into register t0
li t1, 10             # Load 10 into register t1

# Perform addition
add t2, t0, t1        # t2 = t0 + t1

# Store the result at memory address 1
li t3, 216            # Load address of 'result' into t3
sw t2, 4(t3)          # Store t2 at t3+4 (220)

# Insert a few no-operation instructions
nop
nop

# Read the data from the stored address
lw t4, 4(t3)          # Load the value at address in t3+4 into t4

# Perform an operation with the loaded data (e.g., multiply by 2)
sll t5, t4, t1        # shift t4 left by 10 bits (multiply by 1024) and store in t5

sb t5, 0(t3)          # Store the first 8-bits of the result back to the address in t3 (should be 0)
lh t6, 0(t3)          # Load the halfword from the address in t3 into t6 (should also be 0)

cpop a1, t5           # Count bits in t5 and store in a1
clz  a2, t5           # Count leading zeros in t5 and store in a2
ctz  a3, t5           # Count trailing zeros in t5 and store in a3
cpop a4, t6           # Count bits in t6 and store in a4
clz  a5, t6           # Count leading zeros in t6 and store in a5
ctz  a6, t6           # Count trailing zeros in t6 and store in a6

not t6, t6              # Bitwise NOT operation on t6 and store in t7, so t7 should be 32'hFFFFFFFF

cpop a4, t6           # Count bits in t7 and store in a7
clz  a5, t6           # Count leading zeros in t7 and store in a8
ctz  a6, t6           # Count trailing zeros in t7 and store in a9
