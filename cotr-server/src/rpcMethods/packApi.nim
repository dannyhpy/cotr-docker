import
  ./util/rpcCommon,
  ./util/rpcStateDiffFlow

rpcMethod claimPack:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )
