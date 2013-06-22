
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
    bufferon = true
    running = true
    keypress = null

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

        "q": -> process.exit(); return false
        "w": -> bufferon = !bufferon; return false


    rom = "6e0565006b066a00a30cdab17a043a4012087b023b1212066c206d1fa310dcd122f660006100a312d0117008a30ed0116040f015f00730001234c60f671e680169ffa30ed671a310dcd16004e0a17cfe6006e0a17c02603f8c02dcd1a30ed67186848794603f8602611f8712471f12ac46006801463f68ff47006901d6713f0112aa471f12aa600580753f0012aa6001f018806061fc8012a30cd07160fe890322f6750122f6456012de124669ff806080c53f0112ca610280153f0112e080153f0112ee80153f0112e86020f018a30e7eff80e080046100d0113e00123012de78ff48fe68ff12ee7801480268016004f01869ff1270a314f533f265f12963376400d3457305f229d34500eee0008000fc00aa0000000000"



    memory[i] = fonts[i] for val,i in fonts
    memory[512+t] = parseInt(rom.slice(t*2,t*2+2), 16) for t in [0..rom.length / 2]

    #console.log  rom.slice(t*2,t*2+2) for t in [0..rom.length / 2]


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
            val -= 256 if val > 256
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
            v[15] = +(v[x] > v[y])
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
            v[x] =  Math.floor(Math.random() * 0xFF) & (opcode & 0xFF)
        0xD000: ->
            v[15] = 0
            n = opcode & 0x000F           
            for yy in [0..n]
                spr = memory[i+yy]
                for xx in [0..8]
                    xpos = v[x] + xx
                    ypos = v[y] + yy
                    xpos -= 64  if xpos > 64
                    xpos += 64  if xpos < 0
                    ypos -= 32  if ypos > 32
                    ypos += 32  if ypos < 0
                    hasPixel = screen[ypos][xpos] == "#"
                    screen[ypos][xpos] = " "              
                    if(spr & (0x80))
                        if(screen[ypos][xpos] == ' ')
                            screen[ypos][xpos] = "#"
                        else
                            screen[ypos][xpos] = "#"
                            v[15] = 1    
                    if( hasPixel && screen[ypos][xpos]  == ' ') then v[15] = 1  else  
                    spr <<= 1    


        0xE09E: ->
            pc += 2 if keys[v[x]]
        0xE0A1: ->
            pc += 2 unless keys[v[x]]
        0xF007: ->
            v[x] = delay_timer
        0xF00A: ->
            v[x] = 
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
            number = v[x]
            for itr in [3..0]
                memory[i+(itr-1)] = parseInt(number % 10)
                number = number / 10;
        0xF055: ->
            memory[i + itr] = v[itr] for itr in [0..x]
        0xF065: ->
            v[itr] = memory[i + itr] for itr in [0..x]

    cttr = 0;
    cycle = ->
        if running
            keypress = (key) -> console.log "fall through"
            opcode = memory[pc] << 8 | memory[pc+1]
            x = (opcode & 0x0F00) >> 8
            y = (opcode & 0x00F0) >> 4
        #console.log(opcode.toString(16),pc,v,x,y,memory[pc],memory[pc+1]);
            method = opx[opcode & 0xF0FF] unless method
            method = opx[opcode & 0xF00F] unless method
            method = opx[opcode & 0xF000] unless method
            unless method
                console.log(opcode.toString(16),pc,v,x,y,memory[pc],memory[pc+1]);
                throw "invalid opcode"
            pc += 2
            method()
            
            sound_timer-- unless sound_timer < 1
            delay_timer-- unless delay_timer < 1
            3 if sound_timer > 1

            buffer = ""
            for k, yy in screen
                
                for vv,xx in screen[yy]
                    buffer+="\x1B[#{yy+1};#{xx}H";
                    buffer+=vv;
            buffer+="\x1B[#{32};#{3}H";
            if bufferon
               process.stdout.write(buffer)
            else
               #console.log(screen)
               console.log(opcode.toString(16),pc,v,x,y,memory[pc],memory[pc+1]);

        setImmediate(cycle)
    process.nextTick cycle

    sound = ->
        console.log("beep")
    process.stdin.setRawMode true
    process.stdin.setEncoding('utf8')
    process.stdin.on('data', (chunk) ->
        method = keys[chunk.toString()]
        keypress method() if method
    )
start()
