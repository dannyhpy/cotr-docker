import
  std/base64,
  std/httpclient,
  std/json

import
  ./config

proc setupCommands*() =
  let basicAuth = base64.encode(config.clientId & ":" & config.clientSecret)
  let client = newHttpClient()

  # Client Credentials Grant
  client.headers = {
    "Authorization": "Basic " & basicAuth,
    "Content-Type": "application/json"
  }.newHttpHeaders()
  let jsonBody = parseJson client.postContent(
    discordApi & "/oauth2/token",
    $ %*{
      "grant_type": "client_credentials",
      "scope": "identify applications.commands.update"
    }
  )
  let bearerToken = getStr jsonBody["access_token"]

  # Register commands
  client.headers = {
    "Authorization": "Bearer " & bearerToken,
    "Content-Type": "application/json"
  }.newHttpHeaders()
  let response = client.put(
    discordApi & "/applications/" & config.clientId & "/commands",
    $ %*[] # TODO
  )
  assert response.status == "200 OK"
