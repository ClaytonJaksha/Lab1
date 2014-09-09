Lab 1: Simple Calculator
===
#### Clayton Jaksha | ECE 382 | Dr. York | M2A

## Objective and Purpose
### Objective

The objective of this lab is to produce a simple calculator in assemply code that can read a series of instructions programmed into ROM, perform the desired operations, and write the results to a location in RAM.
### Purpose

The purpose is to develop familiarity with the assembly instructions for the MSP430 family and to begin designing larger, more complex instruction sets.

## Preliminary Design

My initial design, outlined below in the flowchart and section pseudocode, loops through each command by loading the operands, picking the appropriate operation to work from, loading the result into memory and the next operation, and incrementing memory and program pointers.

## Flowchart/Pseudocode

![alt text](http://i.imgur.com/yfCbwaz.png "Flowchart")

### Pseudocode

##### Addition
Since the MSP430 has an addition command, this process is extremely simple. Operand1 holds the sum at the end and the result is also stored wherever `myResults` points. If the difference is greater than 255, the answer will be 255. `myResults` is incremented at the end to advance it forward in memory.
```
operand1+=operand2;
if operand1>255 then:
	operand1=255;
	end if;
store operand1 in 0(myResults);
myResults+=1;
```
#### Subtraction
Since the MSP430 has an emulated subtraction command, this process is fairly simple. Operand1 holds the difference at the end and the result is also stored wherever `myResults` points. If the difference is less than zero, the answer will be zero.
```
operand1-=operand2;
if operand1<0 then:
	operand1=0;
	end if;
store operand1 in 0(myResults);
myResults+=1;
```
#### Multiplication
This piece of code aims to multiply operand1 and operand 2 with an O[logx] process and will store the result wherever the `myResults` pointer points along with updating the first operand. Additionally, it checks for overflow and will account for that if necessary.
```
n=1;
while n<8:
	if bit n in operand2==1:
		product+=operand1;
		end if;
	arithmetic shift left operand1;
	n+=1;
	end while;
if product>255:
	product=255;
	end if;
store product in 0(myResults);
operand1=product;
myResults+=1;
```
#### Clear
This code is simple, it stores a zero into memory as the result and then loads operand2 as the next operand1 to be worked from.
```
store 0 in 0(myResults);
operand1=operand2;
myResults+=1;
```
#### End Op
`END_OP` will trap the processor at the end of the code.
```
n=0;
while n==0:
	end while;
```

## Code Walkthrough

#### Memory Locations
This first portion of the code saves space in ROM for `myProgram`, from which the lower portions of code will draw its commands.

The portion after `.data` reserves 20 bytes of space in RAM under the label `myProgram`. After reserving this space, I assign labels to the different operations so the code below is more readable.
```				
				.text
myProgram:		.byte		0x22, 0x11, 0x22, 0x22, 0x33, 0x33, 0x08, 0x44, 0x08, 0x22, 0x09, 0x44, 0xff, 0x11, 0xff, 0x44, 0xcc, 0x33, 0x02, 0x33, 0x00, 0x44, 0x33, 0x33, 0x08, 0x55

				.data
myResults:		.space		20

ADD_OP:			.equ		0x11
SUB_OP:			.equ		0x22
CLR_OP:			.equ		0x44
END_OP:			.equ		0x55
MUL_OP:			.equ		0x33
```

#### Initialization
Before entering the main loop, we must first initialize our working registers. In this program the `myProgram` pointer is in `r7`, the first operand will be in `r8`, the operation is in `r9`, the second operand is in `r10`, and the `myResults` pointer is in r11. This portion of code needs to be different from the `nextup` loop below because it uniquely loads `r7`, `r8`, and `r11` registers. 

After initializing the registers, the code determines which operation to perform and sends the operands off to the program to begin calculations.

```
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
```
#### Main Loop
This loop, `nextup`, is the "home base" if you will for the code. After every operation, the program jumps back to here, increments the pointers, and gets busy deciding what operation to do next.
```
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
```
#### Addition
The addition loop makes use of the add.w instruction to perform the actual arithmatic. The code then checks for overflow and stores the result.
```
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
```
#### Subtraction
The MSP430 has an emulated subtraction instruction `sub[.w]` that I make use of to compute the difference between the two. However, before actually subtracting, I compare the two operands and if the result will be zero or negative, I immediately make 0 the result and begin the next command.
```
;------------SUBTRACTION-----------
;---Like the addition section, this portion of the code is fairly easy to read since there is a built-in assembly instruction (emulated) for subtraction.
;---First, it compares the two operands and if it's going to produce a negative result then it automatically stores 0 as the answer.
subtraction		cmp 	r8, r10
				jge 		zeero
				sub.w 	r10, r8
				mov.b 	r8, 0(r11)
				jmp 		nextup
zeero			mov.b 	#0, 0(r11)	;why is there an extra 'e' in zero? I don't have a good reason.
				mov.w 	#0, r8
				jmp 		nextup
```
#### Clear
This portion of the code simply stores zero as the result and loads the second operand as the first operand for the next operation.
```
;--------CLEAR--------------------
;---Another simple function: stores a 0 as the result and loads the second operand as the first operand for the next operation.
clearop			mov.b 	#0, 0(r11)
				mov.w	r10, r8
				jmp 		nextup
```
#### End Op
The simplest portion of the code. When the program jumps here, we trap the CPU and nothing else gets done.
```
;--------------ENDOP----------------
;---When this is the operation, it simply traps the CPU, effectively ending the program.
endop				jmp 		endop
```
#### Multiply
This is the most complicated block of the larger code, I will break it up in order to make it more readable. Comments in the code can help clarify what specific registers are doing. My general process is to shift-add the first operand by wherever there are '1's in the second operand.

###### Part 1: Initialization
This first portion is essentially the first iteration of the loop that follows it. The main reason there must be a different first loop is that we initialize the tracker bit, clear the memory location the product will be stored at, and do not have a shift command in this iteration. If a '1' exists in the first bit of the second operand, then the first operand is added to the product's memory location and the product is compared for >255 condition.
```
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
```
###### Part 2: Main Loop
The loop starts out by shifting the second operand left; if the nth value of the second operand is '1', that shift will be added to the product. When n=8, we jump to the final loop because that too has some unique characteristics that necessitate a separate loop for its iteration. As in the first loop, we check for overflow and account properly.
```
;---this loop does the meat of the work for multiplying. It checks the 2nd through 7th bits for '1's and, if they're present, adds that value of shift of the first operand to the total prodcut.
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
```
###### Part 3: Final Iteration
This iteration essentially does the same thing as the main loop, except it adds a `done` jump that signals the program that we are done with the program and this loop is unnecessary. This would be the case whenever there is a not a '1' in the `0x0080` bit of the second operand. We check for overflow here as well.
```
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
```
###### Part 4: Done
If the code detects we are done with shift-adding, we move the given result into the first operand (for the next operation) and jump back to `nextup`.
```
;---this small portion of code sets the product as the first operand for the next operation and jumps back to the main loop
done			mov.b	@r11, r8
				jmp		nextup
```
###### Part 5: Overflow
If at any shift-add, the value exceeds `0xFF`, the program will jump here and `0xFF` gets stored as the result. Then, the program jumps to the next command.
```
;---if at any time the loop detects and overflow, the value #0xff will be moved into the product and we return to the main loop
overflow		mov.b	#255, 0(r11)
				mov.w	#255, r8
				jmp		nextup
```



## Debugging

## Testing Methodology/Results

## Observations and Conclusion

## Documentation
##### None
