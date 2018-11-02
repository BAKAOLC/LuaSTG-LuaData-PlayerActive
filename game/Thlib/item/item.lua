LoadTexture('item','THlib\\item\\item.png')
LoadImageGroup('item','item',0,0,32,32,2,5,8,8)
LoadImageGroup('item_up','item',64,0,32,32,2,5)
SetImageState('item1','mul+add',Color(128,255,255,255))
SetImageState('item2','mul+add',Color(128,255,255,255))
--SetImageState('item6','',Color(255,255,255,255))
SetImageState('item8','mul+add',Color(192,255,255,255))
LoadTexture('bonus1','THlib\\item\\item.png')
LoadTexture('bonus2','THlib\\item\\item.png')
LoadTexture('bonus3','THlib\\item\\item.png')

lstg.var.collectingitem=0

--自机活常量
local POWERMINOR=1--常量，小灵力点加灵力的数量

item=Class(object)
function item:init(x,y,t,v,angle)
	x=min(max(x,lstg.world.l+8),lstg.world.r-8)
	self.x=x
	self.y=y
	angle=angle or 90
	v=v or 1.5
	SetV(self,v,angle)
	self.v=v
	self.group=GROUP_ITEM
	self.layer=LAYER_ITEM
	self.bound=false
	self.img='item'..t
	self.imgup='item_up'..t
	self.attract=0
end
function item:render()
	if self.y>lstg.world.t then
		Render(self.imgup,self.x,lstg.world.t-8)
	else
		object.render(self)
	end
end
function item:frame()
	local player=self.target
	if self.timer<24 then
		self.rot=self.rot+45
		self.hscale=(self.timer+25)/48
		self.vscale=self.hscale
		if self.timer==22 then self.vy=min(self.v,2) self.vx=0 end
	elseif self.attract>0 then
		local a=Angle(self,player)
		self.vx=self.attract*cos(a)+player.dx*0.5
		self.vy=self.attract*sin(a)+player.dy*0.5
	else self.vy=max(self.dy-0.03,-1.7) end
	if self.y<lstg.world.b-32 then Del(self) end
	if self.attract>=8 then self.collected=true end
end
function item:colli(other)
	if IsPlayer(other) then
		if self.class.collect then 
			self.class.collect(self,other) 
			RunSystem("on_collect_item",self,other)
		end
		Kill(self)
		PlaySound('item00',0.3,self.x/200)
	end
	IsPlayerEnd()
end

function GetPower(v)
	local before=int(lstg.var.power/100)
	lstg.var.power=min(400,lstg.var.power+v)
	local after=int(lstg.var.power/100)
	if after>before then PlaySound('powerup1',0.5) end
	if lstg.var.power>=400 then
		lstg.var.score=lstg.var.score+v*100
	end
--    if lstg.var.power==500 then
--        for i,o in ObjList(GROUP_ITEM) do
--            if o.class==item_power or o.class==item_power_large then
--                o.class=item_faith
--                o.img='item5'
--                o.imgup='item_up5'
--                New(bubble,'parimg12',o.x,o.y,16,0.5,1,Color(0xFF00FF00),Color(0x0000FF00),LAYER_ITEM+50)
--            end
--        end
--    end
end

function Getlife(v)
	lstg.var.chip=lstg.var.chip+v
	if lstg.var.chip>=100 then
		lstg.var.chip=lstg.var.chip-100
		lstg.var.lifeleft=lstg.var.lifeleft+1
		PlaySound('extend',0.5)
		New(hinter,'hint.extend',0.6,0,112,15,120)
	end
end

function Getbomb(v)
	lstg.var.bombchip=lstg.var.bombchip+v
	if lstg.var.bombchip>=100 then
		lstg.var.bomb=lstg.var.bomb+1
		lstg.var.bombchip=lstg.var.bombchip-100
		PlaySound('cardget',0.8)
	end
end

function Getpsy(p,v)--自机活使用
	local slot=GetCurrentPlayerSlot(p)
	
	lstg.var.psychic[slot]=max(0,lstg.var.psychic[slot]+v)
	
	local maxpsy=p.maxpsy*p.psyuse
	local expsy=p.expsy*p.psyuse
	if lstg.var.psychic[slot]>maxpsy and p.death==0 then
		lstg.var.expsychic[slot]=lstg.var.expsychic[slot]+(lstg.var.psychic[slot]-maxpsy)
	end
	
	lstg.var.psychic[slot]=max(0,min(lstg.var.psychic[slot],maxpsy))
	lstg.var.expsychic[slot]=max(0,min(lstg.var.expsychic[slot],expsy))
end
function Clearpsy(p)
	local slot=GetCurrentPlayerSlot(p)
	lstg.var.psychic[slot]=0
	lstg.var.expsychic[slot]=0
end

item_power=Class(item)
function item_power:init(x,y,v,a)
	item.init(self,x,y,1,v,a)
end
function item_power:oldcollect()
	Getlife(0.3)
end
function item_power:collect(other)--自机活使用
	Getpsy(other,POWERMINOR)
end

item_power_large=Class(item)
function item_power_large:init(x,y,v,a)
	item.init(self,x,y,6,v,a)
end
function item_power_large:oldcollect()
	GetPower(100)
end
function item_power_large:collect(other)--自机活使用
	Getpsy(other,100*POWERMINOR)
end

item_power_full=Class(item)
function item_power_full:init(x,y)
	item.init(self,x,y,4)
end
function item_power_full:oldcollect()
	GetPower(400)
end
function item_power_full:collect(other)--自机活使用
	Getpsy(other,32768)
end

item_extend=Class(item)
function item_extend:init(x,y)
	item.init(self,x,y,7)
end
function item_extend:collect()
	lstg.var.lifeleft=lstg.var.lifeleft+1
	PlaySound('extend',0.5)
	New(hinter,'hint.extend',0.6,0,112,15,120)
end

item_chip=Class(item)
function item_chip:init(x,y)
	item.init(self,x,y,3)
end
function item_chip:collect()
	Getlife(20)
end

----------------------------
item_bombchip=Class(item)
function item_bombchip:init(x,y)
	item.init(self,x,y,9)
end
function item_bombchip:collect()
	Getbomb(20)
end

item_bomb=Class(item)
function item_bomb:init(x,y)
	item.init(self,x,y,10)
end
function item_bomb:collect()
	lstg.var.bomb=lstg.var.bomb+1
	PlaySound('cardget',0.8)
end

----------------------------
item_faith=Class(item)
function item_faith:init(x,y)
	item.init(self,x,y,5)
end
function item_faith:collect()
	Getbomb(0.6)
end

item_faith_minor=Class(object)
function item_faith_minor:init(x,y)
	self.x=x self.y=y
	self.img='item8'
	self.group=GROUP_ITEM
	self.layer=LAYER_ITEM
	if not BoxCheck(self,lstg.world.l,lstg.world.r,lstg.world.b,lstg.world.t) then RawDel(self) end
	self.vx=ran:Float(-0.15,0.15)
	self._vy=ran:Float(3.25,3.75)
	self.flag=1
	self.attract=0
	self.bound=false
	self.is_minor=true
	self.target=jstg.players[ex._item1%#jstg.players+1]
	ex._item1=ex._item1+1
end
function item_faith_minor:frame()
	local player=self.target
	if player.death>80 and player.death<90 then
		self.flag=0
		self.attract=0
	end
	if self.timer<45 then
		self.vy=self._vy-self._vy*self.timer/45
	end
	if self.timer>=54 and self.flag==1 then
		SetV(self,8,Angle(self,player))
	end
	if self.timer>=54 and self.flag==0 then
		if self.attract>0 then
			local a=Angle(self,player)
			self.vx=self.attract*cos(a)+player.dx*0.5
			self.vy=self.attract*sin(a)+player.dy*0.5
		else
			self.vy=max(self.dy-0.03,-2.5)
			self.vx=0
		end
		if self.y<lstg.world.b-32 then Del(self) end
	end
	if Dist(self,player)<10 then
		PlaySound('item00',0.3,self.x/200)
		lstg.var.faith=lstg.var.faith+4
		Del(self)
	end
end
function item_faith_minor:collect()
	local var=lstg.var
	var.faith=var.faith+4
	var.score=var.score+500
end
function item_faith_minor:colli(other)
	item.colli(self,other)
end

item_faith_minor=Class(object)--自机活使用
function item_faith_minor:init(x,y)
	self.x=x
	self.y=y
	self.img='item8'
	self.a,self.b,self.rect=8,8,false
	self.group=GROUP_ITEM
	self.layer=LAYER_ITEM
	--if not BoxCheck(self,lstg.world.l,lstg.world.r,lstg.world.b,lstg.world.t) then RawDel(self) end
	self.vx=ran:Float(-0.15,0.15)
	local ranvy=ran:Float(3.25,3.75)
	self.vy=ranvy
	self.ay=-ranvy/45
	self.attract=0
	self.bound=false
	self.is_minor=true
	self.target=jstg.players[ex._item1%#jstg.players+1]
	ex._item1=ex._item1+1
end
function item_faith_minor:frame()
	local player=self.target
	if self.timer==45 then
		self.ay=0
	end
	if self.timer>=54 then
		SetV(self,8,Angle(self,player))
	end
end
function item_faith_minor:colli(other)
	if IsPlayer(other) then
		item_faith_minor.collect(self,other)
		PlaySound('item00',0.3,self.x/200)
		Del(self)
	end
	IsPlayerEnd()
end
function item_faith_minor:collect(other)
	local slot=GetCurrentPlayerSlot(other)
	local var=lstg.var
	--自适应出字位置和方向
	local w=lstg.world
	local x,y,v,a=self.x+32,self.y+8,2,60
	if x>(w.r-16) then
		x,a=self.x-32,120
	end
	if y>(w.t-24) then
		y,a=self.y-8,-a
	end
	if self.attract==8 then
		New(float_text,'item',int(var.pointrates[slot]/1000)*10,x,y,v,a,15,0.6,0.6,Color(0x80FFFF00),Color(0x00FFFF00))
		var.score=var.score+int(var.pointrates[slot]/1000)*10
	else
		New(float_text,'item',int(var.pointrates[slot]/2000)*10,x,y,v,a,15,0.6,0.6,Color(0x80FFFFFF),Color(0x00FFFFFF))
		var.score=var.score+int(var.pointrates[slot]/2000)*10
	end
end

item_point=Class(item)
function item_point:init(x,y)
	item.init(self,x,y,2)
end
function item_point:collect(other)
	local slot=GetCurrentPlayerSlot(other)
	local var=lstg.var
	--自适应出字位置和方向
	local w=lstg.world
	local x,y,v,a=self.x+32,self.y+8,1,60
	if x>(w.r-16) then
		x,a=self.x-32,120
	end
	if y>(w.t-24) then
		y,a=self.y-8,-a
	end
	if self.attract==8 then
		New(float_text,'item',var.pointrates[slot],x,y,v,a,30,0.6,0.6,Color(0x80FFFF00),Color(0x00FFFF00))
		var.score=var.score+var.pointrates[slot]
	else
		New(float_text,'item',int(var.pointrates[slot]/20)*10,x,y,v,a,30,0.6,0.6,Color(0x80FFFFFF),Color(0x00FFFFFF))
		var.score=var.score+int(var.pointrates[slot]/20)*10
	end
end

function item.oldDropItem(x,y,drop)
	local m
	if lstg.var.power==400 then
		m = drop[1]
	elseif drop[1] >= 400 then
		m = drop[1]
	else
		m = drop[1] / 100 + drop[1] % 100
	end
	local n=m+drop[2]+drop[3]
	if n<1 then return end
	local r=sqrt(n-1)*5
	if drop[1] >= 400 then
		local r2=sqrt(ran:Float(1,4))*r
		local a=ran:Float(0,360)
		New(item_power_full,x+r2*cos(a),y+r2*sin(a))
	else
		drop[4] = drop[1] / 100
		drop[1] = drop[1] % 100
		for i=1,drop[4] do
			local r2=sqrt(ran:Float(1,4))*r
			local a=ran:Float(0,360)
			New(item_power_large,x+r2*cos(a),y+r2*sin(a))
		end
		for i=1,drop[1] do
			local r2=sqrt(ran:Float(1,4))*r
			local a=ran:Float(0,360)
			New(item_power,x+r2*cos(a),y+r2*sin(a))
		end
	end
	for i=1,drop[2] do
		local r2=sqrt(ran:Float(1,4))*r
		local a=ran:Float(0,360)
		New(item_faith,x+r2*cos(a),y+r2*sin(a))
	end
	for i=1,drop[3] do
		local r2=sqrt(ran:Float(1,4))*r
		local a=ran:Float(0,360)
		New(item_point,x+r2*cos(a),y+r2*sin(a))
	end
end

function item.DropItem(x,y,drop)--自机活使用
	local m
	if lstg.var.power==400 then
		m = drop[1]
	elseif drop[1] >= 400 then
		m = drop[1]
	else
		m = drop[1] / 100 + drop[1] % 100
	end
	local n=m+drop[2]+drop[3]
	if n<1 then return end
	local r=sqrt(n-1)*5
	if drop[1] >= 400 then
		local r2=sqrt(ran:Float(1,4))*r
		local a=ran:Float(0,360)
		New(item_power_full,x+r2*cos(a),y+r2*sin(a))
	else
		drop[4] = drop[1] / 100
		drop[1] = drop[1] % 100
		for i=1,drop[4] do
			local r2=sqrt(ran:Float(1,4))*r
			local a=ran:Float(0,360)
			New(item_power_large,x+r2*cos(a),y+r2*sin(a))
		end
		for i=1,drop[1] do
			local r2=sqrt(ran:Float(1,4))*r
			local a=ran:Float(0,360)
			New(item_power,x+r2*cos(a),y+r2*sin(a))
		end
	end
	--[=[
	for i=1,drop[2] do
		local r2=sqrt(ran:Float(1,4))*r
		local a=ran:Float(0,360)
		New(item_faith,x+r2*cos(a),y+r2*sin(a))
	end
	--]=]
	for i=1,drop[3] do
		local r2=sqrt(ran:Float(1,4))*r
		local a=ran:Float(0,360)
		New(item_point,x+r2*cos(a),y+r2*sin(a))
	end
end

item.sc_bonus_max=2000000
item.sc_bonus_base=1000000

function item:oldStartChipBonus()
	self.chip_bonus=true
	self.bombchip_bonus=true
end

function item:oldEndChipBonus(x,y)
	if self.chip_bonus and self.bombchip_bonus then
			New(item_chip,x-20,y)
			New(item_bombchip,x+20,y)
	else
		if self.chip_bonus then New(item_chip,x,y) end
		if self.bombchip_bonus then New(item_bombchip,x,y) end
	end
end

function item:StartChipBonus()--自机活使用
end

function item:EndChipBonus(x,y)--自机活使用
end

------------------------------------------
function item.oldPlayerInit()
	lstg.var.power=100
	lstg.var.lifeleft=2
	lstg.var.bomb=2
	lstg.var.bonusflag=0
	lstg.var.chip=0
	lstg.var.faith=0
	lstg.var.graze=0
	lstg.var.score=0
	lstg.var.bombchip=0
	lstg.var.coun_num=0
	lstg.var.pointrate=item.PointRateFunc(lstg.var)
	lstg.var.collectitem={0,0,0,0,0,0}
	lstg.var.itembar={0,0,0}
	lstg.var.block_spell=false
	lstg.var.chip_bonus=false
	lstg.var.bombchip_bonus=false
	lstg.var.init_player_data=true
end

function item.PlayerInit()--自机活使用
	lstg.var.power=400
	lstg.var.lifeleft=0
	lstg.var.bomb=0
	lstg.var.graze=0
	lstg.var.score=0
	lstg.var.coun_num=0
	lstg.var.block_spell=false
	lstg.var.init_player_data=true
	
	lstg.var.grazes={0,0,0,0}
	local rate=item.PointRateFunc(lstg.var)
	lstg.var.pointrate=rate
	lstg.var.pointrates={rate,rate,rate,rate}
	lstg.var.psychic={400,400,400,400}
	lstg.var.expsychic={0,0,0,0}
end

function item.oldPlayerReinit()
	lstg.var.power=400
	lstg.var.lifeleft=2
	lstg.var.chip=0
	lstg.var.bomb=2
	lstg.var.bomb_chip=0
	lstg.var.block_spell=false
	lstg.var.init_player_data=true
	lstg.var.coun_num=min(9,lstg.var.coun_num+1)
	lstg.var.score=lstg.var.coun_num
end

function item.PlayerReinit()--自机活使用
	lstg.var.power=400
	lstg.var.lifeleft=0
	lstg.var.bomb=0
	lstg.var.graze=0
	lstg.var.block_spell=false
	lstg.var.init_player_data=true
	lstg.var.coun_num=min(9,lstg.var.coun_num+1)
	lstg.var.score=lstg.var.coun_num
	
	lstg.var.grazes={0,0,0,0}
	local rate=item.PointRateFunc(lstg.var)
	lstg.var.pointrate=rate
	lstg.var.pointrates={rate,rate,rate,rate}
	lstg.var.psychic={400,400,400,400}
	lstg.var.expsychic={0,0,0,0}
end

------------------------------------------
--HZC的收点系统
function item.playercollect(n)
	New(tasker,function()
		local z=0
		local Z=0
		local var=lstg.var
		local f=nil
		local maxpri=-1
		for i,o in ObjList(GROUP_ITEM) do
			if o.attract>=8 and not o.collecting and not o.is_minor then
				local dx=player.x-o.x
				local dy=player.y-o.y
				local pri=abs(dy)/(abs(dx)+0.01)
				if pri>maxpri then maxpri=pri f=o end
				o.collecting=true
			end
		end
		for i=1,300 do
			if not(IsValid(f)) then break end
			task.Wait(1)
		end
		z=lstg.var.collectitem[n]
		local x=player.x
		local y=player.y
		if z>=0 and z<40 then Z=1.0
		elseif z<60 then Z=1.5
		elseif z<80 then Z=2.4
		elseif z<100 then Z=3.6
		elseif z<120 then Z=5.0
		elseif z>=120 then Z=8.0 end
		if z>=5 and z<20 then
			task.Wait(15)
			New(float_text2,'bonus','NO BONUS',x,y+60,0,90,120,0.5,0.5,Color(0xF0B0B0B0),Color(0x00B0B0B0))
		elseif z>=20 and z<40 then
			PlaySound('pin00',0.8)
			task.Wait(15)
			New(float_text2,'bonus',string.format('BONUS',Z),x,y+70,0,120,120,0.5,0.5,Color(0xFF29E8E8),Color(0x0029E8E8))
			New(float_text2,'bonus',string.format('%d X %.1f',z*20,Z),x,y+60,0,120,120,0.5,0.5,Color(0xFF29E8E8),Color(0x0029E8E8))
			var.faith=var.faith+Z*z*20
		elseif z>=40 and z<60 then
			PlaySound('pin00',0.8)
			task.Wait(15)
			New(float_text2,'bonus',string.format('BONUS',Z),x,y+70,0,120,120,0.5,0.5,Color(0xFF29E8E8),Color(0x0029E8E8))
			New(float_text2,'bonus',string.format('%d X %.1f',z*20,Z),x,y+60,0,120,120,0.5,0.5,Color(0xFF29E8E8),Color(0x0029E8E8))
			var.faith=var.faith+Z*z*20
		elseif z>=60 and z<80 then
			PlaySound('pin00',0.8)
			task.Wait(15)
			New(float_text2,'bonus',string.format('BONUS',Z),x,y+70,0,120,120,0.5,0.5,Color(0xFF44FFA1),Color(0x0044FFA1))
			New(float_text2,'bonus',string.format('%d X %.1f',z*20,Z),x,y+60,0,120,120,0.5,0.5,Color(0xFF44EEA1),Color(0x0044EEA1))
			var.faith=var.faith+Z*z*20
		elseif z>=80 and z<100 then
			PlaySound('pin00',0.8)
			task.Wait(15)
			New(float_text2,'bonus',string.format('BONUS',Z),x,y+70,0,120,120,0.5,0.5,Color(0xFF44FFA1),Color(0x0044FFA1))
			New(float_text2,'bonus',string.format('%d X %.1f',z*20,Z),x,y+60,0,120,120,0.5,0.5,Color(0xFF44FFA1),Color(0x0044FFA1))
			var.faith=var.faith+Z*z*20
		elseif z>=100 and z<120 then
			PlaySound('pin00',0.8)
			task.Wait(15)
			New(float_text2,'bonus',string.format('BONUS',Z),x,y+70,0,120,120,0.5,0.5,Color(0xFFFFFF00),Color(0x00FFFF00))
			New(float_text2,'bonus',string.format('%d X %.1f',z*20,Z),x,y+60,0,120,120,0.5,0.5,Color(0xFFFFFF00),Color(0x00FFFF00))
			var.faith=var.faith+Z*z*20
		elseif z>=120 then
			PlaySound('pin00',0.8)
			task.Wait(15)
			New(float_text2,'bonus',string.format('BONUS',Z),x,y+70,0,120,120,0.5,0.5,Color(0xFFFF4422),Color(0x00FF4422))
			New(float_text2,'bonus',string.format('%d X %.1f',z*20,Z),x,y+60,0,120,120,0.5,0.5,Color(0xFFFF4422),Color(0x00FF4422))
			var.faith=var.faith+Z*z*20
		end
		lstg.var.collectitem[n]=0
	end)

end

-----------------------------
function item:PlayerMiss()
	lstg.var.chip_bonus=false
	if lstg.var.sc_bonus then lstg.var.sc_bonus=0 end
	ex.ClearBonus(true,false)
	self.protect=360
	lstg.var.lifeleft=lstg.var.lifeleft-1
	lstg.var.bomb=max(lstg.var.bomb,2)
end

function item.PlayerSpell()
	if lstg.var.sc_bonus then lstg.var.sc_bonus=0 end
	ex.ClearBonus(false,true)
	lstg.var.bombchip_bonus=false
end

function item.oldPlayerGraze()
	lstg.var.graze=lstg.var.graze+1
end

function item.oldPointRateFunc(var)
	local r=10000+int(var.graze/10)*10+int(lstg.var.faith/10)*10
	return r
end

function item.PointRateFunc(var,p)--自机活使用
	if p then
		local slot=GetCurrentPlayerSlot(p)
		local expsy=p.expsy*p.psyuse
		local r=(10000+int(var.grazes[slot]/10)*10)*(1.0+3.0*(var.expsychic[slot]/expsy))
		return r
	else
		local r=(10000+int(var.graze/10)*10)*1.0
		return r
	end
end

------------------------------------------
--自机活使用
function item.PlayerDeath(p)--玩家疮痍
	p.protect=360
	lstg.var.lifeleft=lstg.var.lifeleft-1
end

function item.PlayerBreak(p)--玩家中弹后超过决死判定
	local slot=GetCurrentPlayerSlot(p)
	if lstg.var.sc_bonus then lstg.var.sc_bonus=0 end
	ex.ClearBonus(true,false)
	
	local shoulduse=p.psyuse*(2^p._breaktimes)
	if lstg.var.psychic[slot]>=p.psyuse then
		--还有灵力
		p.death=0
		--无敌时间只能为整数，否正行走图闪烁有问题
		--无敌时间最好不小于0
		p.protect=int(360*max(0,(min(lstg.var.psychic[slot],shoulduse)/shoulduse)))--先判断无敌时间
		Getpsy(p,-shoulduse)--再扣除
	else
		--灵力不足
		Clearpsy(p)
		item.PlayerDeath(p)
	end
end

function item.PlayerPsy(p)--玩家灵击
	local slot=GetCurrentPlayerSlot(p)
	if lstg.var.sc_bonus then lstg.var.sc_bonus=0 end
	ex.ClearBonus(false,true)
	Getpsy(p,-p.psyuse)--灵击消耗
end

function item.PlayerCanPsy(p)--判断玩家是否可以灵击
	return lstg.var.psychic[GetCurrentPlayerSlot(p)]>=p.psyuse
end

function item.PlayerStruck(p)--中弹
	--只要中弹就清空溢出值
	local slot=GetCurrentPlayerSlot(p)
	lstg.var.expsychic[slot]=0
end

function item.PlayerGraze(p)--自机活擦弹
	local slot=GetCurrentPlayerSlot(p)
	lstg.var.grazes[slot]=lstg.var.grazes[slot]+1
	lstg.var.graze=lstg.var.graze+1
end
