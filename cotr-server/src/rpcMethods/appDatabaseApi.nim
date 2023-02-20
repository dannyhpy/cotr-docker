import
  ./util/rpcCommon

rpcMethod getAppDatabase:
  result[0] = %* nil
  if params.isNil(): return
  if params.kind != JArray: return
  if params.len() != 1: return
  if params[0].kind != JInt: return
  result[0] = %* {
    "appDbDto": {
      "items": []
    }
  }
