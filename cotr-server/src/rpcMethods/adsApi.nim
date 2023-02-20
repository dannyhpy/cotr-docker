import
  ./util/rpcCommon,
  ./util/rpcStateDiffFlow

rpcMethod egpPurchase:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )
