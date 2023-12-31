#include <REG51F380.H>

public  Init_Device

INIT SEGMENT CODE
    rseg INIT

; Peripheral specific initialization functions,
; Called from the Init_Device label
/*
PCA_Init:
    mov  PCA0MD,    #0h
    ret

Timer_Init:
    mov  TMOD,      #002h
    mov  CKCON,     #002h
    ret

Port_IO_Init:
    mov  P2MDOUT,   #0FFh
    mov  XBR0,      #001h
    mov  XBR1,      #040h
    ret

Oscillator_Init:
    mov  FLSCL,     #090h
    mov  CLKSEL,    #003h
    ret

Interrupts_Init:
    mov  IE,        #002h
    ret
*/
; Initialization function for device,
; Call Init_Device from your main program

Init_Device:
	;Oscillator_Init
	mov  FLSCL,     #090h
    mov  CLKSEL,    #003h
	;PCA_Init
    mov  PCA0MD,    #0h
	;Timer_Init
    mov  TMOD,      #002h
    mov  CKCON,     #002h
	;Port_IO_Init
    mov  P2MDOUT,   #0FFh
    mov  XBR0,      #001h
    mov  XBR1,      #040h
	;Interrupts_Init
    mov  IE,        #002h
	MOV TL0,#(-0FAH)
	MOV TH0,#(-0FAH)
    ret
end