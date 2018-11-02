--======================================
--player
--======================================

----------------------------------------
--加载资源

LoadPS('player_death_ef','THlib\\player\\player_death_ef.psi','parimg1')
LoadPS('graze','THlib\\player\\graze.psi','parimg6')
LoadImageFromFile('player_spell_mask','THlib\\player\\spellmask.png')

--自机活使用
LoadTexture('pa_magicline','THlib\\player\\playermagicline.png',false)
LoadImageGroup('pa_collect_circleline','pa_magicline',256,0,64,32,1,16)

----------------------------------------
--player class

player_class=Class(object)

function player_class:init(slot)
	if not lstg.var.init_player_data then error('Player data has not been initialized. (Call function item.PlayerInit.)') end
	
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
	self.A=0
	self.B=0
	self.item=1
	self.death=0
	self.protect=120
	lstg.player=self
	player=self
	self.grazer=New(grazer,self)
	self.support=int(lstg.var.power/100)
	self.sp={}
	self.time_stop=false
	
	RunSystem("on_player_init",self)
	
	--自机活使用变量
	self.collect_line=256--失礼了。收点线？不存在的
	
	self.checkF=10--决死时间
	self.collectR1=24--高速收点半径
	self.collectR2=160--低速收点半径
	self.psyuse=100--灵力消耗
	self.maxpsy=16--最大灵力
	self.expsy=8--灵力溢出（倍数）
	self.eyeshot=1--感知距离
	
	self._collectR=24--过渡变量
	self._lh2=0--过渡变量
	self._collectRA=0--收点圈透明度
	self._breaktimes=0--连续miss次数
	----------------
	
	--ex+坑爹输入系统
	--存下按键状态
	self._temp_key=nil
	self._temp_keyp=nil
	--输入槽位
	if slot then self.keyslot=slot end
	self._keyslot=self.keyslot--私密变量
	
	self._wisys = PlayerWalkImageSystem(self)--by OLC，自机行走图系统
end

function player_class:frame()
	player_class.keystart(self)
	
	player_class.framefunc(self)
	
	player_class.keyend(self)
end

function player_class:oldframefunc()
	self.grazer.world=self.world
	--find target
	if ((not IsValid(self.target)) or (not self.target.colli)) then player_class.findtarget(self) end
	if not KeyIsDown'shoot' then self.target=nil end
	--all op
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
		
		for i=1,#jstg.worlds do
			if IsInWorld(self.world,jstg.worlds[i].world) then
				self.x=math.max(math.min(self.x,jstg.worlds[i].pr-8),jstg.worlds[i].pl+8)
				self.y=math.max(math.min(self.y,jstg.worlds[i].pt-32),jstg.worlds[i].pb+16)
			end
		end
		
		end
		--fire
		if KeyIsDown'shoot' and not self.dialog then self.fire=self.fire+0.16 else self.fire=self.fire-0.16 end
		if self.fire<0 then self.fire=0 end
		if self.fire>1 then self.fire=1 end
		--item
		 if self.y>self.collect_line then
			for i,o in ObjList(GROUP_ITEM) do 
				local flag=false
				if o.attract<8 then
					flag=true			
				elseif o.attract==8 and o.target~=self then
					if (not o.target) or o.target.y<self.y then
						flag=true
					end
				end
				if flag then
					o.attract=8 o.num=self.item 
					o.target=self
				end
			end
		 else
			if KeyIsDown'slow' then
				for i,o in ObjList(GROUP_ITEM) do
					if Dist(self,o)<48 then
						if o.attract<3 then
							o.attract=max(o.attract,3) 
							o.target=self
						end	
					end
				end
			else
				for i,o in ObjList(GROUP_ITEM) do
					if Dist(self,o)<24 then 
						if o.attract<3 then
							o.attract=max(o.attract,3) 
							o.target=self
						end	
					end
				end
			end
		end
	elseif self.death==90 then
		if self.time_stop then self.death=self.death-1 end
		item.PlayerMiss(self)
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
	if not(self._wisys) then
		self._wisys=PlayerWalkImageSystem(self)
	end
	if not(self.time_stop) then
		self._wisys:frame(dx)--by OLC，自机行走图系统
		
		self.lh=self.lh+(self.slow-0.5)*0.3
		if self.lh<0 then self.lh=0 end
		if self.lh>1 then self.lh=1 end
		
		if self.nextshoot>0 then self.nextshoot=self.nextshoot-1 end
		if self.nextspell>0 then self.nextspell=self.nextspell-1 end
		
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
	end
	--time_stop
	if self.time_stop then self.timer=self.timer-1 end
	
	RunSystem("on_player_frame",self)
end

function player_class:framefunc()--自机活使用
	self.grazer.world=self.world
	--find target
	if ((not IsValid(self.target)) or (not self.target.colli)) then player_class.findtarget(self) end
	if not KeyIsDown'shoot' then self.target=nil end
	--
	local dx=0
	local dy=0
	local v=self.hspeed
	if (self.death==0 or self.death>90) and (not self.lock) and not(self.time_stop) then
		--slow
		if KeyIsDown'slow' then
			self.slow=1
		else
			self.slow=0
		end
		--shoot and spell
		if not self.dialog then
			if KeyIsDown'shoot' and self.nextshoot<=0 then
				self.class.shoot(self)
			end
			if KeyIsDown'spell' and self.nextspell<=0 and not lstg.var.block_spell and item.PlayerCanPsy(self) then
				item.PlayerPsy(self)--item.PlayerSpell()
				self.class.spell(self)
				self.death=0
				self.nextcollect=90--???
				self._breaktimes=0--连续miss次数
			end
		else
			self.nextshoot=15
			self.nextspell=30
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
		
		for i=1,#jstg.worlds do
			if IsInWorld(self.world,jstg.worlds[i].world) then
				self.x=math.max(math.min(self.x,jstg.worlds[i].pr-8),jstg.worlds[i].pl+8)
				self.y=math.max(math.min(self.y,jstg.worlds[i].pt-32),jstg.worlds[i].pb+16)
			end
		end
		
		end
		--fire
		if KeyIsDown'shoot' and not self.dialog then self.fire=self.fire+0.16 else self.fire=self.fire-0.16 end
		if self.fire<0 then self.fire=0 end
		if self.fire>1 then self.fire=1 end
		--item
		if self.y>self.collect_line then
			for i,o in ObjList(GROUP_ITEM) do
				local flag=false
				if o.attract<8 then
					flag=true
				elseif o.attract==8 and o.target~=self then
					if (not o.target) or o.target.y<self.y then
						flag=true
					end
				end
				if flag then
					o.attract=8
					o.num=self.item
					o.target=self
				end
			end
		else
			for i,o in ObjList(GROUP_ITEM) do
				if Dist(self,o)<self._collectR then
					if o.attract<6 then
						o.attract=max(o.attract,6)
						o.target=self
					end
				end
			end
		end
	elseif self.death==90 then
		if self.time_stop then self.death=self.death-1 end
		item.PlayerBreak(self)
		self._breaktimes=min(self._breaktimes+1,3)--连续miss次数
		New(player_death_ef,self.x,self.y)
		self.deathee={}
		self.deathee[1]=New(deatheff,self.x,self.y,'first')
		self.deathee[2]=New(deatheff,self.x,self.y,'second')
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
		self._wisys:frame(dx)--by OLC，自机行走图系统
		
		self.lh=self.lh+(self.slow-0.5)*0.3
		if self.lh<0 then self.lh=0 end
		if self.lh>1 then self.lh=1 end
		
		if self.nextshoot>0 then self.nextshoot=self.nextshoot-1 end
		if self.nextspell>0 then self.nextspell=self.nextspell-1 end
		
		if self.support>int(lstg.var.power/100) then self.support=self.support-0.0625
		elseif self.support<int(lstg.var.power/100) then self.support=self.support+0.0625 end
		if abs(self.support-int(lstg.var.power/100))<0.0625 then self.support=int(lstg.var.power/100) end
		
		self.supportx=self.x+(self.supportx-self.x)*0.6875
		self.supporty=self.y+(self.supporty-self.y)*0.6875
		
		if self.protect>0 then self.protect=self.protect-1 end
		if self.death>0 then self.death=self.death-1 end
		
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
		
		--collectR
		self._lh2=self._lh2+(self.slow-0.5)*0.1
		if self._lh2<0 then self._lh2=0 end
		if self._lh2>1 then self._lh2=1 end
		local k=sin(self._lh2*90)
		self._collectRA=max(0,min(k,1))
		self._collectR=k*self.collectR2+(1-k)*self.collectR1
		
		--pointrate
		lstg.var.pointrates[GetCurrentPlayerSlot(self)]=item.PointRateFunc(lstg.var,self)
	end
	--time_stop
	if self.time_stop then self.timer=self.timer-1 end
end

function player_class:keystart()
	if self.key then
		self._temp_key=KeyState
		self._temp_keyp=KeyStatePre
		KeyState=self.key
		KeyStatePre=self.keypre
	end
end

function player_class:keyend()
	if self.key then
		KeyState=self._temp_key
		KeyStatePre=self._temp_keyp
	end
end

function player_class:render()
	self._wisys:render()--by OLC，自机行走图系统
	
	player_class.systemrender(self)--自机活使用
end

function player_class:systemrender()--自机活使用
	if self._collectRA>=0.01 then
		for i=1,16 do SetImageState('pa_collect_circleline'..i,'mul+add',Color(self._collectRA*80,255,255,255)) end
		misc.RenderRing('pa_collect_circleline',self.x,self.y,self._collectR-32,self._collectR,self.ani*2,48,16)
	end
end

function player_class:oldcolli(other)
	if self.death==0 and not self.dialog and not cheat then
		if self.protect==0 then
			PlaySound('pldead00',0.5)
			self.death=100
		end
		if other.group==GROUP_ENEMY_BULLET then Del(other) end
	end
end

function player_class:colli(other)--自机活使用
	if self.death==0 and not self.dialog and not cheat then
		if self.protect<=0 then
			PlaySound('pldead00',0.5)
			item.PlayerStruck(self)
			self.death=90+self.checkF--可以设置决死时间
		end
		if other.group==GROUP_ENEMY_BULLET then Del(other) end
	end
end

function player_class:findtarget()
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
	for i,o in ObjList(GROUP_NONTJT) do
		if o.colli then
			local dx=self.x-o.x
			local dy=self.y-o.y
			local pri=abs(dy)/(abs(dx)+0.01)
			if pri>maxpri then maxpri=pri self.target=o end
		end
	end
end

function MixTable(x,t1,t2)--子机位置表的线性插值
	r={}
	local y=1-x
	if t2 then
		for i=1,#t1 do
			r[i]=y*t1[i]+x*t2[i]
		end
		return r
	else
		local n=int(#t1/2)
		for i=1,n do
			r[i]=y*t1[i]+x*t1[i+n]
		end
		return r
	end
end


grazer=Class(object)

function grazer:init(player)
	self.layer=LAYER_ENEMY_BULLET_EF+50
	self.group=GROUP_PLAYER
	self.player=player or lstg.player
	self.grazed=false
	self.img='graze'
	ParticleStop(self)
	self.a=24
	self.b=24
	self.aura=0
end

function grazer:frame()
	self.x=self.player.x
	self.y=self.player.y
	self.hide=self.player.hide
	if not self.player.time_stop then
		self.aura=self.aura+1.5
	end
	--
	if self.grazed then
		PlaySound('graze',0.3,self.x/200)
		self.grazed=false
		ParticleFire(self)
	else
		ParticleStop(self)
	end
end

function grazer:render()
	object.render(self)
	SetImageState('player_aura','',Color(0xC0FFFFFF)*self.player.lh+Color(0x00FFFFFF)*(1-self.player.lh))
	Render('player_aura',self.x,self.y, self.aura,2-self.player.lh)
	SetImageState('player_aura','',Color(0xC0FFFFFF))
	Render('player_aura',self.x,self.y,-self.aura,self.player.lh)
end

function grazer:colli(other)
	if other.group~=GROUP_ENEMY and (not other._graze) then
		item.PlayerGraze(self.player)
		self.grazed=true
		other._graze=true
	end
end


function GetCurrentPlayerSlot(p)--获得传入的玩家的槽位，返回整数1、2等，分别代表1p、2p等--自机活使用
	if p==nil and IsValid(player) then p=player end--没有传入player时指向当前player
	if p._keyslot then
		return p._keyslot--有这个变量时直接返回
	elseif jstg.players then
		--没有keyslot时先遍历jstg.players
		for pos=1,#jstg.players do
			if IsValid(jstg.players[pos]) then
				if jstg.players[pos]==p then
					return pos
				end
			end
		end
		if #jstg.players<1 then
			return 0--没有自机的情况，比如在主菜单，异常情况，应该特别处理
		end
	else
		Print('Warning:jstg.players is non-existent.')
		return 0--异常情况，在ex+中，jstg.players一定存在，如果执行到这里说明jstg.players炸了
	end
end

----------------------------------------
--一些自机组件

player_bullet_straight=Class(object)

function player_bullet_straight:init(img,x,y,v,angle,dmg)
	self.group=GROUP_PLAYER_BULLET
	self.layer=LAYER_PLAYER_BULLET
	self.img=img
	self.x=x
	self.y=y
	self.rot=angle
	self.vx=v*cos(angle)
	self.vy=v*sin(angle)
	self.dmg=dmg
	if self.a~=self.b then self.rect=true end
end

player_bullet_hide=Class(object)

function player_bullet_hide:init(a,b,x,y,v,angle,dmg,delay)
	self.group=GROUP_PLAYER_BULLET
	self.layer=LAYER_PLAYER_BULLET
	self.colli=false
	self.a=a
	self.b=b
	self.x=x
	self.y=y
	self.rot=angle
	self.vx=v*cos(angle)
	self.vy=v*sin(angle)
	self.dmg=dmg
	self.delay=delay or 0
end

function player_bullet_hide:frame()
	if self.timer==self.delay then self.colli=true end
end

player_bullet_trail=Class(object)

function player_bullet_trail:init(img,x,y,v,angle,target,trail,dmg)
	self.group=GROUP_PLAYER_BULLET
	self.layer=LAYER_PLAYER_BULLET
	self.img=img
	self.x=x
	self.y=y
	self.rot=angle
	self.v=v
	self.target=target
	self.trail=trail
	self.dmg=dmg
end

function player_bullet_trail:frame()
	if IsValid(self.target) and self.target.colli then
		local a=math.mod(Angle(self,self.target)-self.rot+720,360)
		if a>180 then a=a-360 end
		local da=self.trail/(Dist(self,self.target)+1)
		if da>=abs(a) then self.rot=Angle(self,self.target)
		else self.rot=self.rot+sign(a)*da end
	end
	self.vx=self.v*cos(self.rot)
	self.vy=self.v*sin(self.rot)
end

player_spell_mask=Class(object)

function player_spell_mask:init(r,g,b,t1,t2,t3)
	self.x=0
	self.y=0
	self.group=GROUP_GHOST
	self.layer=LAYER_BG+1
	self.img='player_spell_mask'
	self.bcolor={['blend']='mul+add',['a']=0,['r']=r,['g']=g,['b']=b}
	task.New(self,function()
		for i=1,t1 do
			self.bcolor.a=i*255/t1
			task.Wait(1)
		end
		task.Wait(t2)
		for i=t3,1,-1 do
			self.bcolor.a=i*255/t3
			task.Wait(1)
		end
		Del(self)
	end)
end

function player_spell_mask:frame()
	task.Do(self)
end

function player_spell_mask:render()
	local w=lstg.world
	local c=self.bcolor
	SetImageState(self.img,c.blend,Color(c.a,c.r,c.g,c.b))
	RenderRect(self.img,w.l,w.r,w.b,w.t)
end

player_death_ef=Class(object)

function player_death_ef:init(x,y)
	self.x=x self.y=y self.img='player_death_ef' self.layer=LAYER_PLAYER+50
end

function player_death_ef:frame()
	if self.timer==4 then ParticleStop(self) end
	if self.timer==60 then Del(self) end
end

deatheff=Class(object)

function deatheff:init(x,y,type_)
	self.x=x
	self.y=y
	self.type=type_
	self.size=0
	self.size1=0
	self.layer=LAYER_TOP-1
	task.New(self,function()
		local size=0
		local size1=0
		if self.type=='second' then task.Wait(30) end
		for i=1,360 do
			self.size=size
			self.size1=size1
			size=size+12
			size1=size1+8
			task.Wait(1)
		end
	end)
end

function deatheff:frame()
	task.Do(self)
	if self.timer>180 then Del(self) end
end

function deatheff:render()
	--稍微减少了死亡反色圈的分割数，视觉效果基本不变，减少性能消耗（原分割数为180）
	if self.type=='first' then
		rendercircle(self.x,self.y,self.size,60)
		rendercircle(self.x+35,self.y+35,self.size1,60)
		rendercircle(self.x+35,self.y-35,self.size1,60)
		rendercircle(self.x-35,self.y+35,self.size1,60)
		rendercircle(self.x-35,self.y-35,self.size1,60)
	elseif self.type=='second' then
		rendercircle(self.x,self.y,self.size,60)
	end
end

----------------------------------------
--加载自机

player_list={
	{'Hakurei Reimu','reimu_player','Reimu'},
	{'Kirisame Marisa','marisa_player','Marisa'},
	{'Izayoi Sakuya','sakuya_player','Sakuya'},
}

function AddPlayerToPlayerList(displayname,classname,replayname,pos,_replace)--然并卵……
	if _replace then
		player_list[pos]={displayname,classname,replayname}
	elseif pos then
		table.insert(player_list,pos,{displayname,classname,replayname})
	else
		table.insert(player_list,{displayname,classname,replayname})
	end
end

Include'THlib\\player\\reimu\\reimu.lua'
Include'THlib\\player\\marisa\\marisa.lua'
Include'THlib\\player\\sakuya\\sakuya.lua'
