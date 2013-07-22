opcode = 0 # Refers to the current instruction being executed

v = []  # Array of registered that are used as a working space for calculations
v[ii] = 0 for ii in [0..0xF] # There are 16 registers, we just reset them all to 0

x = 0 # Refers to the second position in an opcode, which most of the time is used to identify a register, reffered to as register x
y = 0 # Referes to the third position in an opcode, like register x, but refered to as register y

i = 0 # A special register, used ot store memory addresses

f = 0xF # A static refernce to register 15 (which is a special register used as a flag)

pc = 0x200 # Refers to the program counter, which is the memory address of the next instruction to be proccessed
stack = [] # An array to keep track of subroutines, which stores memory adresses of structions that the program should return to
pointer = 0 # The current position in the stack

sound_timer = 0 #will beep if this does not equal zero, and should decrement at a rate of 60hz
delay_timer = 0 #will dercement at a rate of 60Hz

draw_timer = 0 #not part of chip8, but used to keep track of screen drawing intervals
cycle_timer = 0 #used to control the speed in which timers decrement also not a component of chip 8

screen = [] # An array that will store the xy co-ordinates that refer to pixels on a screen
prevscreen = [] # The previous screen that is compared with the current screen, so only changes are drawn

bufferon = true # Used to switch between screenoutput and opcode output (used for debugging)

running = true # Used to see if the processor is paused, sometimes the processor is paused untill it recieves a key
keydown = 0 # Used to keep track of the last key that was pressed
keypress = 0 # Stores the function that is used to handle a keypress, which changes when the processor is paused


fonts = [
    0xF0, 0x90, 0x90, 0x90, 0xF0, # 0
    0x20, 0x60, 0x20, 0x20, 0x70, # 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, # 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, # 3
    0x90, 0x90, 0xF0, 0x10, 0x10, # 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, # 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, # 6
    0xF0, 0x10, 0x20, 0x40, 0x40, # 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, # 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, # 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, # A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, # B
    0xF0, 0x80, 0x80, 0x80, 0xF0, # C
    0xE0, 0x90, 0x90, 0x90, 0xE0, # D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, # E
    0xF0, 0x80, 0xF0, 0x80, 0x80  # F
]

###
Each byte referres to a line which is 8 pixels wide.,,

0xF0 = 11110000   ****
0x90 = 10010000   *  *
0xF0 = 11110000   ****
0x90 = 10010000   *  *
0x90 = 10010000   *  *
###

rom = require('fs').readFileSync(process.argv[2]).toJSON() # Loads the room from the args supplied in the terminal


memory = [] # Memory is stored in an array each position will hold one byte Chip8 has 4k of ram.
memory[ii] = fonts[ii] for val,ii in fonts # the fonts are the first things that get loaded into memory
memory[0x200+ii] = rom[ii] for ii in [0..rom.length]
# Rom address space starts at the the 512th byte, so we start loading our rom from that point


###
There are 16 possible keys in chip8, each referring to a number
I have also usd the same key mapping to handle auxulliry tasks in my emulator
###


keys =
    "1": -> return 0x1  # 1
    "2": -> return 0x2  # 2
    "3": -> return 0x3  # 3
    "4": -> return 0x4  # 4
    "q": -> return 0x5  # Q
    "w": -> return 0x6  # W
    "e": -> return 0x7  # E
    "r": -> return 0x8  # R
    "a": -> return 0x9  # A
    "s": -> return 0xA  # S
    "d": -> return 0xB  # D
    "f": -> return 0xC  # F
    "z": -> return 0xD  # Z
    "x": -> return 0xE  # X
    "c": -> return 0xF  # C
    "v": -> return 0x10  # V

    "p": -> process.exit(); return false
    "l": -> bufferon = !bufferon; return false



# Our opcodes
opx =
    0x00E0: -> # 00e0 - CLS
        clear()
    0x00EE: -> # 00ee - RET
        pc = stack[--pointer]
    0x1000: -> # 0nnn - SYS addr
        pc = opcode & 0xFFF
    0x2000: -> # 1nnn - JP addr
        stack[pointer] = pc
        pointer++
        pc = opcode & 0x0FFF
    0x3000: -> # 3xkk - SE Vx, byte
        pc += 2 if v[x] == (opcode & 0xFF)
    0x4000: -> # 4xkk - SNE Vx, byte
        pc += 2 if v[x] != (opcode & 0x00FF)
    0x5000: -> # 5xkk - SE Vx, Vy
        pc += 2 if v[x] == v[y]
    0x6000: -> # 6xkk - LD Vx, byte
        v[x] = (opcode & 0xFF)
    0x7000: -> # 7xkk - ADD Vx, byte
        val = (opcode & 0xFF) + v[x]
        val -= 256 if val > 255
        v[x] = val
    0x8000: -> # 8xy0 - LD Vx, Vy
        v[x] = v[y]
    0x8001: -> # 8xy1 - OR Vx, Vy
        v[x] = v[x] | v[y]
    0x8002: -> # 8xy2 - AND Vx, Vy
        v[x] = v[x] & v[y]
    0x8003: -> # 8xy3 - XOR Vx, Vy
        v[x] = v[x] ^ v[y]
    0x8004: -> # 8xy4 - ADD Vx, Vy
        v[x] = v[x] + v[y]
        v[f] = +(v[x] > 255)
        v[x] = v[x] - 256 if v[x] > 255
    0x8005: -> # 8xy5 - SUB Vx, Vy
        v[f] = +(v[x] > v[y ])
        v[x] = v[x] + v[y]
        v[x] = v[x] + 256 if v[x] < 0
    0x8006: -> # 8xy6 - SHR Vx, Vy
        v[f] = 1 if v[x] & 0x1
        v[x] = v[x] >> 1
    0x8007: -> # 8xy7 - SUBN Vx, Vy
        v[f] = +(v[y] > v[x])
        v[x] = v[y] - v[x]
        v[x] = v[x] + 256 if v[x] < 0
    0x800E: -> # 8xy8 - SHL Vx, Vy
        v[f] = +(v[x] & 0x80)
        v[x] = v[x] << 1
        v[x] = v[x] - 256 if v[x] > 255
    0x9000: -> # 8xy9 - SNE Vx, Vy
        pc += 2 if v[x] != v[y]
    0xA000: -> # Annn - LD I, addr
        i = opcode & 0xFFF
    0xB000: -> # Bnnn - JP V0, addr
        pc = (opcode & 0xFFF) + v[0]
    0xC000: -> # Cxkk - RND Vx, byte
        v[x] =  Math.floor(Math.random() * 0xFF) & (opcode & 0xFF)
    0xD000: -> # Dxyn - DRW Vx, Vy, nibble
        v[f] = 0
        n = opcode & 0x000F
        for yy in [0..n-1]
            for xx in [0..7]
                xc = v[x]+xx
                yc = v[y]+yy
                if (memory[i+yy] >> (7 - xx)) & 0x1
                    v[f] = 1 if screen[v[y]+yy][v[x]+xx]
                    screen[yc][xc] = screen[yc][xc] ^ 1
    0xE09E: -> # Ex9E - SKP Vx
        pc += 2 if v[x] == keydown
    0xE0A1: -> # ExA1 - SKNP Vx
        pc += 2 unless v[x] == keydown
    0xF007: -> # Fx07 - LD Vx, DT
        v[x] =  delay_timer
    0xF00A: -> # Fx0A - LD Vx, K
        running = false;
        keypress = (key) ->
            v[x] = key
            running = true;
    0xF015: -> # Fx15 - LD DT, Vx
        delay_timer = v[x]
    0xF018: -> # Fx18 - LD ST, Vx
        sound_timer = v[x]
    0xF01E: -> # Fx1E - ADD I, Vx
        i = i + v[x]
    0xF029: -> # Fx29 - LD F, Vy
        i = v[x] * 5;
    0xF033: -> # Fx33 - LD B, Vy
        memory[i] = v[x] / 100;
        memory[i + 1] = (v[x] % 100)/10
        memory[i + 2] = v[x] % 10
    0xF055: -> # Fx55 - LD [I], Vx
        memory[i + itr] = v[itr] for itr in [0..x]
    0xF065: -> # Fx65 - LD Vx, [I]
        v[itr] = memory[i + itr] for itr in [0..x]


# The cpu loop
cycle = ->
    if running
        keypress = (key) ->
            keydown = key
            clearTimeout(key_timer)
            key_timer = setTimeout(->
                keydown = false
            ,100)

        # Instructions are 2 bytes long, so we join the currnet memory position with the next position
        opcode = memory[pc] << 8 | memory[pc+1]

        x = (opcode & 0x0F00) >> 8 # Extract x register reference
        y = (opcode & 0x00F0) >> 4 # Extract y register reference


        method = opx[opcode & 0xF0FF] unless method
        method = opx[opcode & 0xF00F] unless method
        method = opx[opcode & 0xF000] unless method

        unless method
            console.log(opcode.toString(16),pc,v,x,y,memory[pc],memory[pc+1]);
            throw "invalid opcode"
        ###
         Instruction is decoded, via pattern matching with an AND operation
         We start with the most strict pattern, and go to the least untill we find one
         If one cannot be found, it means the opcode was not valid, and we could have data corruption
        ###

        pc += 2 # Move the program counter to read the next instruction in memory
        method() # Execute the instruction
        console.log("\x07") if sound_timer > 0 #Handles sound
    # Decrement Timers once every 2 instructions
    unless cycle_timer % 2
        sound_timer-- unless sound_timer < 1
        delay_timer-- unless delay_timer < 1
    cycle_timer++

    setTimeout(cycle,2) # Repeat cycle

draw = ->
    buffer = "" #What gets sent to the terminal
    for k, yy in screen
        for vv,xx in screen[yy]  #loop through every pixel in screen memory
            if screen[yy][xx] != prevscreen[yy][xx] #if there has been a change
                buffer+="\x1B[#{yy+1};#{xx+0}H" # Move cursor to position
                buffer+= if vv then '\x1B[42m ' else '\x1B[40m ' #Set or unset pixel by changing background
                prevscreen[yy][xx] = screen[yy][xx] # Update previous screen in memory
        buffer += '\x1B[40m '

    #Refresh the whole screen every 100 screen draws
    unless draw_timer > 100
        refresh()
        draw_timer = 0
    draw_timer++

    if bufferon
        process.stdout.write(buffer) #Sends instructions to terminal
    else
        console.log(opcode.toString(16),pc,v,x,y,memory[pc],memory[pc+1])

    setTimeout(draw,60) #Repeat again in 60ms


#Will ensure every pixel is redrawn to the screen
refresh = ->
    prevscreen[yy] = [] for yy in [0..31]
    prevscreen[yy][xx] = true for xx in [0..63] for yy in [0..31]

#Will clear the whole screen
clear = ->
    screen[yy] = [] for yy in [0..31]
    screen[yy][xx] = false for xx in [0..63] for yy in [0..31]

refresh() #Setsup  Screen Buffer
clear() #Setsup Screen

# Handle keypresses
process.stdin.setRawMode true
process.stdin.setEncoding('utf8')

process.stdin.on('data', (chunk) ->
    method = keys[chunk.toString()]
    keypress method() if method
    console.log ("no mapping: #{chunk}") unless method
)

process.nextTick cycle # Starts the processor loop
process.nextTick draw  # Starts the draw loop