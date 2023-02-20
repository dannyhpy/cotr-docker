import
  std/macros,
  std/strutils,
  std/tables

macro defineRpcMethodTable(
  tableIdent,
  methodList: untyped
) =
  result = nnkStmtList.newTree()

  var modules = newSeq[string]()
  for dotExpr in methodList:
    let modIdent = dotExpr[0]
    if $modIdent notin modules:
      modules.add($modIdent)
      result.add quote do:
        from ./rpcMethods/`modIdent` import nil

  let tableContents = nnkTableConstr.newTree()
  for dotExpr in methodList:
    let rpcMethod = capitalizeAscii($dotExpr[0] & "." & $dotExpr[1])
    tableContents.add nnkExprColonExpr.newTree(
      newLit(rpcMethod),
      dotExpr
    )

  result.add quote do:
    const `tableIdent`* = toTable `tableContents`

defineRpcMethodTable rpcMethodTable:
  adsApi.egpPurchase
  appAbTestApi.getAppUserAbCases
  appApi.notifyAppStart
  appCommonCatalogApi.getCatalog
  appCoreIdentityApi.authenticate
  appCoreIdentityApi.getAuthenticationInfo
  appCoreIdentityApi.logIn
  appCoreIdentityApi.signUp
  appEmailAndPasswordIdentityApi.authenticate
  appDatabaseApi.getAppDatabase
  appKingAccountApi.acceptTermsOfServiceAndPrivacyPolicy
  appKingAccountApi.getCurrentAccount
  appPermissionsApi.getConsents3
  appPermissionsApi.grant2
  appPermissionsApi.revoke2
  appTimeApi.getServerTime
  appStoreApi.createJournal4
  applicationSettingsApi.getSettings
  configApi.getConfigEntriesCached
  groupChatApi.poll
  inventoryApi.convertCrashPoints
  miloGuildApi.createGuild
  miloGuildApi.getCommonGuildSettings
  miloGuildApi.getGuild
  miloGuildApi.getGuildJoinCooldownLeft
  miloGuildApi.getMyGuild
  miloGuildApi.joinGuild
  miloGuildApi.leaveGuild
  miloGuildApi.suggestGuilds2
  miloSeasonApi.claimSeasonWithoutTeamReward
  miloSeasonApi.getGuildSeasonLeaderboardResult
  miloSeasonApi.spendTeamRunTicket
  otaApi.selectPackageDescriptors
  packApi.claimPack
  productionApi.buyProducer
  productionApi.collectProducer
  productionApi.speedUpProducer
  productionApi.startProducer
  productionApi.startProducerMissingResources
  productionApi.upgradeBuilding
  productionApi.upgradeBuildingMissingResources
  profileApi.getPlayerStats
  profileApi.setPlayerActiveSkin
  progressApi.finishedTutorial
  progressApi.levelUpPlayer
  progressApi.startTutorial
  pushNotificationTokenApi.updatePushNotificationToken2
  questApi.claimQuestReward
  questApi.reportQuestProgress
  questApi.startQuest
  runnerApi.endCollectionRun
  runnerApi.endRun
  runnerApi.playerDeath
  serverAuthLiveOpsApi.getLiveOps
  shopApi.deliverOpenTransactions
  shopApi.loadProducts
  shopApi.purchaseProduct
  stateApi.completeState
  stateApi.syncState
  trackingApi.appTrack2
  trackingApi.getUniqueACId
  unlockApi.unlockBuildings
  unlockApi.unlockIsland
  unlockApi.unlockItems
  unlockApi.unlockLand

static:
  macro genUnsupportedRpcMethodArray(varIdent, methodList) =
    result = nnkStmtList.newTree()
    result.add quote do:
      var `varIdent` = newSeq[string]()
    for dotExpr in methodList:
      var rpcMethod = capitalizeAscii($dotExpr[0] & "." & $dotExpr[1])
      result.add quote do:
        `varIdent`.add `rpcMethod`

  genUnsupportedRpcMethodArray undefined:
    appClientCrashReport.trackCrashReport
    appCoreIdentityApi.solveMergeConflict
    appEmailAndPasswordIdentityApi.link
    appKingAccountApi.updateCurrentAccount
    groupChatApi.postAndPoll
    groupChatApi.reportAbusiveMessage
    miloGuildApi.getLeaderboard
    miloGuildApi.searchGuilds
    profileApi.getAccountMergePlayerProgress

  var n = 0
  for name in undefined:
    if name notin rpcMethodTable:
      echo "rpc: unsupported method: " & name
      n.inc()

  echo "rpc: total unsupported: " & $n
