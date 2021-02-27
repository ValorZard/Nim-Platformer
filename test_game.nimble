# Package

version = "0.1.0"
author = "Your Name"
description = "test_game"
license = "?"

# Deps
requires "nim >= 1.2.0"
requires "bumpy >= 1.0.2"
requires "nico >= 0.2.5"

srcDir = "src"

task runr, "Runs test_game for current platform":
 exec "nim c -r -d:release -o:test_game src/main.nim"

task rund, "Runs debug test_game for current platform":
 exec "nim c -r -d:debug -o:test_game src/main.nim"

task release, "Builds test_game for current platform":
 exec "nim c -d:release -o:test_game src/main.nim"

task debug, "Builds debug test_game for current platform":
 exec "nim c -d:debug -o:test_game_debug src/main.nim"

task web, "Builds test_game for current web":
 exec "nim js -d:release -o:test_game.js src/main.nim"

task webd, "Builds debug test_game for current web":
 exec "nim js -d:debug -o:test_game.js src/main.nim"

task deps, "Downloads dependencies":
 exec "curl https://www.libsdl.org/release/SDL2-2.0.12-win32-x64.zip -o SDL2_x64.zip"
 exec "unzip SDL2_x64.zip"
 #exec "curl https://www.libsdl.org/release/SDL2-2.0.12-win32-x86.zip -o SDL2_x86.zip"
