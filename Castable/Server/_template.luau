--!nonstrict
--!nolint LocalUnused
--!nolint ImportUnused

local Server = game:GetService("ServerScriptService"):WaitForChild("Server")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")

local Castable = require(Shared:WaitForChild("Castable"))
local types = require(Shared:WaitForChild("Castable")._types)

local ClientCast: typeof(require(Shared.Castable._template)) = Castable.Modules[script.Name]

--- ### _template (server)
local _template = { id = script.Name; } :: types.ServerCastable

assert(ClientCast, `servercast "{_template.id}" missing client counterpart`)
assert(ClientCast.id == _template.id, `castable id mismatch: "{ClientCast.id}" (client), "{_template.id}" (server)`)

function _template.input(caster: Player?, input: types.Packet)
	local castid = _template.id
	local unpacked = types.unpackflag(input.flag)
	local step, roll = unpacked.step, unpacked.roll
	--- local R = Random.new(roll)
	local expectstepstring = types.expectstepstring(castid, step)

	if step == 0 then
		types.send({flag = types.packflag({castable = castid; roll = roll; latency = 0;});})
	end

	return
end

return _template