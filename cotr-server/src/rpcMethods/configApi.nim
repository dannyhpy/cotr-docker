import
  std/strutils,
  std/tables

import
  ./util/rpcCommon

const files = {
  "costume-bonuses.json": staticRead"../static/config/costume-bonuses.json",
  "gangs.json": staticRead"../static/config/gangs.json",
  "playareas.json": staticRead"../static/config/playareas.json",
  "run-definitions.json": staticRead"../static/config/run-definitions.json"
}.toTable()

rpcMethod getConfigEntriesCached:
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)
  if params.len() != 2:
    return (nil, getRpcError -32602)
  for it in params:
    if it.kind != JString:
      return (nil, getRpcError -32602)

  result[0] = %*{
    "version": getStr params[0],
    "abGroupsHash": getStr params[1],
    "config": {}
  }

  let userAgent = req.headers.getOrDefault("User-Agent")
  if not isUserAgentAllowed userAgent:
    return

  let sessKeyOpt = req.getSessKeyOpt()
  if sessKeyOpt.isSome():
    let sessKey = db.selectRow(
      @["val", "userId"],
      "sessionKeys",
      { "val": sessKeyOpt.get() }
    )
    if "val" in sessKey:
      let abCaseVal = db.getValue(
        sql"""SELECT caseNum
        FROM abCases
        WHERE name = 'milo_revamp_phase_3'
        AND userId = ?""",
        sessKey["userId"]
      )
      if abCaseVal == "0":
        return

  for filename in files.keys():
    result[0]["config"][filename] = %* files[filename]
