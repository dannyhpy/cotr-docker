import
  std/strutils

import
  ./util/rpcCommon

rpcMethod getPlayerStats:
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)
  if params.len() != 1:
    return (nil, getRpcError -32602)
  if params[0].kind != JInt:
    return (nil, getRpcError -32602)

  let targetPlayerId = getInt params[0]

  result[0] = %*{
    "coreUserId": targetPlayerId,
    "xp": 0,
    "level": 0,
    "powerGems": 0,
    "numberOfSkins": 0
  }

  let targetPlayer = db.selectRow(
    @["id", "xp", "level"],
    "players",
    { "id": $targetPlayerId }
  )
  if "id" notin targetPlayer:
    return

  result[0]["xp"] = %* targetPlayer["xp", int]
  result[0]["level"] = %* targetPlayer["level", int]
  result[0]["powerGems"] = %* parseInt db.getValue(
    sql"SELECT SUM(powerGems) FROM islands WHERE playerId = ?",
    targetPlayer["id"]
  )
  result[0]["numberOfSkins"] = %* parseInt db.getValue(
    sql"SELECT COUNT(1) FROM skins WHERE playerId = ?",
    targetPlayer["id"]
  )

rpcMethod setPlayerActiveSkin:
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)
  if params.len() != 1:
    return (nil, getRpcError -32602)
  if params[0].kind != JInt:
    return (nil, getRpcError -32602)

  let skinId = params[0].getInt()
  if skinId < 0:
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

  result[0] = %* nil

  let player = db.selectRow(
    @["id", "skinId"],
    "players",
    { "id": sessKey["userId"] }
  )
  if "skinId" in player:
    if player["skinId", int] == skinId:
      return
    db.exec(
      sql"UPDATE players SET skinId = ? WHERE id = ?",
      skinId,
      player["id"]
    )
  else:
    db.exec(
      sql"INSERT INTO players (id, skinId) VALUES (?, ?)",
      player["id"],
      skinId
    )
