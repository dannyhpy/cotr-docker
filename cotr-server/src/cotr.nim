import
  std/asyncdispatch,
  std/asynchttpserver,
  std/logging,
  std/strutils,
  std/uri

import
  ./db/dbUtils,
  ./rpc

var consoleLog = newConsoleLogger()
consoleLog.addHandler()

#[
let configPath = getEnv "CONFIG_PATH"
let config* = loadConfig configPath
]#
let server = newAsyncHttpServer()

proc requestListener(req: Request) {.async.} =
  debug $req.reqMethod & " " & req.url.path
  try:
    case req.url.path.strip(
      leading=false,
      chars={'-'}
    )
    of "/c", "/rpc/ClientApi2":
      await req.handleJsonRpc(db=db)
    of "/e", "/DirectMessageEventSource":
      # TODO: Handle this endpoint
      await req.respond(Http404, "")
    else:
      await req.respond(Http404, "")
  except Exception as err:
    stderr.writeLine err.msg
    await req.respond(Http500, "")

  # Flushing the stdout as the std/logging
  # module does not do it automatically
  stdout.flushFile()

waitFor server.serve(8080.Port, requestListener)
