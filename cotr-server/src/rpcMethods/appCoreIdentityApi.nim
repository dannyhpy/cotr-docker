import
  std/base64,
  std/logging,
  std/strutils,
  std/sysrand

import
  ./util/rpcCommon

rpcMethod authenticate:
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)
  if params.len() != 2:
    return (nil, getRpcError -32602)
  if params[0].kind != JString:
    return (nil, getRpcError -32602)
  if params[0].getStr().len() == 0:
    return (nil, getRpcError -32602)
  if params[1].kind != JString:
    return (nil, getRpcError -32602)

  let user = db.selectRow(
    @["id", "remote", "signInToken"],
    "users",
    {"signUpToken": getStr params[0]}
  )
  if "id" notin user:
    result[0] = %*{
      "resultCode": -1002,
      "resultMessage": "Invalid credentials",
      "coreUserId": 0,
      "mergeStatus": 3
    }
    return

  var signInToken = user["signInToken"]
  if signInToken == "":
    signInToken = base64.encode(urandom 36, safe = true)
    db.exec(
      sql"UPDATE users SET signInToken = ? WHERE id = ?", signInToken,
      user["id", int]
    )
  result[0] = %*{
    "resultCode": 1,
    "resultMessage": "Authenticated",
    "coreUserId": user["id", int],
    "signUpToken": getStr params[0],
    "authenticationToken": signInToken,
    "mergeStatus": 2
  }

rpcMethod getAuthenticationInfo:
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)
  if params.len() != 1:
    return (nil, getRpcError -32602)
  if params[0].kind != JArray:
    return (nil, getRpcError -32602)
  for i in 0 ..< params[0].len():
    if params[0][i].kind != JInt:
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

  let user = db.selectRow(
    @["id", "name", "emailAddr"],
    "users",
    { "id": sessKey["userId"] }
  )
  if "id" notin user:
    return (nil, getRpcError 2)

  result[0] = %* { "methodInfos": [] }
  for it in params[0]:
    if it.getInt() != 1: continue
    let emailAddr = user["emailAddr"]
    if emailAddr == "":
      result[0]["methodInfos"].add %*{
        "methodId": 1,
        "links": []
      }
    else:
      result[0]["methodInfos"].add %*{
        "methodId": 1,
        "links": [{
          "id": emailAddr,
          "linkStatus": 1,
          "primary": true,
          "emailVerified": false
        }]
      }
    break

rpcMethod logIn:
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)
  if params.len() != 6:
    return (nil, getRpcError -32602)
  if params[0].kind != JString:
    return (nil, getRpcError -32602)
  if params[1].kind != JString:
    return (nil, getRpcError -32602)
  if params[2].kind != JInt:
    return (nil, getRpcError -32602)
  if params[3].kind != JString:
    return (nil, getRpcError -32602)
  if params[4].kind != JString:
    return (nil, getRpcError -32602)
  if params[5].kind != JString:
    return (nil, getRpcError -32602)

  let signInToken = getStr params[0]
  if signInToken == "":
    result[0] = %*{
      "resultCode": -1002,
      "resultMessage": "Invalid credentials",
      "signInCount": 0
    }
    return

  let user = db.selectRow(
    @["id", "remote", "signInCount"],
    "users",
    {"signInToken": signInToken}
  )
  if "id" notin user:
    result[0] = %*{
      "resultCode": -1002,
      "resultMessage": "Invalid credentials",
      "signInCount": 0
    }
    return

  let genSessKey = base64.encode(urandom 18, safe = true)
  db.exec(
    sql"INSERT INTO sessionKeys (val, remote, userId) VALUES (?, ?, ?)",
    genSessKey,
    false,
    user["id"]
  )

  db.exec(
    sql"""UPDATE users SET
      signInCount = signInCount + 1,
      lastSignInAt = CURRENT_TIMESTAMP
    WHERE id = ?""",
    user["id"]
  )
  result[0] = %*{
    "resultCode": 1,
    "resultMesage": "Logged in",
    "sessionKey": genSessKey,
    "signInCount": block:
      user["signInCount", int] + 1
  }

rpcMethod signUp:
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)
  if params.len() != 1:
    return (nil, getRpcError -32602)
  if params[0].kind != JString:
    return (nil, getRpcError -32602)

  let installId = getStr params[0]
  let signInToken = base64.encode(urandom 36, safe = true)
  let signUpToken = base64.encode(urandom 36, safe = true)
  db.exec(
    sql"""INSERT INTO users (installId, signInToken, signUpToken)
    VALUES (?, ?, ?)""",
    installId,
    signInToken,
    signUpToken
  )
  let userIdStr = db.getValue(sql"SELECT id FROM users WHERE signUpToken = ?", signUpToken)
  notice "Created local user n°" & userIdStr
  result[0] = %*{
    "resultCode": 1,
    "resultMessage": "Created account",
    "coreUserId": parseInt userIdStr,
    "signUpToken": signUpToken
  }
