import
  ./util/rpcCommon

rpcMethod getConsents3:
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)
  if params.len() != 3:
    return (nil, getRpcError -32602)
  if params[0].kind != JArray:
    return (nil, getRpcError -32602)
  if params[1].kind != JString:
    return (nil, getRpcError -32602)
  if params[2].kind != JArray:
    return (nil, getRpcError -32602)

  let sessKeyOpt = req.getSessKeyOpt()
  if sessKeyOpt.isNone():
    return (nil, getRpcError 3)

  let sessKey = db.selectRow(
    @["val", "remote"],
    "sessionKeys",
    { "val": sessKeyOpt.get() }
  )
  if "val" notin sessKey:
    return (nil, getRpcError 2)

  result[0] = %*{
    "evaluatedCountry": "",
    "consents": []
  }

rpcMethod grant2:
  # TODO
  let sessKeyOpt = req.getSessKeyOpt()
  if sessKeyOpt.isNone():
    return (nil, getRpcError 3)

  let sessKey = db.selectRow(
    @["val"],
    "sessionKeys",
    { "val": sessKeyOpt.get() }
  )
  if "val" notin sessKey:
    return (nil, getRpcError 2)

  result[0] = %*{
    "resultCode": 1
  }

rpcMethod revoke2:
  # TODO
  let sessKeyOpt = req.getSessKeyOpt()
  if sessKeyOpt.isNone():
    return (nil, getRpcError 3)

  let sessKey = db.selectRow(
    @["val"],
    "sessionKeys",
    { "val": sessKeyOpt.get() }
  )
  if "val" notin sessKey:
    return (nil, getRpcError 2)

  result[0] = %*{
    "resultCode": 0
  }
