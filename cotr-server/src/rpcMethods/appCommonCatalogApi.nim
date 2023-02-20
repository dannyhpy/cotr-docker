import
  std/strutils

import
  ./util/rpcCommon

const catalogStr = staticRead"../static/catalog.json"

rpcMethod getCatalog:
  result[0] = %*{
    "blueprints": [],
    "placements": [],
    "metadata": [],
    "globalScript": "",
    "sdkScript": ""
  }
  let sessKeyOpt = req.getSessKeyOpt()
  if sessKeyOpt.isSome():
    result[0]["serverVariables"] = %* []

  let userAgent = req.headers.getOrDefault("User-Agent")
  if not isUserAgentAllowed userAgent:
    return

  result[0] = parseJson catalogStr
