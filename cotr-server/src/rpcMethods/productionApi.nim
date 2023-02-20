import
  ./util/rpcCommon,
  ./util/rpcStateDiffFlow

rpcMethod buyProducer:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )

rpcMethod collectProducer:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )

rpcMethod speedUpProducer:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )

rpcMethod startProducer:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )

rpcMethod startProducerMissingResources:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )

rpcMethod upgradeBuilding:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )

rpcMethod upgradeBuildingMissingResources:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )
