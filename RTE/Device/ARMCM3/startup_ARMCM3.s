;/**************************************************************************//**
; * @file     startup_ARMCM3.s
; * @brief    CMSIS Core Device Startup File for
; *           ARMCM3 Device
; * @version  V5.4.0
; * @date     12. December 2018
; ******************************************************************************/
;/*
; * Copyright (c) 2009-2018 Arm Limited. All rights reserved.
; *
; * SPDX-License-Identifier: Apache-2.0
; *
; * Licensed under the Apache License, Version 2.0 (the License); you may
; * not use this file except in compliance with the License.
; * You may obtain a copy of the License at
; *
; * www.apache.org/licenses/LICENSE-2.0
; *
; * Unless required by applicable law or agreed to in writing, software
; * distributed under the License is distributed on an AS IS BASIS, WITHOUT
; * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; * See the License for the specific language governing permissions and
; * limitations under the License.
; */

;//-------- <<< Use Configuration Wizard in Context Menu >>> ------------------


;<h> Stack Configuration
;  <o> Stack Size (in Bytes) <0x0-0xFFFFFFFF:8>
;</h>
RCC         EQU 0x400FE060       ; Adresse du registre RCC
RCC2        EQU 0x400FE070       ; Adresse du registre RCC2 (si utilis�)
RCC_XTAL    EQU 0x000007C0       ; Masque pour le champ XTAL dans RCC
RCC_XTAL_16MHZ EQU 0x00000540    ; Valeur pour un cristal de 16 MHz
RCC_OSCSRC  EQU 0x00000030       ; Masque pour le champ OSCSRC dans RCC
RCC_OSCSRC_MAIN EQU 0x00000000   ; Utiliser l'oscillateur principal
RCC_PWRDN   EQU 0x00002000       ; Bit de mise hors tension du PLL
RCC2_DIV400 EQU 0x40000000       ; Utiliser le diviseur 400 dans RCC2
RCC_SYSDIV  EQU 0x07800000       ; Masque pour le champ SYSDIV dans RCC
RCC_SYSDIV2 EQU 0x1F800000       ; Masque pour le champ SYSDIV2 dans RCC2
	
Stack_Size      EQU      0x00000400

                AREA     STACK, NOINIT, READWRITE, ALIGN=3
__stack_limit
Stack_Mem       SPACE    Stack_Size
__initial_sp


;<h> Heap Configuration
;  <o> Heap Size (in Bytes) <0x0-0xFFFFFFFF:8>
;</h>

Heap_Size       EQU      0x00000C00

                IF       Heap_Size != 0                      ; Heap is provided
                AREA     HEAP, NOINIT, READWRITE, ALIGN=3
__heap_base
Heap_Mem        SPACE    Heap_Size
__heap_limit
                ENDIF


                PRESERVE8
                THUMB


; Vector Table Mapped to Address 0 at Reset

                AREA     RESET, DATA, READONLY
                EXPORT   __Vectors
                EXPORT   __Vectors_End
                EXPORT   __Vectors_Size

__Vectors       DCD      __initial_sp                        ;     Top of Stack
                DCD      Reset_Handler                       ;     Reset Handler
                DCD      NMI_Handler                         ; -14 NMI Handler
                DCD      HardFault_Handler                   ; -13 Hard Fault Handler
                DCD      MemManage_Handler                   ; -12 MPU Fault Handler
                DCD      BusFault_Handler                    ; -11 Bus Fault Handler
                DCD      UsageFault_Handler                  ; -10 Usage Fault Handler
                DCD      0                                   ;     Reserved
                DCD      0                                   ;     Reserved
                DCD      0                                   ;     Reserved
                DCD      0                                   ;     Reserved
                DCD      SVC_Handler                         ;  -5 SVCall Handler
                DCD      DebugMon_Handler                    ;  -4 Debug Monitor Handler
                DCD      0                                   ;     Reserved
                DCD      PendSV_Handler                      ;  -2 PendSV Handler
                DCD      SysTick_Handler                     ;  -1 SysTick Handler

                ; Interrupts
                DCD      Interrupt0_Handler                  ;   0 Interrupt 0
                DCD      Interrupt1_Handler                  ;   1 Interrupt 1
                DCD      Interrupt2_Handler                  ;   2 Interrupt 2
                DCD      Interrupt3_Handler                  ;   3 Interrupt 3
                DCD      Interrupt4_Handler                  ;   4 Interrupt 4
                DCD      Interrupt5_Handler                  ;   5 Interrupt 5
                DCD      Interrupt6_Handler                  ;   6 Interrupt 6
                DCD      Interrupt7_Handler                  ;   7 Interrupt 7
                DCD      Interrupt8_Handler                  ;   8 Interrupt 8
                DCD      Interrupt9_Handler                  ;   9 Interrupt 9

                SPACE    (214 * 4)                           ; Interrupts 10 .. 224 are left out
__Vectors_End
__Vectors_Size  EQU      __Vectors_End - __Vectors


                AREA     |.text|, CODE, READONLY

; Reset Handler

Reset_Handler   PROC
                EXPORT   Reset_Handler             [WEAK]
                IMPORT   SystemInit
                IMPORT   __main
                LDR      R0, =SystemInit   
                BLX      R0
                LDR      R0, =__main
				;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION RCC 
				LDR R2, =RCC			; Adresse du registre RCC
				LDR R1, [R2]			; Contenue du registre RCC
				BIC R1, R1, #0X7C0      ; Effacer le champ OSCSRC
				ORR R1, R1, #RCC_OSCSRC_MAIN ; S�lectionner l'oscillateur principal
				ORR R1, R1, #(0x00<<6)  ; D�finir la fr�quence du cristal � 16 MHz
				BIC R1, R1, #RCC_PWRDN       ; Activer le PLL
				STR R1, [R2]
				;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvFin configuration RCC
				
				;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION STRELOAD 
				LDR R3, =0xE000E014      ; Adresse du registre STRELOAD
				LDR R1, =0x00F423FF      ; Valeur de rechargement pour 1 seconde avec une horloge de 16 MHz
				STR R1, [R3]
				;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvFin configuration STRELOAD 
				
				;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION STCURRENT 				
				LDR R3, =0xE000E018      ; Adresse du registre STCURRENT
				MOV R1, #0
				STR R1, [R3]			 ; Ecriture pour reset STCURRENT
				;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvFin configuration STCURRENT
				
				;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION SysTick
				LDR R3, =0xE000E010      ; Adresse du registre STCTRL
				LDR R1, [R3]			 ; Contenue du registre STCTRL
				ORR R1, R1, #1           ; Mettre le bit ENABLE � 1
				ORR R1, R1, #2           ; Mettre le bit TICKINT � 1 si les interruptions sont n�cessaires
				STR R1, [R3]
				;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvFin configuration STCURRENT
				BX       R0
                ENDP


; Macro to define default exception/interrupt handlers.
; Default handler are weak symbols with an endless loop.
; They can be overwritten by real handlers.
                MACRO
                Set_Default_Handler  $Handler_Name
$Handler_Name   PROC
                EXPORT   $Handler_Name             [WEAK]
                B        .
                ENDP
                MEND


; Default exception/interrupt handler

                Set_Default_Handler  NMI_Handler
                Set_Default_Handler  HardFault_Handler
                Set_Default_Handler  MemManage_Handler
                Set_Default_Handler  BusFault_Handler
                Set_Default_Handler  UsageFault_Handler
                Set_Default_Handler  SVC_Handler
                Set_Default_Handler  DebugMon_Handler
                Set_Default_Handler  PendSV_Handler

                Set_Default_Handler  Interrupt0_Handler
                Set_Default_Handler  Interrupt1_Handler
                Set_Default_Handler  Interrupt2_Handler
                Set_Default_Handler  Interrupt3_Handler
                Set_Default_Handler  Interrupt4_Handler
                Set_Default_Handler  Interrupt5_Handler
                Set_Default_Handler  Interrupt6_Handler
                Set_Default_Handler  Interrupt7_Handler
                Set_Default_Handler  Interrupt8_Handler
                Set_Default_Handler  Interrupt9_Handler

                ALIGN
					
SysTick_Handler
		PUSH {LR}		; Save the return address onto the stack
		ADD R11,#1
		POP {LR}		; Restore the orignal address
		BX LR			; Back to the return address

; User setup Stack & Heap

                IF       :LNOT::DEF:__MICROLIB
                IMPORT   __use_two_region_memory
                ENDIF

                EXPORT   __stack_limit
                EXPORT   __initial_sp
                IF       Heap_Size != 0                      ; Heap is provided
                EXPORT   __heap_base
                EXPORT   __heap_limit
                ENDIF

                END