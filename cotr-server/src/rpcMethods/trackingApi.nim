import
  std/strutils

import
  ./util/rpcCommon

rpcMethod appTrack2:
  result[0] = %* nil

rpcMethod getUniqueACId:
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)
  if params.len() != 1:
    return (nil, getRpcError -32602)
  if params[0].kind != JString:
    return (nil, getRpcError -32602)

  for c in getStr params[0]:
    if not c.isDigit():
      return (%* "0", nil)
  result[0] = params[0]
