import
  ./util/rpcCommon,
  ./util/rpcStateDiffFlow

rpcMethod endCollectionRun:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )

rpcMethod endRun:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )

rpcMethod playerDeath:
  # TODO
  result[0] = %*{
    "stateUpdateOutcome": "CLIENT_REQUEST_ACCEPTED"
  }
