;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;			NAME: Clayton Jaksha
;			FILENAME: main.asm
;			LAST EDITED: 07SEP14
;			PURPOSE: Simple Calculator
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file

;-------------------------------------------------------------------------------
            			.text                           ; Assemble into program memory
            			.retain                         ; Override ELF conditional linking
                                            ; and retain current section
            			.retainrefs                     ; Additionally retain any sections
                                            ; that have references to current
                                            ; section
				.text
myProgram:			.byte		0x22, 0x11, 0x22, 0x22, 0x33, 0x33, 0x08, 0x44, 0x08, 0x22, 0x09, 0x44, 0xff, 0x11, 0xff, 0x44, 0xcc, 0x33, 0x02, 0x33, 0x00, 0x44, 0x33, 0x33, 0x08, 0x55

				.data
myResults:			.space		20

ADD_OP:				.equ		0x11
SUB_OP:				.equ		0x22
CLR_OP:				.equ		0x44
END_OP:				.equ		0x55
MUL_OP:				.equ		0x33
;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer

;-------------------------------------------------------------------------------
                                            ; Main loop here
;-------------------------------------------------------------------------------


;---This portion of the code reads the first three terms of the programs, placing them in the appropriate registers. Then it jumps to the first operation.
;---The program pointer is put in r7, the first operand is placed in r8, the operation in r9, the second operand in r10, and the results pointer is put in r11.

				mov.w	#myProgram, r7
				mov.b	0(r7), r8
				inc		r7
				mov.b	0(r7), r9
				mov.b	1(r7), r10
				mov.w	#myResults, r11
				cmp		#ADD_OP, r9
				jeq		addition
				cmp		#SUB_OP, r9
				jeq		subtraction
				cmp		#CLR_OP, r9
				jeq		clearop
				cmp		#END_OP, r9
				jeq		endop
				cmp		#MUL_OP, r9
				jeq		multiply

;---This is the main loop the caclulator works from. It increments the pointers, pressing the program forward, and determines what operation to perform next.
nextup			incd	r7
				inc		r11
				mov.b	0(r7), r9
				mov.b	1(r7), r10
				cmp		#ADD_OP, r9
				jeq		addition
				cmp		#SUB_OP, r9
				jeq		subtraction
				cmp		#CLR_OP, r9
				jeq		clearop
				cmp		#END_OP, r9
				jeq		endop
				cmp		#MUL_OP, r9
				jeq		multiply
				jmp		nextup

;----------ADDITION------------
;---This section is fairly straightforward; it adds the two operands, stores the result, and then moves the result into the first operand for the next operation.
;---Also, if the sum ends up greater than 255, it have overflow capabilities in place to produce 0xff as the result.
addition		add.w	r8, r10
				cmp		#255, r10
				jge		twofiftyfive
				mov.b	r10, 0(r11)
				mov.w	r10, r8
				jmp		nextup
twofiftyfive	mov.b	#255, 0(r11)
				mov.w	#255, r8
				jmp		nextup

;------------SUBTRACTION-----------
;---Like the addition section, this portion of the code is fairly easy to read since there is a built-in assembly instruction (emulated) for subtraction.
;---First, it compares the two operands and if it's going to produce a negative result then it automatically stores 0 as the answer.
subtraction		cmp 	r8, r10
				jge 	zeero
				sub.w 	r10, r8
				mov.b 	r8, 0(r11)
				jmp 	nextup
zeero			mov.b 	#0, 0(r11)
				mov.w 	#0, r8
				jmp 	nextup

;--------CLEAR--------------------
;---Another simple function: stores a 0 as the result and loads the second operand as the first operand for the next operation.
clearop			mov.b 	#0, 0(r11)
				mov.w	r10, r8
				jmp 	nextup

;--------------ENDOP----------------
;---When this is the operation, it simply traps the CPU, effectively ending the program.
endop			jmp 	endop

;---------------MULTIPLY-------------
;---This opertion is the most complicated, but it can be scaled up O[log n], making it useful for large values.
;---It multiplies the first operand by the second operand by checking in what places there is a '1' in the second operand, then shifting the first operand that many places and adding up
;------all of the shifted values.
;---I will describe what each new register is being used for:
;------r5: takes the value of the second operand, it is used to determine where there are '1's in the second operand.
;------r6:  I call this the "tracker bit". It tracks which bit we are checking in the second operand for '1's. It is shifted from 0x0001 to 0x0080 to cover each individual bit in the byte.
;------r7:  no change.
;------r8:  no change.
;------r9:  no change.
;------r10: no change.
;------r11: points to the address the result is stored in.
;------r12: unused.
;------r13: temporarily holds the word-sized value of the sum of the shifted values; I use this register to check for overflow since it holds a whole word rather than just a byte.
;---The part of the operation here initializes the tracker bit and checks the first bit for a '1' and, if there is one, adds the unshifted value of the first operand to the total product.
multiply		mov.w	r10, r5
				clr.b	0(r11)
				mov.w	#0x0001, r6		;---the tracker bit is initialized at #0x0001, then moves to #0x0002, #0x0004, #0x0008, #0x0010, ... , #0x0080.
				and.w	r6, r5
				rla.w	r6
				tst		r5
				jz		multiploop
				mov.w	@r11, r13
				add.w	r8, r13
				cmp		#256, r13
				jge		overflow
				mov.b	r13, 0(r11)
;---this loop the meat of the work for multiplying. It checks the 2nd through 7th bits for '1's and, if they're present, adds that value of shift of the first operand to the total prodcut.
;---it also checks for overflow. If any value goes over #255, then it will trigger the overflow loop.
multiploop		rla.w	r8
				mov.w	r10, r5
				and.w	r6, r5
				rla.w	r6
				cmp		#0x0080, r6
				jeq		final_loop
				tst		r5
				jz		multiploop
				mov.w	@r11, r13
				add.w	r8, r13
				cmp		#256, r13
				jge		overflow
				mov.b	r13, 0(r11)
				jmp		multiploop
;---Once the tracker bit is at the 8th bit, we move to the final loop which can initiate exiting the loop and another overflow process should and overflow occur on the last bit.
final_loop		rla.w	r8
				mov.w	r10, r5
				and.w	#0x0080, r5
				tst		r5
				jz		done
				mov.w	@r11, r13
				add.w	r8, r13
				cmp		#256, r13
				jge		overflow
				mov.b	r13, 0(r11)
				mov.b	@r11, r8
				jmp		nextup
;---this small portion of code sets the product as the first operand for the next operation and jumps back to the main loop
done				mov.b	@r11, r8
				jmp		nextup
;---if at any time the loop detects and overflow, the value #0xff will be moved into the product and we return to the main loop
overflow		mov.b	#255, 0(r11)
				mov.w	#255, r8
				jmp		nextup



;-------------------------------------------------------------------------------
;           Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect 	.stack

;-------------------------------------------------------------------------------
;           Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
