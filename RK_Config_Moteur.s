	;; RK - Evalbot (Cortex M3 de Texas Instrument); 
; programme - Pilotage 2 Moteurs Evalbot par PWM tout en ASM (configure les pwms + GPIO)

;Les pages se réfèrent au datasheet lm3s9b92.pdf

;Cablage :
;pin 10/PD0/PWM0 => input PWM du pont en H DRV8801RT
;pin 11/PD1/PWM1 => input Phase_R  du pont en H DRV8801RT
;pin 12/PD2		 => input SlowDecay commune aux 2 ponts en H
;pin 98/PD5		 => input Enable 12v du conv DC/DC 
;pin 86/PH0/PWM2 => input PWM du 2nd pont en H
;pin 85/PH1/PWM3 => input Phase du 2nd pont en H	

;; Hexa corresponding values to pin numbers
GPIO_0		EQU		0x1
GPIO_1		EQU		0x2
GPIO_2		EQU		0x4
GPIO_5		EQU		0x20

;; pour enable clock    0x400FE000
SYSCTL_RCGC0	EQU		0x400FE100		;SYSCTL_RCGC0: offset 0x100 (p271 datasheet de lm3s9b92.pdf)
SYSCTL_RCGC2	EQU		0x400FE108		;SYSCTL_RCGC2: offset 0x108 (p291 datasheet de lm3s9b92.pdf)

;; General-Purpose Input/Outputs (GPIO) configuration
PORTD_BASE		EQU		0x40007000
GPIODATA_D		EQU		PORTD_BASE
GPIODIR_D		EQU		PORTD_BASE+0x00000400
GPIODR2R_D		EQU		PORTD_BASE+0x00000500
GPIODEN_D		EQU		PORTD_BASE+0x0000051C
GPIOPCTL_D		EQU		PORTD_BASE+0x0000052C ; GPIO Port Control (GPIOPCTL), offset 0x52C; p444
GPIOAFSEL_D		EQU		PORTD_BASE+0x00000420 ; GPIO Alternate Function Select (GPIOAFSEL), offset 0x420; p426

PORTH_BASE		EQU		0x40027000
GPIODATA_H		EQU		PORTH_BASE
GPIODIR_H		EQU		PORTH_BASE+0x00000400
GPIODR2R_H		EQU		PORTH_BASE+0x00000500
GPIODEN_H		EQU		PORTH_BASE+0x0000051C
GPIOPCTL_H		EQU		PORTH_BASE+0x0000052C ; GPIO Port Control (GPIOPCTL), offset 0x52C; p444
GPIOAFSEL_H		EQU		PORTH_BASE+0x00000420 ; GPIO Alternate Function Select (GPIOAFSEL), offset 0x420; p426

;; Pulse Width Modulator (PWM) configuration
PWM_BASE		EQU		0x040028000 	   ;BASE des Block PWM p.1138
PWMENABLE		EQU		PWM_BASE+0x008	   ; p1145

;Block PWM0 pour sorties PWM0 et PWM1 (moteur 1)
PWM0CTL			EQU		PWM_BASE+0x040 ;p1167
PWM0LOAD		EQU		PWM_BASE+0x050
PWM0CMPA		EQU		PWM_BASE+0x058
PWM0CMPB		EQU		PWM_BASE+0x05C
PWM0GENA		EQU		PWM_BASE+0x060
PWM0GENB		EQU		PWM_BASE+0x064

;Block PWM1 pour sorties PWM1 et PWM2 (moteur 2)
PWM1CTL			EQU		PWM_BASE+0x080 
PWM1LOAD		EQU		PWM_BASE+0x090
PWM1CMPA		EQU		PWM_BASE+0x098
PWM1CMPB		EQU		PWM_BASE+0x09C
PWM1GENA		EQU		PWM_BASE+0x0A0
PWM1GENB		EQU		PWM_BASE+0x0A4
	

RCC         EQU 0x400FE060       ; Adresse du registre RCC
RCC2        EQU 0x400FE070       ; Adresse du registre RCC2 (si utilisé)
RCC_XTAL    EQU 0x000007C0       ; Masque pour le champ XTAL dans RCC
RCC_XTAL_16MHZ EQU 0x00000540    ; Valeur pour un cristal de 16 MHz
RCC_OSCSRC  EQU 0x00000030       ; Masque pour le champ OSCSRC dans RCC
RCC_OSCSRC_MAIN EQU 0x00000000   ; Utiliser l'oscillateur principal
RCC_PWRDN   EQU 0x00002000       ; Bit de mise hors tension du PLL
RCC2_DIV400 EQU 0x40000000       ; Utiliser le diviseur 400 dans RCC2
RCC_SYSDIV  EQU 0x07800000       ; Masque pour le champ SYSDIV dans RCC
RCC_SYSDIV2 EQU 0x1F800000       ; Masque pour le champ SYSDIV2 dans RCC2

;Block Systtick

STCURRENT EQU 0xE000E018         ; Adresse du registre STCURRENT
STCTRL	  EQU 0xE000E010		 ; Adresse du registre STCTRL
STRELOAD  EQU 0xE000E014		 ; Adresse du registre STRELOAD

GPTMCTL EQU 0x40030000+0x00C 
GPTMCFG EQU 0x40030000
GPTMTAMATCHR EQU 0x40030000+0x030
; Broches select
BROCHE4_5			EQU		0x30		; led1 & led2 sur broche 4 et 5



VITESSE			EQU		0x1A2	; Valeures plus petites => Vitesse plus rapide exemple 0x192
								; Valeures plus grandes => Vitesse moins rapide exemple 0x1B2
						
DUREE	        EQU		0x002FFFFF
						
		AREA    |.text|, CODE, READONLY
		ENTRY
		
		;; The EXPORT command specifies that a symbol can be accessed by other shared objects or executables.
		EXPORT	MOTEUR_INIT
		EXPORT	MOTEUR_DROIT_ON
		EXPORT  MOTEUR_DROIT_OFF
		EXPORT  MOTEUR_DROIT_AVANT
		EXPORT  MOTEUR_DROIT_ARRIERE
		EXPORT  MOTEUR_DROIT_INVERSE	
		EXPORT	MOTEUR_GAUCHE_ON
		EXPORT  MOTEUR_GAUCHE_OFF
		EXPORT  MOTEUR_GAUCHE_AVANT
		EXPORT  MOTEUR_GAUCHE_ARRIERE
		EXPORT  MOTEUR_GAUCHE_INVERSE
		EXPORT	Reset_Handlerone
		EXPORT  RESET_TIMER
		EXPORT  INIT_TIMER
		EXPORT  DISTANCE
		EXPORT 	FREEZE_TIMER
		EXPORT  UNFREEZE_TIMER



MOTEUR_INIT	
		ldr r6, = SYSCTL_RCGC0
		ldr	r0, [R6]
        ORR	r0, r0, #0x00100000  ;;bit 20 = PWM recoit clock: ON (p271) 
        str r0, [r6]

	;ROM_SysCtlPWMClockSet(SYSCTL_PWMDIV_1);PWM clock is processor clock /1
	;Je ne fais rien car par defaut = OK!!
	;*(int *) (0x400FE060)= *(int *)(0x400FE060)...;
	
  	;RCGC2 :  Enable port D GPIO(p291 ) car Moteur Droit sur port D 
		ldr r6, = SYSCTL_RCGC2
		ldr	r0, [R6] 		
        ORR	r0, r0, #0x08  ;; Enable port D GPIO 
        str r0, [r6]

	;MOT2 : RCGC2 :  Enable port H GPIO  (2eme moteurs)
		ldr r6, = SYSCTL_RCGC2
		ldr	r0, [R6] 
        ORR	r0, r0, #0x80  ;; Enable port H GPIO 
        str r0, [r6] 
		
		nop
		nop
		nop
	 
	;;Pin muxing pour PWM, port D, reg. GPIOPCTL(p444), 4bits de PCM0=0001<=>PWM (voir p1261)
	;;il faut mettre 1 pour avoir PD0=PWM0 et PD1=PWM1
		ldr r6, = GPIOPCTL_D
		;ldr	r0, [R6] 	 ;;	*(int *)(0x40007000+0x0000052C)=1;
        ;ORR	r0, r0, #0x01 ;; Port D, pin 1 = PWM 
		mov	r0, #0x01  
        str r0, [r6]
		
	;;MOT2 : Pin muxing pour PWM, port H, reg. GPIOPCTL(p444), 4bits de PCM0=0001<=>PWM (voir p1261)
	;;il faut mettre mux = 2 pour avoir PH0=PWM2 et PH1=PWM3
		ldr r6, = GPIOPCTL_H 
		mov	r0, #0x02 
        str r0, [r6]
		
	;;Alternate Function Select (p 426), PD0 utilise alernate fonction (PWM au dessus)
	;;donc PD0 = 1
		ldr r6, = GPIOAFSEL_D
		ldr	r0, [R6] 	  ;*(int *)(0x40007000+0x00000420)= *(int *)(0x40007000+0x00000420) | 0x00000001;
        ORR	r0, r0, #0x01 ;
        str r0, [r6]

	;;MOT2 : Alternate Function Select (p 426), PH0 utilise PWM donc Alternate funct
	;;donc PH0 = 1
		ldr r6, = GPIOAFSEL_H
		ldr	r0, [R6] 	  ;*(int *)(0x40007000+0x00000420)= *(int *)(0x40007000+0x00000420) | 0x00000001;
        ORR	r0, r0, #0x01 ;
        str r0, [r6]
	
	;;-----------PWM0 pour moteur 1 connecté à PD0
	;;PWM0 produit PWM0 et PWM1 output
	;;Config Modes PWM0 + mode GenA + mode GenB
		ldr r6, = PWM0CTL
		mov	r0, #2		;Mode up-down-up-down, pas synchro
        str r0, [r6]	
		
		ldr r6, =PWM0GENA ;en decomptage, qd comparateurA = compteur => sortie pwmA=0
						;en comptage croissant, qd comparateurA = compteur => sortie pwmA=1
		mov	r0,	#0x0B0 	;0B0=10110000 => ACTCMPBD=00 (B down:rien), ACTCMPBU=00(B up rien)
		str r0, [r6]	;ACTCMPAD=10 (A down:pwmA low), ACTCMPAU=11 (A up:pwmA high) , ACTLOAD=00,ACTZERO=00  
		
		ldr r6, =PWM0GENB;en comptage croissant, qd comparateurB = compteur => sortie pwmA=1
		mov	r0,	#0x0B00	;en decomptage, qd comparateurB = compteur => sortie pwmB=0
		str r0, [r6]	
	;Config Compteur, comparateur A et comparateur B
  	;;#define PWM_PERIOD (ROM_SysCtlClockGet() / 16000),
	;;en mesure : SysCtlClockGet=0F42400h, /16=0x3E8, 
	;;on divise par 2 car moteur 6v sur alim 12v
		ldr	r6, =PWM0LOAD ;PWM0LOAD=periode/2 =0x1F4
		mov r0,	#0x1F4
		str	r0,[r6]
		
		ldr	r6, =PWM0CMPA ;Valeur rapport cyclique : pour 10% => 1C2h si clock = 0F42400
		mov	r0, #VITESSE
		str	r0, [r6]  
		
		ldr	r6, =PWM0CMPB ;PWM0CMPB recoit meme valeur. (rapport cyclique depend de CMPA)
		mov	r0,	#0x1F4	
		str	r0,	[r6]
		
	;Control PWM : active PWM Generator 0 (p1167): Enable+up/down + Enable counter debug mod
		ldr	r6, =PWM0CTL 
		ldr	r0, [r6]	
		ORR	r0,	r0,	#0x07
		str	r0,	[r6]

	;;-----------PWM2 pour moteur 2 connecté à PH0
	;;PWM1block produit PWM2 et PWM3 output
		;;Config Modes PWM2 + mode GenA + mode GenB
		ldr r6, = PWM1CTL
		mov	r0, #2		;Mode up-down-up-down, pas synchro
        str r0, [r6]	;*(int *)(0x40028000+0x040)=2;
		
		ldr r6, =PWM1GENA ;en decomptage, qd comparateurA = compteur => sortie pwmA=0
						;en comptage croissant, qd comparateurA = compteur => sortie pwmA=1
		mov	r0,	#0x0B0 	;0B0=10110000 => ACTCMPBD=00 (B down:rien), ACTCMPBU=00(B up rien)
		str r0, [r6]	;ACTCMPAD=10 (A down:pwmA low), ACTCMPAU=11 (A up:pwmA high) , ACTLOAD=00,ACTZERO=00  
		
 		;*(int *)(0x40028000+0x060)=0x0B0; //
		ldr r6, =PWM1GENB	;*(int *)(0x40028000+0x064)=0x0B00;
		mov	r0,	#0x0B00	;en decomptage, qd comparateurB = compteur => sortie pwmB=0
		str r0, [r6]	;en comptage croissant, qd comparateurB = compteur => sortie pwmA=1
	;Config Compteur, comparateur A et comparateur B
  	;;#define PWM_PERIOD (ROM_SysCtlClockGet() / 16000),
	;;en mesure : SysCtlClockGet=0F42400h, /16=0x3E8, 
	;;on divise par 2 car moteur 6v sur alim 12v
		;*(int *)(0x40028000+0x050)=0x1F4; //PWM0LOAD=periode/2 =0x1F4
		ldr	r6, =PWM1LOAD
		mov r0,	#0x1F4
		str	r0,[r6]
		
		ldr	r6, =PWM1CMPA ;Valeur rapport cyclique : pour 10% => 1C2h si clock = 0F42400
		mov	r0,	#VITESSE
		str	r0, [r6]  ;*(int *)(0x40028000+0x058)=0x01C2;
		
		ldr	r6, =PWM1CMPB ;PWM0CMPB recoit meme valeur. (CMPA depend du rapport cyclique)
		mov	r0,	#0x1F4	; *(int *)(0x40028000+0x05C)=0x1F4; 
		str	r0,	[r6]
		
	;Control PWM : active PWM Generator 0 (p1167): Enable+up/down + Enable counter debug mod
		ldr	r6, =PWM1CTL 
		ldr	r0, [r6]	;*(int *) (0x40028000+0x40)= *(int *)(0x40028000+0x40) | 0x07;
		ORR	r0,	r0,	#0x07
		str	r0,	[r6]		
		
	;;-----Fin config des PWMs			
		
	;PORT D OUTPUT pin0 (pwm)=pin1(direction)=pin2(slow decay)=pin5(12v enable)
		ldr	r6, =GPIODIR_D 
		ldr	r0, [r6]
		ORR	r0,	#(GPIO_0+GPIO_1+GPIO_2+GPIO_5)
		str	r0,[r6]
	;Port D, 2mA les meme
		ldr	r6, =GPIODR2R_D ; 
		ldr	r0, [r6]
		ORR	r0,	#(GPIO_0+GPIO_1+GPIO_2+GPIO_5)
		str	r0,[r6]
	;Port D, Digital Enable
		ldr	r6, =GPIODEN_D ;
		ldr	r0, [r6]
		ORR	r0,	#(GPIO_0+GPIO_1+GPIO_2+GPIO_5)	
		str	r0,[r6]	
	;Port D : mise à 1 de slow Decay et 12V et mise à 0 pour dir et pwm
		ldr	r6, =(GPIODATA_D+((GPIO_0+GPIO_1+GPIO_2+GPIO_5)<<2)) 
		mov	r0, #(GPIO_2+GPIO_5) ; #0x24
		str	r0,[r6]
		
	;MOT2, PH1 pour sens moteur ouput
		ldr	r6, =GPIODIR_H 
		mov	r0,	#0x03	; 
		str	r0,[r6]
	;Port H, 2mA les meme
		ldr	r6, =GPIODR2R_H
		mov r0, #0x03	
		str	r0,[r6]
	;Port H, Digital Enable
		ldr	r6, =GPIODEN_H
		mov r0, #0x03	
		str	r0,[r6]	
	;Port H : mise à 1 pour dir 
		ldr	r6, =(GPIODATA_H +(GPIO_1<<2))
		mov	r0, #0x02
		str	r0,[r6]		
		
		BX	LR	; FIN du sous programme d'init.

;Enable PWM0 (bit 0) et PWM2 (bit 2) p1145 
;Attention ici c'est les sorties PWM0 et PWM2
;qu'on controle, pas les blocks PWM0 et PWM1!!!
MOTEUR_DROIT_ON
		;Enable sortie PWM0 (bit 0), p1145 
		ldr	r6,	=PWMENABLE
		ldr r0, [r6]
		orr r0,	#0x01 ;bit 0 à 1
		str	r0,	[r6]
		BX	LR

MOTEUR_DROIT_OFF 
		ldr	r6,	=PWMENABLE
		ldr r0,	[r6]
		and	r0,	#0x0E	;bit 0 à 0
		str	r0,	[r6]
		BX	LR

MOTEUR_GAUCHE_ON
		ldr	r6,	=PWMENABLE
		ldr	r0, [r6]
		orr	r0,	#0x04	;bit 2 à 1
		str	r0,	[r6]
		BX	LR

MOTEUR_GAUCHE_OFF
		ldr	r6,	=PWMENABLE
		ldr	r0,	[r6]
		and	r0,	#0x0B	;bit 2 à 0
		str	r0,	[r6]
		BX	LR

MOTEUR_DROIT_ARRIERE
		;Inverse Direction (GPIO_D1)
		ldr	r6, =(GPIODATA_D+(GPIO_1<<2)) 
		mov	r0, #0
		str	r0,[r6]
		BX	LR

MOTEUR_DROIT_AVANT
		;Inverse Direction (GPIO_D1)
		ldr	r6, =(GPIODATA_D+(GPIO_1<<2)) 
		mov	r0, #2
		str	r0,[r6]
		BX	LR

MOTEUR_GAUCHE_ARRIERE
		;Inverse Direction (GPIO_D1)
		ldr	r6, =(GPIODATA_H+(GPIO_1<<2)) 
		mov	r0, #2 ; contraire du moteur Droit
		str	r0,[r6]
		BX	LR		

MOTEUR_GAUCHE_AVANT
		;Inverse Direction (GPIO_D1)
		ldr	r6, =(GPIODATA_H+(GPIO_1<<2)) 
		mov	r0, #0
		str	r0,[r6]
		BX	LR		

MOTEUR_DROIT_INVERSE
		;Inverse Direction (GPIO_D1)
		ldr	r6, =(GPIODATA_D+(GPIO_1<<2)) 
		ldr	r1, [r6]
		EOR	r0, r1, #GPIO_1
		str	r0,[r6]
		BX	LR

MOTEUR_GAUCHE_INVERSE
		;Inverse Direction (GPIO_D1)
		ldr	r6, =(GPIODATA_H+(GPIO_1<<2)) 
		ldr	r1, [r6]
		EOR	r0, r1, #GPIO_1
		str	r0,[r6]
		BX	LR

INIT_TIMER 
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION RCC 
		LDR R2, =RCC			; Adresse du registre RCC
		LDR R1, [R2]			; Contenue du registre RCC
		BIC R1, R1, #0X7C0      ; Effacer le champ OSCSRC
		ORR R1, R1, #RCC_OSCSRC_MAIN ; Sélectionner l'oscillateur principal
		ORR R1, R1, #(0x00<<6)  ; Définir la fréquence du cristal à 16 MHz
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
		ORR R1, R1, #1           ; Mettre le bit ENABLE à 1
		ORR R1, R1, #2           ; Mettre le bit TICKINT à 1 si les interruptions sont nécessaires
		STR R1, [R3]
		;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvFin configuration STCURRENT
		BX LR

RESET_TIMER
		ldr r0,=STCURRENT		 ; Adresse du registre STCTRL
		ldr r10,=0x0
		str r10, [r0]			 ; Ecriture de 0 dans le registre pour reset le timer 
		ldr r11,=0x0			 ; Remetre notre registre de seconde à 0
		BX LR

FREEZE_TIMER
		ldr r0,=0xE000E010		 ; Adresse du registre STCTRL
		ldr r10, [r0]
		AND r10, r10,#0xFFFFFFFE ; On Met le dernier bit a 0
		str r10, [r0]			 ; Ecriture de 0 dans le registre pour reset le timer 
		BX LR
		
UNFREEZE_TIMER
		ldr r0,=0xE000E010		 ; Adresse du registre STCTRL
		ldr r10, [r0]
		ORR r10, r10, #1           ; Mettre le bit ENABLE à 1
		str r10, [r0]			 ; Ecriture de 0 dans le registre pour reset le timer 
		BX LR
		
DISTANCE
        mov r5, #3                                
        mov r4, #2                                

        ; calcule de la distance en centimètre
        MUL r11,r11,r5    ; multipli r11 par 3
        udiv r11, r11,r4    ; divise r11 par 2
        mov r5, #0                                ; Contient les dizaines pour allumer la led2
        mov r4, #0                                ; Continent les unités pour allumer la led1

        ; Calcule les dizaines de la distance

dizaine
        cmp r11, #10    ; compare r11(distance) avec 10
        bmi finDizaine    ; r6 < 10 ? finDizaine : continue
        subs r11, #10    ; soustraire 10 de r6
        add r5, #1    ; incrémente r5 pour compterle nombre de dizaine
        b dizaine    ; Répéter

finDizaine
        add r4, r11     ; stock les unités réstantes dans r6

blinkDist    
		ldr r1, = DUREE                        ;; pour la duree de la boucle d'attente2 (wait2)
        ; compare les dizaines
        cmp r5, #0                        ;; Comapre les dizaines(r5) avec 0
        BEQ led2                        ;;
        subs r5, #1                        ;; Retire 1 aux dizaines(r5)
		ldr r3,=(BROCHE4_5 & 0x20)
        str r3, [r7]                        ;; Allume la led 2
        b wait2
; compare les unités
led2        
		cmp r4, #0                        ;; Compare les unités(r4) avec 0
        BEQ fin                            ;; 
        subs r4, #1                        ;; Retire 1 aux unités(r4)
		ldr r3,=(BROCHE4_5 & 0x10)
        str r3, [r7]                          ;; Allume LED1 portF broche 4&5 : 00110000 (contenu de r3)

wait2       subs r1, #1                        ;; temps allumé
            bne wait2

        str r2, [r7]                        ;; Eteint LED car r2 = 0x00
        str r2, [r12]
        ldr r1, = DUREE                     ;; pour la duree de la boucle d'attente1 (wait1)

wait10        subs r1, #1                        ;; temps éteint
            bne wait10

        b   blinkDist                        ;; boucle
fin
        bx lr                            ;; retourne sur le code principal



;; TIMER A ( abandonner)
Reset_Handlerone
; Pour le Stellaris LM3S8992, cela pourrait être, par exemple, 0x40030000
    ; Activation de l'horloge pour le GPTM (General Purpose Timer Module)
	

	
    ; Activation de l'horloge pour le TIMER0 en mode normal
    LDR R1, =0x01                     ; Bit correspondant à TIMER0
    LDR R2, =0x400FE104               ; Adresse du registre RCGC1
    STR R1, [R2]                      ; Écrire dans RCGC1 pour activer l'horloge de TIMER0

    ; Activation de l'horloge pour le TIMER0 en mode sommeil
    LDR R1, =0x01                     ; Bit correspondant à TIMER0
    LDR R2, =0x400FE114               ; Adresse du registre SCGC1
    STR R1, [R2]                      ; Écrire dans SCGC1 pour activer l'horloge de TIMER0

    ; Activation de l'horloge pour le TIMER0 en mode sommeil profond
    LDR R1, =0x01                     ; Bit correspondant à TIMER0
    LDR R2, =0x400FE124               ; Adresse du registre DCGC1
    STR R1, [R2]                      ; Écrire dans DCGC1 pour activer l'horloge de TIMER0

    ; Réinitialisation logicielle de TIMER0 si nécessaire
    LDR R1, =0x01                     ; Bit correspondant à TIMER0
    LDR R2, =0x400FE044               ; Adresse du registre SRCR1
    STR R1, [R2]                      ; Réinitialisation logicielle de TIMER0
    NOP                               ; Insérer un délai si nécessaire
    LDR R1, =0x0                      ; Valeur pour effacer le bit de réinitialisation
    STR R1, [R2]                      ; Effacer la réinitialisation logicielle de TIMER0



    ; Configuration du mode du timer
    LDR R0, =0x40030000          ; Pas nécessaire, R0 est déjà chargé avec cette valeur
    LDR R1, =0x4                 ; R1 = 1 (pour le mode RTC)
    STR R1, [R0, #0x000]         ; Écrit 1 dans GPTMCFG pour configurer le mode RTC

    ; Activation du timer
    LDR R0, =0x40030000          ; Pas nécessaire, R0 est déjà chargé avec cette valeur
    LDR R1, =0x1                 ; R1 = 1 (pour activer le timer)
    STR R1, [R0, #0x00C]         ; Écrit 1 dans GPTMCTL pour activer le timer

    ; Fin du gestionnaire de réinitialisation, retourne au programme principal
    BX LR
;;;

		END