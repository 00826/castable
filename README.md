## castable

a concise, straightforward, open-ended system for skill casting. designed for no-network-roundtrips

all castable packets *must* satisfy `{ } & { flag: buffer }`

castables are retrieved with `/Client.get()` or `/Server.get()`, or can be directly referenced from the `.Module` table present in both

every castable must exist in both `/Server` and `/Client` as same-name equivalents. should a castable not have its equivalent on require, the server will emit a warning and the castable will not be accessible during runtime. this should be treated as a fatal warning as castables are indexed alphabetically to fit nicely into a castable flag

## flags

|field (width)|range|value|
|-|-|-|
|`[31, 22] (10)`|index|`[0, 1023]`|
|`[21, 12] (10)`|roll|`[0, 1023]`|
|`[11, 4] (8)`  |latency (ms)|`[0, 255]`|
|`[3, 0] (4)`   |step|`[0, 15]`|

## generic castable with no network roundtrip

`client.input() -> ( client ... ) -> types.send( to server ) ->` \
`|CLIENT -> SERVER|` \
`server.input( player, packet ) -> ( server ... ) -> types.send( to players ) ->` \
`|SERVER -> CLIENT|` \
`client.recv( packet ... ) -> client.render( ...? )`