#include <REG51F380.H>

EXTRN CODE (INIT_DEVICE)
EXTRN CODE (LOAD_ARRAY_TIMER_BACKWARD)
EXTRN CODE (INCREMENTA_TIMER)
EXTRN CODE (RELOAD_TIMER)
EXTRN CODE (ADICIONAR_ARRAY)
EXTRN CODE (INVERTER_ARRAY)
EXTRN CODE (INCREMENTA_ARRAY)
EXTRN CODE (COMPARA_ARRAY)
EXTRN CODE (ENCRIPTAR)
EXTRN CODE (DESENCRIPTAR)
EXTRN CODE (ENCRYPT_ARRAY)
EXTRN CODE (DECRYPT_ARRAY)

PUBLIC VTIMER_BYTE_LEN
;\\\\\\\\\\\\\\\\VARI�VEIS DE CONTROLO DO PROGRAMA/////////////////
STATE DATA 30H
NSTATE DATA 31H
INDEX DATA 32H
ENUM DATA 33H 
FAIL_INDEX DATA 34H ;Quantidade de vezes que o utilizador falhou
FAIL_INDEX_INTERRUPT DATA 35H ;Controlar o n�mero de overflows para contar dependendo do fail_index
OPEN_INDEX_INTERRUPT DATA 36H ;Controlar o n�mero de overflows para contar 30seg (a partir de 500ms)
RECOVERY_CONDITION_INDEX DATA 37H ;Controlar o index para entrar na recovery_condition
;\\\\\\\\\\\\\\\\\\\FLAGS DE CONTROLO DO PROGRAMA//////////////////
TIMEOUT BIT 0H ;Indica quando passaram 30seg no C_OPEN
FLOAD BIT 1H ;Controlo para fluxo do programa
FAIL_INTERRUPT_FLAG BIT 2H ;Indica se pode sair do "delay" no C_FAIL
;\\\\\\\\\\\\\\\\\CHAVES DE SEGURAN�A E UTILIZADOR/////////////////
SEC_KEY IDATA 80H
USR_KEY IDATA 90H
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ESTADOS/////////////////////////////
S_RECOVERY EQU 0
S_LOCKED EQU 1
S_DECRYPT EQU 2
S_OPEN EQU 3
S_FAIL EQU 4
S_BLOCKED EQU 5
S_ENCRYPT EQU 6
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\TAMANHOS/////////////////////////////
KEY_LEN EQU 4
VTIMER_BYTE_LEN EQU 4
;\\\\\\\\\\\\\\\\\\\\\\\\\ENTRADAS/SA�DAS/////////////////////////
KLOAD EQU P0.7
KSET EQU P0.6
DISP EQU P2
DOT EQU P2.7
PBUZZ EQU P3.0 ;Buzzer
PLED EQU P1.0 ;Led para o C_BLOCKED
TENSAO_BLOQUEIO EQU P1.1
;\\\\\\\\\\\\\\\\\\\\\\\\\\\CARACTERES///////////////////////////
DISP_F EQU 8EH
DISP_B EQU 83H
DISP_O EQU 0A3H
DISP_L EQU 0C7H
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ARRAYS/////////////////////////////
CSEG AT 1000H
ARRAYDIGITS:
	DB 0C0H,0F9H,0A4H,0B0H,99H,92H,82H,0F8H,80H,98H

CSEG AT 2000H
RELOAD_TIMERS:
	DB 30H,0F8H,0FFH,0FFH ;2000 * QT = 500ms
	DB 40H,02BH,0FEH,0FFH ;120000 * QT = 30seg			
	DB 60H,0F0H,0FFH,0FFH ;4000 * QT = 1seg 		
RELOAD_LEN	EQU $-RELOAD_TIMERS

ISEG AT 09FH
	TIMER_ARRAY: DS (RELOAD_LEN)
;\\\\\\\\\\\\\\\\\\\\\\\\PROGRAMA PRINCIPAL//////////////////////
CSEG AT 0H
	JMP MAIN
CSEG AT 0B0H
	JMP ISR_TIMER0
CSEG AT 100H

MAIN:
	CALL INIT_DEVICE
	MOV STATE,#S_RECOVERY
	MOV NSTATE,#S_RECOVERY
	MOV FAIL_INDEX,#0
	MOV INDEX,#0
	MOV RECOVERY_CONDITION_INDEX,#(-40)
	MOV OPEN_INDEX_INTERRUPT,#(-60) ;60 * 500ms = 30seg
	MOV ENUM,#0
	CLR FLOAD
	SETB TIMEOUT
	SETB EA
	SETB TENSAO_BLOQUEIO
	CLR FAIL_INTERRUPT_FLAG
	MOV R0,#SEC_KEY
	MOV @R0,#0
	MOV R0,#USR_KEY
	MOV @R0,#0
	MOV DPTR,#RELOAD_TIMERS
	MOV R0,#TIMER_ARRAY
	MOV R7,#RELOAD_LEN
	LCALL LOAD_ARRAY_TIMER_BACKWARD ;Carrega o array de timers
MLOOP:
	ACALL ENCODE_FSM_1
	ACALL TEST_LOAD
NEXTSTATE:
	JNB FLOAD,MLOOP
	CLR FLOAD
	MOV INDEX,#0
	MOV STATE,NSTATE
	SJMP MLOOP
;\\\\\\\\\\\\\\\\\\\\\\\\ENCODE_FSM_1////////////////////////
ENCODE_FSM_1:
	MOV DPTR,#STATES
	MOV A,STATE
	RL A
	JMP @A+DPTR
STATES:
	AJMP C_RECOVERY
	AJMP C_LOCKED
	AJMP C_DECRYPT
	AJMP C_OPEN
	AJMP C_FAIL
	AJMP C_BLOCKED
	AJMP C_ENCRYPT
;////////////////////////////////////////////////
C_RECOVERY:
	MOV NSTATE,#S_LOCKED
	SETB FLOAD
	MOV R0,#SEC_KEY
	MOV @R0,#0
	MOV FAIL_INDEX,#0
	ACALL RECOVERY_LOOP
	RET
RECOVERY_LOOP:
	MOV R7,#0
	MOV A,R7
	LCALL ENCRIPTAR
	MOV R7,A
	MOV A,@R0
	CLR C
	SUBB A,#KEY_LEN
	JZ FIM_RECOVERY_LOOP
	LCALL ADICIONAR_ARRAY
	SJMP RECOVERY_LOOP
FIM_RECOVERY_LOOP: 
	MOV R0,#SEC_KEY
	MOV A,@R0
	LCALL ENCRIPTAR
	MOV @R0,A
	RET
;////////////////////////////////////////////////
C_LOCKED:
	SETB TENSAO_BLOQUEIO
	MOV ENUM,#0
	MOV DISP,#DISP_L
	MOV NSTATE,#S_DECRYPT
	RET
;////////////////////////////////////////////////
C_DECRYPT:
	MOV A,ENUM
	CLR C
	SUBB A,#KEY_LEN
	JZ DECRYPT_LOOP
	ACALL UPDATE_DISP1
	RET
DECRYPT_LOOP:
	MOV R0,#USR_KEY
	MOV A,@R0
	LCALL ENCRIPTAR 
	MOV @R0,A                      ;Encripta o size do array
	MOV R0,#USR_KEY	
	LCALL DECRYPT_ARRAY
	MOV R0,#SEC_KEY
	LCALL DECRYPT_ARRAY            ;Desencripta todos os valores de ambos os arrays
	MOV R0,#USR_KEY                ;Garante que em R0 temos a posi��o de #usr_key na memoria
	LCALL INVERTER_ARRAY
	MOV R7,#KEY_LEN
	LCALL INCREMENTA_ARRAY
	MOV R0,#USR_KEY
	MOV R1,#SEC_KEY
	LCALL COMPARA_ARRAY
	MOV INDEX,#0
	MOV NSTATE,#S_FAIL
	MOV A,#0
	ADDC A,#0
	SETB FLOAD
	JZ FIM_DECRYPT_LOOP
	MOV NSTATE,#S_OPEN
	MOV ENUM,#0
FIM_DECRYPT_LOOP: 
	MOV R0,#SEC_KEY
	LCALL ENCRYPT_ARRAY
	RET
;////////////////////////////////////////////////
C_OPEN:
	CLR TENSAO_BLOQUEIO
	MOV NSTATE,#S_LOCKED
	SETB TR0
	MOV DISP,#DISP_O
	RET
;////////////////////////////////////////////////
C_FAIL:
	MOV NSTATE,#S_BLOCKED
	INC FAIL_INDEX
	CLR C
	MOV A,FAIL_INDEX
	MOV FAIL_INDEX_INTERRUPT,A
	SUBB A,#3						
	SETB FLOAD
	JZ FIM_FAIL
	MOV DISP,#DISP_F
	SETB TR0           
	JNB FAIL_INTERRUPT_FLAG,$
	CLR FAIL_INTERRUPT_FLAG
	MOV INDEX,#0
	MOV NSTATE,#S_LOCKED
	MOV ENUM,#0
	MOV @R0,#0
FIM_FAIL: RET
;////////////////////////////////////////////////
C_BLOCKED:
	SETB TR0
	MOV DISP,#DISP_B
	RET
;////////////////////////////////////////////////
C_ENCRYPT:
	SETB TIMEOUT
	MOV FAIL_INDEX,#0
	MOV NSTATE,#S_LOCKED
	MOV A,ENUM
	CLR C
	SUBB A,#KEY_LEN
	JZ FIM_ENCRYPT
	MOV NSTATE,#S_ENCRYPT
	ACALL UPDATE_DISP1
	RET
FIM_ENCRYPT: 
	SETB FLOAD
	MOV R0,#SEC_KEY
	MOV A,@R0
	LCALL ENCRIPTAR
	MOV @R0,A
	RET
;\\\\\\\\\\\\\\\\\\\\\\\TESTE DE SET E LOAD///////////////////////
TEST_LOAD:
	JB FLOAD,FIM_TEST_SET_LOAD
	JB KLOAD,TEST_SET
	JNB KLOAD,$
	SETB FLOAD
	JNB TIMEOUT,FIM_TEST_SET_LOAD
	MOV A,STATE
	CLR C
	SUBB A,#2
	JZ ADICIONAR_USR
	CLR C
	SUBB A,#3
	JZ RECOVERY_CONDITION
	CLR C
	SUBB A,#1
	JZ ADICIONAR_SEC
	RET
TEST_SET:
	JB KSET,TEST_LOAD
	JNB KSET,$
	INC INDEX
	RET
FIM_TEST_SET_LOAD:RET
;\\\\\\\\\\\\\\\\\\\ROTINAS AUXILIARES MAQUINA ESTADOS PRINCIPAL///////////////////
ADICIONAR_USR:
	MOV R0,#USR_KEY
	SJMP ADICIONAR_KEY
ADICIONAR_SEC:
	MOV R0,#SEC_KEY
ADICIONAR_KEY:
	INC ENUM
	MOV A,INDEX
	LCALL ENCRIPTAR
	MOV R7,A
	LCALL ADICIONAR_ARRAY
	MOV INDEX,#0
	RET
;////////////////////////////////////////////////
RECOVERY_CONDITION: ;Ter� de carregar 40 vezes no KLOAD para "resetar" a m�quina
	MOV A,RECOVERY_CONDITION_INDEX
	ADD A,#1
	MOV RECOVERY_CONDITION_INDEX,A
	MOV A,#0
	ADDC A,#0
	JZ FIM_TEST_SET_LOAD
	CLR TR0
	MOV NSTATE,#S_RECOVERY
	MOV RECOVERY_CONDITION_INDEX,#(-40)
	RET
;////////////////////////////////////////////////
UPDATE_DISP1:
	MOV DPTR,#ARRAYDIGITS
	MOV A,INDEX
	CLR C
	SUBB A,#10
	JZ UPDATE_DISP2
	MOV A,INDEX
	MOVC A,@A+DPTR
	MOV DISP,A
	RET	
UPDATE_DISP2:
	MOV INDEX,#0
	SJMP UPDATE_DISP1
;\\\\\\\\\\\\\\\\\\\\\\\\ENCODE_FSM_2////////////////////////
ISR_TIMER0:				
	PUSH PSW
	PUSH DPH
	PUSH DPL
	PUSH ACC
	LCALL ENCODE_FSM_2
	POP ACC
	POP DPL
	POP DPH
	POP PSW
RETI
;////////////////////////////////////////////////
ENCODE_FSM_2:
	MOV DPTR,#STATE_TIMER
	MOV A,STATE
	RL A
	JMP @A+DPTR
STATE_TIMER:
	AJMP CRECOVERY_INTERRUPT
	AJMP CLOCKED_INTERRUPT
	AJMP CDECRYPT_INTERRUPT
	AJMP COPEN_INTERRUPT
	AJMP CFAIL_INTERRUPT
	AJMP CBLOCKED_INTERRUPT
	AJMP CENCRYPT_INTERRUPT
;////////////////////////////////////////////////
CRECOVERY_INTERRUPT:
	CLR TR0
	LJMP FIM_ENCODE_FSM_2
CLOCKED_INTERRUPT:
	CLR TR0
	LJMP FIM_ENCODE_FSM_2
CDECRYPT_INTERRUPT:
	CLR TR0
	LJMP FIM_ENCODE_FSM_2
CENCRYPT_INTERRUPT:
	CLR TR0
	LJMP FIM_ENCODE_FSM_2
;////////////////////////////////////////////////
CFAIL_INTERRUPT:
	MOV R0,#TIMER_ARRAY				
	MOV A,STATE
	CLR C
	SUBB A,#3
	MOV R7,A
	MOV R6,A
	LCALL INCREMENTA_TIMER ;Incrementa o contador
	MOV A,R7
	JZ FIM_ENCODE_FSM_2 	 ;Se n�o houve overflow sai
	LCALL RELOAD_STATE 		 ;Se houve, d� reload ao array
	CLR TR0 				 ;Para o timer
	SETB FAIL_INTERRUPT_FLAG ;Indica que pode sair do estado C_FAIL caso conte apenas 30seg
	MOV R0,#USR_KEY
	MOV @R0,#0
	DEC FAIL_INDEX_INTERRUPT
	MOV A,FAIL_INDEX_INTERRUPT 
	JZ FIM_ENCODE_FSM_2 	 ;Se FAIL_INDEX_INTERRUPT=1, dar� outra contagem para 60seg
	CLR FAIL_INTERRUPT_FLAG
	SETB TR0
	SJMP FIM_ENCODE_FSM_2
;////////////////////////////////////////////////
COPEN_INTERRUPT:
	MOV R0,#TIMER_ARRAY
	MOV A,STATE
	CLR C
	SUBB A,#3
	MOV R7,A
	MOV R6,A
	LCALL INCREMENTA_TIMER
	MOV A,R7
	JZ FIM_ENCODE_FSM_2
	CPL DOT
	LCALL RELOAD_STATE
	MOV A,OPEN_INDEX_INTERRUPT ;Aumenta OPEN_INDEX_INTERRUPT at� dar overflow (contou 30seg)
	ADD A,#1
	MOV OPEN_INDEX_INTERRUPT,A
	MOV A,#0
	ADDC A,#0
	JZ FIM_ENCODE_FSM_2 ;Se n�o houve overflow,sai
	MOV OPEN_INDEX_INTERRUPT,#(-60)
	CLR TIMEOUT   	  ;Indica que os 30seg passaram
	SETB DOT	 
	MOV NSTATE,#S_ENCRYPT ;Define o pr�ximo estado como ENCRYPT
	MOV R0,#USR_KEY
	MOV @R0,#0
	MOV R0,#SEC_KEY
	MOV @R0,#0
	CLR TR0
	SJMP FIM_ENCODE_FSM_2
;////////////////////////////////////////////////
CBLOCKED_INTERRUPT:
	CPL PBUZZ ;Onda quadrada de 4kHz
	MOV R0,#TIMER_ARRAY
	MOV A,STATE
	CLR C
	SUBB A,#3
	MOV R7,A
	MOV R6,A
	LCALL INCREMENTA_TIMER
	MOV A,R7
	JZ FIM_ENCODE_FSM_2
	LCALL RELOAD_STATE
	CPL PLED ;A cada segundo d� CPL ao LED
	SJMP FIM_ENCODE_FSM_2

FIM_ENCODE_FSM_2:
	RET
RELOAD_STATE:
	MOV DPTR,#RELOAD_TIMERS
	MOV R0,#TIMER_ARRAY
	MOV A,R6
	MOV R7,A
	LCALL RELOAD_TIMER
	RET
END