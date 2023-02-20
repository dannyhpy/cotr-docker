import
  std/random,
  std/times

import
  ../db/stateUtils,
  ./util/rpcCommon,
  ./util/rpcStateDiffFlow

rpcMethod deliverOpenTransactions:
  let sessKeyOpt = req.getSessKeyOpt()
  if sessKeyOpt.isNone():
    return (nil, getRpcError 3)

  let sessKey = db.selectRow(
    @["val", "userId"],
    "sessionKeys",
    { "val": sessKeyOpt.get() }
  )
  if "val" notin sessKey:
    return (nil, getRpcError 2)

  result[0] = initEmptyStateDiff()
  result[0]["stateUpdateOutcome"] = %* "CLIENT_REQUEST_ACCEPTED"

rpcMethod loadProducts:
  if params.isNil():
    return (nil, getRpcError -32602)
  if params.kind != JArray:
    return (nil, getRpcError -32602)
  if params.len() != 1:
    return (nil, getRpcError -32602)
  if params[0].kind != JObject:
    return (nil, getRpcError -32602)

  var placementIds: seq[string]
  if params[0].hasKey "placementIds":
    if params[0].len() != 1:
      return (nil, getRpcError -32602)
    if params[0]["placementIds"].kind != JArray:
      return (nil, getRpcError -32602)
    for it in params[0]["placementIds"]:
      if it.kind != JString:
        return (nil, getRpcError -32602)
      placementIds.add it.getStr()
  else:
    if params[0].len() != 0:
      return (nil, getRpcError -32602)

  result[0] = %* { "placements": [] }

  let sessKeyOpt = req.getSessKeyOpt()
  if sessKeyOpt.isNone():
    return (nil, getRpcError 3)

  let sessKey = db.selectRow(
    @["val", "userId"],
    "sessionKeys",
    { "val": sessKeyOpt.get() }
  )
  if "val" notin sessKey:
    return (nil, getRpcError 2)

  let player = db.selectRow(
    @["id"],
    "players",
    { "id": sessKey["userId"] }
  )

  let now = epochTime().toInt()
  let today = epochTime().toInt() - epochTime().toInt() mod 86400
  let timeLeft = 86400 - now mod 86400
  var r = initRand(today)

  for placementId in placementIds:
    let placement = %*{
      "placementId": placementId,
      "metadata": [],
      "products": []
    }
    result[0]["placements"].add placement
    case placementId
    of "bank", "shop_section_purpleCrystals":
      placement["products"].add %*{
        "blueprintId": "purple-crystals-the-pile",
        "placementId": placementId,
        "version": "0",
        "priceType": "EXTERNAL",
        "externalSku": "com.king.crash.purple_crystals_the_pile",
        "content": [
          { "itemTypeId": 81000, "count": 45, "payload": "" }
        ],
        "display": [
          { "key": "name", "value": "Shop.OfferName.Pile" },
          { "key": "icon", "value": "ui/bank/pile" },
        ],
        "metadata": [
          { "key": "purchasesLeft", "value": "0" }
        ]
      }
      placement["products"].add %*{
        "blueprintId": "purple-crystals-the-pouch",
        "placementId": placementId,
        "version": "0",
        "priceType": "EXTERNAL",
        "externalSku": "com.king.crash.purple_crystals_the_pouch",
        "content": [
          { "itemTypeId": 81000, "count": 120, "payload": "" }
        ],
        "display": [
          { "key": "name", "value": "Shop.OfferName.Pouch" },
          { "key": "icon", "value": "ui/bank/pouch" },
        ],
        "metadata": [
          { "key": "purchasesLeft", "value": "0" }
        ]
      }
      placement["products"].add %*{
        "blueprintId": "purple-crystals-the-crate",
        "placementId": placementId,
        "version": "0",
        "priceType": "EXTERNAL",
        "externalSku": "com.king.crash.purple_crystals_the_crate",
        "content": [
          { "itemTypeId": 81000, "count": 250, "payload": "" }
        ],
        "display": [
          { "key": "name", "value": "Shop.OfferName.Crate" },
          { "key": "icon", "value": "ui/bank/crate" }
        ],
        "metadata": [
          { "key": "purchasesLeft", "value": "0" }
        ]
      }
      placement["products"].add %*{
        "blueprintId": "purple-crystals-the-barrel",
        "placementId": placementId,
        "version": "0",
        "priceType": "EXTERNAL",
        "externalSku": "com.king.crash.purple_crystals_the_barrel",
        "content": [
          { "itemTypeId": 81000, "count": 530, "payload": "" }
        ],
        "display": [
          { "key": "name", "value": "Shop.OfferName.Barrel" },
          { "key": "icon", "value": "ui/bank/barrel" },
        ],
        "metadata": [
          { "key": "purchasesLeft", "value": "0" }
        ]
      }
      placement["products"].add %*{
        "blueprintId": "purple-crystals-the-minecart",
        "placementId": placementId,
        "version": "0",
        "priceType": "EXTERNAL",
        "externalSku": "com.king.crash.purple_crystals_the_minecart",
        "content": [
          { "itemTypeId": 81000, "count": 1150, "payload": "" }
        ],
        "display": [
          { "key": "name", "value": "Shop.OfferName.MineCart" },
          { "key": "icon", "value": "ui/bank/minecart" },
        ],
        "metadata": [
          { "key": "purchasesLeft", "value": "0" }
        ]
      }
      placement["products"].add %*{
        "blueprintId": "purple-crystals-the-vault",
        "placementId": placementId,
        "version": "0",
        "priceType": "EXTERNAL",
        "externalSku": "com.king.crash.purple_crystals_the_vault",
        "content": [
          { "itemTypeId": 81000, "count": 3250, "payload": "" }
        ],
        "display": [
          { "key": "name", "value": "Shop.OfferName.Vault" },
          { "key": "icon", "value": "ui/bank/vault" }
        ],
        "metadata": [
          { "key": "purchasesLeft", "value": "0" }
        ]
      }
    of "free_daily_team_run_ticket":
      placement["products"].add %*{
        "blueprintId": "daily_free_ticket",
        "placementId": placementId,
        "version": "0",
        "priceType": "NONE",
        "content": [
          { "itemTypeId": 81381, "count": 1, "payload": "" }
        ],
        "display": [],
        "metadata": [
          { "key": "softCap", "value": "10" },
          { "key": "transactionContext", "value": "claimTicket" },
          { "key": "gameFeature", "value": "MILO_SEASON_TEAM_RUN_TICKET" },
          { "key": "timeLeft", "value": $timeLeft },
          { "key": "purchasesLeft", "value": "0" },
          { "key": "maxPurchases", "value": "1" }
        ]
      }
    of "shop_section_free_rotatingOffers":
      placement["products"].add %*{
        "blueprintId": "shop_free_rotating_offer",
        "placementId": placementId,
        "version": "0",
        "priceType": "NONE",
        "content": [
          { "itemTypeId": 81026, "count": r.rand 250, "payload": "" }
        ],
        "display": [
          { "key": "badge", "value": "Offers.Value.Popular" }
        ],
        "metadata": [
          { "key": "candidateId", "value": "variant_17" },
          { "key": "timeLeft", "value": $timeLeft },
          { "key": "purchasesLeft", "value": "0" },
          { "key": "maxPurchases", "value": "1" }
        ]
      }
    of "shop_section_rotatingOffers":
      placement["products"].add %*{
        "blueprintId": "shop_daily_rotating_skin_MiloCostumeCocoWumpaSkin",
        "placementId": placementId,
        "version": "0",
        "priceType": "INTERNAL",
        "internalPrices": [
          { "itemTypeId": 81000, "count": 60 }
        ],
        "content": [
          { "itemTypeId": 81605, "count": 1, "payload": "" }
        ],
        "display": [],
        "metadata": [
          { "key": "purchasesLeft", "value": "0" },
          { "key": "maxPurchases", "value": "1" }
        ]
      }
    of "shop_section_teamRunTickets":
      placement["products"].add %*{
        "blueprintId": "shop_teamRunTicket_1",
        "placementId": placementId,
        "version": "0",
        "priceType": "INTERNAL",
        "internalPrices": [
          { "itemTypeId": 81000, "count": 10 }
        ],
        "content": [
          { "itemTypeId": 81381, "count": 1, "payload": "" }
        ],
        "display": [
          { "key": "name", "value": "Shop.OfferName.TeamRunTicketsSmall" },
          { "key": "badge", "value": "New" }
        ],
        "metadata": []
      }
      placement["products"].add %*{
        "blueprintId": "shop_teamRunTicket_2",
        "placementId": placementId,
        "version": "0",
        "priceType": "INTERNAL",
        "internalPrices": [
          { "itemTypeId": 81000, "count": 25 }
        ],
        "content": [
          { "itemTypeId": 81381, "count": 3, "payload": "" }
        ],
        "display": [
          { "key": "name", "value": "Shop.OfferName.TeamRunTicketsMedium" },
          { "key": "badge", "value": "New" }
        ],
        "metadata": []
      }
      placement["products"].add %*{
        "blueprintId": "shop_teamRunTicket_3",
        "placementId": placementId,
        "version": "0",
        "priceType": "INTERNAL",
        "internalPrices": [
          { "itemTypeId": 81000, "count": 40 }
        ],
        "content": [
          { "itemTypeId": 81381, "count": 5, "payload": "" }
        ],
        "display": [
          { "key": "name", "value": "Shop.OfferName.TeamRunTicketsLarge" },
          { "key": "badge", "value": "New" }
        ],
        "metadata": []
      }

rpcMethod purchaseProduct:
  return await rpcHandleUsualStateDiffFlow(
    req,
    db,
    params
  )
