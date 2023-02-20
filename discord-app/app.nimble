# Package

version     = "0.1.0"
author      = "dannyhpy"
description = "Discord integration for CrashOntheRun!"
license     = "MIT"

srcDir = "src"
binDir = "bin"
bin = @["app"]

# Dependencies

requires "nim >= 1.6.10"
requires "zippy >= 0.10.5"
requires "ed25519 >= 0.1.1"
