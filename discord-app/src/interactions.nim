import
  std/asyncdispatch,
  std/asynchttpserver,
  std/json

proc interactionHandler*(req: Request) {.async.} =
  if req.headers.getOrDefault("Content-Type") != "application/json":
    await req.respond(Http400, "")
    return

  let body = block:
    try:
      req.body.parseJson()
    except JsonParsingError:
      await req.respond(Http400, "")
      return

  if not body.hasKey "type": return req.respond(Http400, "")
  if body["type"].kind != JInt: return req.respond(Http400, "")

  # Ping
  if body["type"].getInt() == 1:
    await req.respond(
      Http200,
      $(%*{
        "type": 1
      }),
      {
        "Content-Type": "application/json"
      }.newHttpHeaders()
    )
    return
