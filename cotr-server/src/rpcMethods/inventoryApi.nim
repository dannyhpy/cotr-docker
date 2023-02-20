import
  ./util/rpcCommon,
  ./util/rpcStateDiffFlow

rpcMethod convertCrashPoints:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )
