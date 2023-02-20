import
  std/asyncdispatch,
  std/asynchttpserver,
  std/json,
  std/strutils

import
  ../../db/dbUtils,
  ../../db/stateUtils,
  ./rpcCommon

proc rpcHandleUsualStateDiffFlow*(
  req: Request;
  db: DbConn;
  params: JsonNode;
  stateValidatorProc: proc (sessKey: SelectedRow; stateDiff: JsonNode): bool {.gcsafe.} = nil
): Future[tuple[
  rpcResult: JsonNode,
  rpcError: JsonNode
]] {.async.} =
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)
  if params.len() != 1:
    return (nil, getRpcError -32602)
  if params[0].kind != JObject:
    return (nil, getRpcError -32602)

  let sessKeyOpt = req.getSessKeyOpt()
  if sessKeyOpt.isNone():
    return (nil, getRpcError 3)

  let sessKey = db.selectRow(
    @["val", "remote", "userId"],
    "sessionKeys",
    { "val": sessKeyOpt.get() }
  )
  if "val" notin sessKey:
    return (nil, getRpcError 2)

  template rejectClientReq(): untyped =
    return (%*{
      "stateUpdateOutcome": "CLIENT_REQUEST_REJECTED"
    }, nil)

  let userAgent = req.headers.getOrDefault("User-Agent")
  if not isUserAgentAllowed userAgent:
    rejectClientReq

  let stateDiff = params[0]
  when defined(validateState):
    if not stateValidatorProc.isNil():
      let isPassing = stateValidatorProc(sessKey, stateDiff)
      if not isPassing:
        rejectClientReq

  if not db.applyStateDiff(
    playerId=sessKey["userId", int],
    state=stateDiff
  ):
    rejectClientReq

  return (%*{
    "stateUpdateOutcome": "CLIENT_REQUEST_ACCEPTED"
  }, nil)
