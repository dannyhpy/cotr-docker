import
  ./util/rpcCommon

const settings: array[0, (string, string)] = []

rpcMethod getSettings:
  result[0] = %* []
  for setting in settings:
    result[0].add %*{
      "name": setting[0],
      "value": setting[1]
    }
