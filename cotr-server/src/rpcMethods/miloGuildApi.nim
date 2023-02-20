import
  std/strutils

import
  ../db/objUtils,
  ../db/stateUtils,
  ./util/rpcCommon

proc getGuildDto(
  db: DbConn; 
  id: Natural;
  expandMembers = false
): JsonNode =
  result = guildDtoRepr()

  let guild = db.selectRow(
    @["id", "name", "description", "badgeId"],
    "guilds",
    { "id": $id }
  )
  if "id" notin guild:
    return

  result["guildId"] = %* id
  result["name"] = %* guild["name"]
  result["description"] = %* guild["description"]
  result["numMembers"] = %* parseInt db.getValue(
    sql"SELECT COUNT(1) FROM guildMembers WHERE guildId = ?",
    id
  )
  result["editableProperties"] = %*[
    { "name": "badgeId", "value": guild["badgeId"] }
  ]
  result["computedProperties"] = %*[
    { "name": "memberPowerGemsAvg", "value": "0" },
    { "name": "leagueId", "value": "0" },
    { "name": "leaderboardPosition", "value": "1" },
    { "name": "activityLevel", "value": "5" },
    {
      "name": "crashPoints",
      "value": block:
        let crashPointsSumStr = db.getValue(
          sql"""SELECT SUM(crashPoints)
          FROM players
          WHERE id IN (
            SELECT playerId FROM guildMembers WHERE guildId = ?
          )""",
          id
        )
        if crashPointsSumStr == "": "0"
        else: crashPointsSumStr
    }
  ]
  result["internalProperties"] = %*[
    { "name": "chatId", "value": "1" }
  ]

  if expandMembers:
    let memberRows = db.getAllRows(
      sql"""SELECT playerId, leader
      FROM guildMembers
      WHERE guildId = ?""",
      id
    )
    for memberRow in memberRows:
      let memberId = parseInt memberRow[0]
      let user = db.selectRow(
        @["id", "name"],
        "users",
        { "id": $memberId }
      )
      let player = db.selectRow(
        @["skinId", "crashPoints"],
        "players",
        { "id": $memberId }
      )
      let playerSkinId = block:
        if "skinId" in player: player["skinId"]
        else: "81329"
      let playerCrashPoints = block:
        if "crashPoints" in player: player["crashPoints"]
        else: "0"

      result["members"].add %*{
        "coreUserId": memberId,
        "status": block:
          if memberRow[1][0] == 't': 2
          else: 1,
        "editableProperties": [],
        "computedProperties": [
          { "name": "guildMemberName", "value": userDisplayName user },
          { "name": "memberActiveSkinId", "value": playerSkinId },
          { "name": "contributedCrashPoints", "value": playerCrashPoints }
        ],
        "internalProperties": []
      }

rpcMethod createGuild:
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)
  if params.len() != 1:
    return (nil, getRpcError -32602)
  if params[0].kind != JObject:
    return (nil, getRpcError -32602)
  for strItKey in [
    "teamConfigId",
    "guildName",
    "guildDescription"
  ]:
    if not params[0].hasKey strItKey:
      return (nil, getRpcError -32602)
    if params[0][strItKey].kind != JString:
      return (nil, getRpcError -32602)
  if not params[0].hasKey "guildBadge":
    return (nil, getRpcError -32602)
  if params[0]["guildBadge"].kind != JInt:
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

  let player = db.selectRow(
    @["id", "guildId"],
    "players",
    { "id": sessKey["userId"] }
  )
  if "id" in player:
    if "guildId" in player:
      result[0] = %*{
        "stateUpdateOutcome": "CLIENT_REQUEST_REJECTED"
      }
      return

  if params[0]["teamConfigId"].getStr() != "default":
    result[0] = %*{
      "stateUpdateOutcome": "CLIENT_REQUEST_REJECTED"
    }
    return
  let name = params[0]["guildName"].getStr()
  if name.len() < 2 or name.len() > 32:
    result[0] = %*{
      "stateUpdateOutcome": "CLIENT_REQUEST_REJECTED",
      "responseStatus": "INVALID_GUILD_NAME"
    }
    return
  let desc = params[0]["guildDescription"].getStr()
  if desc.len() > 100:
    result[0] = %*{
      "stateUpdateOutcome": "CLIENT_REQUEST_REJECTED",
      "responseStatus": "INVALID_GUILD_DESCRIPTION"
    }
    return
  let badgeId = params[0]["guildBadge"].getInt()
  if badgeId < 0 or badgeId > 5:
    result[0] = %*{
      "stateUpdateOutcome": "CLIENT_REQUEST_REJECTED",
      "responseStatus": "INVALID_GUILD_BADGE"
    }
    return

  when defined(dbPostgres):
    db.exec(sql"BEGIN")
    try:
      let guildIdStr = db.getValue(
        sql"""INSERT INTO guilds (name, description, badgeId)
        VALUES (?, ?, ?)
        RETURNING id""",
        name,
        desc,
        badgeId
      )
      db.exec(
        sql"""INSERT INTO guildMembers (guildId, playerId, leader)
        VALUES (?, ?, TRUE)""",
        guildIdStr,
        sessKey["userId"]
      )
      db.exec(
        sql"UPDATE players SET guildId = ? WHERE id = ?",
        guildIdStr,
        sessKey["userId"]
      )
      db.exec(sql"COMMIT")
      result[0] = initEmptyStateDiff()
      result[0]["stateUpdateOutcome"] = %* "CLIENT_REQUEST_ACCEPTED"
      result[0]["inventoryDiff"]["items"].add %*{
        "itemTypeId": 81000, "count": -10
      }
    except Exception as err:
      db.exec(sql"ROLLBACK")
      raise err
  else:
    # TODO: Support guild creation using SQLite
    result[0] = %*{
      "stateUpdateOutcome": "CLIENT_REQUEST_REJECTED"
    }

rpcMethod getCommonGuildSettings:
  result[0] = %*{
    "nameConstraints": { "min": 2, "max": 32 },
    "descriptionConstraints": { "min": 0, "max": 128 },
    "properties": []
  }

rpcMethod getGuild:
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)
  if params.len() != 1:
    return (nil, getRpcError -32602)
  if params[0].kind != JInt:
    return (nil, getRpcError -32602)

  let guildId = params[0].getInt()
  result[0] = db.getGuildDto(
    guildId,
    expandMembers=true
  )

rpcMethod getGuildJoinCooldownLeft:
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

  result[0] = %*{
    "stateUpdateOutcome": "CLIENT_REQUEST_ACCEPTED",
    "secondsLeft": 0
  }

rpcMethod getMyGuild:
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

  result[0] = guildDtoRepr()

  let player = db.selectRow(
    @["id", "guildId"],
    "players",
    { "id": sessKey["userId"] }
  )
  if "id" notin player:
    return
  if "guildId" notin player:
    return

  result[0] = db.getGuildDto(
    player["guildId", int],
    expandMembers=true
  )

rpcMethod joinGuild:
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)
  if params.len() != 1:
    return (nil, getRpcError -32602)
  if params[0].kind != JObject:
    return (nil, getRpcError -32602)
  if params[0].len() != 1:
    return (nil, getRpcError -32602)
  if not params[0].hasKey "guildId":
    return (nil, getRpcError -32602)
  if params[0]["guildId"].kind != JInt:
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

  template rejectClientReq(): untyped =
    result[0] = %*{
      "stateUpdateOutcome": "CLIENT_REQUEST_REJECTED"
    }
    return

  let guildId = getInt params[0]["guildId"]
  let guild = db.selectRow(
    @["id"],
    "guilds",
    { "id": $guildId }
  )
  if "id" notin guild:
    rejectClientReq

  let player = db.selectRow(
    @["id", "guildId"],
    "players",
    { "id": sessKey["userId"] }
  )
  if "id" in player:
    if "guildId" in player:
      rejectClientReq

  db.exec(
    sql"""INSERT INTO guildMembers (guildId, playerId)
    VALUES (?, ?)""",
    guildId,
    sessKey["userId"]
  )
  if "id" in player:
    db.exec(
      sql"UPDATE players SET guildId = ? WHERE id = ?",
      guildId,
      sessKey["userId"]
    )
  else:
    db.exec(
      sql"INSERT INTO players (id, guildId) VALUES (?, ?)",
      sessKey["userId"],
      guildId
    )

  result[0] = initEmptyStateDiff()
  result[0]["stateUpdateOutcome"] = %* "CLIENT_REQUEST_ACCEPTED"

rpcMethod leaveGuild:
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

  template rejectClientReq(): untyped =
    result[0] = %*{
      "stateUpdateOutcome": "CLIENT_REQUEST_REJECTED"
    }
    return

  let player = db.selectRow(
    @["id", "guildId"],
    "players",
    { "id": sessKey["userId"] }
  )
  if "id" notin player:
    rejectClientReq
  if "guildId" notin player:
    rejectClientReq

  let guild = db.selectRow(
    @["id"],
    "guilds",
    { "id": player["guildId"] }
  )
  if "id" notin guild:
    rejectClientReq

  db.exec(
    sql"DELETE FROM guildMembers WHERE guildId = ? AND playerId = ?",
    player["guildId"],
    player["id"]
  )
  db.exec(
    sql"UPDATE players SET guildId = NULL WHERE id = ?",
    player["id"]
  )
  result[0] = %*{ "stateUpdateOutcome": "CLIENT_REQUEST_ACCEPTED" }

rpcMethod suggestGuilds2:
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)

  var theirGuildId = -1
  var filterOutTheirGuild = false
  if params.len() == 1:
    if params[0].kind == JObject:
      if params[0].hasKey "filterOutOwnGuild":
        if params[0].len() != 1:
          return (nil, getRpcError -32602)
        if params[0]["filterOutOwnGuild"].kind != JBool:
          return (nil, getRpcError -32602)
        filterOutTheirGuild = params[0]["filterOutOwnGuild"].getBool()
      else:
        if params[0].len() != 0:
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

  if filterOutTheirGuild:
    let player = db.selectRow(
      @["guildId"],
      "players",
      { "id": sessKey["userId"] }
    )
    if "guildId" in player:
      theirGuildId = player["guildId", int]

  result[0] = %* { "guilds": [] }

  let guildIdRows = db.getAllRows(
    sql"SELECT id FROM guilds WHERE id != ? LIMIT 10",
    theirGuildId
  )
  for guildIdRow in guildIdRows:
    result[0]["guilds"].add db.getGuildDto(parseInt guildIdRow[0])
