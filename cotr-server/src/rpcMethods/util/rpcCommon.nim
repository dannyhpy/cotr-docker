import
  std/asyncdispatch,
  std/asynchttpserver,
  std/json,
  std/macros,
  std/options,
  std/strutils,
  std/uri

import
  ../../db/dbUtils,
  ../../db/objUtils

export
  asyncdispatch,
  asynchttpserver,
  dbUtils,
  json,
  objUtils,
  options

macro rpcMethod*(name, body: untyped) =
  let reqIdent = ident"req"
  let paramsIdent = ident"params"
  let dbIdent = ident"db"
  result = quote do:
    proc `name`*(
      `reqIdent`: Request;
      `paramsIdent`: JsonNode;
      `dbIdent`: DbConn
    ): Future[tuple[
      rpcResult: JsonNode;
      rpcError: JsonNode
    ]] {.async.} =
      `body`

func getSessKeyOpt*(req: Request): Option[string] =
  for key, value in decodeQuery req.url.query:
    if key == "_session":
      return some value

func getRpcError*(code: int): JsonNode =
  result = %* { "code": code }
  case code
  of -32700:
    result["message"] = %* "Parse error"
  of -32602:
    result["message"] = %* "Invalid params"
  of -32601:
    result["message"] = %* "Method not found"
  of 2:
    result["message"] = %* "Authentication error"
  of 3:
    result["message"] = %* "No session key error"
  else:
    raise newException(ValueError, "Unknown RPC error code")

func isUserAgentAllowed*(userAgent: string): bool =
  if ';' notin userAgent: return
  let values = userAgent.split(";")
  if values.len() != 5: return
  if values[0] != "212": return
  if values[1] != "v1": return
  if values[2] != "1.170.29":
    if values[2] != "1.170.34": return
  return true
