import
  std/asyncdispatch,
  std/asynchttpserver,
  std/json,
  std/logging,
  std/strutils,
  std/tables

import
  pkg/zippy

import
  ./db/dbUtils,
  ./rpcMethods

proc validateJsonRpcRequestObj(node: JsonNode): bool =
  result = true
  if node.kind != JObject: return false
  if not node.hasKey "jsonrpc": return false
  if node["jsonrpc"].kind != JString: return false
  if node["jsonrpc"].getStr() != "2.0": return false
  if not node.hasKey "id": return false
  if node["id"].kind != JInt: return false
  if not node.hasKey "method": return false
  if node["method"].kind != JString: return false

proc handleJsonRpc*(
  req: Request;
  db: DbConn
) {.async.} =
  template reject400 =
    await req.respond(Http400, "")
    return

  if req.reqMethod != HttpPost:
    await req.respond(Http405, "")
    return

  var bodyStr = req.body
  # Parse 'Content-Encoding' header
  if req.headers.getOrDefault("Content-Encoding") == "gzip":
    try:
      bodyStr = req.body.uncompress()
    except ZippyError:
      await req.respond(Http400, "")
      return

  let body = block:
    try: bodyStr.parseJson()
    except JsonParsingError: reject400

  var response: JsonNode

  if body.kind == JObject:
    let validated = validateJsonRpcRequestObj body
    if not validated:
      reject400

    response = %*{
      "jsonrpc": "2.0",
      "id": body["id"]
    }
    let rpcMethodName = body["method"].getStr()
    debug "Single RPC Call to " & rpcMethodName
    let rpcMethodProc = rpcMethodTable.getOrDefault(rpcMethodName)
    if not rpcMethodProc.isNil():
      let returnVal = await rpcMethodProc(
        req,
        body["params"],
        db
      )
      if returnVal.rpcError.isNil():
        response["result"] = returnVal.rpcResult
      else:
        response["error"] = returnVal.rpcError
    else:
      warn "Missing RPC method (in a single RPC call context): " & getStr body["method"]
      response["error"] = %*{
        "code": -32601,
        "message": "Method not found"
      }
  elif body.kind == JArray:
    response = %* []
    var unsupportedRequests: seq[JsonNode]

    for node in body:
      let validated = validateJsonRpcRequestObj node
      if not validated:
        reject400

      let rpcMethodName = node["method"].getStr()
      debug "RPC Call to " & rpcMethodName
      let rpcMethodProc = rpcMethodTable.getOrDefault(rpcMethodName)
      if not rpcMethodProc.isNil():
        let returnVal = await rpcMethodProc(
          req,
          node["params"],
          db
        )
        let rpcResponse = %*{
          "jsonrpc": "2.0",
          "id": node["id"]
        }
        if returnVal.rpcError.isNil():
          rpcResponse["result"] = returnVal.rpcResult
        else:
          rpcResponse["error"] = returnVal.rpcError
        response.add rpcResponse
      else:
        unsupportedRequests.add node

    if unsupportedRequests.len() > 0:
      for reqNode in unsupportedRequests:
        warn "Missing RPC method: " & reqNode["method"].getStr() & ", POST data: " & $reqNode
        let rpcResponse = %*{
          "jsonrpc": "2.0",
          "id": reqNode["id"]
        }
        rpcResponse["error"] = %*{
          "code": -32601,
          "message": "Method not found"
        }
        response.add rpcResponse
  else:
    reject400

  var encodeResponseInGzip = false
  when not defined(noGzipResponses):
    if "gzip" in req.headers.getOrDefault("Accept-Encoding"):
      encodeResponseInGzip = true
  if encodeResponseInGzip:
    await req.respond(
      Http200,
      compress $response,
      newHttpHeaders(
        {
          "Content-Encoding": "gzip",
          "Content-Type": "application/json",
          "Vary": "Accept-Encoding"
        },
        # This is NECESSARY because the
        # application STRICTLY looks for
        # the "Content-Encoding" header
        # in a CASE-SENSITIVE way.
        titleCase=true
      )
    )
  else:
    await req.respond(
      Http200,
      $response,
      newHttpHeaders(
        {
          "Content-Type": "application/json"
        },
        titleCase=true
      )
    )
