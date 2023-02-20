import
  pkg/bcrypt

import
  ./util/rpcCommon

rpcMethod authenticate:
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)
  if params.len() != 3:
    return (nil, getRpcError -32602)
  for it in params:
    if it.kind != JString:
      return (nil, getRpcError -32602)
  if params[0].getStr().len() == 0:
    return (nil, getRpcError -32602)
  if params[1].getStr().len() == 0:
    return (nil, getRpcError -32602)

  result[0] = %*{
    "coreUserId": 0,
    "mergeStatus": 3
  }

  let email = getStr params[0]
  let passwordPlain = getStr params[1]

  let user = db.selectRow(
    @["id", "emailAddr", "passwordHash", "passwordSalt", "signInToken", "signUpToken"],
    "users",
    { "emailAddr": email }
  )
  if "id" notin user:
    result[0]["resultCode"] = %* -1002
    result[0]["resultMessage"] = %* "Invalid credentials"
    return

  if "passwordHash" notin user:
    result[0]["resultCode"] = %* -1213225217
    result[0]["resultMessage"] = %* "Passwordless user"
    return

  let passwordHash = bcrypt.hash(
    passwordPlain,
    user["passwordSalt"]
  )
  let matching = bcrypt.compare(passwordHash, user["passwordHash"])
  if not matching:
    result[0]["resultCode"] = %* -1002
    result[0]["resultMessage"] = %* "Invalid credentials"
    return

  result[0] = %*{
    "resultCode": 1,
    "resultMessage": "Authenticated",
    "coreUserId": user["id", int],
    "signUpToken": user["signUpToken"],
    "authenticationToken": user["signInToken"],
    "mergeStatus": 2
  }
