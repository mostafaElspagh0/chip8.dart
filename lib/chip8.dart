// generate radom number between 1 and 100
import 'dart:math' as math;

import 'dart:typed_data';

class Chip8 {
  final List<int> _fontset = [
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80 // F
  ];

  late List<int> memory = List<int>.filled(4096, 0);
  late List<List<int>> graphics =
      List.generate(64, (i) => List<int>.filled(32, 0), growable: false);

  late Uint8List v = Uint8List(16);
  late List<int> stack = List.filled(16, 0);
  late List<int> key = List<int>.filled(16, 0);
  late int i;
  late int pc;
  late int sp;
  late int delayTimer;
  late int soundTimer;
  late int opcode;
  late bool drawFlag;

  void loadFonts() {
    for (i = 0; i < 80; i++) {
      memory[i] = _fontset[i];
    }
  }

  void initialize() {
    loadFonts();
    pc = 0x200;
    opcode = 0;
    i = 0;
    sp = 0;
    delayTimer = 0;
    soundTimer = 0;
    drawFlag = false;
    for (i = 0; i < 16; i++) {
      v[i] = 0;
      stack[i] = 0;
      key[i] = 0;
    }
  }

  void emulateCycle() {
    // Fetch Opcode and decode
    opcode = memory[pc] << 8 | memory[pc + 1];

    // execute opcode
    // first 4 bits
    switch (opcode & 0xF000) {
      case 0x0000:
        // last 4 bits
        switch (opcode & 0x000F) {
          // ignore 0x0NNN instruction for now
          case 0x0000:
            // 0x00E0: Clears the screen
            for (var k = 0; k < 64; k++) {
              for (var j = 0; j < 32; j++) {
                graphics[k][j] = 0;
              }
            }
            drawFlag = true;
            pc += 2;
            break;
          case 0x000E:
            // 0x00EE: Returns from subroutine
            sp--;
            pc = stack[sp];
            pc += 2;
            break;
          default:
            throw Exception('Unknown opcode: ${opcode.toRadixString(16)}');
        }
        break;
      case 0x1000:
        // 0x1NNN: Jumps to address NNN
        pc = opcode & 0x0FFF;
        break;
      case 0x2000:
        // 0x2NNN: Calls subroutine at NNN
        stack[sp] = pc;
        sp++;
        pc = opcode & 0x0FFF;
        break;
      case 0x3000:
        // 0x3XNN: Skips the next instruction if VX equals NN
        if (v[(opcode & 0x0F00) >> 8] == (opcode & 0x00FF)) {
          pc += 4; // Skips the next instruction
        } else {
          pc += 2;
        }
        break;
      case 0x4000:
        // 0x4XNN: Skips the next instruction if VX doesn't equal NN
        if (v[(opcode & 0x0F00) >> 8] != (opcode & 0x00FF)) {
          pc += 4; // Skips the next instruction
        } else {
          pc += 2;
        }
        break;
      case 0x5000:
        // 0x5XY0: Skips the next instruction if VX equals VY
        if (v[(opcode & 0x0F00) >> 8] == v[(opcode & 0x00F0) >> 4]) {
          pc += 4; // Skips the next instruction
        } else {
          pc += 2;
        }
        break;
      case 0x6000:
        // 0x6XNN: Sets VX to NN
        v[(opcode & 0x0F00) >> 8] = (opcode & 0x00FF);
        pc += 2;
        break;
      case 0x7000:
        // 0x7XNN: Adds NN to VX
        v[(opcode & 0x0F00) >> 8] += (opcode & 0x00FF);
        pc += 2;
        break;
      case 0x8000:
        switch (opcode & 0x000F) {
          case 0x0000:
            // 0x8XY0: Sets VX to the value of VY
            v[(opcode & 0x0F00) >> 8] = v[(opcode & 0x00F0) >> 4];
            pc += 2;
            break;
          case 0x0001:
            // 0x8XY1: Sets VX to VX or VY
            v[(opcode & 0x0F00) >> 8] |= v[(opcode & 0x00F0) >> 4];
            pc += 2;
            break;
          case 0x0002:
            // 0x8XY2: Sets VX to VX and VY
            v[(opcode & 0x0F00) >> 8] &= v[(opcode & 0x00F0) >> 4];
            pc += 2;
            break;
          case 0x0003:
            // 0x8XY3: Sets VX to VX xor VY
            v[(opcode & 0x0F00) >> 8] ^= v[(opcode & 0x00F0) >> 4];
            pc += 2;
            break;
          case 0x0004:
            // 0x8XY4: Adds VY to VX. VF is set to 1 when there's a carry, and to 0 when there isn't
            if (v[(opcode & 0x00F0) >> 4] >
                (0xFF - v[(opcode & 0x0F00) >> 8])) {
              v[0xF] = 1; //carry
            } else {
              v[0xF] = 0;
            }
            v[(opcode & 0x0F00) >> 8] += v[(opcode & 0x00F0) >> 4];
            pc += 2;
            break;
          case 0x0005:
            // 0x8XY5: VY is subtracted from VX. VF is set to 0 when there's a borrow, and 1 when there isn't
            if (v[(opcode & 0x00F0) >> 4] > v[(opcode & 0x0F00) >> 8]) {
              v[0xF] = 0; // there's a borrow
            } else {
              v[0xF] = 1;
            }
            v[(opcode & 0x0F00) >> 8] -= v[(opcode & 0x00F0) >> 4];
            pc += 2;
            break;
          case 0x0006:
            // 0x8XY6: Shifts VX right by one. VF is set to the value of the least significant bit of VX before the shift
            v[0xF] = v[(opcode & 0x0F00) >> 8] & 0x1;
            v[(opcode & 0x0F00) >> 8] >>= 1;
            pc += 2;
            break;
          case 0x0007:
            // 0x8XY7: Sets VX to VY minus VX. VF is set to 0 when there's a borrow, and 1 when there isn't
            if (v[(opcode & 0x0F00) >> 8] > v[(opcode & 0x00F0) >> 4]) {
              v[0xF] = 0; //borrow
            } else {
              v[0xF] = 1;
            }
            v[(opcode & 0x0F00) >> 8] =
                v[(opcode & 0x00F0) >> 4] - v[(opcode & 0x0F00) >> 8];
            pc += 2;
            break;
          case 0x000E:
            // 0x8XYE: Shifts VX left by one. VF is set to the value of the most significant bit of VX before the shift
            v[0xF] = v[(opcode & 0x0F00) >> 8] >> 7;
            v[(opcode & 0x0F00) >> 8] <<= 1;
            pc += 2;
            break;
          default:
            print('Unknown opcode [0x8000]: 0x$opcode\n');
            break;
        }
        break;
      case 0x9000:
        // 0x9XY0: Skips the next instruction if VX doesn't equal VY
        if (v[(opcode & 0x0F00) >> 8] != v[(opcode & 0x00F0) >> 4]) {
          pc += 4; // Skips the next instruction
        } else {
          pc += 2;
        }
        break;
      case 0xA000:
        // 0xANNN: Sets I to the address NNN
        i = opcode & 0x0FFF;
        pc += 2;
        break;
      case 0xB000:
        // 0xBNNN: Jumps to the address NNN plus V0
        pc = (opcode & 0x0FFF) + v[0];
        break;
      case 0xC000:
        // 0xCXNN: Sets VX to the result of a bitwise and operation on a random number (Typically: 0 to 255) and NN
        v[(opcode & 0x0F00) >> 8] =
            (math.Random().nextInt(254) % 0xFF) & (opcode & 0x00FF);
        pc += 2;
        break;
      case 0xD000:
        // 0xDXYN: Draws a sprite at coordinate (VX, VY) that has a width of 8 pixels and a height of N pixels. Each row of 8 pixels is read as bit-coded starting from memory location I; I value doesn't change after the execution of this instruction. As described above, VF is set to 1 if any screen pixels are flipped from set to unset when the sprite is drawn, and to 0 if that doesn't happen
        var x = v[(opcode & 0x0F00) >> 8];
        var y = v[(opcode & 0x00F0) >> 4];
        var height = opcode & 0x000F;
        v[0xF] = 0;
        for (var yline = 0; yline < height; yline++) {
          var pixel = memory[i + yline];
          for (var xline = 0; xline < 8; xline++) {
            if ((pixel & (0x80 >> xline)) != 0) {
              if (graphics[x + xline][y + yline] == 1) {
                v[0xF] = 1;
              }
              graphics[x + xline][y + yline] ^= 1;
            }
          }
        }
        drawFlag = true;
        pc += 2;
        break;
      case 0xE000:
        switch (opcode & 0x00FF) {
          case 0x009E:
            // 0xEX9E: Skips the next instruction if the key stored in VX is pressed
            if (key[v[(opcode & 0x0F00) >> 8]] == 1) {
              pc += 4; // Skips the next instruction
            } else {
              pc += 2;
            }
            break;
          case 0x00A1:
            // 0xEXA1: Skips the next instruction if the key stored in VX isn't pressed
            if (key[v[(opcode & 0x0F00) >> 8]] == 0) {
              pc += 4; // Skips the next instruction
            } else {
              pc += 2;
            }
            break;
          default:
            throw Exception(
                'Unknown opcode [0xE000]: 0x${opcode.toRadixString(16)}\n');
        }
        break;
      case 0xF000:
        switch (opcode & 0x00FF) {
          case 0x0007:
            // 0xFX07: Sets VX to the value of the delay timer
            v[(opcode & 0x0F00) >> 8] = delayTimer;
            pc += 2;
            break;
          case 0x000A:
            // 0xFX0A: A key press is awaited, and then stored in VX
            for (var k = 0; k < 16; k++) {
              if (key[k] != 0) {
                v[(opcode & 0x0F00) >> 8] = k;
                break;
              }
            }
            pc += 2;
            break;
          case 0x0015:
            // 0xFX15: Sets the delay timer to VX
            delayTimer = v[(opcode & 0x0F00) >> 8];
            pc += 2;
            break;
          case 0x0018:
            // 0xFX18: Sets the sound timer to VX
            soundTimer = v[(opcode & 0x0F00) >> 8];
            pc += 2;
            break;
          case 0x001E:
            // 0xFX1E: Adds VX to I
            if (i + v[(opcode & 0x0F00) >> 8] > 0xFFF) {
              v[0xF] = 1;
            } else {
              v[0xF] = 0;
            }
            i += v[(opcode & 0x0F00) >> 8];
            pc += 2;
            break;
          case 0x0029:
            // 0xFX29: Sets I to the location of the sprite for the character in VX. Characters 0-F (in hexadecimal) are represented by a 4x5 font
            i = v[(opcode & 0x0F00) >> 8] * 0x5;
            pc += 2;
            break;
          case 0x0033:
            // 0xFX33: Stores the binary-coded decimal representation of VX, with the most significant of three digits at the address in I, the middle digit at I plus 1, and the least significant digit at I plus 2. (In other words, take the decimal representation of VX, place the hundreds digit in memory at location in I, the tens digit at location I+1, and the ones digit at location I+2.)
            memory[i] = v[(opcode & 0x0F00) >> 8] ~/ 100;
            memory[i + 1] = (v[(opcode & 0x0F00) >> 8] ~/ 10) % 10;
            memory[i + 2] = (v[(opcode & 0x0F00) >> 8] % 100) % 10;
            pc += 2;
            break;
          case 0x0055:
            // 0xFX55: Stores V0 to VX in memory starting at address I
            for (var k = 0; k <= ((opcode & 0x0F00) >> 8); k++) {
              memory[i + k] = v[k];
            }
            i += ((opcode & 0x0F00) >> 8) + 1;
            pc += 2;
            break;
          case 0x0065:
            // 0xFX65: Fills V0 to VX with values from memory starting at address I
            for (var k = 0; k <= ((opcode & 0x0F00) >> 8); k++) {
              v[k] = memory[i + k];
            }
            i += ((opcode & 0x0F00) >> 8) + 1;
            pc += 2;
            break;
          default:
            throw Exception('Unknown opcode: 0x${opcode.toRadixString(16)}\n');
        }
        break;
      default:
        throw Exception('Unknown opcode: 0x${opcode.toRadixString(16)}\n');
    }
  }

  void loadGame(List<int> game) {
    for (var k = 0; k < game.length; k++) {
      memory[k + 512] = game[k];
    }
  }
}
