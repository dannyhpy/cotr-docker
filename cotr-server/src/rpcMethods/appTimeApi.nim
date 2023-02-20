import
  std/times

import
  ./util/rpcCommon

rpcMethod getServerTime:
  let ms: float = epochTime() * 1_000
  result[0] = %* ms.toInt()
