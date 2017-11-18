{{
        File:     game.spin
        Author:   Connor Spangler
        Date:     11/3/2017
        Version:  2.0
        Description: 
                  This file contains the PASM code defining a test arcade game
}}

CON
  ' Clock settings
  _clkmode = xtal1 + pll16x     ' Standard clock mode w/ 16x PLL
  _xinfreq = 5_000_000          ' 5 MHz clock for x16 = 80 MHz

  ' Constants defining screen dimensions
  vTilesH = 10  ' Number of visible tiles horizontally                                          
  vTilesV = 10  ' Number of visible tiles vertically

  ' Constants defining memory tile palette
  tSizeH = 16   ' Width of tiles in pixels 
  tSizeV = 16   ' Height of tiles in pixels

  ' Constants defining memory tile map
  tMapSizeH = 16  ' Horizontal tile map size in words
  tMapSizeV = 15  ' Vertical tile map size in words

  ' Constants defining calculated attributes
  sMaxH = tMapSizeH - vTilesH   ' Maximum horizontal scroll
  sMaxV = tMapSizeV - vTilesV   ' Maximum vertical scroll

  ' Enumeration of video modes
  #0
  VGA_mode      ' VGA video mode
  RGBS_mode     ' RGBS video mode
  NTSC_mode     ' NTSC video mode 

OBJ
  input         : "input"       ' Import input system
  graphics      : "graphics"    ' Import graphics system
  
VAR
  ' Graphic resources pointers
  long  tile_map_base_          ' Register pointing to base of tile maps
  long  tile_palette_base_      ' Register pointing to base of tile palettes
  long  color_palette_base_     ' Register pointing to base of color palettes

  ' Game resource pointers
  long  input_state_base_       ' Register in Main RAM containing state of inputs
  long  cur_pos_base_           ' Current horizontal tile position

PUB main | started
  tile_map_base_ := @tile_maps                                                                          ' Point tile map base to base of tile maps
  tile_palette_base_ := @tile_palettes                                                                  ' Point tile palette base to base of tile palettes
  color_palette_base_ := @color_palettes                                                                ' Point color palette base to base of color palettes
  input_state_base_ := @input_states                                                                    ' Point input stat base to base of input states
  cur_pos_base_ := @positions                                                                           ' Point current position base to base of positions                
                           
  graphics.config(VGA_mode, @tile_map_base_, vTilesH, vTilesV, tSizeH, tSizeV, tMapSizeH, tMapSizeV)    ' Configure graphics engine
  graphics.start                                                                                        ' Start graphics engine
  input.start(@input_state_base_)                                                                       ' Start input system                        
  cognew(@game, @tile_map_base_)                                                                        ' Start game
  'cognew(@testing, cur_pos_base_)                                                                       ' Start testing routine
                                                                                                        
  started := true                                       ' Initialize video driver status
  repeat                                                ' Loop infinitely
    if (control_state & 8) AND started                  ' Test button #4 and that the video driver is started                  
      graphics.stop                                     ' Stop the video driver
      started := false                                  ' Set started status to false
    elseif (control_state & 4) AND !started             ' Test button #3 and that the video driver is not started
      graphics.start                                    ' Start the video driver
      started := true                                   ' Set started status to true

DAT
        org             0
game    ' Initialize variables
        mov             tmbase, par             ' Load Main RAM tile map base address into tile map base
        mov             isbase, par             ' Load Main RAM tile map base address into input state base
        mov             pobase, par             ' Load Main RAM tile map base address into position base
        add             isbase, #12             ' Point input state pointer to its Main RAM register
        add             pobase, #16             ' Point position pointer to its Main RAM register
        rdlong          tmptr,  tmbase          ' Load tile map base pointer
        rdlong          isptr,  isbase          ' Load input state base pointer
        rdlong          poptr,  pobase          ' Load position base pointer
        mov             xbase,  poptr           ' Set horizontal position base address
        mov             ybase,  poptr           ' Set vertical position base address       
        add             ybase,  #4              ' Increment vertical position base address

        ' Initialize game map attributes
        mov             xpos,   #0              ' Initialize horizontal position
        mov             ypos,   #0              ' Initialize vertical position        
        mov             xbound, #sMaxH          ' Initialize horizontal boundry of tile map
        mov             ybound, #sMaxV          ' Initialize vertical boundry of tile map

        ' Initialize input attributes
        mov             psL,    #0              ' Initialize left push state register                
        mov             psR,    #0              ' Initialize right push state register  
        mov             psU,    #0              ' Initialize up push state register  
        mov             psD,    #0              ' Initialize down push state register
        
:read   rdword          istate, isptr           ' Read input states from Main RAM
:left   test            btn1,   istate wc       ' Test button 1 pressed
        if_c  cmp       psL,    #0 wz
        if_nc mov       psL,    #0
        if_c_and_z mov  psL,    #1
        if_c_and_z cmp  zero,   xpos wc
        if_c_and_z sub  tmptr,  #2
        if_c_and_z sub  xpos,   #1
:right  test            btn2,   istate wc       ' Test button 2 pressed
        if_c  cmp       psR,    #0 wz
        if_nc mov       psR,    #0
        if_c_and_z mov  psR,    #1
        if_c_and_z cmp  xpos,   xbound wc
        if_c_and_z add  tmptr,  #2
        if_c_and_z add  xpos,   #1
:up     test            btn3,   istate wc       ' Test button 3 pressed
        if_c  cmp       psU,    #0 wz
        if_nc mov       psU,    #0
        if_c_and_z mov  psU,    #1
        if_c_and_z cmp  zero,   ypos wc
        if_c_and_z sub  tmptr,  #32
        if_c_and_z sub  ypos,   #1
:down   test            btn4,   istate wc       ' Test button 4 pressed
        if_c  cmp       psD,    #0 wz
        if_nc mov       psD,    #0
        if_c_and_z mov  psD,    #1
        if_c_and_z cmp  ypos,   ybound wc
        if_c_and_z add  tmptr,  #32
        if_c_and_z add  ypos,   #1        
        wrlong          xpos,   xbase
        wrlong          ypos,   ybase
        wrlong          tmptr,  tmbase
        jmp             #:read                  

' Input attributes
btn1          long      |< 7    ' Button 1 location in input states
btn2          long      |< 6    ' Button 2 location in input states
btn3          long      |< 5    ' Button 3 location in input states
btn4          long      |< 4    ' Button 4 location in input states
zero          long      0       ' Register containing zero value


' Registers
psL           res       1       ' State of left input button
psR           res       1       ' State of right input button
psU           res       1       ' State of left input button
psD           res       1       ' State of right input button
tmbase        res       1       ' Pointer to tile maps base register in Main RAM
tmptr         res       1       ' Pointer to tile maps base in Main RAM
isbase        res       1       ' Pointer to input state base register in Main RAM        
isptr         res       1       ' Pointer to tile maps base in Main RAM
istate        res       1       ' Register containing input states
pobase        res       1       ' Pointer to position base register in Main RAM      
poptr         res       1       ' Pointer to tile maps base in Main RAM
xbase         res       1       ' Pointer to x position base in Main RAM      
ybase         res       1       ' Pointer to y position base in Main RAM
xpos          res       1       ' Register containing horizontal game position
ypos          res       1       ' Register containing vertical game position
xbound        res       1       ' Register containing horizontal boundry of tile map
ybound        res       1       ' Register containing vertical boundry of tile map

        fit
DAT
         org             0
 {{
 The "testing" routine tests the behavior of the "input" routine via the DE0-Nano LEDs
 }}
 testing or              dira,   Pin_LED         ' Set LED output pins
 {{
 The "loop" subroutine infinitely loops to display either input_state or tilt_state to the LEDs
 }}        
 :loop   mov             pptr,   par             ' Load Main RAM input_state address into iptr
         rdlong          ps,     pptr            ' Read input_state from Main RAM                                                        
         shl             ps,     #16             ' Shift input_state to LED positions
         mov             ledout, Pin_LED         ' Combine chosen display state with current outputs        
         xor             ledout, xormask         
         and             ledout, outa             
         or              ledout, ps              
         mov             outa,   ledout          ' Display chosen state on LEDs                                           
         jmp             #:loop                  ' Loop infinitely
 Pin_LED       long      |< 16 | |< 17 | |< 18 | |< 19 | |< 20 | |< 21 | |< 22 | |< 23                   ' DE0-Nano LED pin bitmask
 xormask       long      $FFFFFFFF                                                                       ' XOR bitmask to control outputs
 pptr          res       1                                                                               ' Pointer to input_state register in Main RAM
 ps            res       1                                                                               ' Register holding input_state
 ledout        res       1                                                                               ' Register holding final output state
         fit
                 
DAT
tile_maps
              '         |<------------------visible on screen-------------------------------->|<------ to right of screen ---------->|
              ' column     0      1      2      3      4      5      6      7      8      9   |  10     11     12     13     14     15
              ' just the maze
tile_map0     word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 0
              word      $00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01                 ' row 1
              word      $00_01,$00_00,$01_01,$01_01,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$00_00,$01_01,$01_01,$01_01,$00_00,$00_01                 ' row 2
              word      $00_01,$00_00,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_00,$00_01                 ' row 3
              word      $00_01,$00_00,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$00_00,$01_01,$00_00,$00_00,$00_00,$00_01                 ' row 4
              word      $00_01,$00_00,$01_01,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_01                 ' row 5
              word      $00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01                 ' row 6
              word      $00_01,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$01_01,$00_00,$00_00,$01_01,$00_00,$01_01,$01_01,$00_01                 ' row 7
              word      $00_01,$00_00,$01_01,$00_00,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$00_00,$01_01,$00_00,$00_00,$01_01,$00_01                 ' row 8
              word      $00_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_00,$01_01,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_01                 ' row 9
              word      $00_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_01                 ' row 10
              word      $00_01,$00_00,$00_00,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$00_01                 ' row 11
              word      $00_01,$00_00,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_01                 ' row 12
              word      $00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01                 ' row 13
              word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 14

              ' maze plus dots
tile_map1     word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 0
              word      $00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 1
              word      $00_01,$00_02,$01_01,$01_01,$01_01,$00_02,$01_01,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 2
              word      $00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 3
              word      $00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 4
              word      $00_01,$00_02,$01_01,$01_01,$00_02,$01_01,$01_01,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 5
              word      $00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 6
              word      $00_01,$00_02,$01_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 7
              word      $00_01,$00_02,$01_01,$00_02,$00_02,$01_01,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 8
              word      $00_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 9
              word      $00_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 10
              word      $00_01,$00_02,$00_02,$01_01,$00_02,$01_01,$01_01,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 11
              word      $00_01,$00_02,$00_02,$01_01,$00_02,$00_02,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 12
              word      $00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 13
              word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 14

              ' maze plus powerpills
tile_map2     word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 0
              word      $00_01,$00_03,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_03,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 1
              word      $00_01,$00_02,$01_01,$01_01,$01_01,$00_02,$01_01,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 2
              word      $00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 3
              word      $00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 4
              word      $00_01,$00_02,$01_01,$01_01,$00_02,$01_01,$01_01,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 5
              word      $00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 6
              word      $00_01,$00_02,$01_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 7
              word      $00_01,$00_02,$01_01,$00_02,$00_02,$01_01,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 8
              word      $00_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 9
              word      $00_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 10
              word      $00_01,$00_02,$00_02,$01_01,$00_02,$01_01,$01_01,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 11
              word      $00_01,$00_02,$00_02,$01_01,$00_02,$00_02,$00_02,$01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 12
              word      $00_01,$00_03,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_03,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 13
              word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 14

              ' maze plus powerpills (alt color)
tile_map3     word      $01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01                 ' row 0
              word      $01_01,$01_04,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02,$01_04,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 1
              word      $01_01,$01_02,$01_01,$01_01,$01_01,$01_02,$01_01,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 2
              word      $01_01,$01_02,$01_01,$01_02,$01_02,$01_02,$01_02,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 3
              word      $01_01,$01_02,$01_01,$01_02,$01_02,$01_02,$01_02,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 4
              word      $01_01,$01_02,$01_01,$01_01,$01_02,$01_01,$01_01,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 5
              word      $01_01,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 6
              word      $01_01,$01_02,$01_01,$01_02,$01_01,$01_01,$01_02,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 7
              word      $01_01,$01_02,$01_01,$01_02,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 8
              word      $01_01,$01_02,$01_01,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 9
              word      $01_01,$01_02,$01_01,$01_01,$01_02,$01_01,$01_02,$01_02,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 10
              word      $01_01,$01_02,$01_02,$01_01,$01_02,$01_01,$01_01,$01_01,$01_02,$01_01,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02                 ' row 11
              word      $01_01,$01_02,$01_02,$01_01,$01_02,$01_02,$01_02,$01_01,$01_02,$01_01,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02                 ' row 12
              word      $01_01,$01_04,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02,$01_04,$01_01,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02                 ' row 13
              word      $01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01                 ' row 14

              ' maze designed for 10x10 tile screen
tile_map4     word      $01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 0
              word      $01_01,$00_03,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_03,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 1
              word      $01_01,$00_02,$00_01,$00_01,$00_01,$00_02,$00_01,$00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 2
              word      $01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 3
              word      $01_01,$00_02,$00_01,$00_02,$00_02,$00_02,$00_02,$00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 4
              word      $01_01,$00_02,$00_01,$00_01,$00_02,$00_01,$00_01,$00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 5
              word      $01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 6
              word      $01_01,$00_02,$00_01,$00_02,$00_01,$00_01,$00_02,$00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 7
              word      $01_01,$00_03,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_03,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 8
              word      $01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$00_01,$00_01                 ' row 9
              word      $01_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$00_02,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 10
              word      $01_01,$00_02,$00_02,$01_01,$00_02,$01_01,$01_01,$01_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 11
              word      $01_01,$00_02,$00_02,$01_01,$00_02,$00_02,$00_02,$01_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 12
              word      $01_01,$00_03,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_03,$00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02                 ' row 13
              word      $01_01,$01_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 14

tile_palettes
              ' empty tile
tile_blank    long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0                       ' tile 0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0

              ' box tile
tile_box      long      %%1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1                       ' tile 1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_3_3_3_3_3_3_3_3_3_3_3_3_3_3_1
              long      %%1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1

              ' dot tile
tile_dot      long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0                       ' tile 2
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_1_1_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_1_1_1_1_0_0_0_0_0_0
              long      %%0_0_0_0_0_1_1_1_1_1_1_0_0_0_0_0
              long      %%0_0_0_0_0_1_1_1_1_1_1_0_0_0_0_0
              long      %%0_0_0_0_0_0_1_1_1_1_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_1_1_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0

              ' power-up tile
tile_pup      long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0                       ' tile 3
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_2_2_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_2_1_1_2_0_0_0_0_0_0
              long      %%0_0_0_0_0_2_1_1_1_1_2_0_0_0_0_0
              long      %%0_0_0_0_2_1_1_1_1_1_1_2_0_0_0_0
              long      %%0_0_0_2_1_1_1_1_1_1_1_1_2_0_0_0
              long      %%0_0_2_1_1_1_1_1_1_1_1_1_1_2_0_0
              long      %%0_0_2_1_1_1_1_1_1_1_1_1_1_2_0_0
              long      %%0_0_0_2_1_1_1_1_1_1_1_1_2_0_0_0
              long      %%0_0_0_0_2_1_1_1_1_1_1_2_0_0_0_0
              long      %%0_0_0_0_0_2_1_1_1_1_2_0_0_0_0_0
              long      %%0_0_0_0_0_0_2_1_1_2_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_2_2_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0

              ' power-up tile
tile_pup2     long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0                       ' tile 4
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_3_3_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_3_2_2_3_0_0_0_0_0_0
              long      %%0_0_0_0_0_3_2_2_2_2_3_0_0_0_0_0
              long      %%0_0_0_0_3_2_2_2_2_2_2_3_0_0_0_0
              long      %%0_0_0_3_2_2_2_2_2_2_2_2_3_0_0_0
              long      %%0_0_3_2_2_2_2_2_2_2_2_2_2_3_0_0
              long      %%0_0_3_2_2_2_2_2_2_2_2_2_2_3_0_0
              long      %%0_0_0_3_2_2_2_2_2_2_2_2_3_0_0_0
              long      %%0_0_0_0_3_2_2_2_2_2_2_3_0_0_0_0
              long      %%0_0_0_0_0_3_2_2_2_2_3_0_0_0_0_0
              long      %%0_0_0_0_0_0_3_2_2_3_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_3_3_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0

tile_maps_8bit
              '         |<-------------------------------------------------------------visible on screen---------------------------------------------------------->|<-------------------------------- to right of screen ---------------------------->|
              ' column     0      1      2      3      4      5      6      7      8      9      10     11     12     13     14     15     16     17     18     19     20     21     22     23     24     25     26     27      28     29     30     31                
              ' just the maze
tile_map8     word      $00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02                 ' row 0
              word      $00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03                 ' row 1
              word      $00_01,$00_02,$01_01,$01_01,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$00_00,$01_01,$01_01,$01_01,$00_01,$00_02,$00_01,$00_02,$01_01,$01_01,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$00_00,$01_01,$01_01,$01_01,$00_01,$00_02                 ' row 2
              word      $00_04,$00_03,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_04,$00_03,$00_04,$00_03,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_04,$00_03                 ' row 3
              word      $00_01,$00_02,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$00_00,$01_01,$00_00,$00_00,$00_01,$00_02,$00_01,$00_02,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$00_00,$01_01,$00_00,$00_00,$00_01,$00_02                 ' row 4
              word      $00_04,$00_03,$01_01,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$00_04,$00_03,$00_04,$00_03,$01_01,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$00_04,$00_03                 ' row 5
              word      $00_01,$00_02,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01,$00_02,$00_01,$00_02,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01,$00_02                 ' row 6
              word      $00_04,$00_03,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$01_01,$00_00,$00_00,$01_01,$00_00,$01_01,$00_04,$00_03,$00_04,$00_03,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$01_01,$00_00,$00_00,$01_01,$00_00,$01_01,$00_04,$00_03                 ' row 7
              word      $00_01,$00_02,$01_01,$01_01,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_01,$00_01,$00_02,$01_01,$01_01,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_01                 ' row 8
              word      $00_04,$00_03,$00_00,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$00_01,$00_04,$00_03,$00_00,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$00_01                 ' row 9
              word      $00_01,$00_02,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_01,$00_01,$00_02,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_01                 ' row 10
              word      $00_04,$00_03,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01,$00_04,$00_03,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01                 ' row 11
              word      $00_01,$00_02,$01_01,$01_01,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$00_00,$01_01,$01_01,$01_01,$00_01,$00_02,$00_01,$00_02,$01_01,$01_01,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$00_00,$01_01,$01_01,$01_01,$00_01,$00_02                 ' row 12
              word      $00_04,$00_03,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_04,$00_03,$00_04,$00_03,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_04,$00_03                 ' row 13
              word      $00_01,$00_02,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$00_00,$01_01,$00_00,$00_00,$00_01,$00_02,$00_01,$00_02,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$00_00,$01_01,$00_00,$00_00,$00_01,$00_02                 ' row 14
              word      $00_04,$00_03,$01_01,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$00_04,$00_03,$00_04,$00_03,$01_01,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$00_04,$00_03                 ' row 15
              word      $00_01,$00_02,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01,$00_02,$00_01,$00_02,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01,$00_02                 ' row 16
              word      $00_04,$00_03,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$01_01,$00_00,$00_00,$01_01,$00_00,$01_01,$00_04,$00_03,$00_04,$00_03,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$01_01,$00_00,$00_00,$01_01,$00_00,$01_01,$00_04,$00_03                 ' row 17
              word      $00_01,$00_02,$01_01,$01_01,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_01,$00_01,$00_02,$01_01,$01_01,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_01                 ' row 18
              word      $00_04,$00_03,$00_00,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$00_01,$00_04,$00_03,$00_00,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$00_01                 ' row 19
              word      $00_01,$00_02,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_01,$00_01,$00_02,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_01                 ' row 20
              word      $00_04,$00_03,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01,$00_04,$00_03,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01                 ' row 21                            
              word      $00_01,$00_02,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01,$00_02,$00_01,$00_02,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01,$00_02                 ' row 22
              word      $00_04,$00_03,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$01_01,$00_00,$00_00,$01_01,$00_00,$01_01,$00_04,$00_03,$00_04,$00_03,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$01_01,$00_00,$00_00,$01_01,$00_00,$01_01,$00_04,$00_03                 ' row 23
              word      $00_01,$00_02,$01_01,$01_01,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_01,$00_01,$00_02,$01_01,$01_01,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_01                 ' row 24
              word      $00_04,$00_03,$00_00,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$00_01,$00_04,$00_03,$00_00,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$01_01,$00_01                 ' row 25
              word      $00_01,$00_02,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_01,$00_01,$00_02,$00_00,$01_01,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$00_00,$00_01                 ' row 26
              word      $00_04,$00_03,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01,$00_04,$00_03,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01                 ' row 28
              word      $00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02                 ' row 27 
              word      $00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03                 ' row 29
tile_palettes_8bit
              ' empty tile
tile_blank8   word      %%1_0_0_0_0_2_0_0                       ' tile 0
              word      %%0_0_0_0_3_0_0_0
              word      %%0_2_0_0_0_0_0_3
              word      %%0_0_0_0_0_0_0_0
              word      %%0_0_0_2_0_0_0_0
              word      %%0_0_0_0_0_0_0_0
              word      %%0_1_0_0_0_0_0_0
              word      %%0_0_0_0_2_0_0_0

              ' upper left corner of box
tile_box_tl   word      %%1_1_1_1_1_1_1_1                       ' tile 1
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1

              ' upper right corner of box
tile_box_tr   word      %%1_1_1_1_1_1_1_1                       ' tile 2
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3

              ' bottom right corner of box
tile_box_br   word      %%1_3_3_3_3_3_3_3                       ' tile 3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_3_3_3_3_3_3_3
              word      %%1_1_1_1_1_1_1_1

              ' bottom left corner of box
tile_box_bl   word      %%3_3_3_3_3_3_3_1                       ' tile 4
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1
              word      %%3_3_3_3_3_3_3_1
              word      %%1_1_1_1_1_1_1_1

color_palettes
              ' Test palettes
c_palette1    long      %11000011_00110011_00011111_00000011                    ' palette 0
c_palette2    long      %00000011_00110011_11111111_11000011                    ' palette 1

input_states
              ' Input states
control_state word      0       ' Control states
tilt_state    word      0       ' Tilt shift state 

positions
              ' Current position
cur_pos_x     long      0       ' Current horizontal tile position       
cur_pos_y     long      0       ' Current vertical tile position       