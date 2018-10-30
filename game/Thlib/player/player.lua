--======================================
--player
--======================================

----------------------------------------
--加载资源

LoadPS('player_death_ef','THlib\\player\\player_death_ef.psi','parimg1')
LoadPS('graze','THlib\\player\\graze.psi','parimg6')
LoadImageFromFile('player_spell_mask','THlib\\player\\spellmask.png')

----------------------------------------
--player class

player_class=Class(object)

function player_class:init()
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
	--自机判定大小
	self.A=0
	self.B=0
	self.item=1
	self.death=0
	self.protect=120
	lstg.player=self
	player=self
	self.grazer=New(grazer,self)
	if not lstg.var.init_player_data then error('Player data has not been initialized. (Call function item.PlayerInit.)') end
	self.support=int(lstg.var.power/100)
	self.sp={}
	self.time_stop=false
	
	RunSystem("on_player_init",self)
	
	self._wisys = PlayerWalkImageSystem(self, 8)--by OLC，自机行走图系统
end

function player_class:frame()
	self.grazer.world=self.world
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
			-- self.collect_time= self.collect_time + 1
		
			-- if not(self.itemed) and not(self.collecting) then
				-- self.itemed=true
				-- self.collecting=true
-- --				lstg.var.collectitem=0
				-- self.nextcollect=15
			-- end
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
		 -----
		 else
			-- self.nextcollect=0
			-- self.collect_time=0
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
		-- if self.nextcollect<=0 and self.itemed then
			-- item.playercollect(self.item)
			-- self.item=self.item%6+1
-- --			lstg.var.collectitem=0
			-- self.itemed=false
			-- self.collecting=false
		-- end
		-- if self.collecting and not(self.itemed) then end
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
	if not(self.time_stop) then
		self._wisys:frame(dx)--by OLC，自机行走图系统
		
		self.lh=self.lh+(self.slow-0.5)*0.3
		if self.lh<0 then self.lh=0 end
		if self.lh>1 then self.lh=1 end
		
		if self.nextshoot>0 then self.nextshoot=self.nextshoot-1 end
		if self.nextspell>0 then self.nextspell=self.nextspell-1 end
		--if self.nextcollect>0 then self.nextcollect=self.nextcollect-1 end--HZC收点系统
		
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
	
	if self.key then
		KeyState=_temp_key
		KeyStatePre=_temp_keyp
	end
	
end

function player_class:render()
	self._wisys:render()--by OLC，自机行走图系统
end

function player_class:colli(other)
	if self.death==0 and not self.dialog and not cheat then
		if self.protect==0 then
			PlaySound('pldead00',0.5)
			self.death=100
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
	--self.player=lstg.player
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
		item.PlayerGraze()
		--lstg.player.grazer.grazed=true
		self.grazed=true
		other._graze=true
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

function AddPlayerToPlayerList(displayname,classname,replayname,pos,_replace)
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
