import
  std/times

import
  ./util/rpcCommon

rpcMethod poll:
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)
  if params.len() != 3:
    return (nil, getRpcError -32602)
  for i in 0 ..< 3:
    if params[i].kind != JInt:
      return (nil, getRpcError -32602)

  let chatId = params[0].getInt()
  if params[1].getInt() != -1:
    # TODO: Support values other than -1
    return (nil, getRpcError -32602)
  let limit = params[2].getInt()
  if (limit < 0) or (limit > 100):
    return (nil, getRpcError -32602)

  result[0] = %*{
    "resultCodeId": 1,
    "throttled": false,
    "filtered": true,
    "lastMessageId": 1000,
    "messages": []
  }

  var i = 0
  for m in [
    ("Leader role is now correctly attributed on guild creation.", 1676822826833),
    ("Teams were updated to correctly show their member count.", 1676829752426),
    ("Survival Run tickets have returned in the shop.", 1676833158879),
    ("Team trophies were miscalculated somehow. This has been fixed.", 1676900216751)
  ]:
    i.inc()
    result[0]["messages"].add %*{
      "id": i,
      "type": 0,
      "headers": [],
      "senderId": 1005227822,
      "timestampMs": m[1],
      "clientTimestampMs": 0,
      "body": m[0]
    }

  result[0]["messages"].add %*{
    "id": 1000,
    "type": 0,
    "headers": [],
    "senderId": 0,
    "timestampMs": toInt(epochTime() * 1_000),
    "clientTimestampMs": 0,
    "body": "[Chat messages are currently not supported.]"
  }
