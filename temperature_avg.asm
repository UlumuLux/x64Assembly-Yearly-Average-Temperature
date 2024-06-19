section .bss
  BUFFLEN equ 7        ; needed buffer length
  Buffer  resb BUFFLEN ; buffer to read 7 bytes at a time from file

section .data
  Digits db 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 ; digits to fetch for ASCII to int conversion
                                         ; offset will be calculated by subtracting ASCII val from 57
                                         ; which represents the value 9
                                         ; example: 57 (9) - 53 (5) = 4 which will get the value 5 from digits

  Summation: db "The yearly average temperature is: " ; result message
  SummationLen equ $-Summation                        ; result message length for syscall

  ReadErrMsg: db "Could not read from file!", 10      ; error message for read
  REMLEN equ $-ReadErrMsg                             ; msg length for syscall

  WriteErrMsg: db "Could not write val!", 10          ; error message for write
  WEMLEN equ $-WriteErrMsg                            ; msg length for syscall

  RESULT db "00", 10				      ; prepared result display

section .text
global _start

_start:
        xor r9, r9 ; clear r9 which will hold the sum

	ReadInput:
		; Read in first 7 bytes drom file
		mov rax, 0	 ; read_call
		mov rdi, 0	 ; file descriptor
		mov rsi, Buffer  ; buffer offset
		mov rdx, BUFFLEN ; bytes to read
		syscall

		cmp rax, 0	 ; to check for EOF
		je CalcAvg	 ; if EOF -> calculate average
		jb ReadError     ; if lower than 0 -> show read error

                xor rdx, rdx     	; clear rdx
		mov dl, byte [Buffer+4] ; move first temperature digit into dl
                call ConvertToInt1      ; call convert routine
		cmp dl, 0               ; check if val is 0 -> jump to check second val, if not, multiply by 10
		je SecondVal            ; jumpt to get second temperature value

		mov rax, 10 		; move 10 into multiply register
		mul dl    		; multiply first val by 10
                mov dl, al		; move result into dl

	SecondVal:
		; Get second temperature value from input
                xor rbx, rbx		; clear rbx
		mov bl, byte [Buffer+5]	; move second temperature digit into bl
                call ConvertToInt2      ; call convert routine for second val
		add rbx, rdx            ; add values together
		add r9, rbx             ; store sum in r9 register

		jmp ReadInput           ; go to read next 7 bytes

        ConvertToInt1:
		; Convert first ASCII value to actual number
                mov al, 57		  ; move ASCII 57 (9) into al
                sub al, dl		  ; subtract ASCII value of digit to get the number value
                mov dl, byte [Digits+rax] ; move first number into dl by fetching it with offset from Digits

                ret			  ; return ConvertToInt1

        ConvertToInt2:
		; Convert second ASCII value to number
                mov al, 57		  ; move ASCII 57 (9) into al
                sub al, bl		  ; subtract ASCII value if digit to get the number value
                mov bl, byte [Digits+rax] ; move second number into bl by fetching it with the offset from Digits

                ret			  ; return ConvertToInt2

	ReadError:
		; Print read error to stderr
		mov rax, 1          ; write_call
		mov rdi, 2          ; stderr
		mov rsi, ReadErrMsg ; mov address of message start into rsi
		mov rdx, REMLEN     ; move calculated length of message into rdx
		syscall		    ; call sys_write

		jmp Exit            ; Exit program after read error dispay

	WriteError:
		; Print write error to stderr
		mov rax, 1		; write_call
		mov rdi, 2		; stderr
		mov rsi, WriteErrMsg    ; move address of message start into rsi
		mov rdx, WEMLEN         ; move calculated length of message into rdx
		syscall			; call sys_write

		jmp Exit		; Exit program after write error display

	CalcAvg:
		mov rax, r9		; move sum into rax (for div)
                xor rdx, rdx		; clear rdx
                mov rcx, 12     	; move month count into rcx (for div)
		div rcx			; divide rax by rcx
                mov byte [RESULT], al   ; move result into RESULT memory address

                ; Convert RESULT to ASCII
                mov bl, [RESULT]	; mov result val into bl
                mov al, [RESULT]	; also copy result val into al both for calculation purpose
                mov rcx, 10             ; mov 10 into rcx (for div)
                div al			; divide al (result) by 10 to get first digit
                mov dl, al              ; move first digit into dl
                add dl, 48		; add 48 to first digit to get ASCII value
                mov byte [RESULT], dl   ; move ASCII value of first digit into starting address of RESULT
                mul rcx			; multiply first digit again with 10 to restore al
                sub bl, al		; subtract al from result in bl to get last digit of result
                add bl, 48              ; add 48 to last digit to get ASCII value
                mov byte [RESULT+1], bl ; move ASCII value of second digit into RESULT offset by 1 byte

		mov rax, 1		; write_call
		mov rdi, 1		; stdout
		mov rsi, Summation	; move starting address of Summation into rsi
		mov rdx, SummationLen   ; move calculated length of msg into rdx
		syscall			; sys_write

		cmp rax, 0		; check for write error
		jb WriteError		; if error return, display write error

		; If no error, write result to stdout
		mov rax, 1		; write_call
		mov rdi, 1		; stdout
		mov rsi, RESULT		; mov starting address of RESULT into rsi
		mov rdx, 3		; set length for output to 3 bytes (digit 1, digit 2, EOL)
		syscall			; sys_write

		cmp rax, 0		; check for write error
		jb WriteError		; if error return, display write error

  	Exit:
		mov rax, 60		; exit_call
		mov rdi, 0		; return code 0 -> all good
		syscall			; sys_exit
