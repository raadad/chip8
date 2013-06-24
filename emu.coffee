
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
    bufferon = false
    currentkey = 0
    running = true
    keydown = 0
    keypress = 0
    keyTimer = null
    drawTimer = 0
    cycleTimer = 0
    prevscreen = []

    refresh = ->
        prevscreen[yy] = [] for yy in [0..31]
        prevscreen[yy][xx] = true for xx in [0..63] for yy in [0..31]
    refresh()

    clear = ->
        screen[yy] = [] for yy in [0..31]
        screen[yy][xx] = false for xx in [0..63] for yy in [0..31]
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

    keys =
        "1": -> return 0x1  # 1
        "2": -> return 0x2  # 2
        "3": -> return 0x3  # 3
        "a": -> return 0x4  # 4
        "q": -> return 0x5  # Q
        "d": -> return 0x6  # W
        "e": -> return 0x7  # E
        "r": -> return 0x8  # R
        "4": -> return 0x9  # A
        "s": -> return 0xA  # S
        "w": -> return 0xB  # D
        "f": -> return 0xC  # F
        "z": -> return 0xD  # Z
        "x": -> return 0xE  # X
        "c": -> return 0xF  # C
        "v": -> return 0x10  # V

        "p": -> process.exit(); return false
        "l": -> bufferon = !bufferon; return false


    rom = "6e0565006b066a00a30cdab17a043a4012087b023b1212066c206d1fa310dcd122f660006100a312d0117008a30ed0116040f015f00730001234c60f671e680169ffa30ed671a310dcd16004e0a17cfe6006e0a17c02603f8c02dcd1a30ed67186848794603f8602611f8712471f12ac46006801463f68ff47006901d6713f0112aa471f12aa600580753f0012aa6001f018806061fc8012a30cd07160fe890322f6750122f6456012de124669ff806080c53f0112ca610280153f0112e080153f0112ee80153f0112e86020f018a30e7eff80e080046100d0113e00123012de78ff48fe68ff12ee7801480268016004f01869ff1270a314f533f265f12963376400d3457305f229d34500eee0008000fc00aa0000000000"
    rom = "6e0565006b066a00a30cdab17a043a4012087b023b1212066c206d1fa310dcd122f660006100a312d0117008a30ed0116040f015f00730001234c60f671e680169ffa30ed671a310dcd16004e0a17cfe6006e0a17c02603f8c02dcd1a30ed67186848794603f8602611f8712471f12ac46006801463f68ff47006901d6713f0112aa471f12aa600580753f0012aa6001f018806061fc8012a30cd07160fe890322f6750122f6456012de124669ff806080c53f0112ca610280153f0112e080153f0112ee80153f0112e86020f018a30e7eff80e080046100d0113e00123012de78ff48fe68ff12ee7801480268016004f01869ff1270a314f533f265f12963376400d3457305f229d34500eee0008000fc00aa0000000000"
    #rom = "a2cc6a0761006b086000d01170087bff3b00120a71047aff3a00120666006710a2cd6020611ed011631d623f820277ff470012aaff0aa2cbd23165ffc401340164ffa2cd6c006e04eea16cff6e06eea16c01d01180c4d0114f01129842006401423f64ff43006501431f12a4a2cbd23182448354d2313f011242431e12986a02fa187601467012aad231c401340164ffc501350165ff12426a03fa18a2cbd23173ff1236a2cbd2311228a2cdd011a2f0f633f2656318641bf029d3457305f129d3457305f229d34512c8018044ff"
    memory[i] = fonts[i] for val,i in fonts
    memory[512+t] = parseInt(rom.slice(t*2,t*2+2), 16) for t in [0..rom.length / 2]


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
            v[15] = +(v[x] > 255)
            v[x] = v[x] - 256 if v[x] > 255
        0x8005: ->
            v[15] = +(v[x] > v[y])
            v[x] = v[x] + v[y]
            v[x] = v[x] + 256 if v[x] < 0
        0x8006: ->
            v[15] = 1 if v[x] & 0x1
            v[x] = v[x] >> 1
        0x8007: ->
            v[15] = +(v[y] > v[x])
            v[x] = v[y] - v[x]
            v[x] = v[x] + 256 if v[x] < 0
        0x800E: ->
            v[15] = +(v[x] & 0x80)
            v[x] = v[x] << 1
            v[x] = v[x] - 256 if v[x] > 255
        0x9000: ->
            pc += 2 if v[x] != v[y]
        0xA000: ->
            i = opcode & 0xFFF
        0xB000: ->
            pc = (opcode & 0xFFF) + v[0]
        0xC000: ->
            v[x] =  Math.floor( 5 * 0xFF) & (opcode & 0xFF) #Math.random() * 0xFF) & (opcode & 0xFF)
        0xD000: ->
            v[15] = 0
            n = opcode & 0x000F
            for yy in [0..n-1]
                for xx in [0..7]
                    xc = v[x]+xx
                    yc = v[y]+yy
                    if (memory[i+yy] >> (7 - xx)) & 0x1
                        v[15] = 1 if screen[v[y]+yy][v[x]+xx]
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
        for[0..9]
            if running
                
                keypress = (key) ->
                    keydown = key
                    clearTimeout(keyTimer)
                    keyTimer = setTimeout(->
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
                
                console.log('\0x7') if sound_timer > 0

        sound_timer-- unless sound_timer < 1
        delay_timer-- unless delay_timer < 1
        
        setImmediate(cycle)

    draw = ->
        buffer = ""
        for k, yy in screen
            for vv,xx in screen[yy]
                if screen[yy][xx] != prevscreen[yy][xx]
                    buffer+="\x1B[#{yy+1};#{xx+100}H"
                    buffer+= if vv then '\x1B[42m ' else '\x1B[40m '
                    prevscreen[yy][xx] = screen[yy][xx] 
        buffer+="\x1B[40m\x1B[#{32};#{3}H";

        unless drawTimer/500 % 2 
            refresh()
            drawTimer = 0
        if bufferon
            process.stdout.write(buffer)
        else
            #console.log(opcode.toString(16),pc,v,x,y,memory[pc],memory[pc+1])
        setTimeout(draw,1)
    
    process.nextTick cycle
    process.nextTick draw

         
    process.stdin.setRawMode true
    process.stdin.setEncoding('utf8')
    process.stdin.on('data', (chunk) ->
        method = keys[chunk.toString()]
        keypress method() if method
        console.log ("no mapping: #{chunk}") unless method
    )

start()
