import
  std/strutils

import
  ../db/stateUtils,
  ./util/rpcCommon

rpcMethod completeState:
  let sessKeyOpt = req.getSessKeyOpt()
  if sessKeyOpt.isNone():
    return (nil, getRpcError 3)

  let sessKey = db.selectRow(
    @["val", "userId"],
    "sessionKeys",
    { "val": sessKeyOpt.get() }
  )
  if "val" notin sessKey:
    return (nil, getRpcError 2)

  let state = db.queryCompleteState(
    playerId=sessKey["userId", int]
  )
  return (state, nil)

rpcMethod syncState:
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
    @["val", "userId"],
    "sessionKeys",
    { "val": sessKeyOpt.get() }
  )
  if "val" notin sessKey:
    return (nil, getRpcError 2)

  let userAgent = req.headers.getOrDefault("User-Agent")
  if not isUserAgentAllowed userAgent:
    return (db.queryCompleteState(
      playerId=sessKey["userId", int]
    ), nil)

  let userCompleteState = params[0]
  when defined(validateState):
    if db.isCompleteStateOkay(
      playerId=sessKey["userId", int],
      state=userCompleteState
    ):
      result[0] = %* { "stateUpdateOutcome": "CLIENT_REQUEST_ACCEPTED" }
    else:
      info "Incomplete game state from " & sessKey["userId"]
      result[0] = db.queryCompleteState(
        playerId=sessKey["userId", int]
      )
  else:
    # Blindly consider that
    # the user is trustworthy
    db.applyCompleteState(
      playerId=sessKey["userId", int],
      state=userCompleteState
    )
    result[0] = %* { "stateUpdateOutcome": "CLIENT_REQUEST_ACCEPTED" }
