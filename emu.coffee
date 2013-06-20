
start = ->
    stdin = process.openStdin()
    require('tty').setRawMode true
    opcode = 0
    memory = new Uint8Array(4096)
    v = []
    v[ii] = 0 for ii in [0..15]
    x = 0
    y = 0
    i = 0
    sound_timer = 0
    delay_timer = 0
    pc = 0x200
    stack = []
    pointer = 0
    screen = []
    screen[yy] = [] for yy in [0..32]
    screen[yy][xx] = ' ' for xx in [0..64] for yy in [0..32]
    keys = []
    bufferon = false
    clear = ->
        screen[yy] = [] for yy in [0..32]
        screen[yy][xx] = ' ' for xx in [0..64] for yy in [0..32]
    clear()
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

    rom = "
6e0100e06d016a016b018cd08ce24c00
122088d0223e3a4012206a017b063c3f
7d013d3f120af00a400589e48ee43e40
12026a1c6b0d889000e0223e123ca294
f833f2652254dab57a0481202254dab5
7a0500ee8310833483348314a262f31e
00eee0a0a0a0e04040404040e020e080
e0e020e020e0a0a0e02020e080e020e0
e080e0a0e0e020202020e0a0e0a0e0e0
a0e020e0"

    memory[i] = fonts[i] for val,i in fonts
    memory[512+t] = parseInt(rom.slice(t*2,t*2+2), 16) for t in [0..rom.length / 2]

    #console.log  rom.slice(t*2,t*2+2) for t in [0..rom.length / 2]


    opx =
        0x00E0: ->
            clear()
        0x00EE: ->
            pc = [--pointer]
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
            pc += 2 if v[x] != v[y]
        0x6000: ->
            v[x] = (opcode & 0xFF)
        0x7000: ->
            v[x] = v[x] + (opcode & 0xFF)
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
            v[15] = +(v[x] > 255)
            v[x] = v[x] - 256 if v[x] > 255
        0x8005: ->
            v[15] = +(v[x] > v[y])
            v[x] = v[x] + v[y]
            v[x] = v[x] + 256 if v[x] < 0
        0x8006: ->
            v[15] = 1 if v[x] & 0x000F
            v[x] = v[x] >> 1
        0x8007: ->
            v[15] = +(v[x] > v[y])
            v[x] = v[y] - v[x]
            v[x] = v[x] + 256 if v[x] < 0
        0x800E: ->
            v[15] = v[x] & 0xF
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
            v[15] = 0
            n = opcode & 0x000F
            for yy in [0..n]
                spr = memory[i+yy]
                for xx in [0..8]
                    if(spr & (0x80))
                        xpos = v[x] + xx
                        ypos = v[y] + yy
                        #console.log(opcode,v,xpos,v[x],ypos,v[y])
                        ypos = 0 if ypos > 32
                        xpos = 0 if xpos > 64
                        xpos = 64 if xpos < 0
                        ypos = 32 if ypos < 32
                        screen[ypos][xpos] = "#"

        0xE09E: ->
            pc += 2 if keys[v[x]]
        0xE0A1: ->
            pc += 2 unless keys[v[x]]
        0xF007: ->
            v[x] = delay_timer
        0xF00A: ->

        0xF015: ->
            delay_timer = v[x]
        0xF018: ->
            sound_timer = v[x]
        0xF01E: ->
            i = i + v[x]
        0xF029: ->
            i = v[x] * 5;
        0xF033: ->
            number = v[x]
            for itr in [3..0]
                memory[i+(itr-1)] = parseInt(number % 10)
                number = number / 10;
        0xF055: ->
            memory[i + itr] = v[itr] for itr in [0..x]
        0xF065: ->
            v[itr] = memory[i + itr] for itr in [0..x]

    cycle = ->
        opcode = memory[pc] << 8 | memory[pc+1]
        x = opcode & (0x0F00) >> 8
        y = opcode & (0x00F0) >> 4
        #console.log(opcode.toString(16),pc,v,x,y);
        method = opx[opcode & 0xF0FF] unless method
        method = opx[opcode & 0xF00F] unless method
        method = opx[opcode & 0xF000] unless method
        unless method
            console.log(opcode.toString(16),pc,v,x,y,memory[pc],memory[pc+1]);
            throw "invalid opcode"

        method()

        pc += 2
        sound_timer-- unless sound_timer < 1
        delay_timer-- unless delay_timer < 1
        3 if sound_timer > 1

        buffer = ""
        for k, yy in screen
            buffer+="\x1B[#{yy};#{0}H";
            for vv,xx in screen[yy]
                buffer+=vv;
        buffer+="\x1B[#{32};#{0}H";
        if bufferon
           process.stdout.write(buffer)
        else
            console.log(opcode.toString(16),pc,v,x,y,memory[pc],memory[pc+1]);

        setImmediate(cycle)

    process.nextTick cycle

    sound = ->
        console.log("beep");

    process.stdin.setRawMode true
    process.stdin.setEncoding('utf8')


    process.stdin.on('data', (chunk) ->
       process.exit() if chunk == "x"
       bufferon = !bufferon if chunk == "y";
    )

    process.stdin.on('end', ->
        process.stdout.write('end');
    )
start()
