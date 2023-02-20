# Package

version     = "0.1.0"
author      = "dannyhpy"
description = "Server for CrashOntheRun!"
license     = "MIT"

srcDir = "src"
binDir = "bin"
bin = @["cotr"]

# Dependencies

requires "nim >= 1.6.10"
requires "bcrypt >= 0.2.1"
requires "zippy >= 0.10.5"
