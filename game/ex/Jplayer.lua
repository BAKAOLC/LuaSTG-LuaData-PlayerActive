--======================================
--javastg players
--======================================

----------------------------------------
--JavaStage

jstg.players={}
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

function ran:List(list)
	return list[ran:Int(1,#list)]
end
function ran:Player(o)
	return ran:List(Players(o))
end


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




