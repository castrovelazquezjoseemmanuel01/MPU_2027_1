;Program: external interrupt via push button (Toggle LED)
;author: jlbPacheco (adapted)
;GPIO & EXTI programming flow


;GPIO Programming flow
; 1) enable GPIOA,C and AFIO bus clock
; 2) configure GPIOx_CRL/CRH set mode and speed
; 3) access data registers ODR/IDR/BSRR

;EXTIx Programming flow
; 1) configure PYn like input in pull-up/pull-down.
; 2) map EXTI0 in PXn (AFIO_EXTICR1)
; 3) unmask EXTIx (EXTI_IMR)
; 4) configure edge trigger (EXTI_FTSR/EXTI_RTSR)
; 5) congigure interruption flag (EXTI_PR)
; 6) eneable EXTIx in NVIC
; 7) handle EXTIx (ISR)


; Assembler directives
;--------------------
            area constants, data, readonly

RCC_APB2ENR  equ 0x40021018
GPIOA_CRL    equ 0x40010800
GPIOA_ODR    equ 0x4001080C
GPIOC_CRH    equ 0x40011004
GPIOC_ODR    equ 0x4001100C

AFIO_EXTICR1 equ 0x40010008
EXTI_IMR     equ 0x40010400
EXTI_FTSR    equ 0x4001040C
EXTI_PR      equ 0x40010414
NVIC_ISER0   equ 0xE000E100     ; First interrupt set-enable register, controls IRQ0 to IRQ31 (EXTI0 = IRQ6)

; Program
;--------
            area p_04, code, readonly
            export __main
            export EXTI0_IRQHandler

; Main program begin
;-------------------
__main
    ;Enable GPIO and AFIO clocks
    ldr r0, =0x00000015			; Bit 4 = GPIOC, bit 2 = GPIOA, bit 0 = AFIO
    ldr r1, =RCC_APB2ENR
    str r0, [r1]


    ;Configure PA0 as input with pull-up/pull-down (push button)
    ldr r0, =0x44444448			; PA0 configured as input with pull-up/pull-down
    ldr r1, =GPIOA_CRL
    str r0, [r1]


    ldr r0, =0x00000001			; Enable the internal pull-up resistor on PA0
    ldr r1, =GPIOA_ODR
    str r0, [r1]


    ;Configure PC13 mode and speed (LED)
    ldr r0, =0x44244444			; Push-pull output, maximum speed 2 MHz
    ldr r1, =GPIOC_CRH
    str r0, [r1]


    ;Initially turn off the LED
    ldr r0, =0x00002000
    ldr r1, =GPIOC_ODR
    str r0, [r1]


    ;Configure AFIO to connect the GPIO port to the EXTI line
    ldr r0, =0x00000000			; Map EXTI0 to PA0
    ldr r1, =AFIO_EXTICR1
    str r0, [r1]


    ;Configure EXTI interrupt mask and edge trigger
    ldr r0, =0x00000001			; Unmask EXTI0 interrupt request
    ldr r1, =EXTI_IMR
    str r0, [r1]

    ldr r0, =0x00000001			; Enable falling-edge trigger
    ldr r1, =EXTI_FTSR
    str r0, [r1]


    ;Enable EXTI0 interrupt in the NVIC
    ldr r0, =0x00000040			; Enable EXTI0 in NVIC (IRQ6)
    ldr r1, =NVIC_ISER0
    str r0, [r1]

loop
    wfi							; Wait for interrupt
    b loop



;Interrupt Service Routine (ISR)
;----------------------------------------------------------------------
EXTI0_IRQHandler

    ; Read the current state of the output data register (ODR)
    ldr r1, =GPIOC_ODR
    ldr r0, [r1]				; Load the current output states into R0


    ; Apply XOR (EOR) to bit 13 to toggle its state
    ldr r2, =0x00002000			; Bit 13 mask
    eor r0, r0, r2				; R0 = R0 XOR 0x2000 (0 becomes 1, 1 becomes 0)


    ; Store the new output state in the ODR
    str r0, [r1]


    ; Clear the EXTI0 pending interrupt flag in EXTI_PR
    ldr r0, =0x00000001
    ldr r1, =EXTI_PR
    str r0, [r1]


    bx lr						; Return from interrupt


; End of program
;---------------
    end