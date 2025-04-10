7digit.asm linguist-language=Assembly
;___________________________________________________________________________________________________________________________________
;  Author: Bartłomiej Osiak
;  Project: Property 7 – Display Multiplexing for AVR ATmega328PB (Nano version)
;  Date: 07.04.2025
;  Additional info: It works like a stopwatch: disp1 and disp3 reset after reaching 6, while disp2 and disp4 reset after reaching 10
;
;  7-segment display layout (common anode/cathode):
;
;     (d6 d6)
;   (d1)    (d5)
;   (d1)    (d5)
;     (d0 d0)        where (dX) denotes I/O port pins
;   (d2)    (d4)
;   (d2)    (d4)
;     (d3 d3)   (d7)
;
;  Display digit select lines:
;   disp1    disp2    disp3    disp4
;   (c0)     (c1)     (c2)     (c3)
;
;  Button:
;   GND → (b0) → internal pull-up resistors must be used
;_____________________________________________________________________________________________________________________________________

.include "m328PBdef.inc"
;	initialization
init:

	.ORG 0x00
	rjmp main

	.ORG 0x32
	numbers: .DB 0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x7B, 0x77, 0x1F, 0x4E, 0x3D, 0x4F, 0x47

	.ORG 0x100

main:
;	stack
	ldi r16, low(ramend)
	out spl, r16
	ldi r16, high(ramend)
	out sph, r16
;	Z pointer
	ldi zl, low(2*numbers)
	ldi zh, high(2*numbers)
;	USART off
	ldi r16, 0
    sts UCSR0B, r16
;	Output init
	ldi r16, 255
	out ddrd, r16
	out ddrc, r16
	com r16
	out ddrb, r16
	com r16
;	setting pull-ups
	out portb, r16
;	button
wait_press:
    sbis pinb, 0     
    rjmp wait_press 
wait_release:
    sbic pinb, 0    
    rjmp wait_release
    rjmp start       
;	counter init
start:
	ldi r16, 0
	ldi r17, 0
;	counter
count:
	call show
	inc r16
;	when r16 reach 90 increment r17
	cpi r16, 90
	breq continue
	brne count
continue:
	inc r17
	brne count
	rjmp count
;	multiplexing
show:
	ldi r21, 10; waiting loop (changeable) used for timing
loop:
	call disp4
	call hold
	call disp3
	call hold
	call disp2
	call hold
	call disp1
	call hold
	dec r21
	brne loop
	ret

disp4:
	ldi r20, 0b00001000
	com r20
	out portc, r20
	mov r20, r16
	andi r20, 0b00001111
	cpi r20, 10
	breq zero4
back4:
	mov r20, r16
	andi r20, 0b00001111
	push zl
	push zh
	add zl, r20
	lpm r20, z
	pop zh
	pop zl
	com r20
	out portd, r20
	ret
;	reset when 10
zero4:
	andi r16, 0b11110000
	subi r16, -16
	rjmp back4

disp3:
	ldi r20, 0b00000100
	com r20
	out portc, r20
	mov r20, r16
	swap r20
	andi r20, 0b00001111
	cpi r20, 6
	breq zero3
back3:
	mov r20, r16
	swap r20
	andi r20, 0b00001111
	push zl
	push zh
	add zl, r20
	lpm r20, z
	pop zh
	pop zl
	com r20
	out portd, r20
	ret
;	reset when 6
zero3:
	andi r16, 0b00001111
	rjmp back3

disp2:
	ldi r20, 0b00000010
	com r20
	out portc, r20
	mov r20, r17
	andi r20, 0b00001111
	cpi r20, 10
	breq zero2
back2:
	mov r20, r17
	andi r20, 0b00001111
	push zl
	push zh
	add zl, r20
	lpm r20, z
	pop zh
	pop zl
	com r20
	out portd, r20
	ret
;	reset when 10
zero2:
	andi r17, 0b11110000
	subi r17, -16
	rjmp back2

disp1:
	ldi r20, 0b00000001
	com r20
	out portc, r20
	mov r20, r17
	swap r20
	andi r20, 0b00001111
	cpi r20, 6
	breq zero1
back1:
	mov r20, r17
	swap r20
	andi r20, 0b00001111
	push zl
	push zh
	add zl, r20
	lpm r20, z
	pop zh
	pop zl
	com r20
	out portd, r20
	ret
;	reset when 6
zero1:
	andi r17, 0b00001111
	rjmp back1

;	holding loop (changeable) !WARNING! DO NOT SET TOO HIGH
hold:
	push r16
	push r17
	ldi r16, 150 ;you can change this time
lop1:
	ldi r17, 150 ;you can change this time
lop2:
	dec r17
	brne lop2
	dec r16
	brne lop1
	pop r17
	pop r16
	ret

end: rjmp end
