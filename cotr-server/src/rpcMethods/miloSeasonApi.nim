import
  ./util/rpcCommon,
  ./util/rpcStateDiffFlow

rpcMethod claimSeasonWithoutTeamReward:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )

rpcMethod getGuildSeasonLeaderboardResult:
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)
  if params.len() != 1:
    return (nil, getRpcError -32602)
  if params[0].kind != JObject:
    return (nil, getRpcError -32602)
  if not params[0].hasKey "seasonId":
    return (nil, getRpcError -32602)
  if params[0]["seasonId"].kind != JInt:
    return (nil, getRpcError -32602)

  # TODO
  result[0] = %*{
    "responseStatus": "NOT_IN_A_TEAM",
    "seasonTimeLeft": 0
  }

rpcMethod spendTeamRunTicket: 
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )
