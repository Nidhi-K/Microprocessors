#make_bin#

#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#

; add your code here 
jmp st1
db 1024 dup(0)    
st1:cli          
m_shape db 0 
m_amp db 0
m_freq dw 0 
m_cnt db  0 
m_freq1 dw 0 
 
; internal addresses of 8255-1
portA1 equ 00H
portB1 equ 02H
portC1 equ 04H
creg551 equ 06H  
	
; internal addresses of 8255-2
portA2 equ 08H
portB2 equ 0AH
portC2 equ 0CH
creg552 equ 0EH 
	
; internal addresses of Timer-1
counter10 equ 10H
counter11 equ 12H
counter12 equ 14H
cregtimer1 equ 16H      
	
; internal addresses of Timer-2
counter20 equ 18H
counter21 equ 1AH
counter22 equ 1CH
cregtimer2 equ 1EH    


list1 db 128,140,152,165,176,188,198,208,218,226,234,240,245,250,253,254,255,254,253,250,245,240,234,226,218,208,198,188,176,165,152,140,128,115,103,90,79,67,57,47,37,29,21,15,10,5,2,1,0,1,2,5,10,15,21,29,37,47,57,67,79,90,103,115

list2 db 128,136,144,152,160,168,176,184,192,200,208,216,224,232,240,248,255,248,240,232,224,216,208,200,192,184,176,168,160,152,144,136,128,120,112,104,96,88,80,72,64,56,48,40,32,24,16,8,0,8,16,24,32,40,48,56,64,70,80,88,96,104,112,120
   	
;intialize ds, es,ss to start of RAM
          mov       ax,0200h
          mov       ds,ax
          mov       es,ax
          mov       ss,ax
          mov       sp,0FFFEH	
                       
;control word of 8255-1
mov al,10011010b
out creg551,al     
   
;setting the lower port c as 0
mov al,00000000b  ;PC0
out creg551,al

mov al,00000010b  ;PC1
out creg551,al 
          
mov al,00000100b ;PC2
out creg551,al 
            
mov al,00000110b ;PC3
out creg551,al   
          
;programming timer 1 and 2 
mov al,00010000b    ;counter 0 of timer 1
out cregtimer1,al 
          
mov al,01010000b    ;counter 1 of timer 1
out cregtimer1,al
          
mov al,10010000b    ;counter 2 of timer 1
out cregtimer1,al
          
mov al,00010000b    ;counter 0 of timer 2
out  cregtimer2,al 
;moving intial counts into timer
            
mov al,100       
out counter10,al ;for freq=1K

mov al,10   
out counter11,al ;for freq=100
out counter12,al ;for freq=10 

mov al,9
out counter20,al ;for max amp=8;
                
;if switch not pressed, it is high      
;checking if some shape has been pressed              
check_shape:    in al,portA1
                mov bl,al
                and al,01h
                jz sq    ;checking if square has been pressed
      
                mov al,bl
                and al,02h
                jz tri    ;checking if tri has been pressed
     
                mov al,bl     
                and al,04h
                jz sine  ;checking if sine has been pressed
                
                jnz check_shape   ;if nothing has been pressed 
     
;updating shape variable
sq:     mov m_shape,1
        jmp gate_high 
          
tri:    mov m_shape,2
        jmp gate_high  
         
sine:   mov m_shape,3
           
;making the gate of all frequency buttons high to start counting for key press
                     
gate_high:   mov al,00000001b  ;PC0
             out creg551,al  
               
           
             mov al,00000011b  ;PC1
             out creg551,al               ;bitset reset
          
             mov al,00000101b ;PC2
             out creg551,al   
               

check_amp:   in al,portA1
             and al,08h
             jnz check_amp
               
             ;make the gate of amplitude high
             mov al,00000111b  ;PC3
             out creg551,al 
               
             ;now set the frequency gates to 0
             mov al,00000000b  ;PC0
             out creg551,al
           
             mov al,00000010b  ;PC1
             out creg551,al 
         
             mov al,00000100b ;PC2
             out creg551,al 
  
check_gen:   in al,portA1
             and al,10H
             jnz check_gen 
               
             ;now set the amplitude gate to 0
             mov al,00000110b ;PC3
             out creg551,al 
               
calc_freq:   mov al,11011110b ;readback mode
             out cregtimer1,al
               
             in al,counter10  ;freq=1K
             mov bh,al  
             
             in al,counter11  ;freq=100
             mov ch,al
             
             in al,counter12  ;freq=10
             mov dh,al
              
             mov al,bh
             
             cmp al,0
             jnz x11 
               
             mov al,99 
             jmp x12
               
       x11:  cmp al,100
             jbe sub_count
             mov al,99 
             jmp x12
                     
sub_count:   mov bl,100
             sub bl,al
             mov al,bl    

       x12:  ;calculating frequency
             mov bl,100 
             mul bl
             mov m_freq,ax
               
               
             mov al,ch
             
             cmp al,0
             jnz x21 
               
             mov al,9 
             jmp x22
               
       x21:  cmp al,10
             jbe sub_count1
             mov al,9 
             jmp x22
                     
sub_count1:  mov bl,10
             sub bl,al
             mov al,bl    

       x22:  ;calculating frequency
             mov bl,10 
             mul bl
             add m_freq,ax
               
               
             mov al,dh
               
             cmp al,0
             jnz x31 
               
             mov al,9 
             jmp x32
               
       x31:  cmp al,10
             jbe sub_count2   
             mov al,9 
             jmp x32
                     
sub_count2 : mov bl,10
             sub bl,al
             mov al,bl    

       x32:  ;calculating frequency   
             mov ah,0
             add m_freq,ax
               
               
               
             ;calculating amplitude
               
             mov al,00000000b
             out cregtimer2,al
            
             in al,counter20              
               
             cmp al,0
             jnz x41 
               
             mov al,8 
             jmp x42
               
       x41:  cmp al,9
             jb sub_countamp
             mov al,8 
            
             jmp x42 
                
sub_countamp:  mov bl,9
               sub bl,al
               mov al,bl
             
       x42:  mov m_amp,al  
           
             ;At this point, we have calculated 
             ;the frequency and amplitude
            
             ;initializing 8255-2
            
             mov al,10001001b
             out creg552,al  
             mov al,32
             mul m_amp
             
             ;handling amplitude 
             mov bx,8
             cmp ax,bx
             jz amp1
             jmp post_amp
             
       amp1: sub m_amp,1      
             
   post_amp: ;goes to DAC1
             out portA2,al
            
             
             ;Now we will check for which shape has been pressed   
            
             mov al,m_shape  
          
check_sqr:   cmp al,1 
             jne check_tri
             call initcount
             call sq_module  
            
check_tri:   cmp al,2
             jne check_sin
             call initcount
             call tri_module
  
  
check_sin:   cmp al,3
             jne check_shape
             call initcount           
             call sin_module  
        initcount proc 
             ;initial section of this proc is for calculating the count value
             ;for frequencies above 9800Hz
             ;we are using 64 samples over the time period
        
        
             ;count=2.5 megahertz/(64*m_freq) 
            
             mov ax,m_freq  
             cmp ax,9800
             jb count12
             mov m_freq1,ax
             add ax,50
             mov bl,100
             div bl
             mov bl,al
             
             mov ax,39
             div bl
             mov ah,0
             mov m_cnt,al  
       count_init: mov al,01010110b    ;initialize counter 1 of timer 2 
                            ;mode 3
        out  cregtimer2,al  ;(counter 1 of timer 2 is 
                            ; used to enable changing of counts
                            ; to DAC2)  
        mov al,m_cnt                    
        out counter21,al    ;loading LSB into counter 
        jmp x777
        count12: 
        
        x777:nop
           
        ret 
	endp                    
  
        sq_module proc   
    
 start: mov cx,32                     
        
   k1:  mov al,255          ;displaying high part of wave
        out portB2,al   
   
   l1:  in al,portC2
        and al,01h          ;PC0
        cmp al,00h          ;checking if gate goes low
        jne l1              
                            
      
   l2:  in al,portC2
        and al,01h          ;PC0
        cmp al,01h          ;checking if gate goes high
        jne l2              
        loop k1 
        
        
        mov cx,32
         
      
   k2:  mov al,0            ;displaying low part of wave
        out portB2,al
                      
   l3:  in al,portC2
        and al,01h          ;PC0
        cmp al,00h          ;checking if gate goes low
        jne l3              
                            
      
   l4:  in al,portC2
        and al,01h          ;PC0
        cmp al,01h          ;checking if gate goes high
        jne l4              
        loop k2
        
        in al,portA1        ;checking if generate key has been pressed
        mov bl,al
        and al,10h
        jnz check_shape
        
        mov al,bl
        and al,02h
        jz trimod    ;checking if tri has been pressed
     
        mov al,bl     
        and al,04h
        jz sinemod   ;checking if sine has been pressed       
        jnz start  
        
        trimod:call tri_module
        jmp k4 
        
        sinemod:call sin_module
        k4:nop
        ret
        endp                             
        
        
        tri_module proc    
       
    start1: lea di,list2    ;loading the offset of start of sine lookup table values
            mov cx, 64             

   trisrt:  mov al,[di]        
            out portB2,al
                       
      tri1: in al,portC2
            and al,01h     ;PC0
            cmp al,00h     ;checking if gate goes low
            jne tri1       
            
      tri2: in al,portC2
            and al,01h     ;PC0
            cmp al,01h     ;checking if gate goes high
            jne tri2       
            
            inc di
            loop trisrt 
            

	    in al,portA1 
            mov bl,al
            and al,10h     ;checking if generate key has been pressed
            jnz check_shape
        
            mov al,bl
            and al,01h
            jz sq_mod1    ;checking if sq has been pressed
     
            mov al,bl     
            and al,04h
            jz sinemod1   ;checking if sine has been pressed 
            jnz start1 
        
            sq_mod1:call sq_module
            jmp k5 
        
            sinemod1:call sin_module
            k5:nop
            ret
            endp 
            
           
        sin_module proc 
               
  
                 
    start2: lea di,list1    ;loading the offset of start of triangle lookup table values
            mov cx, 64             

   sinesrt: mov al,[di]        
            out portB2,al
                       
      sin1: in al,portC2
            and al,01h     ;PC0
            cmp al,00h     ;checking if gate goes low
            jne sin1       
            
      sin2: in al,portC2
            and al,01h     ;PC0
            cmp al,01h     ;checking if gate goes high
            jne sin2       
            
            inc di
            loop sinesrt 
            
      
           
            in al,portA1
            mov bl,al
            and al,10h     ;checking if generate key has been pressed
            jnz check_shape
        
            mov al,bl
            and al,01h
            jz sq_mod2     ;checking if sq has been pressed
     
            mov al,bl     
            and al,04h     ;checking if tri has been pressed
            jz trimod2   
            jnz start2 
            
            sq_mod2:call sq_module 
            jmp k7  
            
            trimod2:call tri_module
            k7:nop
            ret
            endp                 

HLT           ; halt!




