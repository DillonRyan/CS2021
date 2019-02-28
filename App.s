	AREA	AsmTemplate, CODE, READONLY
	IMPORT	main

; sample program makes the 4 LEDs P1.16, P1.17, P1.18, P1.19 go on and off in sequence
; (c) Mike Brady, 2011 -- 2019.

	EXPORT	start
start

IO1DIR	EQU	0xE0028018
IO1SET	EQU	0xE0028014
IO1CLR	EQU	0xE002801C

forMain
	LDR R0, =number
	LDR R8, [R0]
	MOV R9, R8
	MOV R1, #0x80000000
	LDR R5, =result;
	
	AND R3, R8, R1; keeps track of whether the number is positive or negative
	
	STR R3, [R5], #4
	CMP R3, #0
	BEQ notNegative
	LDR R4, =0xFFFFFFFF
	EOR R8, R8, R4;
	ADD R8, R8, #1

notNegative
	MOV R7, #0; boolean for first non zero entry
	MOV R6, #10
	CMP R3, #0
	BNE negativeSign
	MOV R0, #10
	BL displaySign
negativeSign
	MOV R0, #11
	
displaySign
	BL reverse
	ldr	r1,=IO1DIR
	ldr	r2,=0x000f0000	;select P1.19--P1.16
	str	r2,[r1]		;make them outputs
	ldr	r1,=IO1SET
	str	r2,[r1]		;set them to turn the LEDs off
	ldr	r2,=IO1CLR
	BL display
	
while
	SUB R6, R6, #1
	CMP R6, #0
	BEQ finishedWhile
	
	MOV R0, R8
	MOV R1, R6
	BL mulByNum
	BL tensPlace
	MOV R8, R0
	CMP R7, #0
	BNE partOfNum
	
	CMP R1, #0
	BEQ while
	MOV R7, #1
	
partOfNum
	STR R1, [R5], #4
	MOV R0, R1
	BL reverse
	ldr	r1,=IO1DIR
	ldr	r2,=0x000f0000	;select P1.19--P1.16
	str	r2,[r1]		;make them outputs
	ldr	r1,=IO1SET
	str	r2,[r1]		;set them to turn the LEDs off
	ldr	r2,=IO1CLR
	BL display
	B while
	
finishedWhile
	MOV R0, R8
	STR R0, [R5]
	BL reverse
	ldr	r1,=IO1DIR
	ldr	r2,=0x000f0000	;select P1.19--P1.16
	str	r2,[r1]		;make them outputs
	ldr	r1,=IO1SET
	str	r2,[r1]		;set them to turn the LEDs off
	ldr	r2,=IO1CLR
	BL display
	MOV R0, #-1; trigger to not display anything
	BL display
	LDR	r4,=40000000
dloop	
	SUBS r4,r4,#1
	BNE	dloop
	B forMain
	

; r1 points to the SET register
; r2 points to the CLEAR register

stop	B	stop

reverse
	STMFD SP!, {R4 - R6, LR}
	MOV R4, R0;
	MOV R5, #0
	MOV R6, #4
	
forReverse
	MOVS R4, R4, LSR #1
	LSL R5, #1
	ADC R5, R5, #0
	SUB R6, R6, #1
	CMP R6, #0
	BNE forReverse
	
	LSL R5, #16
	MOV R0, R5
	LDMFD SP!, {R4 - R6, PC}

	; subroutine that displays the corrent binary
display
	STMFD SP!, {R4, LR}
	MOV R4, R0; number to be displayed
	CMP R4, #-1
	BNE notInterval
	LDR R4, =0x000F0000
	STR R4, [R1]
	B endDisplay
	
notInterval
	CMP R4, #0
	BNE set 
	LDR R4, =0xF
	LSL R4, #16

set
	STR R4, [R2]
	
endDisplay

	LDR	r4,=40000000
dloopTwo	
	SUBS r4,r4,#1
	BNE	dloopTwo
	LDMFD SP!, {R4, PC}
	
	
	; subroutine that gives you back the requested power of 10
mulByNum
	STMFD SP!, {R4 - R6, LR}
	MOV R4, R1;
	MOV R5, #10
	MOV R6, #1

forTens
	MUL R6, R5, R6;
	SUB R4, R4, #1
	CMP R4, #0
	BNE forTens
	
	MOV R1, R6; result of to the power of
	LDMFD SP!, {R4 - R6, PC}
	
	
	; subroutine that gives you back the number at the requested tens place and decreases the number by the tens given
tensPlace
	STMFD SP!, {R4 - R9, LR}
	MOV R4, R0; original number
	MOV R5, R1; number in power of 10
	MOV R6, R0; keep a copy of original
	MOV R8, #-1; counter
	
forSub
	ADD R8, R8, #1; 
	MOV R7, R4;
	SUB R4, R4, R5; 
	CMP R4, #0
	BGE forSub
	
	MUL R9, R8, R5;
	SUB R6, R6, R9; decreased number
	
	MOV R1, R8; result
	MOV R0, R6; decreased number
	LDMFD SP!, {R4 - R9, PC}
	
	
	AREA	Numbers, DATA, READWRITE

number DCD -414
	
result DCD 0,0,0,0,0,0,0,0,0,0,0,0

	END