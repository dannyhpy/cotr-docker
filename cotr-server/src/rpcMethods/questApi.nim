import
  ./util/rpcCommon,
  ./util/rpcStateDiffFlow

rpcMethod claimQuestReward:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )

rpcMethod reportQuestProgress:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )

rpcMethod startQuest:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )
