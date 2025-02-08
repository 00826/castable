--!strict

local RunService = game:GetService("RunService")

local types = require(script:WaitForChild("_types"))

export type types = typeof(types)

--- ### CastableClient.luau
---
--- castable client \
--- `client.input() -> ( ... ) -> types.send(to server) -> server.input() -> ( ... ) -> types.send(to clients) -> client.recv()`
local CastableClient = {
	types = types;

	Modules = {} :: { [string]: types.Castable };
}

for _, CastModule in script:GetChildren() do
	if not CastModule:IsA("ModuleScript") then continue end
	local CastableId = CastModule.Name
	if table.find(types.Blacklist, CastableId) then continue end

	local x, y = pcall(function()
		CastableClient.Modules[CastableId] = require(CastModule) :: any
		table.insert(types.Array, CastableId)
	end)
	if not x then warn(`Castable "{CastableId}" error when requiring: {y}`); end
	
	task.defer(function()
		do
			local s = pcall(assert, CastableClient.Modules[CastableId].input)
			if not s then warn(`Castable "{CastableId}" missing .input()`); end
		end
		do
			local s = pcall(assert, CastableClient.Modules[CastableId].recv)
			if not s then warn(`Castable "{CastableId}" missing .recv()`); end
		end
	end)
end

table.sort(types.Array)

if RunService:IsClient() then
	types.Remote.OnClientEvent:Connect(function(recvpacket: types.Packet)
		local unpacked = types.unpackflag(recvpacket.flag)
		local idx = unpacked.castable
		local id = types.Array[idx]
		assert(id, `{id} from index {idx} does not exist`)

		CastableClient.Modules[id].recv(recvpacket)
	end)
end

--- returns client castable
function CastableClient.get(castable: string|number): types.Castable?
	if type(castable) == "number" then
		return CastableClient.Modules[types.Array[castable]]
	elseif type(castable) == "string" then
		return CastableClient.Modules[castable]
	end

	return
end

return CastableClient