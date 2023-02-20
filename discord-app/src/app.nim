import
  std/asyncdispatch,
  std/asynchttpserver,
  std/strutils

import
  pkg/ed25519

import
  ./config,
  ./interactions,
  ./setupcmds

when not defined(noCommandSetup):
  setupCommands()

let server = newAsyncHttpServer()

proc requestListener(req: Request) {.async.} =
  if req.reqMethod != HttpPost:
    await req.respond(Http405, "")
    return

  if not req.headers.hasKey "X-Signature-Ed25519":
    await req.respond(Http401, "")
    return

  if not req.headers.hasKey "X-Signature-Timestamp":
    await req.respond(Http401, "")
    return

  let signatureHex = req.headers["X-Signature-Ed25519"]
  let signatureStr = parseHexStr signatureHex
  var signature: Signature
  for i in 0 .. signature.high:
    signature[i] = byte signatureStr[i]

  let timestamp = req.headers["X-Signature-Timestamp"]
  let verified = verify(
    timestamp & req.body,
    signature,
    config.publicKey
  )
  if not verified:
    await req.respond(Http401, "")
    return

  await interactionHandler(req)

waitFor server.serve(8080.Port, requestListener)
