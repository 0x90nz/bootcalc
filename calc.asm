bits 16
org 0x7c00

	jmp	0:_start	

; Put a single char to the screen
; Clobbers:	ax
putc:
	push	bp
	mov	bp, sp

	mov	ah, 0x0e
	mov	al, [bp+4]
	int	0x10

	mov	sp, bp
	pop	bp
	ret

puts:
	push	bp
	mov	bp, sp
	push	si
	push	bx

	mov	bx, [bp+4]	; pointer to string
	xor	si, si

	mov	al, [bx+si]
.write_char:
	push	ax
	call	putc
	add	sp, 2

	inc	si
	mov	al, [bx+si]
	test	al, al
	jnz	.write_char

	pop	bx
	pop	si
	mov	sp, bp
	pop	bp
	ret

getc:
	xor	ah, ah
	int	16h
	xor	ah, ah
	
	; echo the character
	push	ax
	call	putc
	pop	ax	; restore the char, ax is clobbered by putc

	ret

; Get a number from keyboard. Wraps get_num_sc
; Clobbers:	ax, cx
get_num:
	push	'0'
	call	get_num_sc
	add	sp, 2
	ret

; Get a number from keyboard with a given starting char
; Params:	inital char
; Clobbers: 	ax, cx 
get_num_sc:
	push	bp
	mov	bp, sp
	push	bx

	; store the initial number in cx
	mov	cx, [bp+4]
	sub	cx, '0'
.get_loop:
	; read a keypress
	call	getc

	; store the char for later
	push	ax

	cmp	al, 0x0d	; end of line
	je	.done
	
	; get the current number, multiply it by 10 and store it back
	; we ignore dx, because we're too cool for big numbers
	mov	ax, cx
	mov	bx, 10
	mul	bx
	mov	cx, ax
	
	; add the number we just got onto cx
	pop	ax
	sub	ax, '0'
	add	cx, ax

	jmp	.get_loop

.done:
	; move the result into ax
	mov	ax, cx

	pop	bx
	mov	sp, bp
	pop	bp
	ret


; Print a number using putc.
; Clobbers ax, cx, dx
print_num:
	push	bp
	mov	bp, sp
	push	bx

	xor	bx, bx
	mov	ax, [bp+4]
.conv:
	xor	dx, dx
	mov	cx, 10
	div	cx

	add	dx, '0'
	inc	bx
	push	dx
	test	ax, ax
	jnz	.conv

.out:
	call	putc
	add	sp, 2

	dec	bx
	jnz	.out

	mov	sp, bp
	pop	bp
	ret

; Push an item onto the stack
; Clobbers: ax
push_item:
	push	bp
	mov	bp, sp
	push	bx

	; make space on the stack
	mov	bx, [stack_ptr]
	sub	bx, 2

	; get the value and store it
	mov	ax, [bp+4]
	mov	[bx], ax

	; update the stack ptr to where it is now
	mov	[stack_ptr], bx

	pop	bx
	mov	sp, bp
	pop	bp
	ret

; Get an item off the stack
; Returns: ax
pop_item:
	push	bp
	mov	bp, sp
	push	bx

	; get the stack pointer and then the item it points to
	mov	bx, [stack_ptr]
	mov	ax, [bx]

	; move the stack pointer and store its new location
	add	bx, 2
	
	cmp	bx, stack_top
	jg	.err
	
	mov	[stack_ptr], bx
	jmp	.done

.err:
	push	stack_uflow
	call	puts
	add	sp, 2
	mov	ax, 0

.done:
	pop	bx
	mov	sp, bp
	pop	bp
	ret

_start:
	mov	sp, 0xffff
	mov	ax, 0x7000
	mov	ss, ax

.l1:
	push	prompt
	call	puts
	add	sp, 2

	call	getc
	cmp	ax, 47
	jle	.op

	push	ax
	call	get_num_sc
	add	sp, 2

	; store the number on the stack (and on the calc stack)
	push	ax
	call	push_item

	push	crlf
	call	puts
	add	sp, 2

	call	print_num
	add	sp, 2

	push	crlf
	call	puts
	add	sp, 2

	jmp	.l1

.op:
	; keep the character for later
	push	ax

	push	crlf
	call	puts
	add	sp, 2
	
	call	pop_item
	mov	cx, ax
	call	pop_item
	mov	bx, ax

	; get the character we stored and see what it is
	pop	ax
	cmp	ax, '+'
	je	.add
	cmp	ax, '-'
	je	.sub
	cmp	ax, '*'
	je	.mul
	cmp	ax, '/'
	je	.div
	jmp	.l1

.add:
	add	bx, cx
	jmp	.op_done
.sub:
	sub	bx, cx
	jmp	.op_done
.mul:
	jmp	.op_done
.div:
	; TODO
	jmp	.op_done

.op_done:
	push	bx
	call	push_item
	call	print_num
	add	sp, 2
	
	push	crlf
	call	puts
	add	sp, 2

	jmp	.l1

	cli
	hlt

stack_top:	equ 0x7f00
stack_ptr: 	dw stack_top
crlf:		db `\r\n`, 0
prompt:		db `> `, 0
stack_uflow:	db `Stack underflow\r\n`, 0

times	510 - ($ - $$) db 0
dw	0xaa55
