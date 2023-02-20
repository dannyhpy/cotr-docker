import
  ./util/rpcCommon

rpcMethod selectPackageDescriptors:
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)
  if params.len() != 2:
    return (nil, getRpcError -32602)
  if params[0].kind != JObject:
    return (nil, getRpcError -32602)
  if params[1].kind != JArray:
    return (nil, getRpcError -32602)

  result[0] = %*{
    "otaPackageDescriptorDtos": [],
    "baseUrl": "https://milo.king.com/s/ota"
  }
