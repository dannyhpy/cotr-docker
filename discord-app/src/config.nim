import
  std/os,
  std/parsecfg,
  std/strutils

import
  pkg/ed25519

const discordApi* = "https://discord.com/api/v10"

let cfgPath = getenv "CONFIG_PATH"
if cfgPath == "":
  stderr.writeLine "Missing CONFIG_PATH environment variable"
  quit 1

let cfg* = loadConfig cfgPath

# Parse public key
var publicKey*: PublicKey
block:
  let publicKeyHex = cfg.getSectionValue("Discord Application", "public key")
  if publicKeyHex == "":
    stderr.writeline "[CONFIG] 'Discord Application' -> 'public key' is missing"
    quit 1
  assert publicKeyHex.len() == 2 * 32

  let publicKeyStr = parseHexStr publicKeyHex
  for i in 0 .. publicKey.high:
    publicKey[i] = byte publicKeyStr[i]

var clientId* = cfg.getSectionValue("Discord Application", "id")
if clientId == "":
    stderr.writeline "[CONFIG] 'Discord Application' -> 'id' is missing"
    quit 1

var clientSecret* = cfg.getSectionValue("Discord Application", "secret")
if clientSecret == "":
    stderr.writeline "[CONFIG] 'Discord Application' -> 'secret' is missing"
    quit 1

export parsecfg
