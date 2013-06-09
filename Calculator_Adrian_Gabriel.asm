
PUTC MACRO char
    PUSH AX
    MOV AL, char
    MOV AH, 0Eh
    INT 10h
    POP AX
ENDM

org 100h
      
JMP start
      
;declare variables
msg0 db 10,13, "Por favor ingrese el operando 1: $"
msg1 db "Por favor ingrese el operando 2: $"
msg2 db "Por favor ingrese el operador que desea aplicar. ", 0Dh, 0Ah
     db "Operadores permitidos (+-*/): $"
msg3 db "El resultado de la operacion es: $"  
msg4 db "Presione la tecla ESC en cualquier momento, si desea salir del programa. $" 
msg5 db "Si desea hacer otra operacion, presione la tecla 1, de lo contrario, presione la tecla ESC para salir. $"

;variable to store op1 input
number1 dw ?
number2 dw ?
result dw ?

ten dw 10                               

start:

MOV DX, offset msg4
CALL PRINT_TEXT

;print message requesting op1
MOV DX, offset msg0
CALL PRINT_TEXT

                   
                   
;get op1 input

CALL scan_num
MOV number1, CX

;print new line
PUTC 0Dh
PUTC 0Ah

;print message requesting op2
MOV DX, offset msg1
CALL PRINT_TEXT

;get op2 input


CALL SCAN_NUM 
MOV number2, CX


get_operator:

;print new line
PUTC 0Dh
PUTC 0Ah           

;print message requesting operator sign
MOV DX, offset msg2
CALL PRINT_TEXT

;get operator sign
MOV AH, 1
INT 21h

CMP AL, '+' ;compare input to + key.
JE do_sum 

CMP AL, '-' ;compare input to - key.
JE do_rest

CMP AL, '/' ;compare input to / key.
JE do_div

CMP AL, '*' ;compare input to * key.
JE do_mult       


CMP     AL, 1bh    ;compare input to ESC key.(Closes program if positive)
JE      get_out

JMP get_operator;calls function that asks for operator of there's no match with allowed signs or ESC.



do_sum: 
;add number1 and number1
MOV AX, number1
ADD AX, number2  
MOV result, AX  
;print new line
PUTC 0Dh
PUTC 0Ah     

;print the previous operation result.
MOV DX, offset msg3
CALL PRINT_TEXT 
MOV AX, result   
CALL PRINT_NUM

;print new line
PUTC 0Dh
PUTC 0Ah
JMP another_one;calls function that asks if the user wants to do another operation or get out.


do_rest: 
;substract number2 from number1
MOV AX, number1
SUB AX, number2  
MOV result, AX
;print new line
PUTC 0Dh
PUTC 0Ah                             

;print the previous operation result.
MOV DX, offset msg3
CALL PRINT_TEXT 
MOV AX, result   
CALL PRINT_NUM
;print new line
PUTC 0Dh
PUTC 0Ah 
JMP another_one;calls function that asks if the user wants to do another operation or get out.

do_mult:
;multiply number1 by number2.
MOV DX, number1
MOV AX, number2
MUL DL                                                                                         
MOV result, AX

;print new line
PUTC 0Dh
PUTC 0Ah
;print the previous operation result.
MOV DX, offset msg3   
CALL PRINT_TEXT 
MOV AX, result   
CALL PRINT_NUM     
;print new line
PUTC 0Dh
PUTC 0Ah
JMP another_one;calls function that asks if the user wants to do another operation or get out.

do_div:
;divide number1 by number2.                                                                           
MOV AX,number1
MOV BX,number2
DIV BL
MOV AH, 0
MOV result, AX
;print new line
PUTC 0Dh
PUTC 0Ah
MOV DX, offset msg3   
CALL PRINT_TEXT 
MOV AX, result   
CALL PRINT_NUM     
;print new line
PUTC 0Dh
PUTC 0Ah
JMP another_one;calls function that asks if the user wants to do another operation or get out.   

beg:;function called when user wants to do another operation after the doing one.
;print new line
PUTC 0Dh
PUTC 0Ah

JMP start;just starting over again.

another_one:;function that asks if he user wants to do another operation after doing one.   

;print new line
PUTC 0Dh
PUTC 0Ah

MOV DX, offset msg5;prints instructions for the user.
CALL PRINT_TEXT

MOV AH, 1 ;gets input into AL.
INT 21h

CMP AL,'1';compares input to one.
JE beg    


CMP AL, 1bh ;compares input to ESC.   
JE  get_out 

JMP another_one;asks for an input again if there's no match with ESC or 1.






RET ; Return to operating system                      

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; these functions are copied from emu8086.inc ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; gets the multi-digit SIGNED number from the keyboard,
; and stores the result in CX register:
SCAN_NUM        PROC    NEAR
        
        PUSH    DX
        PUSH    AX
        PUSH    SI
        
        MOV     CX, 0

        ; reset flag:
        MOV     CS:make_minus, 0

next_digit:

        ; get char from keyboard
        ; into AL:
        MOV     AH, 00h
        INT     16h
        
        ; compare it to ESC key
        CMP     AL, 1bh    
        JE      get_out 
        
        ; and print it:
        MOV     AH, 0Eh
        INT     10h

        ; check for MINUS:
        CMP     AL, '-'
        JE      set_minus 
        
        

        ; check for ENTER key:
        CMP     AL, 0Dh  ; carriage return?
        JNE     not_cr 
        JMP     stop_input   
        

not_cr:


        CMP     AL, 8                   ; 'BACKSPACE' pressed?
        JNE     backspace_checked
        MOV     DX, 0                   ; remove last digit by
        MOV     AX, CX                  ; division:
        DIV     CS:ten                  ; AX = DX:AX / 10 (DX-rem).
        MOV     CX, AX
        PUTC    ' '                     ; clear position.
        PUTC    8                       ; backspace again.
        JMP     next_digit
backspace_checked:


        ; allow only digits:
        CMP     AL, '0'
        JAE     ok_AE_0
        JMP     remove_not_digit
ok_AE_0:        
        CMP     AL, '9'
        JBE     ok_digit
remove_not_digit:       
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered not digit.
        PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for next input.       
ok_digit:


        ; multiply CX by 10 (first time the result is zero)
        PUSH    AX
        MOV     AX, CX
        MUL     CS:ten                  ; DX:AX = AX*10
        MOV     CX, AX
        POP     AX

        ; check if the number is too big
        ; (result should be 16 bits)
        CMP     DX, 0
        JNE     too_big

        ; convert from ASCII code:
        SUB     AL, 30h

        ; add AL to CX:
        MOV     AH, 0
        MOV     DX, CX      ; backup, in case the result will be too big.
        ADD     CX, AX
        JC      too_big2    ; jump if the number is too big.

        JMP     next_digit

set_minus:
        MOV     CS:make_minus, 1
        JMP     next_digit

too_big2:
        MOV     CX, DX      ; restore the backuped value before add.
        MOV     DX, 0       ; DX was zero before backup!
too_big:
        MOV     AX, CX
        DIV     CS:ten  ; reverse last DX:AX = AX*10, make AX = DX:AX / 10
        MOV     CX, AX
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered digit.
        PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for Enter/Backspace.
        
        
stop_input:
        ; check flag:
        CMP     CS:make_minus, 0
        JE      not_minus
        NEG     CX
not_minus:

        POP     SI
        POP     AX
        POP     DX  

        RET
make_minus      DB      ?       ; used as a flag.
SCAN_NUM        ENDP


;Custom Procs

; this procedure prints what is in register DX
PRINT_TEXT PROC NEAR
       MOV AH, 9
       INT 21h
       RET
PRINT_TEXT ENDP  
PRINT_NUM       PROC    NEAR
        PUSH    DX
        PUSH    AX

        CMP     AX, 0
        JNZ     not_zero

        PUTC    '0'
        JMP     printed

not_zero:
        ; the check SIGN of AX,
        ; make absolute if it's negative:
        CMP     AX, 0
        JNS     positive
        NEG     AX

        PUTC    '-' 
        

positive:
        CALL    PRINT_NUM_UNS
printed:
        POP     AX
        POP     DX
        RET
PRINT_NUM       ENDP



; this procedure prints out an unsigned
; number in AX (not just a single digit)
; allowed values are from 0 to 65535 (FFFF)
PRINT_NUM_UNS   PROC    NEAR
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX

        ; flag to prevent printing zeros before number:
        MOV     CX, 1

        ; (result of "/ 10000" is always less or equal to 9).
        MOV     BX, 10000       ; 2710h - divider.

        ; AX is zero?
        CMP     AX, 0
        JZ      print_zero

begin_print:

        ; check divider (if zero go to end_print):
        CMP     BX,0
        JZ      end_print

        ; avoid printing zeros before number:
        CMP     CX, 0
        JE      calc
        ; if AX<BX then result of DIV will be zero:
        CMP     AX, BX
        JB      skip
calc:
        MOV     CX, 0   ; set flag.

        MOV     DX, 0
        DIV     BX      ; AX = DX:AX / BX   (DX=remainder).

        ; print last digit
        ; AH is always ZERO, so it's ignored
        ADD     AL, 30h    ; convert to ASCII code.
        PUTC    AL


        MOV     AX, DX  ; get remainder from last div.

skip:
        ; calculate BX=BX/10
        PUSH    AX
        MOV     DX, 0
        MOV     AX, BX
        DIV     CS:ten  ; AX = DX:AX / 10   (DX=remainder).
        MOV     BX, AX
        POP     AX

        JMP     begin_print
        
print_zero:
        PUTC    '0'
        
end_print:

        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
PRINT_NUM_UNS   ENDP

get_out:
MOV AH,4ch
INT 21h             