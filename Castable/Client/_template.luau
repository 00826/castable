--!nonstrict
--!nolint LocalUnused
--!nolint ImportUnused

local RunService = game:GetService("RunService")
local IsServer = RunService:IsServer()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")

local types = require(script.Parent._types)

local Config = {
	icdname = script.Name .. "_icd";
	icdtime = 1;
}

--- ### _template (client)
local _template = { id = script.Name; Config = Config; } :: types.Castable & { Config: typeof(Config) }

type _input = {  }

function _template.input(castinput: types.Input & _input)
	local flag, int = types.packflag({castable = _template.id})
	local roll = bit32.extract(int, 12, 10)
	--- local R = Random.new(roll)

	_template.render(types.unpackflag(flag))

	types.send({flag = flag;})
end

type _recv = { vector: Vector3 }

function _template.recv(recvpacket: types.Packet & _recv)
	local flag = recvpacket.flag
	if not flag then warn(`{_template.id}.recv no recvpacket!`); return end
	local unpacked = types.unpackflag(flag)
	
	_template.render(unpacked)
end

function _template.render(unpackedflag: types.UnpackedFlag)
	local step, roll = unpackedflag.step, unpackedflag.roll
	--- local R = Random.new(roll)

	if step == 0 then
		
	end

	return
end

return _template