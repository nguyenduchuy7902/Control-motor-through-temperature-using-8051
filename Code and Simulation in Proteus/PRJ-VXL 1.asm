ORG 0000h
ljmp main
RS bit P2.0
RW bit P2.1
E  bit P2.2
lcd_port equ P0
adc_ale bit P2.7
adc_data equ P1
pwm_out bit P2.3
IN2 bit P3.0
ENA bit P3.1
button_1 bit P3.4
button_2 bit P3.5
lcd_data equ 30h
ORG 0013h
   ljmp ISR_T1
   

ORG 0030h
main:
   acall lcd_init	;init LCD
   mov IE,#10000100b	;Enable external interrupt 1 
   acall lcd_display    ;display LCD
   SETB P3.1; Define clockwise rotation direction of motor 
   CLR P3.0; Define clockwise rotation direction of motor 
loop:
   acall lcd_display
   acall auto_mode; define auto_mode of motor
sjmp loop
  
lcd_display:
      mov A,#80h
      acall lcd_cmd
      mov A,#" "
      acall lcd_write
      mov A,#" "
      acall lcd_write
      mov A,#" "
      acall lcd_write
      mov A,#"T"
      acall lcd_write
      mov A,#"E"
      acall lcd_write
      mov A,#"M"
      acall lcd_write
      mov A,#"P"
      acall lcd_write
       mov A,#":"
      acall lcd_write
      mov A,#" "
      acall lcd_write
      mov A,#" "
      acall lcd_write
      mov A,#" "
      acall lcd_write

ret
auto_mode:
      
      mov A,P1; move decimal temperature value into A register
      CLR C   ;delete C after compare with threshold temp
      subb A,#25; compare with threshold temperture(T=25oC) to define pwm_duty 50 or 80
      jc pwm_duty50
      jnc pwm_duty80 
return:acall temp_display
ret
     

temp_display: ;separate each number in temperature value to display each in LCD
	 mov A,P1
	 mov B,#100
	 div AB
	 ADD A,#'0'            ;convert number into character in LCD
	 acall lcd_write
	 mov A,B
	 mov B,#10
	 div AB
	 ADD A,#'0'     ;convert number into character in LCD
	 acall lcd_write
	 mov a,b
	 ADD A, #'0'    ;convert number into character in LCD
	 call lcd_write
	 mov A,#'o'
	 acall lcd_write
	 mov A,#'C'
	 acall lcd_write	 
	
ret
   
lcd_cmd:
   clr RS ;indicating a command will be sent to the LCD
   clr RW ;data will be written to the LCD
   SETB E ;enabling the signal pulse to synchronize the data write
   mov lcd_port,A
   CLR E   ;the successful transmission of data to the LCD
   acall delay
ret

lcd_write:
   setb RS   ;indicating data will be sent to the LCD.
   clr RW    ;data will be written to the LCD
   SETB E    ;enabling the signal pulse to synchronize the data write
   mov lcd_port,A
   CLR E     ;the successful transmission of data to the LCD
   acall delay
ret

lcd_init:
   mov A,#0ch; TURN ON LCD and Pointer
   acall lcd_cmd
   mov A,#80h; Return Pointer back the first position
   acall lcd_cmd
   mov A,#06h; Increment Pointer
   acall lcd_cmd
   mov A, #01h; Clear all LCD
   acall lcd_cmd
   mov A, #02h; Return main LCD
   acall lcd_cmd
ret


pwm_duty50: ;set time signal pulse in high equals to in low
   setb pwm_out
   acall delay_ms
   acall delay_ms
   clr pwm_out
   acall delay_ms
   acall delay_ms
jmp return; come back to display temp in LCD

pwm_duty80: ;set time signal pulse in high equals 4 times  in low
   setb pwm_out
   acall delay_ms
   acall delay_ms
   acall delay_ms
   acall delay_ms
   clr pwm_out
   acall delay_ms
jmp return; come back to display temp in LCD

delay:
   mov R2, #50 
   djnz R2,$
ret

delay_ms:
   mov R3, #50
   PAUSE: mov R6,#100
   djnz R6,$
   djnz R3,PAUSE
ret

ISR_T1:
   set_up:	
      acall lcd_display
      acall temp_display
      clr pwm_out; when 0 external interrupt happens, reset PWM
     
      jb P3.3,RETURNI	;get off range of interrupt when P3.3 is not pressed
      jnb button_1,set_duty50;if button_1 is pressed set duty 50%
      jnb button_2,set_duty80;if button_2 is pressed set duty 80%
      jmp set_up; come back set_up to check each button
   set_duty50:
      acall lcd_display
      acall temp_display
      jnb button_2,stop	;stop if all button is pressed
      lcall pwm_duty50 	
      jmp set_up; come back set_up to check each button
    set_duty80:
      acall lcd_display
      acall temp_display
      lcall pwm_duty80
      jmp set_up; come back set_up to check each button
    stop: 
      CLR pwm_out
RETURNI: reti
end