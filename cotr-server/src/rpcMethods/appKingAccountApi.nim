import
  ./util/rpcCommon

rpcMethod acceptTermsOfServiceAndPrivacyPolicy:
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)
  if params.len() != 2:
    return (nil, getRpcError -32602)
  if params[0].kind != JInt:
    return (nil, getRpcError -32602)
  if params[1].kind != JString:
    return (nil, getRpcError -32602)

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
    "acceptToSResultCode": 0,
    "acceptToSResultMessage": "",
    "toSAndPPAcceptanceDto": kingTosAndPpAcceptanceDtoRepr()
  }

rpcMethod getCurrentAccount:
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

  let user = db.selectRow(
    @["id", "name"],
    "users",
    { "id": sessKey["userId"] }
  )
  if "id" notin user:
    return (nil, getRpcError 2)
  result[0] = kingAccDtoRepr user
