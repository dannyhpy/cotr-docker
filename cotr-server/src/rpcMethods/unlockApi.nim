import
  ./util/rpcCommon,
  ./util/rpcStateDiffFlow

rpcMethod unlockBuildings:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )

rpcMethod unlockIsland:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )

rpcMethod unlockItems:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )

rpcMethod unlockLand:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )
