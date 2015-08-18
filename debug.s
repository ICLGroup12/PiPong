// ----------------------------------------------------------------------------
//        ________  _______   ________  ___  ___  ________                     
//       |\   ___ \|\  ___ \ |\   __  \|\  \|\  \|\   ____\                    
//       \ \  \_|\ \ \   __/|\ \  \|\ /\ \  \\\  \ \  \___|                    
//        \ \  \ \\ \ \  \_|/_\ \   __  \ \  \\\  \ \  \  ___                  
//         \ \  \_\\ \ \  \_|\ \ \  \|\  \ \  \\\  \ \  \|\  \                 
//          \ \_______\ \_______\ \_______\ \_______\ \_______\                
//           \|_______|\|_______|\|_______|\|_______|\|_______|                
//                                                                             
// ----------------------------------------------------------------------------
// Set number to be printed out. r6 = number.                                  
// ----------------------------------------------------------------------------
output_number:

    mov r10, lr             // backup link register

    mov r0, #1
    lsl r0, #6              // set pin 2 output

    mov r1, #1
    lsl r1, #12
    orr r0, r1              // set pin 4 output

    ldr r1, =0x20200000
    str r0, [r1]            // store pin settings

    ldr r5, =0x20003004
    ldr r5, [r5]
    add r5, #1048576

    mov r4, #1

    bl led_one_off
    bl led_zero_off

    print:
        tst r4, r6
        blne led_one_on
        tst r4, r6
        bleq led_zero_on

        delay:        
            ldr r2, =0x20003004
            ldr r2, [r2]
            cmp r2, r5
            ble delay
            add r5, #1048576

        bl led_one_off
        bl led_zero_off

        delay2:        
            ldr r2, =0x20003004
            ldr r2, [r2]
            cmp r2, r5
            ble delay2
            add r5, #1048576

        lsr r6, #1

        cmp r6, #0
        bgt print

        bl led_zero_on
        bl led_one_on

        mov lr, r10
        mov pc, lr

// ----------------------------------------------------------------------------
// LED binary 1 ON
// Args:
// Clobbers: r0, r1
// ----------------------------------------------------------------------------
led_one_on:
    mov r0, #1
    lsl r0, #4
    ldr r1, =0x20200028
    str r0, [r1]       // turn pin low

    mov pc, lr

// ----------------------------------------------------------------------------
// LED binary 1 OFF
// Args:
// Clobbers: r0, r1
// ----------------------------------------------------------------------------
led_one_off:
    mov r0, #1
    lsl r0, #4
    ldr r1, =0x2020001C
    str r0, [r1]       // turn pin low

    mov pc, lr

// ----------------------------------------------------------------------------
// LED binary 0 ON
// Args:
// Clobbers: r0, r1
// ----------------------------------------------------------------------------
led_zero_on:
    mov r0, #1
    lsl r0, #2
    ldr r1, =0x20200028
    str r0, [r1]       // turn pin low

    mov pc, lr

// ----------------------------------------------------------------------------
// LED binary 0 OFF
// Args:
// Clobbers: r0, r1
// ----------------------------------------------------------------------------
led_zero_off:
    mov r0, #1
    lsl r0, #2
    ldr r1, =0x2020001C
    str r0, [r1]       // turn pin low

    mov pc, lr

// ----------------------------------------------------------------------------
// Blink a number of times to show an error
// Args: r1: number of times to blink
// Clobbers: r0, r1, r2, r3, r4
// ----------------------------------------------------------------------------
blink_error:
    mov r10, lr
    mov r4, r1  // r4 = number of times to blink

blink_error1:
    mov r0, #16 // r0 = pin
    bl write_gpclr0
    bl wait_a_sec 
    mov r0, #16 // r0 = pin
    bl write_gpset0
    bl wait_a_sec 
    
    sub r4, #1 
    cmp r4, #1
    bge blink_error1
    
    mov lr, r10
    mov pc, lr

// ----------------------------------------------------------------------------
// Wait for roughly one second
// Clobbers: r1, r0
// ----------------------------------------------------------------------------
wait_a_sec:
    ldr r0, =0x20003004
    ldr r0, [r0]
    mov r1, #0x100000
    add r0, r1
    wait_a_sec1:
        ldr r1, =0x20003004
        ldr r1, [r1]
        cmp r1, r0
        ble wait_a_sec1

    mov pc, lr
