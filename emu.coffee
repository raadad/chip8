require('tty').setRawMode true
fs = require('fs');

opcode = 0

v = []
v[ii] = 0 for ii in [0..15]

x = 0
y = 0
i = 0
f = 0xF


pc = 0x200
stack = []
pointer = 0


sound_timer = 0
delay_timer = 0
draw_timer = 0
cycle_timer = 0

screen = []
prevscreen = []

bufferon = true
currentkey = 0

running = true
keydown = 0
keypress = 0

rom = fs.readFileSync(process.argv[2]).toJSON()

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

memory = []
memory[ii] = fonts[ii] for val,ii in fonts
memory[512+ii] = rom[ii] for ii in [0..rom.length]

opx =
    0x00E0: ->
        clear()
    0x00EE: ->
        pc = stack[--pointer]
    0x1000: ->
        pc = opcode & 0xFFF
    0x2000: ->
        stack[pointer] = pc
        pointer++
        pc = opcode & 0x0FFF
    0x3000: ->
        pc += 2 if v[x] == (opcode & 0xFF)
    0x4000: ->
        pc += 2 if v[x] != (opcode & 0x00FF)
    0x5000: ->
        pc += 2 if v[x] == v[y]
    0x6000: ->
        v[x] = (opcode & 0xFF)
    0x7000: ->
        val = (opcode & 0xFF) + v[x]
        val -= 256 if val > 255
        v[x] = val
    0x8000: ->
        v[x] = v[y]
    0x8001: ->
        v[x] = v[x] | v[y]
    0x8002: ->
        v[x] = v[x] & v[y]
    0x8003: ->
        v[x] = v[x] ^ v[y]
    0x8004: ->
        v[x] = v[x] + v[y]
        v[f] = +(v[x] > 255)
        v[x] = v[x] - 256 if v[x] > 255
    0x8005: ->
        v[f] = +(v[x] > v[y])
        v[x] = v[x] + v[y]
        v[x] = v[x] + 256 if v[x] < 0
    0x8006: ->
        v[f] = 1 if v[x] & 0x1
        v[x] = v[x] >> 1
    0x8007: ->
        v[f] = +(v[y] > v[x])
        v[x] = v[y] - v[x]
        v[x] = v[x] + 256 if v[x] < 0
    0x800E: ->
        v[f] = +(v[x] & 0x80)
        v[x] = v[x] << 1
        v[x] = v[x] - 256 if v[x] > 255
    0x9000: ->
        pc += 2 if v[x] != v[y]
    0xA000: ->
        i = opcode & 0xFFF
    0xB000: ->
        pc = (opcode & 0xFFF) + v[0]
    0xC000: ->
        v[x] =  Math.floor(Math.random() * 0xFF) & (opcode & 0xFF)
    0xD000: ->
        v[f] = 0
        n = opcode & 0x000F
        for yy in [0..n-1]
            for xx in [0..7]
                xc = v[x]+xx
                yc = v[y]+yy
                if (memory[i+yy] >> (7 - xx)) & 0x1
                    v[f] = 1 if screen[v[y]+yy][v[x]+xx]
                    screen[yc][xc] = screen[yc][xc] ^ 1
    0xE09E: ->
        pc += 2 if v[x] == keydown
    0xE0A1: ->
        pc += 2 unless v[x] == keydown
    0xF007: ->
        v[x] =  delay_timer
    0xF00A: ->
        running = false;
        keypress = (key) ->
            v[x] = key
            running = true;
    0xF015: ->
        delay_timer = v[x]
    0xF018: ->
        sound_timer = v[x]
    0xF01E: ->
        i = i + v[x]
    0xF029: ->
        i = v[x] * 5;
    0xF033: ->
        memory[i] = v[x] / 100;
        memory[i + 1] = (v[x] % 100)/10
        memory[i + 2] = v[x] % 10
    0xF055: ->
        memory[i + itr] = v[itr] for itr in [0..x]
    0xF065: ->
        v[itr] = memory[i + itr] for itr in [0..x]



cycle = ->
    if running
        keypress = (key) ->
            keydown = key
            clearTimeout(key_timer)
            key_timer = setTimeout(->
                keydown = false
            ,100)

        opcode = memory[pc] << 8 | memory[pc+1]
        x = (opcode & 0x0F00) >> 8
        y = (opcode & 0x00F0) >> 4

        method = opx[opcode & 0xF0FF] unless method
        method = opx[opcode & 0xF00F] unless method
        method = opx[opcode & 0xF000] unless method

        unless method
            console.log(opcode.toString(16),pc,v,x,y,memory[pc],memory[pc+1]);
            throw "invalid opcode"
        pc += 2
        method()
        console.log("\x07") if sound_timer > 0

    unless cycle_timer % 2
        sound_timer-- unless sound_timer < 1
        delay_timer-- unless delay_timer < 1

    cycle_timer++
    setTimeout(cycle)

draw = ->
    buffer = ""
    for k, yy in screen
        for vv,xx in screen[yy]
            if screen[yy][xx] != prevscreen[yy][xx]
                buffer+="\x1B[#{yy+1};#{xx+10}H"
                buffer+= if vv then '\x1B[42m ' else '\x1B[40m '
                prevscreen[yy][xx] = screen[yy][xx]
        buffer += '\x1B[40m '


    unless draw_timer > 100
        refresh()
        draw_timer = 0
    draw_timer++

    if bufferon
        process.stdout.write(buffer)
    else
        console.log(opcode.toString(16),pc,v,x,y,memory[pc],memory[pc+1])
    setTimeout(draw,60)


refresh = ->
    prevscreen[yy] = [] for yy in [0..31]
    prevscreen[yy][xx] = true for xx in [0..63] for yy in [0..31]


clear = ->
    screen[yy] = [] for yy in [0..31]
    screen[yy][xx] = false for xx in [0..63] for yy in [0..31]

refresh()
clear()

process.nextTick cycle
process.nextTick draw
process.stdin.setRawMode true
process.stdin.setEncoding('utf8')
process.stdin.on('data', (chunk) ->
    method = keys[chunk.toString()]
    keypress method() if method
    console.log ("no mapping: #{chunk}") unless method
)