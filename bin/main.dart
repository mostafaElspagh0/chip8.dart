import 'dart:io';

import 'package:chip8/chip8.dart';

var chip8 = Chip8();

void main(List<String> arguments) async {
  chip8.initialize();
  // read file
  var file = File('assets/test_opcode.ch8');
  await file.readAsBytes().then((bytes) async {
    chip8.loadGame(bytes);
    while (true) {
      chip8.emulateCycle();
      if (chip8.drawFlag) {
        for (var i = 0; i < 32; i++) {
          for (var j = 0; j < 64; j++) {
            stdout.write(chip8.graphics[j][i] == 1 ? '■' : ' ');
          }
          stdout.write('\n');
        }
        chip8.drawFlag = false;
      }
      await Future.delayed(Duration(microseconds: 1000 ~/ 60));
    }
  });
}
