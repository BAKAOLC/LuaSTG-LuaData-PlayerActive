--======================================
--自机活额外辅助库
--code by Xiliusha
--======================================

etc={}

----------------------------------------
--文件包含

DoFile('etc\\etc_map.lua')
DoFile('etc\\etc_gamemap.lua')
DoFile('etc\\etc_navigation.lua')

----------------------------------------
--辅助用的字符串格式化函数

function etc.serialize(obj)
	local lua = ""
	local t = type(obj)
	if t == "number" then
		lua = lua .. obj
	elseif t == "boolean" then
		lua = lua .. tostring(obj)
	elseif t == "string" then
		lua = lua .. string.format("%q", obj)
	elseif t == "table" then
		lua = lua .. "{\n"
	for k, v in pairs(obj) do
		lua = lua .. "[" .. etc.serialize(k) .. "]=" .. etc.serialize(v) .. ",\n"
	end
	local metatable = getmetatable(obj)
		if metatable ~= nil and type(metatable.__index) == "table" then
		for k, v in pairs(metatable.__index) do
			lua = lua .. "[" .. etc.serialize(k) .. "]=" .. etc.serialize(v) .. ",\n"
		end
	end
		lua = lua .. "}"
	elseif t == "nil" then
		return nil
	else
		error("can not serialize a " .. t .. " type.")
	end
	return lua
end

function etc.unserialize(lua)
	local t = type(lua)
	if t == "nil" or lua == "" then
		return nil
	elseif t == "number" or t == "string" or t == "boolean" then
		lua = tostring(lua)
	else
		error("can not unserialize a " .. t .. " type.")
	end
	lua = "return " .. lua
	local func = loadstring(lua)
	if func == nil then
		return nil
	end
	return func()
end

