import
  std/strutils,
  std/tables

import
  ./util/rpcCommon

type
  AbCases = Table[string, tuple[
    version: int,
    caseNum: int
  ]]

proc queryAbCases(
  db: DbConn;
  userId: Natural
): AbCases =
  let rows = db.getAllRows(sql"SELECT name, version, caseNum FROM abCases WHERE userId = ?", userId)
  for row in rows:
    result[row[0]] = (
      version: parseInt row[1],
      caseNum: parseInt row[2]
    )

proc getDefaultAbCase(name: string): JsonNode =
  result = %*{
      "version": 0,
      "caseNum": block:
        case name
        of "milo_battle_run_speed_up": 0
        of "milo_collection_run_speed_up_2": 0
        of "milo_egp_ingredient_checkpoint_loss": 5
        of "milo_forage_run_goal": 1
        of "milo_instant_respawn": 1
        of "milo_low_60fps": 1
        of "milo_offers_rework": 0
        of "milo_revamp_phase_3": 1
        else: 0
    }

rpcMethod getAppUserAbCases:
  result[0] = %* { "cases": [] }
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)
  if params.len() != 1:
    return (nil, getRpcError -32602)
  if params[0].kind != JArray:
    return (nil, getRpcError -32602)
  if params[0].len() == 0:
    return

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

  let userId = sessKey["userId", int]
  let abCases = db.queryAbCases(userId)
  for nameJson in params[0]:
    if nameJson.kind != JString:
      return (nil, getRpcError -32602)
    if abCases.hasKey getStr nameJson:
      let abCase = abCases[getStr nameJson]
      result[0]["cases"].add %*{
        "version": abCase.version,
        "caseNum": abCase.caseNum
      }
    else:
      result[0]["cases"].add getDefaultAbCase getStr nameJson
