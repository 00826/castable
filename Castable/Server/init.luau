--!strict

local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Client = require(Shared:WaitForChild("Castable"))
local types = require(Shared:WaitForChild("Castable")._types)

--- ### CastableServer.luau
---
--- castable server
local CastableServer = {
	Modules = {} :: { [string]: types.ServerCastable };
}

for _, CastModule in script:GetChildren() do
	if not CastModule:IsA("ModuleScript") then continue end
	local CastableId = CastModule.Name
	if table.find(types.Blacklist, CastableId) then continue end

	local x, y = pcall(function()
		CastableServer.Modules[CastableId] = require(CastModule) :: any
	end)
	if not x then warn(`Castable "{CastableId}" error when requiring: {y}`); end
	
	task.defer(function()
		local s = pcall(assert, CastableServer.Modules[CastableId].input)
		if not s then warn(`Castable "{CastableId}" missing .input()`); end
	end)
end

if RunService:IsServer() then
	Client.types.Remote.OnServerEvent:Connect(function(player: Player, sendpacket: types.Packet)
		assert(type(sendpacket) == "table")
		assert(type(sendpacket.flag) == "buffer")

		local unpacked = types.unpackflag(sendpacket.flag)
		local idx = unpacked.castable
		local id = types.Array[idx]
		assert(id, `{id} from index {idx} does not exist`)

		CastableServer.Modules[id].input(player, sendpacket)
	end)
end

--- returns server castable
function CastableServer.get(castable: string): types.ServerCastable
	local c = CastableServer.Modules[castable]
	assert(c, `castable "{castable}" does not exist`)

	return c
end

return CastableServer