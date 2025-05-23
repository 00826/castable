--!strict

local RunService = game:GetService("RunService")
local IsServer = RunService:IsServer()

local Players = game:GetService("Players")

--- type describing set of inputs that are passed into castable.input()
export type Input = { [string]: unknown; }

--- type describing castable network packet
export type Packet = { flag: buffer; [string]: unknown; }

--- type describing the minimal set of entries for a castable flag
export type MinimalFlag = {
	--- roll
	roll: number?;
	--- caster latency
	latency: number?;
	--- step
	step: number?;
}

--- type describing an unpacked castable flag (buffer)
export type UnpackedFlag = {
	--- numeric index of this castable
	castable: number;
	--- roll
	roll: number;
	--- caster latency
	latency: number;
	--- step
	step: number;
}

export type Castable = {
	--- string id of this castable
	id: string;
	--- call when an input related to this castable is read
	input: (input: Input) -> ();
	--- internally called when client receives a packet related to this castable
	recv: (recvpacket: Packet) -> ();
	--- call when rendering any visual effect related to this castable
	render: (unpackedflag: UnpackedFlag, ...any) -> ();

	--- unknown/undefined
	[string]: unknown;
}

export type ServerCastable = {
	--- string id of this castable
	id: string;
	--- internally called when server receives a packet related to this castable \
	--- or call when a server-owned caster desires to use this castable
	input: (caster: Player, input: Packet) -> ();

	--- unknown/undefined
	[string]: unknown;
}

type ClientArg = 
	| nil
	| number
	| Player
	| { number | Player }
	| (Player) -> boolean

local types = {
	Remote = script.Parent:WaitForChild("CastRemote");
	R = Random.new();
	rollmaxvalue = 1024 - 1;

	Blacklist = { "_template"; "_types"; };
	Array = table.create(#script.Parent:GetChildren());
}

--- returns number (offset) representation of castable offset or string
function types.tonumber(castable: number|string)
	if type(castable) == "string" then
		local idx = table.find(types.Array, castable)
		assert(idx, `{castable} not indexed in types.Array`)
		return idx
	elseif type(castable) == "number" then
		return castable
	else
		error(type(castable))
	end
end

--- returns string representation of castable offset or string
function types.tostring(castable: number|string)
	if type(castable) == "string" then
		local idx = table.find(types.Array, castable)
		assert(idx, `{castable} not indexed in types.Array`)
		return types.Array[idx]
	elseif type(castable) == "number" then
		return types.Array[castable]
	else
		error(type(castable))
	end
end

--- packs array of castables into a buffer
function types.pack(list: {number|string})
	local p = buffer.create(#list)
	for i, value in ipairs(list) do
		if type(value) == "string" then
			local idx = table.find(types.Array, value)
			if not idx then
				buffer.writeu8(p, i - 1, 0)
			else
				buffer.writeu8(p, i - 1, idx)
			end
		elseif type(value) == "number" then
			if value > 255 then
				buffer.writeu8(p, i - 1, 0)
			elseif value < 1 then
				buffer.writeu8(p, i - 1, 0)
			else
				buffer.writeu8(p, i - 1, value)
			end
		end
	end

	return p
end

--- returns byte offset of castable inside of pack
function types.findinpack(pack: buffer, castable: number|string): number?
	local number = types.tonumber(castable)
	if number == 0 then
		return nil
	else
		for i = 1, buffer.len(pack) do
			if buffer.readu8(pack, i - 1) == number then
				return i
			end
		end
	end

	return nil
end

--- returns packed flag and its associated u32 integer with respect to minimally-populated unpacked flag \
--- latency, if passed, is in seconds and is clamped within range `[0, 0.255]` (255ms)
function types.packflag(min: {castable: number|string} & MinimalFlag)
	local int = bit32.replace(0, types.tonumber(min.castable), 22, 10)
		int = bit32.replace(int, min.roll or types.R:NextInteger(0, types.rollmaxvalue), 12, 10)
		int = bit32.replace(int, min.latency and math.clamp(min.latency * 1000, 0, 255) or 0, 4, 8)
		int = bit32.replace(int, min.step or 0, 0, 4)

	local flag = buffer.create(4)
	buffer.writeu32(flag, 0, int)

	return flag, int
end

--- returns unpacked flag with respect to packed flag \
--- latency is within range `[0, 0.255]` (255ms)
function types.unpackflag(f: buffer): UnpackedFlag
	local int = buffer.readu32(f, 0)
	return {
		castable = bit32.extract(int, 22, 10);
		roll = bit32.extract(int, 12, 10);
		latency = bit32.extract(int, 4, 8) / 1000;
		step = bit32.extract(int, 0, 4);
	}
end

--- merges minimally-populated unpacked flag into packed flag \
--- latency, if passed, is in seconds and is clamped within range `[0, 0.255]` (255ms) \
--- returns flag for convenience
function types.mergeflag(f: buffer, min: MinimalFlag)
	local int = buffer.readu32(f, 0)
	if min.roll then
		int = bit32.replace(int, min.roll, 12, 10)
	end
	if min.latency then
		int = bit32.replace(int, math.clamp(min.latency * 1000, 0, 255), 4, 8)
	end
	if min.step then
		int = bit32.replace(int, min.step, 0, 4)
	end

	buffer.writeu32(f, 0, int)

	return f
end

--- returns string for expected castable step
function types.expectstepstring(castable: string, step: number)
	return "exp" .. castable .. tostring(step)
end

--- `server`: sends packet to clientarg \
--- `client`: sends packet to server
function types.send(packet: Packet, clientarg: ClientArg?)
	if IsServer then
		if type(clientarg) == "nil" then --- fire all
			types.Remote:FireAllClients(packet)
		elseif type(clientarg) == "number" then --- fire by userid
			local player = Players:GetPlayerByUserId(packet)
			if player then
				types.Remote:FireClient(player, packet)
			end
		elseif typeof(clientarg) == "Instance" then --- fire by player
			assert(clientarg:IsA("Player"), debug.traceback(string.format("expected Player, got %s", clientarg.ClassName), 2))
			types.Remote:FireClient(clientarg, packet)
		elseif type(clientarg) == "table" then --- fire by list of userids or players
			for _, a in clientarg do
				if typeof(a) == "number" then
					local player = Players:GetPlayerByUserId(a)
					if player then
						types.Remote:FireClient(player, packet)
					end
				else
					types.Remote:FireClient(a, packet)
				end
			end
		elseif type(clientarg) == "function" then --- fire by case
			for _, a in Players:GetPlayers() do
				if clientarg(a) == true then
					types.Remote:FireClient(a, packet)
				end
			end
		else
			warn(string.format("(packet dropped) error solving clientarg: type(%s) typeof(%s)", type(clientarg), typeof(clientarg)), clientarg, packet)
		end
	else
		types.Remote:FireServer(packet)
	end
end

--- optionally deferred when a castable step is reached \
--- left blank to be overwritten externally
function types.stepped(...)
	
end

--- optionally deferred when a "hit" should be applied \
--- left blank to be overwritten externally
function types.hit(...)
	
end

return types