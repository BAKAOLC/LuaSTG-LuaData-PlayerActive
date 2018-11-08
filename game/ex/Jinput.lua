--======================================
--javastg input controll
--======================================

----------------------------------------
--JavaStage多人输入系统

--格式化输入的列表
jstg.syskey={ repslow =8, menu =9, repfast =10, snapshot =11, retry =12, right =4, left =5, slow =3, down =6, up =7, special =2, shoot =0, spell =1}
--对应的反查字符串
jstg.syskey2={"shoot","spell","special","slow","right","left","down","up","repslow","menu","repfast","snapshot","retry"}


--extern jstg.player_template={}
--extern jstg.players={}
jstg.keys={}
jstg.keypres={}
jstg.keymaps={}
jstg.inputcount=1

jstg.splitplayer=false

function jstg.CreateInput(count,delay)
	jstg.inputcount=count
	for i=count,1,-1 do
		jstg.keys[i]={}
		jstg.keypres[i]={}
	end
end
jstg.CreateInput(2)

jstg.enable_player=false
function jstg.CreatePlayers()
	jstg.enable_player=true
	
	local last=New(_G[lstg.var.player_name],1)
	last.keyslot=1--by ETC
	jstg.players={last}
	jstg.CreateInput(1)
	jstg.UpdateWorld()
	--lstg.var.player_name2='marisa_player'
	--jstg.network.slots[2]='local'
	--jstg.network.slots[1]='local'
	--jstg.MultiPlayer()
	last.key=jstg.keys[1]
	last.keypre=jstg.keypres[1]

	if lstg.var.player_name2 then
		last.world=2
	
		jstg.CreateInput(2)
		last.key=jstg.keys[1]
		last.keypre=jstg.keypres[1]
		
		last=New(_G[lstg.var.player_name2],2)
		last.keyslot=2--by ETC
		last.key=jstg.keys[2]
		last.keypre=jstg.keypres[2]
		last.world=4
		jstg.players[2]=last
	end
end
function jstg.Compatible()--for old mod
	jstg.players={player}
	local last=player
	jstg.CreateInput(1)
	jstg.worlds={lstg.world}
	jstg.worldcount=1
	lstg.world.world=7
	jstg.UpdateWorld()
	if last then
		last.keyslot=1--by ETC
		last.key=jstg.keys[1]
		last.keypre=jstg.keypres[1]
	end
	if lstg.var.player_name2 then
		last.world=2
	
		jstg.CreateInput(2)
		last.key=jstg.keys[1]
		last.keypre=jstg.keypres[1]
		last=New(_G[lstg.var.player_name2],2)
		last.keyslot=2--by ETC
		last.key=jstg.keys[2]
		last.keypre=jstg.keypres[2]
		last.world=4
		jstg.players[2]=last
	end
end



_GetLastKey=GetLastKey

function GetLastKey(id)
	if id then
		local k1=jstg.keys[id]
		local kp=jstg.keypres[id]
		for k, v in pairs(jstg.syskey) do
			if k1[k]~= kp[k] and k1[k] then
				return jstg.SysVKey2Key(v)
			end
		end
	else
		return jstg.LastKey
	end
end

function KeyIsDown(key,id)--？？？ESC你怎么了……为什么不写这个--by ETC
	if id then
		return jstg.keys[id][key]
	else
		return KeyState[key]
	end
end KeyPress = KeyIsDown

function KeyIsPressed(key,id)
	if id then
		return jstg.keys[id][key] and (not jstg.keypres[id][key])
	else
		return KeyState[key] and (not KeyStatePre[key])
	end
end KeyTrigger = KeyIsPressed


function jstg.GetLocalPlayerIndexs()
	local p={}
	for i=1,#jstg.players do
		if jstg.network.playerkeymask[i] == 0 or jstg.network.slots[jstg.network.playerkeymask[i]]=='local' then
			p[#p+1]=i
		end
	end
	return p
end

--重置输入设备
function jstg.ChangeInput()
	--清空当前的输入设备
	for i=1,#jstg.devices do
		BindInput(0,i,0,0)--取消输入设备挂载
		ReleaseInputDevice(jstg.devices[i])--删除输入设备
	end
	jstg.devices={}
	ResetInput()--重置总线的时间戳
	local playerid=1
	local slotmask=2
	for i=1,#jstg.network.slots do
		if jstg.network.slots[i]=='local' then
			local p=CreateInputDevice(false)--创建本地输入
			--设置按键
			local playerkeyinfo=setting.keys
			local syskeyinfo=setting.keysys
			if playerid>1 then playerkeyinfo=setting['keys'..playerid] end
			for k,v in pairs(jstg.syskey) do
				local key=playerkeyinfo[k]
				if key==nil then
					key=syskeyinfo[k]
				end
				if key==nil then
					key=0
				end
				AddInputAlias(p,v,key)			
			end
			--绑定总线
			jstg.devices[i]=p
			BindInput(p,i,1+slotmask,jstg.network.delay)
			Print('bind',i,1+slotmask)
			playerid=playerid+1
		else
			local p=CreateInputDevice(true)--创建远程输入
			jstg.devices[i]=p
			BindInput(p,i,1+slotmask,jstg.network.delay)
		end
		slotmask=slotmask+slotmask
	end	
end

function jstg.ChangeInput2()--for watch single player
	--clear current input devices
	for i=1,#jstg.devices do
		BindInput(0,i,0,0)--unbind input
		ReleaseInputDevice(jstg.devices[i])--release data
	end
	jstg.devices={}
	ResetInput()--reset frame stamp
	local playerid=1
	local slotmask=2
	local i=1
	if jstg.network.slots[i]=='local' then
		local p=CreateInputDevice(false)
		--set key alias
		local playerkeyinfo=setting.keys
		local syskeyinfo=setting.keysys
		if playerid>1 then playerkeyinfo=setting['keys'..playerid] end
		for k,v in pairs(jstg.syskey) do
			local key=playerkeyinfo[k]
			if key==nil then
				key=syskeyinfo[k]
			end
			if key==nil then
				key=0
			end
			AddInputAlias(p,v,key)			
		end
		--fill table
		jstg.devices[i]=p
		BindInput(p,i,1+slotmask,jstg.network.delay)
		playerid=playerid+1
	else--remote
		local p=CreateInputDevice(true)
		jstg.devices[i]=p
		BindInput(p,i,1+slotmask,jstg.network.delay)
	end
end

jstg.KeyState={}
jstg.KeyStatePre={}
jstg.LastKey=0
jstg.OldKeyState={}

--将虚拟按键转化为按键名
function jstg.SysVKey2Key(vkey)
	local keyname=jstg.syskey2[vkey+1]
	if setting.keysys[keyname] then return setting.keysys[keyname] end
	if setting.keys[keyname] then return setting.keys[keyname] end
	if setting.keys2[keyname] then return setting.keys2[keyname] end
	return 0
end

function jstg.GetInputEx(is_pause)
	--get players input
	for i=1,jstg.inputcount do
		KeyStatePre = {}
		KeyState = jstg.keys[i]
		jstg.GetInputSingleEx(i,is_pause)
		for k, v in pairs(setting.keys) do
			jstg.keypres[i][k] = KeyStatePre[k]
		end
	end
	--get system input
	--！！警告：jstg.KeyState一直是空的草
	KeyStatePre = {}
	KeyState = jstg.KeyState
	for k, v in pairs(jstg.syskey) do
		KeyStatePre[k] = KeyState[k]
	end
	--update and get last key
	--！！警告：lastkey虽然正常，但是还是有问题
	jstg.LastKey=0
	for k, v in pairs(jstg.syskey) do
		local t = GetVKeyStateEx(0,jstg.syskey[k])
		if t~= KeyState[k] then
			local s=jstg.SysVKey2Key(v)
			if t then
				jstg.LastKey=s
			else
				if s==jstg.LastKey then
					jstg.LastKey=0
				end
			end
			KeyState[k]=t
		end
	end
	--compatible old stage replay
	if ext.replay.IsReplay() and jstg.enable_player==false then
		KeyState=jstg.OldKeyState
		KeyStatePre = {}
		for k, v in pairs(setting.keys) do
			KeyStatePre[k] = KeyState[k]
			KeyState[k] = jstg.keys[1][k]
		end
	end
end

function jstg.GetInputSingleEx(i,is_pause)
	local sk=setting.keys
	if stage.next_stage then
		KeyStatePre = {}
	else
		-- 刷新KeyStatePre
		for k, v in pairs(sk) do
			KeyStatePre[k] = KeyState[k]
		end
	end

	-- 不是录像时更新按键状态
	if not ext.replay.IsReplay() then
		for k,v in pairs(sk) do
			KeyState[k] = GetVKeyStateEx(jstg.network.playerkeymask[i],jstg.syskey[k])
		end
	end

	if not is_pause then
		if ext.replay.IsRecording() then
			-- 录像模式下记录当前帧的按键
			replayWriter:Record(KeyState)
		elseif ext.replay.IsReplay() then
			-- 回放时载入按键状态
			--Print("ReadReplay")
			if not replayReader:Next(KeyState) then--by ETC，检测rep是否已经结束，结束则弹出暂停菜单，状态为replay播放完
				--算了，算了，bug一堆
				--ext.rep_over=true
				--ext.pop_pause_menu=true
				--ext.SetPauseMenuType('replay-finish')
			end
			--assert(replayReader:Next(KeyState), "Unexpected end of replay file.")
		end
	end
end



