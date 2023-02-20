import
  std/strutils

import
  ./util/rpcCommon,
  ./util/rpcStateDiffFlow

rpcMethod finishedTutorial:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )

rpcMethod levelUpPlayer:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )

rpcMethod startTutorial:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )
