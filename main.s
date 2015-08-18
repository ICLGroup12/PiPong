//                   ____  _    ____
//                  / __ \(_)  / __ \____  ____  ____ _
//                 / /_/ / /  / /_/ / __ \/ __ \/ __ `/
//                / ____/ /  / ____/ /_/ / / / / /_/ /
//               /_/   /_/  /_/    \____/_/ /_/\__, /
//                                            /____/
//                       A Group 12 Extension

b main


.space 1024                    // 1k full descending stack
stack:

back_buffer:
.space 614400                  // back buffer for 16 bit 640 x 480 display

.space 60                      // manually pad frame buffer structure to 16
                               // byte boundary

frame_buffer_info:
.4byte 640                     // +0x00 Physical width
.4byte 480                     // +0x04 Physical height
.4byte 640                     // +0x08 Virtual width
.4byte 480                     // +0x0c Virtual height
.4byte 0                       // +0x10 GPU pitch
.4byte 16                      // +0x14 GPU depth
.4byte 0                       // +0x18 X
.4byte 0                       // +0x1c Y
.4byte 0                       // +0x20 Buffer pointer
.4byte 0                       // +0x24 Buffer size

player_one_pos:                // top of player one's paddle
.4byte 216

player_two_pos:                // top of player two's paddle
.4byte 216

ball:
.4byte 318                     // +0x00 Ball x position
.4byte 254                     // +0x04 Ball y position
.4byte -4                      // +0x08 Ball x velocity
.4byte 4                       // +0x0c Ball y velocity


player_one_score:
.space 4
player_two_score:
.space 4

main:
    ldr sp, =stack             // set up stack

    bl init_pins
    bl setup_framebuffer

    ldr r1, =frame_buffer_info
    ldr r1, [r1, #0x20]
    cmp r1, #0
    moveq r0, #16
    bleq write_gpclr0          // turn GPIO16 LED on if we don't get a pointer


    game_start:                // return to here after resets

    ldr r0, =black_background
    bl swap_buffers            // set the background to black

    mov r0, #156
    mov r1, #110
    mov r2, #360
    mov r3, #176
    ldr r4, =start_screen_logo
    bl draw_image_slow         // transition the logo in 
                            

    start_loop:                // wait for any button presses to start the game
        mov r0, #24
        bl read_gplev0
        cmp r1, #1
        beq game_loop

        mov r0, #25
        bl read_gplev0
        cmp r1, #1
        beq game_loop

        mov r0, #23
        bl read_gplev0
        cmp r1, #1
        beq game_loop

        mov r0, #18
        bl read_gplev0
        cmp r1, #1
        beq game_loop

        bl draw_start_screen

        ldr r0, =black_background
        bl swap_buffers        // output and clear display
    b start_loop


    game_loop:                 // main game loop
        bl move_player_one
        bl move_player_two
        bl move_ball

        ldr r1, =player_one_score
        ldr r1, [r1]
        cmp r1, #11
        beq game_over          // end game when either player has score > 11

        ldr r1, =player_two_score
        ldr r1, [r1]
        cmp r1, #11
        beq game_over

        bl draw_scores
        bl draw_ball
        bl draw_player_one
        bl draw_player_two

        ldr r0, =game_background
        bl swap_buffers        // output and clear display to background image
    b game_loop


    game_over:
        ldr r0, =black_background
        bl swap_buffers        // clear screen to black

        bl draw_game_over_screen

        ldr r0, =black_background
        bl swap_buffers        // display screen then zero fill back buffer 

        ldr r0, =player_one_score
        mov r1, #0
        str r1, [r0]           // reset player 1 score to 0

        ldr r0, =player_two_score
        mov r1, #0
        str r1, [r0]           // reset player 2 score to 0

        mov r0, #4194304       // approx 4 sec delay before return to start
        bl wait

    b game_start


// ----------------------------------------------------------------------------
// Draw player one's paddle
// Clobbers: r0, r1, r2, r3
// ----------------------------------------------------------------------------
draw_player_one:
    stmdb sp!, {r4, lr}

    mov r0, #16                 // the top left x of player 1's paddle
    ldr r1, =player_one_pos
    ldr r1, [r1]
    mov r2, #8
    mov r3, #80
    ldr r4, =0xC000C000
    bl draw_rect

    ldmia sp!, {r4, lr}
    mov pc, lr

// ----------------------------------------------------------------------------
// Draw player two's paddle
// Clobbers: r0, r1, r2, r3
// ----------------------------------------------------------------------------
draw_player_two:
    stmdb sp!, {r4, lr}

    ldr r0, =616               // the top left x of player 2's paddle
    ldr r1, =player_two_pos
    ldr r1, [r1]
    mov r2, #8
    mov r3, #80
    ldr r4, =0x00120012
    bl draw_rect

    ldmia sp!, {r4, lr}
    mov pc, lr


// ----------------------------------------------------------------------------
// Draw ball
// Clobbers: r0, r1, r2, r3
// ----------------------------------------------------------------------------
draw_ball:
    stmdb sp!, {r4, lr}

    ldr r0, =ball
    ldr r0, [r0]               // r0 = ball x
    ldr r1, =ball
    ldr r1, [r1, #0x4]         // r1 = ball y
    mov r2, #4
    mov r3, #4
    mvn r4, #0

    bl draw_rect

    ldmia sp!, {r4, lr}
    mov pc, lr

// ----------------------------------------------------------------------------
// Draw rectangles at the top of the screen to represent each player's score
// Clobbers: r0, r1, r2, r3
// ----------------------------------------------------------------------------
draw_scores:
    stmdb sp!, {r4-r9, lr}

    mov r6, #4                 // score rectangle width
    mov r7, #14                // score rectangle height
    mov r8, #12                // y start for drawing score rectangles

    // setup for player 1 loop
    ldr r5, =player_one_score
    ldr r5, [r5]

    ldr r4, =0xC000C000        // p1 colour
    mov r9, #104               // p1 score x start
    draw_scores1:              // while r5 > 0
        cmp r5, #0
        ble draw_scores2

        mov r0, r9
        mov r1, r8
        mov r2, r6
        mov r3, r7
        bl draw_rect

        add r9, #6             // continue drawing with 2 pixel gap
        sub r5, #1
        b draw_scores1         // endwhile
    draw_scores2:


    // setup for player 2 loop
    ldr r5, =player_two_score
    ldr r5, [r5]

    ldr r4, =0x00120012        // p2 colour
    ldr r9, =532               // p2 score x start
    draw_scores3:              // while r4 > 0
        cmp r5, #0
        ble draw_scores4

        mov r0, r9
        mov r1, r8
        mov r2, r6
        mov r3, r7
        bl draw_rect

        sub r9, #6             // continue drawing with 2 pixel gap
        sub r5, #1
        b draw_scores3         // endwhile
    draw_scores4:

    ldmia sp!, {r4-r9, lr}
    mov pc, lr

// ----------------------------------------------------------------------------
// Draw the start screen. Logo and flashing prompt to press button
// Clobbers: r0, r1, r2, r3
// ----------------------------------------------------------------------------
draw_start_screen:
    stmdb sp!, {r4, lr}

    mov r0, #156
    mov r1, #110
    mov r2, #360
    mov r3, #176
    ldr r4, =start_screen_logo
    bl draw_image

    ldr r0, =0x20003004    // r0 = current time (microseconds)
    ldr r0, [r0]
    mov r1, #1
    lsl r1, #20            // check the 19th bit (changes roughly every
    tst r0, r1             // 0.5 seconds)
    beq no_draw_prompt     // if it's set then draw the press button
        mov r0, #161       // prompt
        mov r1, #356
        mov r2, #320
        mov r3, #16
        ldr r4, =start_screen_text
        bl draw_image
    no_draw_prompt:

    ldmia sp!, {r4, lr}
    mov pc, lr



// ----------------------------------------------------------------------------
// Draw the game over screen. Different colour bats for each player victory
// Clobbers: r0, r1, r2, r3
// ----------------------------------------------------------------------------
draw_game_over_screen:
    stmdb sp!, {r4, lr}

    ldr r1, =player_one_score
    ldr r1, [r1]
    ldr r2, =player_two_score
    ldr r2, [r2]
    cmp r1, r2
    bge game_over1         // determine who won

    mov r0, #208
    mov r1, #194
    mov r2, #224
    mov r3, #96
    ldr r4, =game_over_player2
    bl draw_image
    b game_over2           // draw player 2 win image

game_over1:
    mov r0, #208
    mov r1, #194
    mov r2, #224
    mov r3, #96
    ldr r4, =game_over_player1
    bl draw_image          // draw player 1 win image

game_over2:
    mov r0, #26
    mov r1, #12
    mov r2, #64
    mov r3, #16
    ldr r4, =score_text
    bl draw_image          // draw left score text

    mov r0, #552
    mov r1, #12
    mov r2, #64
    mov r3, #16
    ldr r4, =score_text
    bl draw_image          // draw right score text

    bl draw_scores
        
    ldmia sp!, {r4, lr}
    mov pc, lr

// ----------------------------------------------------------------------------
// Moves player one according to input
// Clobbers: r0, r1, r2, r3
// ----------------------------------------------------------------------------
move_player_one:
    stmdb sp!, {lr}

    ldr r3, =player_one_pos
    ldr r3, [r3]

    mov r0, #24                // check if p1 up button down
    bl read_gplev0
    cmp r1, #1                 // try to move up if button down
    addeq r3, #4

    mov r0, #25                // check if p1 down button down
    bl read_gplev0
    cmp r1, #1                 // try to move down if button down
    subeq r3, #4

    cmp r3, #48                // ensure we don't move the paddle above top
    blt move_player_one1

    cmp r3, #384               // ensure we don't move paddle below bottom
    bgt move_player_one1

    ldr r1, =player_one_pos
    str r3, [r1]               // save the new position

move_player_one1:
    ldmia sp!, {lr}
    mov pc, lr

// ----------------------------------------------------------------------------
// Moves player two according to input
// Clobbers: r0, r1, r2, r3
// ----------------------------------------------------------------------------
move_player_two:
    stmdb sp!, {lr}

    ldr r3, =player_two_pos
    ldr r3, [r3]

    mov r0, #23                // check if p2 up button down
    bl read_gplev0
    cmp r1, #1                 // try to move up if button down
    addeq r3, #4

    mov r0, #18                // check if p2 down button down
    bl read_gplev0
    cmp r1, #1                 // try to move down if button down
    subeq r3, #4

    cmp r3, #48                // ensure we don't move the paddle above top
    blt move_player_two1

    cmp r3, #384               // ensure we don't move paddle below bottom
    bgt move_player_two1

    ldr r1, =player_two_pos
    str r3, [r1]               // save the new position

move_player_two1:
    ldmia sp!, {lr}
    mov pc, lr

// ----------------------------------------------------------------------------
// Handles a score by player one by incrementing their score and resetting the
// ball
// Clobbers: r1 r2
// ----------------------------------------------------------------------------
increment_player_one_score:
    ldr r1, =player_one_score
    ldr r2, [r1]
    add r2, #1
    str r2, [r1]

    mov pc, lr

// ----------------------------------------------------------------------------
// Increments player two's score
// Clobbers: r1 r2
// ----------------------------------------------------------------------------
increment_player_two_score:
    ldr r1, =player_two_score
    ldr r2, [r1]
    add r2, #1
    str r2, [r1]

    mov pc, lr


// ----------------------------------------------------------------------------
// Waits a given amount of time
// Args: r0 - number of microseconds to wait for
// Clobbers: r1
// ----------------------------------------------------------------------------
wait:
    ldr r1, =0x20003004       // r1 = current time
    ldr r1, [r1]
    add r1, r1, r0            // r1 = current time + wait

wait1:                        // loop while current time < r1
    ldr r0, =0x20003004
    ldr r0, [r0]
    cmp r0, r1
    blt wait1

    mov pc, lr


// ----------------------------------------------------------------------------
// Resets the position of the player's paddles
// Clobbers: r0 r1 r2
// ----------------------------------------------------------------------------
reset_paddles:
    stmdb sp!, {lr}

    ldr r0, =player_one_pos
    ldr r1, =player_two_pos
    mov r2, #216
    str r2, [r0]
    str r2, [r1]

    ldmia sp!, {lr}


// ----------------------------------------------------------------------------
// Resets the position of the ball and sets it on a random velocity
// randomized based on the LSB of the system clock
// Clobbers: r0, r1, r2, r3
// ----------------------------------------------------------------------------
reset_ball:
    stmdb sp!, {lr}

    mov r0, #524288              // ~half second delay before reset
    bl wait

    ldr r1, =0x20003004          // 'randomize' x velocity of ball
    ldr r1, [r1]
    tst r1, #1

    movne r2, #4
    mvneq r2, #3

    ldr r1, =ball
    str r2, [r1, #0x8]           // save x velocity

    ldr r1, =0x20003004          // 'randomize' y velocity of ball
    ldr r1, [r1]
    tst r1, #1

    movne r2, #4
    mvneq r2, #3

    ldr r1, =ball
    str r2, [r1, #0xc]         // save y velocity

    ldr r1, =ball              // put ball back in middle
    ldr r2, =318
    ldr r3, =254
    str r2, [r1]
    str r3, [r1, #0x4]

    ldmia sp!, {lr}
    mov pc, lr

// ----------------------------------------------------------------------------
// Moves the ball according to its velocity and any collisions
// Clobbers: r0, r1, r2, r3
// ----------------------------------------------------------------------------
move_ball:
    stmdb sp!, {lr}

    ldr r0, =ball
    mov r2, r0
    ldr r1, [r0]               // r1 = x position
    ldr r2, [r2, #0x8]         // r2 = x velocity
    add r1, r2, r1             // r1 = x pos + x velocity
    str r1, [r0]               // save new x position

    // check for edge of screen collisions in x
    // if (x < 8 || x > 632) then x = -x and handle score
    cmp r1, #8
    blle increment_player_two_score
    blle reset_ball
    blle reset_paddles

    ldr r0, =ball 
    ldr r0, [r0]               // r0 = x position
    ldr r1, =628
    cmp r0, r1 
    blge increment_player_one_score
    blge reset_ball
    blge reset_paddles

move_ball1:                    // advance in y direction
    ldr r0, =ball
    mov r1, r0
    mov r2, r0                 
    ldr r1, [r1, #0x4]         // r1 = y position
    ldr r2, [r2, #0xc]         // r2 = y velocity
    add r1, r2, r1             // r1 = y pos + y velocity
    str r1, [r0, #0x4]         // save new y position

    // check for edge of screen collisions in y
    cmp r1, #40                // if (y <= 40 || y > 464) y = -y
    movle r1, r2               // r1 = current y velocity
    blle negate_y_vel

    ldr r1, =ball
    ldr r1, [r1, #0x4]

    cmp r1, #464
    movgt r1, r2              // r1 = current y velocity
    blgt negate_y_vel

move_ball2:

    // check for paddle collisions
    ldr r0, =ball              // r0 = ball x position
    ldr r0, [r0]

    // check for left paddle collision
    cmp r0, #24
    ble check_left_col         // if x <= 26 check for left collision

    ldr r1, =610
    cmp r0, r1
    bge check_right_col        // if x >= 610 check for right collision

    b move_ball3               // otherwise there won't be paddle collisions

check_left_col:
    // possible p1 paddle collision
    ldr r0, =ball
    ldr r0, [r0, #0x4]         // r0 = ball y position
    ldr r1, =player_one_pos
    ldr r1, [r1]               // r1 = player 1 paddle top

    sub r0, r0, r1
    cmn r0, #1
    ble move_ball3             // ball was above paddle
    cmp r0, #78
    bge move_ball3             // ball was below paddle

    // at this point there must have been a collision with the paddle

    cmp r0, #40                // top half collision
    mvnle r2, #3               // r2 = -4
    movgt r2, #4               // r2 = 4

    ldr r3, =ball
    str r2, [r3, #0xc]         // store the new y velocity

    mov r2, #4
    ldr r3, =ball
    str r2, [r3, #0x8]         // store new x velocity

    b move_ball3               // balls can't be in two places at once


check_right_col:
    // possible p2 paddle collision
    ldr r0, =ball
    ldr r0, [r0, #0x4]         // r0 = ball y position
    ldr r1, =player_two_pos
    ldr r1, [r1]               // r1 = player 2 paddle top

    sub r0, r0, r1
    cmn r0, #1
    ble move_ball3             // ball was above paddle
    cmp r0, #78
    bge move_ball3             // ball was below paddle

    // proceed like above, the only difference being x will be flipped

    cmp r0, #40
    mvnle r2, #3
    movgt r2, #4

    ldr r3, =ball
    str r2, [r3, #0xc]
    mvn r2, #3
    ldr r3, =ball
    str r2, [r3, #0x8]

move_ball3:
    ldmia sp!, {lr}
    mov pc, lr


// ----------------------------------------------------------------------------
// Negate the x velocity of the ball
// Args: r1 - current x velocity
// Clobbers: r3
// ----------------------------------------------------------------------------
negate_x_vel:
    mvn r1, r1                 // invert r1
    add r1, #1                 // add 1, now r1 is negated
    ldr r3, =ball
    str r1, [r3, #0x8]         // now x velocity is negated

    mov pc, lr

// ----------------------------------------------------------------------------
// Negate the y velocity of the ball
// Args: r1 - current y velocity
// Clobbers: r3
// ----------------------------------------------------------------------------
negate_y_vel:
    mvn r1, r1                 // invert r1
    add r1, #1                 // add 1, now r1 is negated
    ldr r3, =ball
    str r1, [r3, #0xc]         // now y velocity is negated

    mov pc, lr

// ----------------------------------------------------------------------------
// Initialize pins, setting them as inputs or outputs correctly and clearing
// Clobbers: r0, r1
// ----------------------------------------------------------------------------
init_pins:
    // 23, 24, 25 inputs
    ldr r0, =0x20200008
    mov r1, #0                 // we just set all pins as inputs
    str r1, [r0]

    // pin 18 as input, 16 as output
    ldr r0, =0x20200004
    ldr r1, =0x00040000 
    str r1, [r0]

    mov pc, lr


// ----------------------------------------------------------------------------
// Turn given pin in GPCLR0 register on
// Args: r0 - GPIO pin
// Clobbers: r1, r2
// ----------------------------------------------------------------------------
write_gpclr0:
    mov r1, #1
    mov r1, r1, lsl r0
    ldr r2, =0x20200028
    str r1, [r2]

    mov pc, lr


// ----------------------------------------------------------------------------
// Turn given pin in GPSET0 register on
// Args: r0 - GPIO pin
// Clobbers: r1, r2
// ----------------------------------------------------------------------------
write_gpset0:
    mov r1, #1
    mov r1, r1, lsl r0
    ldr r2, =0x2020001C
    str r1, [r2]

    mov pc, lr

// ----------------------------------------------------------------------------
// Get status of GPIO pin from pin level 0 GPIO register
// Args: r0 - GPIO pin
// Returns r1 - GPIO r0 status
// Clobbers: r2
// ----------------------------------------------------------------------------
read_gplev0:
    mov r1, #1
    mov r1, r1, lsl r0

    ldr r2, =0x20200034
    ldr r2, [r2]
    and r1, r1, r2
    mov r1, r1, lsr r0

    mov pc, lr

// ----------------------------------------------------------------------------
// Initialise a frame buffer by transacting with the PI's GPU
// Args: none
// Clobbers:
// ----------------------------------------------------------------------------
setup_framebuffer:
    stmdb sp!, {lr}

    ldr r0, =0x1               // request a frame buffer "form"
    ldr r1, =frame_buffer_info // provide our template
    orr r1, #0x40000000
    bl  mailbox_write
    bl  mailbox_read

    ldmia sp!, {lr}
    mov pc, lr

// ----------------------------------------------------------------------------
// Write a message to the mailbox
// Args: r1 - data, r0 - channel
// Clobbers: r2 r3
// ----------------------------------------------------------------------------
mailbox_write:
    ldr r2, =0x2000B880        // mailbox address

    ldr r3, [r2, #0x18]
    tst r3, #0x80000000
    bne mailbox_write          // check we're writing to the correct channel

    orr r1, r0, r1
    str r1, [r2, #0x20]        // store the value in the mailbox

    mov pc, lr

// ----------------------------------------------------------------------------
// Read a message from the mailbox
// Args: r0 - channel
// Returns: r1 - data
// Clobbers: r2 r3
// ----------------------------------------------------------------------------
mailbox_read:
    ldr r2, =0x2000B880        // mailbox address

    ldr r3, [r2, #0x18]        // check if mailbox is ready
    tst r3, #0x40000000
    bne mailbox_read           // repeat until ready or timeout

    and r1, r3, #0x0F          // check we're reading the correct channel
    teq r0, r1
    bne mailbox_read           // repeat until the channel is right

    bic r1, r3, #0xF           // get the value

    mov pc, lr

//-----------------------------------------------------------------------------
// Renders a rectangle of size r2xr3 and colour r4 starting at (r0, r1)
// Args: r0 - x, r1 - y, r2 - width, r3 - height, r4 - colour
// Clobbers:
// Note: Rectangle width must be a multiple of 4
//-----------------------------------------------------------------------------
draw_rect:
  stmdb sp!, {r5-r12}

  ldr r7, =frame_buffer_info
  ldr r7, [r7, #0x10]          // r7 = pitch
  ldr r6, =back_buffer         // r6 = backbuffer address

  mov r12, r4                  // duplicate colour in r12

  add r11, r1, r3              // r10 = y + height
draw_rect1:                    // while y < (y + height)
  mov r5, #0                   // r5 = 0
    draw_rect2:                // while r5 < width
      mla r8, r7, r1, r6       // r8 = backbuffer + y * pitch

      add r9, r0, r5           // r9 = x + r5  (current horizontal position)
      add r8, r8, r9, lsl #1   // r8 = backbuffer + (y * pitch) + (r9 * 2)

      stm r8, {r12, r4}        // pixels = colour

      add r5, #4               // r5++

      cmp r5, r2
      blt draw_rect2           // endwhile
  add r1, #1                   // y++

  cmp r1, r11
  blt draw_rect1               // while y < (y + height)

  ldmia sp!, {r5-r12}
  mov pc, lr

//-----------------------------------------------------------------------------
// Draws the image at image_start (size r2xr3) at position (r0, r1)
// Args: r0 - start_x, r1 - start_y, r2 - image_width, r3 - image_height,
//       r4 - image_start
// Clobbers:
// Note: The image width must be a multiple of 8
//-----------------------------------------------------------------------------
draw_image:
  stmdb sp!, {r5-r12}

  ldr r7, =frame_buffer_info
  ldr r7, [r7, #0x10]            // r7 = pitch
  ldr r8, =back_buffer           // r8 = backbuffer address

  mov r6, #0                     // y = 0
draw_image1:                     // while y < image_height
    mov r5, #0                   // x = 0
draw_image2:                     // while x < image_width

      mul r9, r6, r2             // r9 = y * image_width
      add r9, r9, r5             // r9  = y + image_width + x
      lsl r9, #1                 // r9  *= 2 (2 bytes per pixel)
      add r9, r9, r4             // r9  += image_start

      ldm r9, {r11, r12}         // copy 4 pixels at once

      add r9, r1, r6             // r9  = start_y + y
      mul r9, r7, r9             // r9  *= pitch
      add r10, r5, r0            // r10 = start_x + x
      lsl r10, #1                // r10 *= 2 (2 bytes per pixel)

      add r9, r10, r9            // r9 += 2 * (start_x + x)
      add r9, r8, r9             // r9 += back buffer start

      stm r9, {r11, r12}

      add r5, #4                 // x += 4 (4 pixels each time)
      cmp r5, r2
      blt draw_image2            // end draw_image1
    add r6, #1                   // y++
    cmp r6, r3
    blt draw_image1              // end draw_image2

  ldmia sp!, {r5-r12}
  mov pc, lr

//-----------------------------------------------------------------------------
// Draws the image at image_start (size r2xr3) at position (r0, r1)
// Draws it directly into the framebuffer with a delay between each draw,
// causing it to slowly appear on the screen 
// Args: r0 - start_x, r1 - start_y, r2 - image_width, r3 - image_height,
//       r4 - image_start
// Clobbers:
// Note: This function draws directly onto the framebuffer. Copying the 
//       backbuffer with swap_buffers will overwrite the image drawn.
//-----------------------------------------------------------------------------
draw_image_slow:
  stmdb sp!, {r5-r11, lr}

  ldr r7, =frame_buffer_info
  ldr r7, [r7, #0x10]            // r7 = pitch
  ldr r8, =frame_buffer_info     // r8 = backbuffer address
  ldr r8, [r8, #0x20]

  mov r6, #0                     // y = 0
draw_image_slow1:                // while y < image_height
    mov r5, #0                   // x = 0
draw_image_slow2:                // while x < image_width

      mul r9, r6, r2             // r9 = y * image_width
      add r9, r9, r5             // r9  = y + image_width + x
      lsl r9, #1                 // r9  *= 2 (2 bytes per pixel)
      add r9, r9, r4             // r9  += image_start

      ldr r11, [r9]              // copy 2 pixels at once

      add r9, r1, r6             // r9  = start_y + y
      mul r9, r7, r9             // r9  *= pitch
      add r10, r5, r0            // r10 = start_x + x
      lsl r10, #1                // r10 *= 2 (2 bytes per pixel)

      add r9, r10, r9            // r9 += 2 * (start_x + x)
      add r9, r8, r9             // r9 += frame buffer start

      str r11, [r9] 

      mov r9, r0                 // delay before next pixel
      mov r11, r1 
      mov r0, #128
      bl wait
      mov r0, r9
      mov r1, r11

      add r5, #2                 // x += 2 (2 pixels each time)
      cmp r5, r2
      blt draw_image_slow2       // end draw_image1
    add r6, #1                   // y++
    cmp r6, r3
    blt draw_image_slow1         // end draw_image2

  ldmia sp!, {r5-r11, lr}
  mov pc, lr



//-----------------------------------------------------------------------------
// Loads the back buffer into the display buffer then resets it to image at r0
// Args: r0 start address of image to fill back buffer with after swapping
// Clobbers: r1, r2, r3
// Note: the image in r0 must be at least the size of the display buffers or
//       this routing will read past the end of it
//-----------------------------------------------------------------------------
swap_buffers:
  stmdb sp!, {r4-r12}
  stmdb sp!, {r0}              // store image address until we need it later


  ldr r0, =back_buffer         // r0 = backbuffer address
  ldr r1, =frame_buffer_info
  ldr r1, [r1, #0x20]          // r1 = framebuffer address
  ldr r2, =frame_buffer_info
  ldr r2, [r2, #0x24]          // r2 = framebuffer size
  add r2, r1, r2               // r2 = end position

  swap_buffers1:               // while r3 < framebuffer size

      ldm r0!, {r3-r12}        // load 20 pixels from backbuffer
      stm r1, {r3-r12}         // store 20 pixels in the pi framebuffer

      add r1, #40

  cmp r1, r2                   // endwhile
  blt swap_buffers1

  ldmia sp!, {r0}              // retrieve image start address

  ldr r1, =back_buffer
  ldr r2, =frame_buffer_info
  ldr r2, [r2, #0x24]          // r2 = framebuffer size
  add r2, r1, r2               // end address

  swap_buffers2:
      ldm r0!, {r3-r12}        // load 20 pixels from the background image
      stm r1, {r3-r12}         // store 20 pixels in the backbuffer

      add r1, #40
  cmp r1, r2
  blt swap_buffers2


  ldmia sp!, {r4-r12}
  mov pc, lr


.ltorg                         // dump the literal pool here to keep image
                               // data labels in range


start_screen_logo:             // the 2 bat logo on the start screen
.incbin "start_screen_logo"

start_screen_text:             // the flashing press any button to start text
.incbin "start_screen_text"

game_background:               // flattened image containing playing area and
.incbin "background"

game_over_player1:             // 2 blue bat logo for p1 victory
.incbin "game_over_player1"

game_over_player2:             // 2 red bat logo for p2 victory
.incbin "game_over_player2"

score_text:                    // seperate score text for victory screen
.incbin "score_text"

black_background:              // fill with zeros to size of buffer
.space 614400
