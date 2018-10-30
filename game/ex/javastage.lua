-- javastage
jstg = {}

jstg.EX_MASK_SYSTEM=1
jstg.EX_MASK_PLAYER1=2
jstg.EX_MASK_PLAYER2=4
jstg.EX_MASK_PLAYER3=8
jstg.EX_MASK_PLAYER4=16

jstg.EX_SLOT_SYSTEM=0
jstg.EX_SLOT_PLAYER1=1
jstg.EX_SLOT_PLAYER2=2
jstg.EX_SLOT_PLAYER3=3
jstg.EX_SLOT_PLAYER4=4

jstgobj=Class(object)

frame=0
stg_target={}

function jstgobj:init(baseobj)
	self.layer=LAYER_ENEMY
	self.group=GROUP_GHOST
	self.frame=0
	self.obj=baseobj
	for _,v in baseobj do
		self[_]=v
	end
	if self.init ~= nil then
		self.init(self)
	end
end
function jstgobj:frame()
	task.Do(self)
	self.frame=self.frame+1
	frame=self.frame
	stg_target=self
	if self.script ~= nil then
		self.script(self)
	end
end
function jstgobj:del()
	if self.finalize ~= nil then
		self.finalize(self)
	end
end

function jstg.AddObject(obj)
	return New(jstgobj,obj)
end

function jstg:ActionCoolDown(varname,delay,condition)
	self[varname]=self[varname] or 0
	if self[varname]>0 then
		self[varname]=self[varname]-1
	else
		if condition then
			self[varname]=delay
			return true
		end
	end
	return false
end

jstg.worldcount=1
jstg.worlds={}
jstg.worlds[1]=lstg.world
lstg.world.world=7
jstg.currentworld=1

--{l=-192,r=192,b=-224,t=224,boundl=-224,boundr=224,boundb=-256,boundt=256,scrl=32,scrr=416,scrb=16,scrt=464,pl=-192,pr=192,pb=-224,pt=224}

function jstg.SetWorldCount(cnt)
   jstg.worldcount=cnt
end
function SetLuaSTGWorld(world,width,height,boundout,sl,sr,sb,st)
	world.l=-width/2
	world.pl=-width/2
	world.boundl=-width/2-boundout
	world.r=width/2
	world.pr=width/2
	world.boundr=width/2+boundout
	world.b=-height/2
	world.pb=-height/2
	world.boundb=-height/2-boundout
	world.t=height/2
	world.pt=height/2
	world.boundt=height/2+boundout
	world.scrl=sl
	world.scrr=sl+width
	world.scrb=sb
	world.scrt=sb+height
	--world.scrl=16
	--world.scrr=304
	--world.scrb=16
	--world.scrt=464

end
function SetLuaSTGWorld2(world,width,height,boundout,sl,sb,m)
	world.l=-width/2
	world.pl=-width/2
	world.boundl=-width/2-boundout
	world.r=width/2
	world.pr=width/2
	world.boundr=width/2+boundout
	world.b=-height/2
	world.pb=-height/2
	world.boundb=-height/2-boundout
	world.t=height/2
	world.pt=height/2
	world.boundt=height/2+boundout
	world.scrl=sl
	world.scrr=sl+width
	world.scrb=sb
	world.scrt=sb+height
	world.world=m
end
function jstg.UpdateWorld()
	local a={0,0,0,0}
	for i=1,jstg.worldcount do
		a[i]=jstg.worlds[i].world or 0
	end
	ActiveWorlds(a[1],a[2],a[3],a[4])
end
function jstg.SetWorld(index,world,mask)
	world.world=mask
	jstg.worlds[index]=world
end
function jstg.GetWorld(index)
	return jstg.worlds[index]
end
function jstg.SwitchWorld(index)
	jstg.currentworld=index
	lstg.world=jstg.GetWorld(index)
	SetBound(lstg.world.boundl,lstg.world.boundr,lstg.world.boundb,lstg.world.boundt)
end
function jstg.ApplyWorld(world)
	--jstg.currentworld=index
	lstg.world=world
	SetBound(lstg.world.boundl,lstg.world.boundr,lstg.world.boundb,lstg.world.boundt)
end
function jstg.TestWorld(a)
	jstg.SetWorldCount(2)
	local w1={}
	SetLuaSTGWorld(w1,288,448,32,16,288+16,16,16+448);
	jstg.SetWorld(1,w1,1+2)
	local w2={}
	SetLuaSTGWorld(w2,288,448,32,320+16,288+320+16,16,16+448);
	jstg.SetWorld(2,w2,1+4)
end
--jstg.TestWorld(0)


--JavaStage PlayerSystem
jstg.player_template={}
jstg.players={}
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
function jstg.GetInput()

	for i=jstg.inputcount,1,-1 do
		KeyStatePre = {}
		KeyState = jstg.keys[i]
		local ss=setting.keys
		if i>1 then
			ss=setting['keys'..i]
		end
		jstg.GetInputSingle(ss)
		for k, v in pairs(ss) do
			jstg.keypres[i][k] = KeyStatePre[k]
		end
	end
end



function jstg.GetInputSingle(sk)
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
			KeyState[k] = GetKeyState(v)
		end
	end

	if ext.replay.IsRecording() then
		-- 录像模式下记录当前帧的按键
		replayWriter:Record(KeyState)
	elseif ext.replay.IsReplay() then
		-- 回放时载入按键状态
		replayReader:Next(KeyState)
		--assert(replayReader:Next(KeyState), "Unexpected end of replay file.")
	end
end
jstg.enable_player=false
function jstg.CreatePlayers()
	jstg.enable_player=true
	
	local last=New(_G[lstg.var.player_name])
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
		last.key=jstg.keys[1]
		last.keypre=jstg.keypres[1]
	end
	if lstg.var.player_name2 then
		last.world=2
	
		jstg.CreateInput(2)
		last.key=jstg.keys[1]
		last.keypre=jstg.keypres[1]
		last=New(_G[lstg.var.player_name2],2)
		last.key=jstg.keys[2]
		last.keypre=jstg.keypres[2]
		last.world=4
		jstg.players[2]=last
	end
end

jstg.network={}
jstg.network.status=0
jstg.network.host="127.0.0.1"
jstg.network.port=26033
jstg.network.slots={}
jstg.network.delay=4
jstg.network.devices={}
jstg.network.playerkeymask={0,0,0,0,0,0}

jstg.NETSTATES={'Connecting','Wait for reply','Wait for player','Wait for sync','Connected'}

function jstg.SendData(...)
	local arg={...}
	return SendData('O'..Serialize(arg))
end

jstg.pingframe = 0

function jstg.ProceedConnect()
	if jstg.network.status>1 then
		local dt=ReceiveData()
		while dt do
			Print(jstg.network.status,dt)
			if string.sub(dt,1,1)=='O' then
				--user lua object, decode it
				dt=string.sub(dt,2,string.len(dt))
				local da=DeSerialize(dt)
				if da[1]=='client' and jstg.network.is_host and jstg.network.status==3 then
					--join room
					jstg.network.slots[da[2]]='remote'
					if da[2]==2 then
						if jstg.network.delay==-1 then
							--send a ping package
							jstg.pingframe = ex.stageframe
							jstg.SendData('ping')
						else 
							--if we have enough players ,send message to start
							jstg.network.status=4
							jstg.network.ran_seed = ((os.time() % 65536) * 877) % 65536
							--todo send a ping package to get delay
							
							--send players,delay,ran,type seed to sync game status
							jstg.SendData('server',2,jstg.network.delay,jstg.network.ran_seed,jstg.network.type)
						end
					end
				end	
				if da[1]=='server' and not jstg.network.is_host then
					--receive players,delay,ran seed to sync game status
					jstg.network.status=4
					for i=1,da[2] do
						jstg.network.slots[i]='remote'
					end
					jstg.network.slots[jstg.network.slot]='local'
					jstg.network.delay=da[3]
					jstg.network.ran_seed=da[4]
					jstg.network.type=da[5]
				end
				if da[1]=='ping' then
					jstg.SendData('back',jstg.network.slot)
				end
				if da[1]=='back' and da[2]==2 and jstg.network.is_host and jstg.network.status==3 then
					jstg.network.delay = ex.stageframe - jstg.pingframe
					jstg.network.status=4
					jstg.network.ran_seed = ((os.time() % 65536) * 877) % 65536
					--todo send a ping package to get delay
					
					--send players,delay,ran,type seed to sync game status
					jstg.SendData('server',2,jstg.network.delay,jstg.network.ran_seed,jstg.network.type)
				end
			end
			if string.sub(dt,1,1)=='S' then
				--Server send connect slot (start with 1)
				dt=string.sub(dt,2,string.len(dt))
				jstg.network.slot=tonumber(dt)
				jstg.network.slots={}
				jstg.network.is_host=(jstg.network.slot==1)
				jstg.network.status=3
				if not jstg.network.is_host then
					jstg.SendData('client',jstg.network.slot)
				else
					jstg.network.slots[1]='local'
				end
			end
			dt=ReceiveData()
		end
	end

	if jstg.network.status==1 then --connecting
		local host=jstg.network.host
		local rt=ConnectTo(jstg.network.host,jstg.network.port)
		if rt then
			jstg.network.status=2
		else
			ConnectTo('',0)
			jstg.network.status=0
		end
	end
	if jstg.network.status==4 then --create input
		if jstg.network.type==1 then
			jstg.WatchSinglePlayer()
		elseif jstg.network.type==2 then
			jstg.CoopSinglePlayer()
		elseif jstg.network.type==3 then
			jstg.MultiPlayer()
		end
		jstg.network.status=5
		jstg.nettitle[1]='Disconnect'
		stage_menu.update(jstg.menu_title)
		menu.FlyIn(jstg.menu_title,'left')
		menu.FlyOut(jstg.menu_network,'right')	
		ran:Seed(jstg.network.ran_seed)
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

function KeyIsPressed(key,id)
	if id then
		return jstg.keys[id][key] and (not jstg.keypres[id][key])
	else
		return KeyState[key] and (not KeyStatePre[key])
	end
end

jstg.syskey={ repslow =8, menu =9, repfast =10, snapshot =11, retry =12, right =4, left =5, slow =3, down =6, up =7, special =2, shoot =0, spell =1}
jstg.syskey2={"shoot","spell","special","slow","right","left","down","up","repslow","menu","repfast","snapshot","retry"}

function jstg.GetLocalPlayerIndexs()
	local p={}
	for i=1,#jstg.players do
		if jstg.network.playerkeymask[i] == 0 or jstg.network.slots[jstg.network.playerkeymask[i]]=='local' then
			p[#p+1]=i
		end
	end
	return p
end

function jstg.ChangeInput()
	--clear current input devices
	for i=1,#jstg.network.devices do
		BindInput(0,i,0,0)--unbind input
		ReleaseInputDevice(jstg.network.devices[i])--release data
	end
	jstg.network.devices={}
	ResetInput()--reset frame stamp
	local playerid=1
	local slotmask=2
	for i=1,#jstg.network.slots do
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
			jstg.network.devices[i]=p
			BindInput(p,i,1+slotmask,jstg.network.delay)
			Print('bind',i,1+slotmask)
			playerid=playerid+1
		else--remote
			local p=CreateInputDevice(true)
			jstg.network.devices[i]=p
			BindInput(p,i,1+slotmask,jstg.network.delay)
		end
		slotmask=slotmask+slotmask
	end	
end

function jstg.ChangeInput2()--for watch single player
	--clear current input devices
	for i=1,#jstg.network.devices do
		BindInput(0,i,0,0)--unbind input
		ReleaseInputDevice(jstg.network.devices[i])--release data
	end
	jstg.network.devices={}
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
		jstg.network.devices[i]=p
		BindInput(p,i,1+slotmask,jstg.network.delay)
		playerid=playerid+1
	else--remote
		local p=CreateInputDevice(true)
		jstg.network.devices[i]=p
		BindInput(p,i,1+slotmask,jstg.network.delay)
	end
end

function jstg.SinglePlayer()
	


	if jstg.network.status>1 then
		--break connection
		for i=1,#jstg.network.devices do
			BindInput(0,i,0,0)--unbind input
			ReleaseInputDevice(jstg.network.devices[i])--release data
		end
		jstg.network.devices={}
		ConnectTo('',0)
	end
	--reset network
	jstg.network.slots={'local'}
	jstg.network.delay=0
	jstg.network.status=0
	jstg.network.ran_seed=nil
	--update input
	jstg.ChangeInput()
	--set key usage
	jstg.network.playerkeymask={0,0,0,0,0,0} --same as 1 
	Print('Single')
end
function jstg.WatchSinglePlayer()
	--update input
	jstg.ChangeInput2()
	--set key usage
	jstg.network.playerkeymask={0,0,0,0,0,0} --same as 1 
	Print('Single')
end
function jstg.CoopSinglePlayer()
	--update input
	jstg.ChangeInput()
	--set key usage
	jstg.network.playerkeymask={0,0,0,0,0,0} --same as 1 
	Print('Single')
end
function jstg.MultiPlayer()
	--update input
	jstg.ChangeInput()
	--set key usage
	jstg.network.playerkeymask={1,2,3,4,5,6} 
	Print('Multi')
end
function jstg.TwoPlay()
	--update input
	jstg.ChangeInput()
	--set key usage
	jstg.network.playerkeymask={0,0,0,0,0,0} 
	Print('Single')
end
jstg.KeyState={}
jstg.KeyStatePre={}
jstg.LastKey=0

function jstg.SysVKey2Key(vkey)
	local keyname=jstg.syskey2[vkey+1]
	if setting.keysys[keyname] then return setting.keysys[keyname] end
	if setting.keys[keyname] then return setting.keys[keyname] end
	if setting.keys2[keyname] then return setting.keys2[keyname] end
	return 0
end

function jstg.CreateConnect(ctype)
	if ctype==0 then
		jstg.SinglePlayer()
	elseif jstg.network.status==0 then
		jstg.network.type=ctype
		jstg.network.status=1
		jstg.network.host=network.server
		jstg.network.port=network.port
		jstg.network.delay=network.delay or -1
		if jstg.network.type==1 then
			jstg.network.delay=0
		end
	end
end
jstg.OldKeyState={}
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
	KeyStatePre = {}
	KeyState = jstg.KeyState
	for k, v in pairs(jstg.syskey) do
		KeyStatePre[k] = KeyState[k]
	end
	--update and get last key
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
			replayReader:Next(KeyState)
			--assert(replayReader:Next(KeyState), "Unexpected end of replay file.")
		end
	end
end
jstg.SinglePlayer()

--jstg player object system
--const
jstg.PLAYER_NORMAL=1
jstg.PLAYER_HIT=2
jstg.PLAYER_DEAD=3
jstg.PLAYER_BIRTH=0

function ran:List(list)
	return list[ran:Int(1,#list)]
end
function ran:Player(o)
	return ran:List(Players(o))
end

jstg.player_class=Class(object)
--通过world掩码获取player数组
function jstg.GetObjectByWorld(list,world)
	local w={}
	local j=1
	for i=1,#list do
		if IsInWorld(world,list[i].world) then
			w[j]=list[i]
			j=j+1
		end
	end
	return w
end
function jstg.GetObjectByObject(list,world)
	local w={}
	local j=1
	for i=1,#list do
		if IsSameWorld(world,list[i].world) then
			w[j]=list[i]
			j=j+1
		end
	end
	return w
end

function jstg.GetPlayersByWorld(world)
	return jstg.GetObjectByWorld(jstg.players,world)
end
--通过world掩码获取worlds对象数组
function jstg.GetWorldsByWorld(world)
	return jstg.GetObjectByWorld(jstg.worlds,world)
end
--计算在当前多场地多玩家情况下，玩家应该在哪里出现
function jstg:GetPlayerBirthPos()
	--Get players that may be in a same world
	local ps=jstg.GetPlayersByWorld(self.world)
	local n=#ps
	local p=1
	for i=1,n do
		if self==ps[i] then
			p=i
			break
		end
	end
	if n==0 then n=1 end --the player is not actually in game
	--Get worlds
	local ws=jstg.GetWorldsByWorld(self.world)
	--if this player is in no world,abandon
	if #ws==0 then
		return 0,-24
	end
	--just use the first one
	ws=ws[1]
	return (ws.r-ws.l)/n*0.5*(2*i-1)+ws.r,ws.b-24	
end

--替换xxx==player
function IsPlayer(obj)
	for i=1,#jstg.players do
		if obj==jstg.players[i] then
			jstg._player=player
			player=obj
			return true
		end
	end
	return false
end
function IsPlayerEnd() if jstg._player then player=jstg._player jstg._player=nil end end

function SetPlayer(p)
	jstg.current_player=p
end

--替换editor中的player（单体）
function _Player(o)
	if jstg.current_player then return jstg.current_player end
	return Player(o)
end

--替换player（单体），不使用随机数
function Player(o)
	if o==nil then o=GetCurrentObject() end
	if o then 
		local w=jstg.GetPlayersByWorld(o.world)
		if #w==0 then return player end --no player in same world,return a random one
		if #w==1 then return w[1] end
		return w[ex.stageframe%#w+1]
	end
	return player
end
function Players(o)
	if o==nil then o=GetCurrentObject() end
	if o then 
		local w=jstg.GetObjectByObject(jstg.players,o.world)
		return w
	end
	return jstg.players
end

function ListSet(l,a,v)
	for i=1,#l do
		l[i][a]=v
	end
end

jstg.player_properties={'power','bomb','lifeleft','chip','bombchip'}

function jstg.player_class:init(slot,world,var)
	self.slot=slot
	self.world=world
	jstg.players[slot]=self
	self.group=GROUP_PLAYER
	self.y=-176
	self.supportx=0
	self.supporty=self.y
	self.hspeed=4
	self.lspeed=2
	self.collect_line=96
	self.slow=0
	self.layer=LAYER_PLAYER
	self.lr=1
	self.lh=0
	self.fire=0
	self.lock=false
	self.dialog=false
	self.nextshoot=0
	self.nextspell=0
	self.A=0        --自机判定大小
	self.B=0
	self.nextcollect=0--HZC收点系统
	self.item=1
	self.death=0
	self.protect=120
	lstg.player=self
	player=self
	self.grazer=New(grazer)
	if not lstg.var.init_player_data then error('Player data has not been initialized. (Call function item.PlayerInit.)') end
	self.support=int(var.power/100)
	--set playerside data
	for i=1,#jstg.player_properties do
		self[jstg.player_properties[i]]=var[i]
	end
	
	self.sp={}
	self.time_stop=false
	--New(item_bar)
end



function jstg.player_class:frame()
	local _temp_key=nil
	local _temp_keyp=nil
	if self.key then
		_temp_key=KeyState
		_temp_keyp=KeyStatePre
		KeyState=self.key
		KeyStatePre=self.keypre
	end


	--find target
	if ((not IsValid(self.target)) or (not self.target.colli)) then player_class.findtarget(self) end
	if not KeyIsDown'shoot' then self.target=nil end
	--
	local dx=0
	local dy=0
	local v=self.hspeed
	if (self.death==0 or self.death>90) and (not self.lock) and not(self.time_stop) then
		--slow
		if KeyIsDown'slow' then self.slow=1 else self.slow=0 end
		--shoot and spell
		if not self.dialog then
			if KeyIsDown'shoot' and self.nextshoot<=0 then self.class.shoot(self) end
			if KeyIsDown'spell' and self.nextspell<=0 and lstg.var.bomb>0 and not lstg.var.block_spell then
				item.PlayerSpell()
				lstg.var.bomb=lstg.var.bomb-1
				self.class.spell(self)
				self.death=0
				self.nextcollect=90
			end
		else self.nextshoot=15 self.nextspell=30
		end
		--move
		if self.death==0 and not self.lock then
		if self.slowlock then self.slow=1 end
		if self.slow==1 then v=self.lspeed end
		if KeyIsDown'up' then dy=dy+1 end
		if KeyIsDown'down' then dy=dy-1 end
		if KeyIsDown'left' then dx=dx-1 end
		if KeyIsDown'right' then dx=dx+1 end
		if dx*dy~=0 then v=v*SQRT2_2 end
		self.x=self.x+v*dx
		self.y=self.y+v*dy
		self.x=math.max(math.min(self.x,lstg.world.pr-8),lstg.world.pl+8)
		self.y=math.max(math.min(self.y,lstg.world.pt-32),lstg.world.pb+16)
		end
		--fire
		if KeyIsDown'shoot' and not self.dialog then self.fire=self.fire+0.16 else self.fire=self.fire-0.16 end
		if self.fire<0 then self.fire=0 end
		if self.fire>1 then self.fire=1 end
		--item
		if self.y>self.collect_line then
			if not(self.itemed) and not(self.collecting) then
				self.itemed=true
				self.collecting=true
--				lstg.var.collectitem=0
				self.nextcollect=15
			end
			for i,o in ObjList(GROUP_ITEM) do o.attract=8 o.num=self.item end
		-----
		else
			self.nextcollect=0
			if KeyIsDown'slow' then
				for i,o in ObjList(GROUP_ITEM) do
					if Dist(self,o)<48 then o.attract=max(o.attract,3) end
				end
			else
				for i,o in ObjList(GROUP_ITEM) do
					if Dist(self,o)<24 then o.attract=max(o.attract,3) end
				end
			end
		end
		if self.nextcollect<=0 and self.itemed then
			item.playercollect(self.item)
			self.item=self.item%6+1
--			lstg.var.collectitem=0
			self.itemed=false
			self.collecting=false
		end
		if self.collecting and not(self.itemed) then end
	elseif self.death==90 then
		if self.time_stop then self.death=self.death-1 end
		item.PlayerMiss()
		self.deathee={}
		self.deathee[1]=New(deatheff,self.x,self.y,'first')
		self.deathee[2]=New(deatheff,self.x,self.y,'second')
		New(player_death_ef,self.x,self.y)
	elseif self.death==84 then
		if self.time_stop then self.death=self.death-1 end
		self.hide=true
		self.support=int(lstg.var.power/100)
	elseif self.death==50 then
		if self.time_stop then self.death=self.death-1 end
		self.x=0
		self.supportx=0
		self.y=-236
		self.supporty=-236
		self.hide=false
		New(bullet_deleter,self.x,self.y)
	elseif self.death<50 and not(self.lock) and not(self.time_stop) then
		self.y=-176-1.2*self.death
	end
	--img
	---加上time_stop的限制来实现图像时停
	if not(self.time_stop) then
	if abs(self.lr)==1 then
		self.img=self.imgs[int(self.ani/8)%8+1]
	elseif self.lr==-6 then
		self.img=self.imgs[int(self.ani/8)%4+13]
	elseif self.lr== 6 then
		self.img=self.imgs[int(self.ani/8)%4+21]
	elseif self.lr<0 then
		self.img=self.imgs[7-self.lr]
	elseif self.lr>0 then
		self.img=self.imgs[15+self.lr]
	end
	--------------------
	self.a=self.A
	self.b=self.B
	--some status
	self.lr=self.lr+dx;
	if self.lr> 6 then self.lr= 6 end
	if self.lr<-6 then self.lr=-6 end
	if self.lr==0 then self.lr=self.lr+dx end
	if dx==0 then
		if self.lr> 1 then self.lr=self.lr-1 end
		if self.lr<-1 then self.lr=self.lr+1 end
	end

	self.lh=self.lh+(self.slow-0.5)*0.3
	if self.lh<0 then self.lh=0 end
	if self.lh>1 then self.lh=1 end

	if self.nextshoot>0 then self.nextshoot=self.nextshoot-1 end
	if self.nextspell>0 then self.nextspell=self.nextspell-1 end
	if self.nextcollect>0 then self.nextcollect=self.nextcollect-1 end--HZC收点系统

	if self.support>int(lstg.var.power/100) then self.support=self.support-0.0625
	elseif self.support<int(lstg.var.power/100) then self.support=self.support+0.0625 end
	if abs(self.support-int(lstg.var.power/100))<0.0625 then self.support=int(lstg.var.power/100) end

	self.supportx=self.x+(self.supportx-self.x)*0.6875
	self.supporty=self.y+(self.supporty-self.y)*0.6875

	if self.protect>0 then self.protect=self.protect-1 end
	if self.death>0 then self.death=self.death-1 end

	lstg.var.pointrate=item.PointRateFunc(lstg.var)
	--update supports
		if self.slist then
			self.sp={}
			if self.support==5 then
				for i=1,4 do self.sp[i]=MixTable(self.lh,self.slist[6][i]) self.sp[i][3]=1 end
			else
				local s=int(self.support)+1
				local t=self.support-int(self.support)
				for i=1,4 do
					if self.slist[s][i] and self.slist[s+1][i] then
						self.sp[i]=MixTable(t,MixTable(self.lh,self.slist[s][i]),MixTable(self.lh,self.slist[s+1][i]))
						self.sp[i][3]=1
					elseif self.slist[s+1][i] then
						self.sp[i]=MixTable(self.lh,self.slist[s+1][i])
						self.sp[i][3]=t
					end
				end
			end
		end
	--
	end---time_stop
	if self.time_stop then self.timer=self.timer-1 end
	
	
	if self.key then
		KeyState=_temp_key
		KeyStatePre=_temp_keyp
	end
	
end

function jstg.player_class:render()
	if self.protect%3==1 then SetImageState(self.img,'',Color(0xFF0000FF))
	else SetImageState(self.img,'',Color(0xFFFFFFFF)) end
	object.render(self)
end

function jstg.player_class:colli(other)
	if self.death==0 and not self.dialog and not cheat then
		if self.protect==0 then
			PlaySound('pldead00',0.5)
			self.death=100
		end
		if other.group==GROUP_ENEMY_BULLET then Del(other) end
	end
end

function jstg.player_class:findtarget()
	self.target=nil
	local maxpri=-1
	for i,o in ObjList(GROUP_ENEMY) do
		if o.colli then
			local dx=self.x-o.x
			local dy=self.y-o.y
			local pri=abs(dy)/(abs(dx)+0.01)
			if pri>maxpri then maxpri=pri self.target=o end
		end
	end
end

jstg.network.slots[2]='local'
jstg.network.slots[1]='local'
jstg.MultiPlayer()
jstg.CreateInput(2)




