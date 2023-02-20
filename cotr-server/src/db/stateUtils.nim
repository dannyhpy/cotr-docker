import
  std/json,
  std/options,
  std/sequtils,
  std/strutils,
  std/tables

import
  ./dbUtils

proc initEmptyStateDiff*(): JsonNode =
  result = %*{
    "inventoryDiff": { "items": [] },
    "progressDiff": {
      "xp": 0,
      "level": 0,
      "crashPointsEarned": 0,
      "powerGems": [],
      "coloredGems": [],
      "relicProgress": [],
      "islandUnlockInfos": [],
      "buildingUnlockInfos": [],
      "itemUnlockInfos": [],
      "characterProgress": [],
      "statueProgress": [],
      "gangProgress": [],
      "buildingProgress": [],
      "producerProgress": [],
      "tutorialProgress": [],
      "liveOpProgress": {
        "liveOpDragonsOrderProgress": []
      },
      "packProgerss": [],
      "seasonProgress": [
        {
          "progressBySeason": [],
          "purchasedSeasonPassProducts": []
        }
      ],
      "questProgress": [],
      "currentGangProgress": {
        "defeatedBossIds": []
      }
    },
    "gameStateDiff": {
      "producerStates": [],
      "cooldowns": [],
      "reseedTimers": [],
      "unclaimedSeasonPassScore": []
    }
  }

template handleInventoryDiff(): untyped =
  let items = state["inventoryDiff"]["items"]
  # TODO

template handleProgressDiff(): untyped =
  let progressDiff = state["progressDiff"]
  
  if progressDiff.hasKey "xp":
    if progressDiff["xp"].kind == JInt:
      db.exec(
        sql"UPDATE players SET xp = xp + ? WHERE id = ?",
        getInt state["progressDiff"]["xp"],
        playerId
      )

  if progressDiff.hasKey "level":
    if progressDiff["level"].kind == JInt:
      db.exec(
        sql"UPDATE players SET level = level + ? WHERE id = ?",
        getInt state["progressDiff"]["level"],
        playerId
      )

  if progressDiff.hasKey "tutorialProgress":
    if progressDiff["tutorialProgress"].kind == JObject:
      let tutorialRows = db.getAllRows(
        sql"SELECT id FROM tutorials WHERE playerId = ?",
        playerId
      )
      let currTutorialIds = tutorialRows.mapIt(it[0])
      for it in progressDiff["tutorialProgress"]:
        if not it.hasKey "tutorialId": continue
        if it["tutorialId"].kind != JString: continue
        let tutorialId = it["tutorialId"].getStr()
        if tutorialId in currTutorialIds: continue
        db.exec(
          sql"INSERT INTO tutorials (id, playerId) VALUES (?, ?)",
          tutorialId,
          playerId
        )

  if progressDiff.hasKey "buildingUnlockInfos":
    if progressDiff["buildingUnlockInfos"].kind == JObject:
      let buildingRows = db.getAllRows(
        sql"SELECT id, unlockedLevel, level FROM buildings WHERE playerId = ?",
        playerId
      )
      var buildings: Table[Natural, tuple[
        unlockedLevel: Natural,
        level: Natural
      ]]
      for row in buildingRows:
        let buildingId = Natural parseInt row[0]
        buildings[buildingId] = (
          unlockedLevel: Natural parseInt row[1],
          level: Natural parseInt row[2]
        )
      for it in progressDiff["buildingUnlockInfos"]:
        if not it.hasKey "buildingId": continue
        if not it.hasKey "unlockedLevel": continue
        if it["buildingId"].kind != JInt: continue
        if it["unlockedLevel"].kind != JInt: continue
        let itId = getInt it["buildingId"]
        let itUnlockedLevel = getInt it["unlockedLevel"]
        if buildings.hasKey itId:
          let currBuilding = buildings[itId]
          if currBuilding.unlockedLevel != itUnlockedLevel:
            db.exec(
              sql"UPDATE buildings SET unlockedLevel = ? WHERE id = ? AND playerId = ?",
              itUnlockedLevel,
              itId,
              playerId
            )
        else:
          if itUnlockedLevel != 0:
            db.exec(
              sql"INSERT INTO buildings (id, unlockedLevel, playerId) VALUES (?, ?, ?)",
              itId,
              itUnlockedLevel,
              playerId
            )
  # TODO

proc applyStateDiff*(
  db: DbConn,
  playerId: Natural,
  state: JsonNode
): bool =
  result = true

  db.exec(sql"BEGIN")
  try:
    let player = db.selectRow(
      @["id"],
      "players",
      { "id": $playerId }
    )
    if "id" notin player:
      db.exec(sql"INSERT INTO players (id) VALUES (?)", playerId)

    if state.hasKey "inventoryDiff":
      if state["inventoryDiff"].kind == JObject:
        if state["inventoryDiff"].hasKey "items":
          if state["inventoryDiff"]["items"].kind == JArray:
            handleInventoryDiff

    if state.hasKey "progressDiff":
      if state["progressDiff"].kind == JObject:
        handleProgressDiff

    # TODO
  except Exception as err:
    db.exec(sql"ROLLBACK")
    raise err

  db.exec(sql"COMMIT")

proc applyCompleteState*(
  db: DbConn,
  playerId: Natural,
  state: JsonNode
) =
  db.exec(sql"BEGIN")
  try:
    let player = db.selectRow(
      @["id"],
      "players",
      { "id": $playerId }
    )
    if "id" notin player:
      db.exec(sql"INSERT INTO players (id) VALUES (?)", playerId)

    let itemRows = db.getAllRows(sql"SELECT id, count FROM inventoryItems WHERE playerId = ?", playerId)
    var currItems = initTable[Natural, int]()
    for itemRow in itemRows:
      currItems[parseInt itemRow[0]] = parseInt itemRow[1]
      
    for it in state["inventoryDiff"]["items"]:
      let itemId = getInt it["itemTypeId"]
      let count = getInt it["count"]
      if itemId in currItems:
        let currCount = currItems[itemId]
        if count != currCount:
          db.exec(sql"UPDATE inventoryItems SET count = ? WHERE id = ? AND playerId = ?", count, itemId, playerId)
      else:
        db.exec(sql"INSERT INTO inventoryItems (id, playerId, count) VALUES (?, ?, ?)", itemId, playerId, count)

    if state["progressDiff"]["xp"].kind == JInt:
      db.exec(sql"UPDATE players SET xp = ? WHERE id = ?", getInt state["progressDiff"]["xp"], playerId)
    if state["progressDiff"]["level"].kind == JInt:
      db.exec(sql"UPDATE players SET level = ? WHERE id = ?", getInt state["progressDiff"]["level"], playerId)
    if state["progressDiff"]["crashPointsEarned"].kind == JInt:
      db.exec(sql"UPDATE players SET crashPoints = ? WHERE id = ?", getInt state["progressDiff"]["crashPointsEarned"], playerId)

    let islandRows = db.getAllRows(sql"SELECT id, powerGems FROM islands WHERE playerId = ?", playerId)
    var islands = initTable[Natural, Natural]()
    for row in islandRows:
      islands[parseInt row[0]] = parseInt row[1]

    for it in state["progressDiff"]["powerGems"]:
      let islandId = getInt it["islandId"]
      let powerGems = getInt it["numPowerGems"]
      if islandId in islands:
        if islands[islandId] != powerGems:
          db.exec(sql"UPDATE islands SET powerGems = ? WHERE id = ? AND playerId = ?", powerGems, islandId, playerId)
      else:
        db.exec(sql"INSERT INTO islands (id, playerId, powerGems) VALUES (?, ?, ?)", islandId, playerId, powerGems)

    let tutorialRows = db.getAllRows(sql"SELECT id FROM tutorials WHERE playerId = ?", playerId)
    let tutorials = tutorialRows.mapIt it[0]

    for it in state["progressDiff"]["tutorialProgress"]:
      let tutorialId = getStr it["tutorialId"]
      if tutorialId in tutorials: continue
      db.exec(sql"INSERT INTO tutorials (id, playerId) VALUES (?, ?)", tutorialId, playerId)

    let buildingRows = db.getAllRows(
      sql"SELECT id, unlockedLevel, level FROM buildings WHERE playerId = ?",
      playerId
    )
    var buildings: Table[Natural, tuple[
      unlockedLevel: Natural,
      level: Natural
    ]]
    for row in buildingRows:
      let buildingId = Natural parseInt row[0]
      buildings[buildingId] = (
        unlockedLevel: Natural parseInt row[1],
        level: Natural parseInt row[2]
      )

    for it in state["progressDiff"]["buildingUnlockInfos"]:
      let itId = getInt it["buildingId"]
      let itUnlockedLevel = getInt it["unlockedLevel"]
      if itUnlockedLevel == 0: continue
      if buildings.hasKey itId:
        let currBuilding = buildings[itId]
        if currBuilding.unlockedLevel != itUnlockedLevel:
          db.exec(
            sql"UPDATE buildings SET unlockedLevel = ? WHERE id = ? AND playerId = ?",
            itUnlockedLevel,
            itId,
            playerId
          )
      else:
        db.exec(
          sql"INSERT INTO buildings (id, playerId, unlockedLevel) VALUES (?, ?, ?)",
          itId,
          playerId,
          itUnlockedLevel
        )

    for it in state["progressDiff"]["buildingProgress"]:
      let itId = getInt it["buildingId"]
      let itLevel = getInt it["level"]
      if itLevel == 0: continue
      if buildings.hasKey itId:
        let currBuilding = buildings[itId]
        if currBuilding.level != itLevel:
          db.exec(
            sql"UPDATE buildings SET level = ? WHERE id = ? AND playerId = ?",
            itLevel,
            itId,
            playerId
          )
      else:
        db.exec(
          sql"INSERT INTO buildings (id, playerId, level) VALUES (?, ?, ?)",
          itId,
          playerId,
          itLevel
        )

    let packRows = db.getAllRows(
      sql"SELECT id FROM packs WHERE playerId = ?",
      playerId
    )
    var packs = packRows.mapIt it[0]

    for it in state["progressDiff"]["packProgress"]:
      let itId = getStr it["packId"]
      if itId notin packs:
        db.exec(
          sql"INSERT INTO packs (id, playerId) VALUES (?, ?)",
          itId,
          playerId
        )

    let itemUnlockRows = db.getAllRows(
      sql"SELECT id FROM itemUnlocks WHERE playerId = ?",
      playerId
    )
    var itemUnlocks = itemUnlockRows.mapIt parseInt it[0]

    for it in state["progressDiff"]["itemUnlockInfos"]:
      let itId = getInt it["itemId"]
      if itId notin itemUnlocks:
        db.exec(
          sql"INSERT INTO itemUnlocks (id, playerId) VALUES (?, ?)",
          itId,
          playerId
        )

    let skinRows = db.getAllRows(
      sql"SELECT id, characterId FROM skins WHERE playerId = ?",
      playerId
    )
    var characterSkins: Table[Natural, seq[Natural]]
    for row in skinRows:
      let characterId = Natural parseInt row[1]
      if characterSkins.hasKey characterId:
        characterSkins[characterId].add Natural parseInt row[0]
      else:
        characterSkins[characterId] = @[Natural parseInt row[0]]

    for it in state["progressDiff"]["characterProgress"]:
      let itId = getInt it["characterId"]
      if itId notin characterSkins:
        for skinId in it["skinIds"].mapIt(getInt it):
          db.exec(
            sql"INSERT INTO skins (id, characterId, playerId, obtainedAt) VALUES (?, ?, ?, NULL)",
            skinId,
            itId,
            playerId
          )
      else:
        let currCharSkins = characterSkins[itId]
        for skinId in it["skinIds"].mapIt(getInt it):
          if skinId notin currCharSkins:
            db.exec(
              sql"INSERT INTO skins (id, characterId, playerId, obtainedAt) VALUES (?, ?, ?, NULL)",
              skinId,
              itId,
              playerId
            )

    let gangMemberRows = db.getAllRows(
      sql"SELECT runDefinitionId, gangId, defeated FROM gangMembers WHERE playerId = ?",
      playerId
    )
    var gangs: Table[string, Table[string, bool]]
    for row in gangMemberRows:
      let runDefinitionId = row[0]
      let gangId = row[1]
      if gangs.hasKey gangId:
        gangs[gangId][runDefinitionId] = row[2][0] == 't'

    for it in state["progressDiff"]["gangProgress"]:
      let gangId = getStr it["gangId"]
      for gangMemberIt in it["gangMembers"]:
        let runDefinitionId = getStr gangMemberIt["runDefinitionId"]
        let defeated = getBool gangMemberIt["defeated"]
        if gangs.hasKey gangId:
          if gangs[gangId].hasKey runDefinitionId:
            if gangs[gangId][runDefinitionId] != defeated:
              db.exec(
                sql"UPDATE gangMembers SET defeated = ? WHERE runDefinitionId = ? AND playerId = ? AND gangId = ?",
                defeated,
                runDefinitionId,
                playerId,
                gangId
              )
            continue
        db.exec(
          sql"INSERT INTO gangMembers (runDefinitionId, playerId, gangId, defeated, defeatedAt) VALUES (?, ?, ?, ?, NULL)",
          runDefinitionId,
          playerId,
          gangId,
          defeated
        )
    
  except Exception as err:
    db.exec(sql"ROLLBACK")
    raise err

  db.exec(sql"COMMIT")

proc queryCompleteState*(
  db: DbConn,
  playerId: Natural
): JsonNode =
  result = initEmptyStateDiff()
  result["stateUpdateOutcome"] = %* "SERVER_COMPLETE_STATE"

  let player = db.selectRow(
    @["id", "xp", "level", "crashPoints"],
    "players",
    { "id": $playerId }
  )
  if "id" notin player: return

  result["progressDiff"]["xp"] = %* player["xp", int]
  result["progressDiff"]["level"] = %* player["level", int]
  result["progressDiff"]["crashPointsEarned"] = %* player["crashPoints", int]

  let itemRows = db.getAllRows(
    sql"SELECT id, count FROM inventoryItems WHERE playerId = ?",
    playerId
  )
  for itemRow in itemRows:
    result["inventoryDiff"]["items"].add %*{
      "itemTypeId": parseInt itemRow[0],
      "count": parseInt itemRow[1]
    }

  let islandRows = db.getAllRows(
    sql"SELECT id, powerGems FROM islands WHERE playerId = ?",
    playerId
  )
  for islandRow in islandRows:
    result["progressDiff"]["powerGems"].add %*{
      "islandId": parseInt islandRow[0],
      "numPowerGems": parseInt islandRow[1]
    }

  let tutorialRows = db.getAllRows(
    sql"SELECT id FROM tutorials WHERE playerId = ?",
    playerId
  )
  for tutorialRow in tutorialRows:
    result["progressDiff"]["tutorialProgress"].add %*{
      "tutorialId": tutorialRow[0]
    }

  let buildingRows = db.getAllRows(
    sql"SELECT id, unlockedLevel, level FROM buildings WHERE playerId = ?",
    playerId
  )
  for buildingRow in buildingRows:
    result["progressDiff"]["buildingUnlockInfos"].add %*{
      "buildingId": parseInt buildingRow[0],
      "unlockedLevel": parseInt buildingRow[1]
    }
    result["progressDiff"]["buildingProgress"].add %*{
      "buildingId": parseInt buildingRow[0],
      "level": parseInt buildingRow[2]
    }

  let packRows = db.getAllRows(
    sql"SELECT id FROM packs WHERE playerId = ?",
    playerId
  )
  for packRow in packRows:
    result["progressDiff"]["packProgress"].add %*{
      "packId": packRow[0]
    }

  let itemUnlockRows = db.getAllRows(
    sql"SELECT id FROM itemUnlocks WHERE playerId = ?",
    playerId
  )
  for itemUnlockRow in itemUnlockRows:
    result["progressDiff"]["itemUnlockInfos"].add %*{
      "itemId": itemUnlockRow[0]
    }

  let skinRows = db.getAllRows(
    sql"SELECT id, characterId FROM skins WHERE playerId = ?",
    playerId
  )
  var characterSkins: Table[Natural, seq[Natural]]
  for row in skinRows:
    let characterId = Natural parseInt row[1]
    if characterSkins.hasKey characterId:
      characterSkins[characterId].add Natural parseInt row[0]
    else:
      characterSkins[characterId] = @[Natural parseInt row[0]]
  for characterId in characterSkins.keys():
    let skinIds = characterSkins[characterId]
    result["progressDiff"]["characterProgress"].add %*{
      "characterId": characterId,
      "skinIds": skinIds
    }

  let gangMemberRows = db.getAllRows(
    sql"SELECT runDefinitionId, gangId, defeated FROM gangMembers WHERE playerId = ?",
    playerId
  )
  var gangs: Table[string, Table[string, bool]]
  for row in gangMemberRows:
    let runDefinitionId = row[0]
    let gangId = row[1]
    if gangs.hasKey gangId:
      gangs[gangId][runDefinitionId] = row[2][0] == 't'
  for gangId, gangMembers in gangs:
    let gangJson = %* { "gangId": gangId, "gangMembers": [] }
    for runDefinitionId, defeated in gangMembers:
      gangJson["gangMembers"].add %*{
        "runDefinitionId": runDefinitionId,
        "defeated": defeated
      }
    result["progressDiff"]["gangProgress"].add gangJson

when defined(validateState):
  proc isCompleteStateOkay*(
    db: DbConn,
    playerId: Natural,
    state: JsonNode
  ): bool =
    let player = db.selectRow(
      @["id"],
      "players",
      { "id": $playerId }
    )
    if "id" notin player:
      return

    let completeState = db.queryCompleteState(
      playerId=playerId
    )

    if not state.hasKey "inventoryDiff": return
    if state["inventoryDiff"].kind != JObject: return
    if not state["inventoryDiff"].hasKey "items": return
    if state["inventoryDiff"]["items"].kind != JArray: return
    # TODO

    if not state.hasKey "progressDiff": return
    if state["progressDiff"].kind != JObject: return
    if not state["progressDiff"].hasKey "xp": return
    if state["progressDiff"]["xp"].kind != JInt: return
    let userXp = state["progressDiff"]["xp"].getInt()
    let serverXp = completeState["progressDiff"]["xp"].getInt()
    if userXp != serverXp: return
    if not state["progressDiff"].hasKey "level": return
    if state["progressDiff"]["level"].kind != JInt: return
    let userLevel = state["progressDiff"]["level"].getInt()
    let serverLevel = completeState["progressDiff"]["level"].getInt()
    if userLevel != serverLevel: return
    # TODO

    if not state.hasKey "gameStateDiff": return
    if state["gameStateDiff"].kind != JObject: return
    # TODO

    result = true
