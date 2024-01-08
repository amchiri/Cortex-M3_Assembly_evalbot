	;; RK - Evalbot (Cortex M3 de Texas Instrument)
; programme - Pilotage 2 Moteurs Evalbot par PWM tout en ASM (Evalbot tourne sur lui même)



		AREA    |.text|, CODE, READONLY
		ENTRY
		EXPORT	__main
		
		;; The IMPORT command specifies that a symbol is defined in a shared object at runtime.
		IMPORT	MOTEUR_INIT					; initialise les moteurs (configure les pwms + GPIO)
		
		IMPORT	MOTEUR_DROIT_ON				; activer le moteur droit
		IMPORT  MOTEUR_DROIT_OFF			; déactiver le moteur droit
		IMPORT  MOTEUR_DROIT_AVANT			; moteur droit tourne vers l'avant
		IMPORT  MOTEUR_DROIT_ARRIERE		; moteur droit tourne vers l'arrière
		IMPORT  MOTEUR_DROIT_INVERSE		; inverse le sens de rotation du moteur droit
		
		IMPORT	MOTEUR_GAUCHE_ON			; activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		IMPORT  MOTEUR_GAUCHE_AVANT			; moteur gauche tourne vers l'avant
		IMPORT  MOTEUR_GAUCHE_ARRIERE		; moteur gauche tourne vers l'arrière
		IMPORT  MOTEUR_GAUCHE_INVERSE		; inverse le sens de rotation du moteur gauche
		IMPORT	Reset_Handlerone
		IMPORT  RESET_TIMER
		IMPORT  INIT_TIMER
		IMPORT  DISTANCE
		IMPORT  FREEZE_TIMER
		IMPORT  UNFREEZE_TIMER
			
SYSCTL_PERIPH_GPIO EQU		0x400FE108	; SYSCTL_RCGC2_R (p291 datasheet de lm3s9b92.pdf)

; The GPIODATA register is the data register
GPIO_PORTF_BASE		EQU		0x40025000	; GPIO Port F (APB) base: 0x4002.5000 (p416 datasheet de lm3s9B92.pdf)
	
SYS_TICK_BASE    EQU 0xE000E010
STCTRL           EQU SYS_TICK_BASE + 0x010
STRELOAD         EQU SYS_TICK_BASE + 0x014
STCURRENT        EQU SYS_TICK_BASE + 0x018
	
OFF_LED 			EQU 0x00

; The GPIODATA register is the data register
GPIO_PORTD_BASE		EQU		0x40007000		; GPIO Port D (APB) base: 0x4000.7000 (p416 datasheet de lm3s9B92.pdf)
	
; The GPIODATA register is the data register
GPIO_PORTE_BASE		EQU		0x40024000		; GPIO Port E (APB) base: 0x4000.4000 (p416 datasheet de lm3s9B92.pdf)

; configure the corresponding pin to be an output
; all GPIO pins are inputs by default
GPIO_O_DIR   		EQU 	0x00000400  ; GPIO Direction (p417 datasheet de lm3s9B92.pdf)

; The GPIODR2R register is the 2-mA drive control register
; By default, all GPIO pins have 2-mA drive.
GPIO_O_DR2R   		EQU 	0x00000500  ; GPIO 2-mA Drive Select (p428 datasheet de lm3s9B92.pdf)

; Digital enable register
; To use the pin as a digital input or output, the corresponding GPIODEN bit must be set.
GPIO_O_DEN  		EQU 	0x0000051C  ; GPIO Digital Enable (p437 datasheet de lm3s9B92.pdf)

; Pul_up
GPIO_I_PUR   		EQU 	0x00000510  ; GPIO Pull-Up (p432 datasheet de lm3s9B92.pdf)

; Broches select
BROCHE4_5			EQU		0x30		; led1 & led2 sur broche 4 et 5

BROCHE0_1			EQU		0x03		; Bumper1 & Bumper2 sur broche 0 et 1

BROCHE6_7			EQU 	0xC0		; bouton poussoir 1 & bouton poussoir 2 sur broche 6 et 7

DUREE_TOURNE        EQU		0x015FFFFF  ; Duree pour tournée

DUREE_OFF	        EQU		0x1FFFF

; blinking frequency
DUREE   			EQU     0x002FFFFF

__main	
		; ;; Enable the Port F & D peripheral clock 		(p291 datasheet de lm3s9B96.pdf)
		; ;;
		BL INIT_TIMER
		ldr r6, = SYSCTL_PERIPH_GPIO  			;; RCGC2
        mov r0, #0x00000038  					;; Enable clock sur GPIO D, E et F où sont branchés les leds (0x28 == 0b111000)
		; ;;														 									      (GPIO::FEDCBA)
        str r0, [r6]
		
		; ;; "There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
		nop	   									;; tres tres important....
		nop	   
		nop	   									;; pas necessaire en simu ou en debbug step by step...
	
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION LED

        ldr r6, = GPIO_PORTF_BASE+GPIO_O_DIR    ;; 1 Pin du portF en sortie (broche 4 : 00010000)
        ldr r0, = BROCHE4_5 	
        str r0, [r6]
		
		ldr r6, = GPIO_PORTF_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE4_5		
        str r0, [r6]
		
		ldr r6, = GPIO_PORTF_BASE+GPIO_O_DR2R	;; Choix de l'intensité de sortie (2mA)
        ldr r0, = BROCHE4_5			
        str r0, [r6]
		
		mov r2, #0x000       					;; pour eteindre LED
     
		; allumer la led broche 4 (BROCHE4_5)
		mov r3, #BROCHE4_5		;; Allume LED1&2 portF broche 4&5 : 00110000
		
		ldr r7, = GPIO_PORTF_BASE + (BROCHE4_5<<2)  ;; @data Register = @base + (mask<<2) ==> LED1
		
		str r3, [r7]
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration LED 
		
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION Switcher 1
		
		
	    ldr r8, = GPIO_PORTD_BASE+GPIO_I_PUR	;; Pul_up 
        ldr r0, = BROCHE6_7		
        str r0, [r8]
		
		ldr r8, = GPIO_PORTD_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE6_7	
        str r0, [r8]     
		
		ldr r8, = GPIO_PORTD_BASE + (BROCHE6_7<<2)  ;; @data Register = @base + (mask<<2) ==> Switcher
		
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration Switcher 
		
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION Bumper
		
	    ldr r9, = GPIO_PORTE_BASE+GPIO_I_PUR	;; Pul_up 
        ldr r0, = BROCHE0_1		
        str r0, [r9]
		
		ldr r9, = GPIO_PORTE_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE0_1	
        str r0, [r9]     
		
		ldr r9, = GPIO_PORTE_BASE + (BROCHE0_1<<2)  ;; @data Register = @base + (mask<<2) ==> Bumper		
		
		
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration Bumper
;		BL Reset_Handlerone	
ReadState

		ldr r10,[r8]
		CMP r10,#0x40			; On vérifie si le switch 2 est appuyé
		BNE ReadState			; Si non appuyé on revient on reste en lecture

		; Configure les PWM + GPIO
		BL	MOTEUR_INIT	   		   
		
		; Activer les deux moteurs droit et gauche
		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON
		BL	MOTEUR_DROIT_AVANT	   
		BL	MOTEUR_GAUCHE_AVANT
		BL  RESET_TIMER							; On Reset le timer
        ldr r1, = DUREE_OFF 					;; pour la duree de la boucle d'attente1 (duree)
		

		; Boucle de pilotage des 2 Moteurs (Evalbot tourne sur lui même)
loop	
		; Evalbot avance droit devant
        str r2, [r7]    						;; Eteint LED car r2 = 0x00      
		ldr r10,[r8]
		CMP r10,#0x80							; On vérifie si le switch 1 est appuyé
		BEQ OFF_MOTOR							; Si appuyé on éteint le moteur 
		ldr r10,[r9]
		CMP r10,#0x02							; On vérifie si le Bumper Gauche est appuyé
		BEQ GAUCHE								; On va dans l'étiquette GAUCHE sinon on continue
		CMP r10,#0x01							; On vérifie si le Bumper Droite est appuyé
		BEQ DROITE								; On va dans l'étiquette Droite sinon on continue
		B loop									; Si on y va dans aucun étiquette on revient a l'étiquette loop
end_
		BL	MOTEUR_DROIT_AVANT	   
		BL	MOTEUR_GAUCHE_AVANT
		str r2, [r7]    						;; Eteint LED car r2 = 0x00      
        ldr r1, = DUREE 						;; pour la duree de la boucle d'attente1 (wait1)
		ldr r10,[r8]
		CMP r10,#0x40							; On vérifie si le switch 2 est appuyé
		BEQ ON_MOTOR							; Si appuyé on allumme le moteur
		B  end_
		
OFF_MOTOR
		BL MOTEUR_DROIT_OFF
		BL MOTEUR_GAUCHE_OFF
		ldr r10,[r8]
		CMP r10,#0x80							; On vérifie si le switch 1 est appuyé
		BEQ FIN									; Si appuyé on va dans l'étiquette FIN
		b OFF_MOTOR							    ; Sinon on boucle dans l'étiquette OFF_MOTOR
		
ON_MOTOR
		BL MOTEUR_DROIT_ON
		BL MOTEUR_GAUCHE_ON
		BL	MOTEUR_DROIT_AVANT	   
		BL	MOTEUR_GAUCHE_AVANT
		BL  RESET_TIMER
		b loop

GAUCHE 
		ldr r10,[r9]
		CMP r10,#0x00								; On vérifie si les deux Bumper sont appuyé pendant un certain temps
		BEQ OFF_MOTOR								; Si oui on eteint les moteurs
		subs r1, #1
        bne GAUCHE
		BL FREEZE_TIMER								; On Freeze le timer
		BL MOTEUR_GAUCHE_ARRIERE					; Sinon on  Commence à tourner à gauche 
		ldr r1, = DUREE_TOURNE 						;; pour la duree de la boucle d'attente1 (wait1)
tempo 
		subs r1, #1
		BL FREEZE_TIMER
        bne tempo
		BL MOTEUR_GAUCHE_AVANT
		ldr r1, = DUREE_TOURNE
tempo1 
		subs r1, #1
        bne tempo1
		BL MOTEUR_DROIT_ARRIERE
		ldr r1, = DUREE_TOURNE 						;; pour la duree de la boucle d'attente1 (wait1)
tempo2 
		subs r1, #1
        bne tempo2
		BL	MOTEUR_DROIT_AVANT	   
		BL	MOTEUR_GAUCHE_AVANT
		BL  UNFREEZE_TIMER                          ; On UNFREEZE le timer
		B loop

DROITE 
		ldr r10,[r9]
		CMP r10,#0x00								; On vérifie si les deux Bumper sont appuyé pendant un certain temps
		BEQ OFF_MOTOR								; Si oui on eteint les moteurs
		subs r1, #1									
        bne DROITE		
		BL FREEZE_TIMER								; On Freeze le timer
		BL MOTEUR_DROIT_ARRIERE						; Sinon on  Commence à tourner à droite 
		ldr r1, = DUREE_TOURNE 						;; pour la duree de la boucle d'attente1 (wait1)
tempoD 
		subs r1, #1
        bne tempoD
		BL MOTEUR_DROIT_AVANT
		ldr r1, = DUREE_TOURNE
tempoD1 
		subs r1, #1
        bne tempoD1
		BL MOTEUR_GAUCHE_ARRIERE
		ldr r1, = DUREE_TOURNE 						;; pour la duree de la boucle d'attente1 (wait1)
tempoD2 
		subs r1, #1
        bne tempoD2
		BL	MOTEUR_DROIT_AVANT	   
		BL	MOTEUR_GAUCHE_AVANT
		BL  UNFREEZE_TIMER                          ; On UNFREEZE le timer
		B loop

FIN
		BL DISTANCE								  ; Affiche la distance
		B end_

		NOP
        END