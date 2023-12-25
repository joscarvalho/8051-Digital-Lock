#include <REG51F380.H>

PUBLIC ADICIONAR_ARRAY
PUBLIC INVERTER_ARRAY
PUBLIC INCREMENTA_ARRAY
PUBLIC COMPARA_ARRAY
PUBLIC ENCRIPTAR
PUBLIC DESENCRIPTAR
PUBLIC DECRYPT_ARRAY
PUBLIC ENCRYPT_ARRAY

;////////////////////////////////////////////////
CSEG AT 3000H
ADICIONAR_ARRAY:
	MOV A,R0
	PUSH ACC
	MOV A,@R0
	ADD A,#1
	MOV @R0,A
	MOV A,@R0
	ADD A,R0
	MOV R0,A
	MOV A,R7
	MOV @R0,A
	POP ACC
	MOV R0,A
	MOV R7,A
	RET
;////////////////////////////////////////////////
INVERTER_ARRAY: 
;Complemento para 1 de um array
	MOV A,R0
	PUSH ACC
	MOV A,R7
	PUSH ACC
	MOV A,@R0
	ADD A,#1
	MOV R7,A
INVLOOP:
	MOV A,@R0
	CPL A
	MOV @R0,A
	DEC R7
	MOV A,R7
	JZ INVERTER_ARRAY_FIM
	INC R0
	SJMP INVLOOP
INVERTER_ARRAY_FIM:
	POP ACC
	MOV R7,A
	POP ACC
	MOV R0,A
	RET
;////////////////////////////////////////////////
INCREMENTA_ARRAY: 
;Complemento para 2 de um array
	MOV A,R0
	PUSH ACC
	INC R7
	SETB C
INCLOOP:
	MOV A,@R0
	ADDC A,#0
	MOV @R0,A
	DEC R7
	MOV A,R7
	JZ INCREMENTA_ARRAY_FIM
	INC R0
	SJMP INCLOOP
INCREMENTA_ARRAY_FIM:
	POP ACC
	MOV R0,A
	RET
;////////////////////////////////////////////////
COMPARA_ARRAY:
	MOV A,R0
	PUSH ACC
	MOV A,R1
	PUSH ACC
	MOV A,R7
	PUSH ACC
	CLR C
	MOV A,@R1
	INC A
	MOV R7,A
SUMLOOP:
	MOV A,@R0
	ADDC A,@R1
	MOV @R0,A
	JZ CONTINUE_SOMALOOP
	CLR C
	SJMP FIM_SOMALOOP
CONTINUE_SOMALOOP:
	DEC R7
	MOV A,R7
	JZ FIM_SOMALOOP
	INC R0
	INC R1
	SJMP SUMLOOP
FIM_SOMALOOP:
	POP ACC
	MOV R7,A
	POP ACC
	MOV R1,A
	POP ACC
	MOV R0,A
	MOV A,#0
	RET
;////////////////////////////////////////////////
ENCRIPTAR:
	CPL A
	SWAP A
	RR A
	RET
;Move para R7 o nº de elemntos do array (size+1), percorre o array para encriptar todos os valores do mesmo
ENCRYPT_ARRAY:                                     
	MOV A,@R0
	ADD A,#1
	MOV R7,A
ENCLOOP:
	MOV A,@R0
	ACALL ENCRIPTAR
	MOV @R0,A
	DEC R7
	MOV A,R7
	JNZ NZERO_ENC
	RET
NZERO_ENC:
	INC R0
	SJMP ENCLOOP
;////////////////////////////////////////////////
DESENCRIPTAR:
	RL A
	SWAP A
	CPL A
	RET
;Desencripta o size do array e adiciona-lhe 1, move para R7 este resultado e percorre o array desencriptando cada posição
DECRYPT_ARRAY:                                     
	MOV A,@R0
	ACALL DESENCRIPTAR
	ADD A,#1
	MOV R7,A
DECLOOP:
	MOV A,@R0
	ACALL DESENCRIPTAR
	MOV @R0,A
	DEC R7
	MOV A,R7
	JNZ NZERO_DEC
	RET
NZERO_DEC:
	INC R0
	SJMP DECLOOP
END