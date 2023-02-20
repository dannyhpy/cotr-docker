import
  std/json,
  std/options,
  std/strutils

import
  ./dbUtils

proc userDisplayName*(r: SelectedRow): string =
  result = r["name"]
  if result == "":
    return "user" & $(r["id", int] mod 10_000)

proc kingTosAndPpAcceptanceDtoRepr*(): JsonNode =
  result = %*{
    "acceptedVersion": 2,
    "latestVersion": 2,
    "latestToSUrl": "about:blank",
    "latestPPUrl": "about:blank"
  }

proc kingAccDtoRepr*(user: SelectedRow): JsonNode =
  result = %*{
    "coreUserId": user["id", int],
    "toSAndPPAcceptanceDto": kingTosAndPpAcceptanceDtoRepr(),
    "avatarUploadEnabled": false,
    "editable": false,
    "name": userDisplayName user,
    "avatarUrl": nil,
    "bigAvatarUrl": nil,
    "dateOfBirthKnown": false,
    "dateOfBirthRequired": false,
    "ageGateStateId": 1
  }

proc guildDtoRepr*(): JsonNode =
  result = %*{
    "guildId": 0,
    "name": "",
    "description": "",
    "isApplicationRequired": false,
    "numMembers": 0,
    "maxNumMembers": 0,
    "members": [],
    "invites": [],
    "autoJoinLimit": 0,
    "editableProperties": [],
    "computedProperties": [],
    "internalProperties": []
  }
