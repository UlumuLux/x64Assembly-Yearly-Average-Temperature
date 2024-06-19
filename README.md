# x64Assembly-Yearly-Average-Temperature
Read in a file with temperatures and calculate the average for a year

Usage: CREATED WITH NASM ASSEMBLER

1. create object code file (with debug info) as follows:
nasm -f elf64 -g -F dwarf temperature_avg.asm

2. Link object code as follows:
ld -o temperature_avg temperature_avg.o

3. run
./temperature_avg < input_test.txt
