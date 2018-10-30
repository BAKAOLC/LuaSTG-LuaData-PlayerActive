LoadTexture('boss','THlib\\enemy\\boss.png')
LoadImageGroup('bossring1','boss',80,0,16,8,1,16)
for i=1,16 do SetImageState('bossring1'..i,'mul+add',Color(0x80FFFFFF)) end
LoadImageGroup('bossring2','boss',48,0,16,8,1,16)
for i=1,16 do SetImageState('bossring2'..i,'mul+add',Color(0x80FFFFFF)) end
LoadImage('spell_card_ef','boss',96,0,16,128)
LoadImage('hpbar','boss',116,0,8,128)
--LoadImage('hpbar1','boss',116,0,2,2)
LoadImage('hpbar2','boss',116,0,2,2)
SetImageCenter('hpbar',0,0)
LoadTexture('undefined','THlib\\enemy\\undefined.png')
LoadImage('undefined','undefined',0,0,128,128,16,16)
SetImageState('undefined','mul+add',Color(0x80FFFFFF))
LoadImageFromFile('base_hp','THlib\\enemy\\ring00.png')
SetImageState('base_hp','',Color(0xFFFF0000))
LoadTexture('lifebar','Thlib\\enemy\\lifebar.png')
LoadImage('life_node','lifebar',20,0,12,16)
LoadImage('hpbar1','lifebar',4,0,2,2)
SetImageState('hpbar1','',Color(0xFFFFFFFF))
SetImageState('hpbar2','',Color(0x77D5CFFF))
LoadTexture('magicsquare','THlib\\enemy\\eff_magicsquare.png')
LoadImageGroup('boss_aura_3D','magicsquare',0,0,256,256,5,5)
LoadImageFromFile('dialog_box','THlib\\enemy\\dialog_box.png')
boss=Class(enemybase)

function boss:init(x,y,name,cards,bg,dif)
	enemybase.init(self,999999999)
	self.x=x
	self.y=y
	self.img='undefined'
	--self.ani_intv=8
	--self.lr=1
	--self.cast=0
	self.aura_alpha=255
	self.aura_alpha_d=4
	self.aura_scale=1--by OLC
	self.cards=cards
	self.card_num=0
	self.dmg_factor=0
	self.ui=New(boss_ui,self)
	self.ui.name=name or ''
	self.last_card=1
	self.ui.sc_left=0
	--self.cast_t=0
	self.sc_pro=0
	self.lifepoint=160
	self.hp_flag=0
	self.sp_point={}
	self.sc_bonus_max=item.sc_bonus_max
	self.sc_bonus_base=item.sc_bonus_base
	self.spell_get=false
	self.spell_timeout=false
	self.spell_damage=0
	
	if self.ex then
		self.ex.lifes={}
		self.ex.lifesmax={}
		self.ex.modes={}
		self.ex.cards={}
		self.ex.cardcount=0
		self.ex.nextcard=0
		self.ex.status=0 --0 空闲 1--符卡中
		self.ex.timer=0
		self.ex.taskself=self
	end
	
	self.difficulty=dif
	if self.difficulty==nil then self.difficulty='All' end
	for i,c in pairs(cards) do
		if c.is_combat then self.last_card=i end
		if c.is_sc then self.ui.sc_left=self.ui.sc_left+1 end
	end
	self.bg=bg
	lstg.tmpvar.boss=self
	
	ex.AddBoss(self)
	
--	if self.class.bgm ~= "" then
--		LoadMusicRecord(self.class.bgm)
--		_play_music(self.class.bgm)
--	end
	if self.ex==nil then
		Kill(self) -- open the first spell card. (= =|||)
	end
	
	self._wisys = BossWalkImageSystem(self)--by OLC，行走图系统
end

function boss:frame()
	--enemybase.frame(self)
	self.hp=max(0,self.hp)
	if self.ex then
		self.ex.timer=self.ex.timer+1
		if self.ex.status==1 then
			if self.ex.finish==1 then
				self.hp=0
			end
			self.ex.lifes[self.ex.nextcard]=self.hp
		end
		self.ex.finish=0
		task.Do(self.ex)
	end
	SetAttr(self,'colli',BoxCheck(self,lstg.world.boundl,lstg.world.boundr,lstg.world.boundb,lstg.world.boundt) and self._colli)
	if self.hp<=0 then
		if self.ex then
			if not(self.killed) then
				Kill(self)
			end
		elseif self.card_num==self.last_card and not(self.no_killeff) and not(self.killed) then
			boss.explode(self)
		else
			if not(self.killed) then
				Kill(self)
			end
		end
	end
	task.Do(self)
	--by OLC，行走图系统
	if self.img4 then
		self._wisys.mode = 4
	elseif self.img3 then
		self._wisys.mode = 3
	elseif self.img2 then
		self._wisys.mode = 2
	elseif self.img1 then
		self._wisys.mode = 1
	else
		self._wisys.mode = 0
	end
	self._wisys:frame()
	if self.dmgt then self.dmgt = max(0, self.dmgt - 1) end
	if self.sc_pro>0 then self.sc_pro=self.sc_pro-1 end
	if abs(self.x)<lstg.world.r then self.ui.pointer_x=self.x else self.ui.pointer_x=nil end--适配宽屏
	self.aura_alpha=self.aura_alpha+self.aura_alpha_d
	self.aura_alpha=min(max(0,self.aura_alpha),128)
	
	local c=self.cards[self.card_num]
	if self.ex then
		if self.ex.status==1 then
			c=self.ex.cards[self.ex.nextcard]
		end
	end
	
	
	--if self.cards[self.card_num] then
	if c then
		--local c=self.cards[self.card_num]
		c.frame(self)
		if player.nextspell>0 and self.timer<=0 then
			self.sc_pro=player.nextspell
		end
		--不再生效
		--if self.timer<self.sc_pro then
		--	self.dmg_factor=0.1
		--end
		self.timeout=0
		if self.timer<c.t1 then
			self.dmg_factor=0
		elseif self.sc_pro>0 then--by OLC，修复开卡前bomb的boss高防
			self.dmg_factor=0.1
		elseif self.timer<c.t2 then
			self.dmg_factor=(self.timer-c.t1)/(c.t2-c.t1)
		elseif self.timer<c.t3 then
			self.dmg_factor=1
		else 
			self.hp=0
			self.timeout=1
		end--Kill(self) end
		if c.is_extra and lstg.player.nextspell>0 then self.dmg_factor=0 end
		if c.t1==c.t3 then self.dmg_factor=0 end
		if c.t1==c.t3 then self.time_sc=true else self.time_sc=false end
		if self.sc_bonus and self.sc_bonus>0 and c.t1~=c.t3 and not(self.killed) then self.sc_bonus=self.sc_bonus-(self.sc_bonus_max-self.sc_bonus_base)/c.t3 end
		self.ui.hpbarlen=self.hp/self.maxhp
		self.ui.countdown=(c.t3-self.timer)/60
		---
		
		local players=Players(self)
		local _flag=false
		for i=1,#players do
			if IsValid(players[i]) and Dist(players[i],self)<=70 then
				self.hp_flag=self.hp_flag+1
				_flag=true
			end
		end
		if not _flag then 
			self.hp_flag=self.hp_flag-1
		end
		--if IsValid(lstg.player) and Dist(lstg.player,self)<=70 then
		--	self.hp_flag=self.hp_flag+1
		--else
		--	self.hp_flag=self.hp_flag-1
		--end
		self.hp_flag=min(max(0,self.hp_flag),18)
		---
		if self.bg then
			if c.is_sc then self.bg.alpha=min(1,self.bg.alpha+0.025) else self.bg.alpha=max(0,self.bg.alpha-0.025) end
			if lstg.tmpvar.bg then
				if self.bg.alpha==1 then lstg.tmpvar.bg.hide=true else lstg.tmpvar.bg.hide=false end
			end
		end
	end
	
end


function boss:prepareSpellCards(cardlist)
	if self.ex==nil then return end
	local a=self.ex
	while self.ex.status==1 do
		task.Wait(1)
	end
	self.ex.lifes={}
	self.ex.lifesmax={}
	self.ex.modes={}
	self.ex.cards={}
	self.ex.timer=0
	for i,v in pairs(cardlist) do
		local c=ex.GetCardObject(v)
		a.cards[i]=c
		a.lifes[i]=c.hp
		a.lifesmax[i]=c.hp
		if c.is_sc or c.fake then
			a.modes[i]=1
		else
			a.modes[i]=0
		end
	end
	a.nextcard=#cardlist
	a.cardcount=#cardlist
end

function boss:finishSpell(b)
	if self.ex==nil then return end
	if self.ex.status==1 then
		if b then
			self.life=0
		end
		self.life=0
		Kill(self)
		task.Wait(1)
	end
end

function boss:finishSpellC(b)
	if self.ex==nil then return end
	if self.ex.status==1 then
		self.ex.finish=1
	end
end


function boss:castSpell(spellname,waitforend)
	if self.ex==nil then return end
	while self.ex.status==1 do
		task.Wait(1)
	end
	
	local a=self.ex
	local c=0
	if spellname==nil then
		c=a.cards[a.nextcard]
	else 
		c=ex.GetCardObject(spellname)
	end
	if #a.cards==0 or a.nextcard==0 then   --you have no card left in your hand, get one 
		boss.prepareSpellCards(self,{spellname})
	end
	
	if a.cards[a.nextcard] ~= c then   --you are using another card to replace your next prepared card
		local i=a.nextcard
		a.cards[i]=c
		a.lifes[i]=c.hp
		a.lifesmax[i]=c.hp
		if c.is_sc then
			a.modes[i]=1
		else
			a.modes[i]=0
		end
	end
	
	a.status=1
	boss._castcard(self,c)
	if waitforend then
		while a.status==1 do
			task.Wait(1)
		end
	end
end



--extracted
function boss:explode(a)
	if a then
		self.killed=true
		self.no_killeff=true
		task.Clear(self)
		if self.ex then task.Clear(self.ex) end
		PlaySound("enep01",0.5,self.x/256)
		self.colli=false
		self.hp=0
		self.lr= 28
		task.New(self,function()
			local angle=ran:Float(10,20)
			self.vx=0.3*cos(angle) self.vy=0.3*sin(angle)
			New(bullet_cleaner,self.x,self.y, 1500, 120, 60, true, true, 0)
			for i=1,120 do
				self.hp=0
				self.timer=self.timer-1
				local lifetime=ran:Int(60,90)
				local l=ran:Float(200,500)
				New(boss_death_ef_unit,self.x,self.y,l/lifetime,ran:Float(0,360),lifetime,ran:Float(2,3))
				task.Wait(1)
			end
			
			PlaySound("enep01",0.5,self.x/256)
			New(deatheff,self.x,self.y,'first')
			New(deatheff,self.x,self.y,'second')
			
			Kill(self)
		end)
	else
		Kill(self)
	end
end


function boss:render()
--	SetImageState('boss_aura','mul+add',Color(self.aura_alpha,255,255,255))
--	Render('boss_aura',self.x,self.y,self.ani*5,1.8+0.4*sin(self.ani*2.5))
	for i=1,25 do SetImageState('boss_aura_3D'..i,'mul+add',Color(self.aura_alpha,255,255,255)) end
	Render('boss_aura_3D'..self.ani%25+1,self.x,self.y,self.ani*0.75,0.92*self.aura_scale,(0.8+0.12*cos(self.ani*0.75))*self.aura_scale)--by OLC，允许调节魔法阵大小
	
	if self.ex then
		if self.ex.status==1 then	
			self.ex.cards[self.ex.nextcard].render(self)
		end
	end
	
	--if self.cards[self.card_num] then
	--	self.cards[self.card_num].render(self)
	--end
	if self.current_card then--by OLC，新增current_card
		self.current_card.render(self)
	end
	
	--[=[
	if self.img1 then
		if self._blend then
			SetImageState(self.img,self._blend,Color(self._a,self._r,self._g,self._b))
		else
			SetImageState(self.img,'mul+alpha',Color(255,255,255,255))	
		end
		Render(self.img,self.x,self.y+sin(self.ani*4)*4,self.rot,self.hscale,self.vscale)
	else
	if self._blend then
			SetImageState('undefined',self._blend,Color(self._a,self._r,self._g,self._b))
		else
			SetImageState('undefined','mul+add',Color(0x80FFFFFF))		
		end
		Render('undefined',self.x+cos( self.ani*6+180)*3,self.y+sin( self.ani*6+180)*3, self.ani*10)
		Render('undefined',self.x+cos(-self.ani*6+180)*3,self.y+sin(-self.ani*6+180)*3,-self.ani*10)
		Render('undefined',self.x+cos( self.ani*6)*3,self.y+sin( self.ani*6)*3, self.ani*20)
		Render('undefined',self.x+cos(-self.ani*6)*3,self.y+sin(-self.ani*6)*3,-self.ani*20)
	end
	]=]
	
	self._wisys:render(self.dmgt, self.dmgmaxt)--by OLC，行走图系统
end

function boss:take_damage(dmg)
	if self.dmgmaxt then self.dmgt = self.dmgmaxt end
	if not self.protect then
		local dmg0=dmg*self.dmg_factor
		self.spell_damage=self.spell_damage+dmg0
		self.hp=self.hp-dmg0
		lstg.var.score=lstg.var.score+10
	end
end

function boss:PopSpellResult(c)
	if c.is_combat then
		self.spell_get=false
		if (self.hp<=0 and self.timeout==0) or (c.t1==c.t3 and self.timeout==1) then
			if c.drop then item.DropItem(self.x,self.y,c.drop) end
			item.EndChipBonus(self,self.x,self.y)
			if self.sc_bonus and not c.fake then
				if self.sc_bonus>0 then
					lstg.var.score=lstg.var.score+self.sc_bonus-self.sc_bonus%10
					PlaySound('cardget',1.0,0)
					New(hinter_bonus,'hint.getbonus',0.6,0,112,15,120,true,self.sc_bonus-self.sc_bonus%10)
					New(kill_timer,0,30,self.timer)
					if not ext.replay.IsReplay() then
						scoredata.spell_card_hist[lstg.var.player_name][self.difficulty][c.name][1]=scoredata.spell_card_hist[lstg.var.player_name][self.difficulty][c.name][1]+1
					end
					self.spell_get=true

				else
					New(hinter,'hint.bonusfail',0.6,0,112,15,120)
					New(kill_timer,0,60,self.timer)
				end
			end
		else
			if c.is_sc and self.timeout==1 then PlaySound('fault',1.0,0) end
			if self.sc_bonus then New(hinter,'hint.bonusfail',0.6,0,112,15,120,15) end
		end
		self.spell_timeout=(self.timeout==1)
		if self.no_clear_buller then--OLC加的新flag，可以控制结束符卡后是否需要清除子弹
			self.no_clear_buller = nil
		else
			PlaySound('enep02',0.4,0)
			local players=Players()
			Print("Clear ",#players)
			for _,p in pairs(players) do
				New(bullet_killer,p.x,p.y,true)
			end
		end
		--New(bullet_killer,lstg.player.x,lstg.player.y,true)
	end
	if c.is_sc then self.ui.sc_left=self.ui.sc_left-1 end
end




function boss:kill()
	_kill_servants(self)
	self.sp_point={}
	
	if self.ex then
		if self.ex.status==1 then
			local c=self.ex.cards[self.ex.nextcard]
			self.ex.lifes[self.ex.nextcard]=0
			self.ex.nextcard=self.ex.nextcard-1
			c.del(self)
			boss.PopSpellResult(self,c)
			PreserveObject(self)
			self.hp=9999
			task.Clear(self)
			self.ex.status=0
		else 
			task.Clear(self.ex)
			if self.ui then Del(self.ui) end
			if self.bg then Del(self.bg) self.bg=nil end
			if self.dialog_displayer then Del(self.dialog_displayer) end
			if lstg.tmpvar.bg then lstg.tmpvar.bg.hide=false end
			if self.class.defeat then self.class.defeat(self) end
			ex.RemoveBoss(self)
		end
		return
	end
	
	--if self.cards[self.card_num] then
	if self.current_card then--OLC，新增current_card
		--local c=self.cards[self.card_num]
		local c=self.current_card
		c.del(self)
		boss.PopSpellResult(self,c)
		if self.card_num==self.last_card then
			if self.cards[#self.cards].is_move then
				PlaySound('enep01',0.4,0)
			else
				New(boss_death_ef,self.x,self.y)
				self.hide=true
				self.colli=false
			end
		end
	end
	self.card_num=self.card_num+1
	if self.cards[self.card_num] then
		local c=self.cards[self.card_num]
		--------------------1-----------------
		local ccc=nil
		local cc=nil
		--[=[
		local number=self.card_num
		if self.cards[number+1] and not(self.cards[number+1].is_combat) and number~=self.last_card then
			number=number+1
		end
		ccc=self.cards[number+1]
		number=self.card_num
		if self.cards[number-1] then
			if not(self.cards[number-1].is_combat) then
				number=number-1
			end
			cc=self.cards[number-1]
		end
		]=]
		--by OLC，修复了非符、符卡前有多个动作时血条不完整的问题
		for i = self.card_num + 1, #self.cards do
			if self.cards[i] and self.cards[i].is_combat then
				ccc = self.cards[i]
				break
			end
		end
		for i = self.card_num - 1, 1, -1 do
			if self.cards[i] and self.cards[i].is_combat then
				cc = self.cards[i]
				break
			end
		end
		-----------------------2------------------
		if c.is_sc then
			if cc and cc.is_sc then
				self.ui.hpbarcolor1=Color(0xFFFF8080)
				self.ui.hpbarcolor2=nil
			elseif cc and not(cc.is_sc) then
				self.ui.hpbarcolor1=Color(0xFFFF8080)
				self.ui.hpbarcolor2=Color(0xFFFF8080)
			elseif not(cc) then
				self.ui.hpbarcolor1=Color(0xFFFF8080)
				self.ui.hpbarcolor2=nil
			end
			if not c.fake then
				self.sc_bonus=self.sc_bonus_max
			end
		--	self.ui.hpbarcolor=Color(0xFFFF8080)
			New(spell_card_ef)
			PlaySound('cat00',0.5)
			if scoredata.spell_card_hist==nil then scoredata.spell_card_hist={} end
			if scoredata.spell_card_hist[lstg.var.player_name]==nil then scoredata.spell_card_hist[lstg.var.player_name]={} end
			if scoredata.spell_card_hist[lstg.var.player_name][self.difficulty]==nil then scoredata.spell_card_hist[lstg.var.player_name][self.difficulty]={} end
			if scoredata.spell_card_hist[lstg.var.player_name][self.difficulty][c.name]==nil then scoredata.spell_card_hist[lstg.var.player_name][self.difficulty][c.name]={0,0} end
			if not ext.replay.IsReplay() then
				scoredata.spell_card_hist[lstg.var.player_name][self.difficulty][c.name][2]=scoredata.spell_card_hist[lstg.var.player_name][self.difficulty][c.name][2]+1
			end
			self.ui.sc_hist=scoredata.spell_card_hist[lstg.var.player_name][self.difficulty][c.name]
		elseif not(c.is_sc)  and ccc and ccc.is_sc then
			if not c.fake then
				self.sc_bonus=nil
			end
			
			self.ui.hpbarcolor1=Color(0xFFFF8080)
			self.ui.hpbarcolor2=Color(0xFFFFFFFF)
		elseif not(c.is_sc)  and ccc and not(ccc.is_sc) and ccc.is_combat then
			if not c.fake then
				self.sc_bonus=nil
			end
			self.ui.hpbarcolor1=nil
			self.ui.hpbarcolor2=Color(0xFFFFFFFF)
		else
			if not c.fake then
				self.sc_bonus=nil
			end
		end
--		else
--			self.sc_bonus=nil
--			self.ui.hpbarcolor=Color(0xFFFFFFFF)
--		end
		if c.is_combat then 
		item.StartChipBonus(self) 
		self.spell_damage=0
		end
		if c.name~='' then self.ui.sc_name=c.name end
		self.ui.countdown=c.t3/60
		self.ui.is_combat=c.is_combat
		task.Clear(self.ui)
		task.Clear(self)
		self.current_card=self.cards[self.card_num]--by OLC，新增current_card
		c.init(self)
		self.timer=-1
		self.hp=c.hp
		self.maxhp=c.hp
		self.dmg_factor=0
		PreserveObject(self)
	else
		if self.ui then Del(self.ui) end
		if self.bg then Del(self.bg) self.bg=nil end
		if self.dialog_displayer then Del(self.dialog_displayer) end
		if lstg.tmpvar.bg then lstg.tmpvar.bg.hide=false end
		if self.class.defeat then self.class.defeat(self) end
		ex.RemoveBoss(self)
	end
end

function boss:_castcard(c)
	if c.is_sc then	
		if not c.fake then
			self.sc_bonus=self.sc_bonus_max
		end
		
	--	self.ui.hpbarcolor=Color(0xFFFF8080)
		New(spell_card_ef)
		PlaySound('cat00',0.5)
		if scoredata.spell_card_hist==nil then scoredata.spell_card_hist={} end
		if scoredata.spell_card_hist[lstg.var.player_name]==nil then scoredata.spell_card_hist[lstg.var.player_name]={} end
		if scoredata.spell_card_hist[lstg.var.player_name][self.difficulty]==nil then scoredata.spell_card_hist[lstg.var.player_name][self.difficulty]={} end
		if scoredata.spell_card_hist[lstg.var.player_name][self.difficulty][c.name]==nil then scoredata.spell_card_hist[lstg.var.player_name][self.difficulty][c.name]={0,0} end
		if not ext.replay.IsReplay() then
			scoredata.spell_card_hist[lstg.var.player_name][self.difficulty][c.name][2]=scoredata.spell_card_hist[lstg.var.player_name][self.difficulty][c.name][2]+1
		end
		self.ui.sc_hist=scoredata.spell_card_hist[lstg.var.player_name][self.difficulty][c.name]
	else
		if not c.fake then
			self.sc_bonus=nil
		end
	end
	if c.is_combat 
	then 
	item.StartChipBonus(self) 
	self.spell_damage=0
	end
	if c.name~='' then self.ui.sc_name=c.name end
	self.ui.countdown=c.t3/60
	self.ui.is_combat=c.is_combat
	task.Clear(self.ui)
	task.Clear(self)
	c.init(self)
	self.timer=-1
	self.hp=c.hp
	self.maxhp=c.hp
	self.dmg_factor=0

	PreserveObject(self)
end


function boss:del()
	if self.ex then 
		task.Clear(self.ex)
	end
	if self.ui then Del(self.ui) end
	if self.bg then Del(self.bg) self.bg=nil end
	if self.dialog_displayer then Del(self.dialog_displayer) end
	if lstg.tmpvar.bg then lstg.tmpvar.bg.hide=false end
	ex.RemoveBoss(self)
end

function boss.MoveTowardsPlayer(t)
	local dirx,diry
	local self=task.GetSelf()
	local p=Player(self)
	if self.x>64 then dirx=-1 elseif self.x<-64 then dirx=1
	else
		--if self.x>lstg.player.x then dirx=-1 else dirx=1 end
		if self.x>p.x then dirx=-1 else dirx=1 end
	end
	if self.y>144 then diry=-1 elseif self.y<128 then diry=1 else diry=ran:Sign() end
	--local dx=max(16,min(abs((self.x-lstg.player.x)*0.3),32))
	local dx=max(16,min(abs((self.x-p.x)*0.3),32))
	task.MoveTo(self.x+ran:Float(dx,dx*2)*dirx,self.y+diry*ran:Float(16,32),t)
end

function boss:show_aura(show)
	if show then self.aura_alpha_d=4 else self.aura_alpha_d=-4 end
end

function boss:cast(cast_t)
	self.cast_t=cast_t+0.5
	self.cast=1
end

boss.card={}
function boss.card.New(name,t1,t2,t3,hp,drop,is_extra)
	local c={}
	c.frame=boss.card.frame
	c.render=boss.card.render
	c.init=boss.card.init
	c.del=boss.card.del
	c.name=tostring(name)
	if t1>t2 or t2>t3 then error('t1<t2<t3 must be satisfied.') end
	c.t1=int(t1)*60
	c.t2=int(t2)*60
	c.t3=int(t3)*60
	c.hp=hp
	c.is_sc=(name~='')
	c.drop=drop
	c.is_extra=is_extra or false
	c.is_combat=true
	return c
end
function boss.card:frame() end
function boss.card:render()
	local last=_boss
	_boss=self
	--local c=self.cards[self.card_num]
	local c=self.current_card--by OLC，新增current_card
	if c and c.is_sc and c.t1~=c.t3 then
		for i=1,16 do SetImageState('bossring1'..i,'mul+add',Color(self.aura_alpha,255,255,255)) end
		if self.timer<90 then
			if _boss.fxr and _boss.fxg and _boss.fxb then
				local of=1-self.timer/180
				for i=1,16 do SetImageState('bossring2'..i,'mul+add',Color(1.9*self.aura_alpha,_boss.fxr*of,_boss.fxg*of,_boss.fxb*of)) end
			else
				for i=1,16 do SetImageState('bossring2'..i,'mul+add',Color(self.aura_alpha,255,255,255)) end
			end
			misc.RenderRing('bossring1',self.x,self.y,self.timer*2+270*sin(self.timer*2),self.timer*2+270*sin(self.timer*2)+16, self.ani*3,32,16)
			misc.RenderRing('bossring2',self.x,self.y,90+self.timer*1,-180+self.timer*4-16,-self.ani*3,32,16)
		else
			if _boss.fxr and _boss.fxg and _boss.fxb then
				for i=1,16 do SetImageState('bossring2'..i,'mul+add',Color(1.9*self.aura_alpha,_boss.fxr/2,_boss.fxg/2,_boss.fxb/2)) end
			else
				for i=1,16 do SetImageState('bossring2'..i,'mul+add',Color(self.aura_alpha,255,255,255)) end
			end
			local t=self.current_card.t3--self.cards[self.card_num].t3
			misc.RenderRing('bossring1',self.x,self.y,(t-self.timer)/(t-90)*180,(t-self.timer)/(t-90)*180+16, self.ani*3,32,16)
			misc.RenderRing('bossring2',self.x,self.y,(t-self.timer)/(t-90)*180,(t-self.timer)/(t-90)*180-16,-self.ani*3,32,16)
		end
	end
	_boss=last
end
function boss.card:init() end
function boss.card:del() end

boss.dialog={}

function boss.dialog.New(can_skip)
	local c={}
	c.frame=boss.dialog.frame
	c.render=boss.dialog.render
	c.init=boss.dialog.init
	c.del=boss.dialog.del
	c.name=''
	c.t1=999999999
	c.t2=999999999
	c.t3=999999999
	c.hp=999999999
	c.is_sc=false
	c.is_extra=false
	c.is_combat=false
	_dialog_can_skip=can_skip
	return c
end

function boss.dialog:frame()
	if self.task and coroutine.status(self.task[1])=='dead' then Kill(self) end
end
function boss.dialog:render() end
function boss.dialog:init()
	lstg.player.dialog=true
	self.dialog_displayer=New(dialog_displayer)
end
function boss.dialog:del()
	lstg.player.dialog=false
	Del(self.dialog_displayer)
	self.dialog_displayer=nil
end

function boss.dialog:sentence(img,pos,text,t,hscale,vscale)
	if pos=='left' then pos=1 else pos=-1 end
	self.dialog_displayer.text=text
	self.dialog_displayer.char[pos]=img
	if self.dialog_displayer.active~=pos then
		self.dialog_displayer.active=pos
		self.dialog_displayer.t=16
	end
	self.dialog_displayer._hscale[pos]=hscale or pos
	self.dialog_displayer._vscale[pos]=vscale or 1
	task.Wait()
	t=t or (60+#text*5)
	for i=1,t do
		if (KeyIsPressed'shoot' or self.dialog_displayer.jump_dialog>60) and _dialog_can_skip then
			PlaySound('plst00',0.35,0,true)
			break
		end
		task.Wait()
	end
	task.Wait(2)
end
-------------
dialog_displayer=Class(object)
function dialog_displayer:init()
	self.layer=LAYER_TOP
	self.char={}
	self._hscale={}
	self._vscale={}
	self.t=16
	self.death=0
	self.co=0
	self.jump_dialog=0
end
function dialog_displayer:frame()
	task.Do(self)
	if self.t>0 then self.t=self.t-1 end
	if self.active then
	self.co=max(min(60,self.co+1.5*self.active),-60)
	end
	if player.dialog==true and self.active then
		if KeyIsDown'shoot' then self.jump_dialog=self.jump_dialog+1 else self.jump_dialog=0 end
	end
end
function dialog_displayer:render()
	if self.active then
		SetViewMode'ui'
			if self.char[-self.active] then
				SetImageState(self.char[-self.active],'',Color(0xFF404040)+(  self.t/16)*Color(0xFFC0C0C0)-(self.death/30)*Color(0xFF000000))
				local t=(1-self.t/16)^3
				Render(self.char[-self.active],224+self.active*(-(1-2*t)*16+128)+self.death*self.active*12,240-65-t*16-25,0,self._hscale[-self.active],self._vscale[-self.active])
			end
			if self.char[self.active] then
				SetImageState(self.char[ self.active],'',Color(0xFF404040)+(1-self.t/16)*Color(0xFFC0C0C0)-(self.death/30)*Color(0xFF000000))
				local t=(  self.t/16)^3
				Render(self.char[ self.active],224+self.active*( (1-2*t)*16-128)-self.death*self.active*12,240-65-t*16-25,0,self._hscale[self.active],self._vscale[self.active])
			end
		SetViewMode'world'
	end
	if self.text and self.active then
		---SetImageState('white','',Color(0xC0000000))
		local kx,ky1,ky2,dx,dy1,dy2
			kx=168
			ky1=-210
			ky2=-90
			dx=160
			dy1=-144
			dy2=-126
			SetImageState('dialog_box','',Color(225,195-self.co,150,195+self.co))
			Render('dialog_box',0,-144-self.death*8)
			RenderTTF('dialog',self.text,-dx,dx,dy1-self.death*8,dy2-self.death*8,Color(0xFF000000),'paragraph')
			if self.active>0 then
				RenderTTF('dialog',self.text,-dx,dx,dy1-self.death*8,dy2-self.death*8,Color(255,255,200,200),'paragraph')
			else
				RenderTTF('dialog',self.text,-dx,dx,dy1-self.death*8,dy2-self.death*8,Color(255,200,200,255),'paragraph')
			end
	end
end
function dialog_displayer:del()
	PreserveObject(self)
	task.New(self,function()
		for i=1,30 do
			self.death=i
			task.Wait()
		end
		RawDel(self)
	end)
end
----------------------------------------
--[[
dialog_displayer=Class(object)
function dialog_displayer:init()
	self.layer=LAYER_TOP
	self.char={}
	self.t=16
	self.death=0
end
function dialog_displayer:frame()
	task.Do(self)
	if self.t>0 then self.t=self.t-1 end
end
function dialog_displayer:render()
	if self.active then
		if self.char[-self.active] then
			SetImageState(self.char[-self.active],'',Color(0xFF404040)+(  self.t/16)*Color(0xFFC0C0C0))
			local t=(1-self.t/16)^3
			Render(self.char[-self.active],self.active*(-(1-2*t)*16+128)+self.death*self.active*8,-65-t*16,0,-self.active,1)
		end
		if self.char[self.active] then
			SetImageState(self.char[ self.active],'',Color(0xFF404040)+(1-self.t/16)*Color(0xFFC0C0C0))
			local t=(  self.t/16)^3
			Render(self.char[ self.active],self.active*( (1-2*t)*16-128)-self.death*self.active*8,-65-t*16,0, self.active,1)
		end
	end
	if self.text then
		SetImageState('white','',Color(0xC0000000))
		RenderRect('white',-176,176,-176-self.death*8,-128-self.death*8)
		RenderTTF('dialog',self.text,-167,169,-179-self.death*8,-137-self.death*8,Color(0xFF000000),'paragraph')
		if self.active>0 then
			RenderTTF('dialog',self.text,-168,168,-178-self.death*8,-136-self.death*8,Color(0xFFA0FFFF),'paragraph')
		else
			RenderTTF('dialog',self.text,-168,168,-178-self.death*8,-136-self.death*8,Color(0xFFFFA0A0),'paragraph')
		end
	end
end
function dialog_displayer:del()
	PreserveObject(self)
	task.New(self,function()
		for i=1,30 do
			self.death=i
			task.Wait()
		end
		RawDel(self)
	end)
end
]]
boss.move={}

function boss.move.New(x,y,t,m)
	local c={}
	c.frame=boss.move.frame
	c.render=boss.move.render
	c.init=boss.move.init
	c.del=boss.move.del
	c.name=''
	c.t1=999999999
	c.t2=999999999
	c.t3=999999999
	c.hp=999999999
	c.is_sc=false
	c.is_extra=false
	c.is_combat=false
	c.is_move=true
	c.x=x c.y=y c.t=t c.m=m
	return c
end
function boss.move:frame() end
function boss.move:render() end
function boss.move:init()
	local c=self.current_card--self.cards[self.card_num]
	task.New(self,function()
		task.MoveTo(c.x,c.y,c.t,c.m)
		Kill(self)
	end)
end
function boss.move:del() end

boss.escape={}

function boss.escape.New(x,y,t,m)
	local c={}
	c.frame=boss.escape.frame
	c.render=boss.escape.render
	c.init=boss.escape.init
	c.del=boss.escape.del
	c.name=''
	c.t1=999999999
	c.t2=999999999
	c.t3=999999999
	c.hp=999999999
	c.is_sc=false
	c.is_extra=false
	c.is_combat=false
	c.is_escape=true
	c.x=x c.y=y c.t=t c.m=m
	return c
end
function boss.escape:frame() end
function boss.escape:render() end
function boss.escape:init()
	local c=self.current_card--self.cards[self.card_num]
	task.New(self,function()
		task.MoveTo(c.x,c.y,c.t,c.m)
		Kill(self)
	end)
end
function boss.escape:del() end

boss_ui=Class(object)

boss_ui.active_count=0

function boss:SetUIDisplay(hp,name,cd,spell,pos,pointer)
	self.ui.drawhp=hp
	self.ui.drawname=name
	self.ui.drawtime=cd
	self.ui.drawspell=spell
	self.ui.needposition=pos
	self.ui.drawpointer=pointer or 1
end


function boss_ui:init(b)
	self.layer=LAYER_TOP
	self.group=GROUP_GHOST
	self.boss=b
	self.sc_name=''
	self.drawhp=1
	self.drawname=1
	self.drawtime=1
	self.drawspell=1
	self.needposition=1
	self.drawpointer=1
	--b.ex={}
	--test_ex(b.ex)
	if b.class.sc_image then self.sc_image = New(b.class.sc_image) end
end

function test_ex(ex)
	ex.lifes={300,100,400}
	ex.lifesmax={300,100,700}
	ex.modes={0,1,0}
end


function boss_ui:render()
	local yn=boss_ui.active_count
	local dy1=yn*36
	local dy2=yn*44
	if self.needposition then
	boss_ui.active_count=boss_ui.active_count+1
	end
	
	SetViewMode'world'
	local _dy=0
	local alpha1=1-self.boss.hp_flag/30
	
	
	--SetImageState('base_hp','',Color(alpha1*255,255,0,0))
	SetImageState('base_hp','',Color(alpha1*255,255,0,0))
	SetImageState('hpbar1','',Color(alpha1*255,255,255,255))
	SetImageState('hpbar2','',Color(0,255,255,255))
	SetImageState('life_node','',Color(alpha1*255,255,255,255))
	if self.boss.ex then
		if self.boss.ex.cardcount and self.drawhp then	
			boss_ui.render_hpbar_ex(self)
		end
	end
--	RenderText('bonus',self.ex.status,0,207,0.5,'right')
	if self.is_combat then
		if self.hpbarlen or self.boss.ex then
			if not(self.boss.time_sc) and self.drawhp then
				if self.boss.ex then
					--if self.boss.ex.cardcount then	
					--	boss_ui.render_hpbar_ex(self)
					--end
				elseif not(self.hpbarcolor2) then  --  sp-'sp'
					misc.Renderhpbar(self.boss.x,self.boss.y,90,360,60,64,360,1)
					misc.Renderhp(self.boss.x,self.boss.y,90,360,60,64,360,self.hpbarlen*min(1,self.boss.timer/60))
					Render('base_hp',self.boss.x,self.boss.y,0,0.274,0.274)
					Render('base_hp',self.boss.x,self.boss.y,0,0.256,0.256)
					if self.boss.sp_point and #self.boss.sp_point~=0 then
						for i=1,#self.boss.sp_point do
							Render('life_node',self.boss.x+61*cos(self.boss.sp_point[i]),self.boss.y+61*sin(self.boss.sp_point[i]),self.boss.sp_point[i]-90,0.5)
						end
					end
				elseif not(self.hpbarcolor1) then  --'non'-non
					misc.Renderhpbar(self.boss.x,self.boss.y,90,360,60,64,360,1)
					misc.Renderhp(self.boss.x,self.boss.y,90,360,60,64,360,self.hpbarlen*min(1,self.boss.timer/60))
					Render('base_hp',self.boss.x,self.boss.y,0,0.274,0.274)
					Render('base_hp',self.boss.x,self.boss.y,0,0.256,0.256)
				elseif self.hpbarcolor1==self.hpbarcolor2 then  --non-'sp'
					misc.Renderhpbar(self.boss.x,self.boss.y,90,360,60,64,360,1)
					misc.Renderhp(self.boss.x,self.boss.y,90,self.boss.lifepoint-90,60,64,self.boss.lifepoint-88,self.hpbarlen)
					Render('base_hp',self.boss.x,self.boss.y,0,0.274,0.274)
					Render('base_hp',self.boss.x,self.boss.y,0,0.256,0.256)
				elseif self.hpbarcolor1~=self.hpbarcolor2 then  --'non'-sp
					misc.Renderhpbar(self.boss.x,self.boss.y,90,360,60,64,360,1)
					if self.boss.timer<=60 then
						misc.Renderhp(self.boss.x,self.boss.y,90,360,60,64,360,self.hpbarlen*min(1,self.boss.timer/60))
					else
						misc.Renderhp(self.boss.x,self.boss.y,90,self.boss.lifepoint-90,60,64,self.boss.lifepoint-88,1)
						misc.Renderhp(self.boss.x,self.boss.y,self.boss.lifepoint,450-self.boss.lifepoint,60,64,450-self.boss.lifepoint,self.hpbarlen)
					end
					Render('base_hp',self.boss.x,self.boss.y,0,0.274,0.274)
					Render('base_hp',self.boss.x,self.boss.y,0,0.256,0.256)
					Render('life_node',self.boss.x+61*cos(self.boss.lifepoint),self.boss.y+61*sin(self.boss.lifepoint),self.boss.lifepoint-90,0.55)
					SetFontState('bonus','',Color(255,255,255,255))
				end
				if self.boss.show_hp then
				SetFontState('bonus','',Color(255,0,0,0))
				RenderText('bonus',int(max(0,self.boss.hp))..'/'..self.boss.maxhp,self.boss.x-1,self.boss.y-40-1,0.6,'centerpoint')
				SetFontState('bonus','',Color(255,255,255,255))
				RenderText('bonus',int(max(0,self.boss.hp))..'/'..self.boss.maxhp,self.boss.x,self.boss.y-40,0.6,'centerpoint')
				end
			end
		---------------------------
			if self.drawname then
				RenderTTF('boss_name',self.name,-185,-185,222-dy1,222-dy1,Color(0xFF000000),'noclip')
				RenderTTF('boss_name',self.name,-186,-186,223-dy1,223-dy1,Color(0xFF80FF80),'noclip')
			local m = int((self.sc_left-1)/8)
				if m >= 0 then
					for i=0,m-1 do
						for j=1,8 do
							Render('boss_sc_left',-194+j*12,207-i*12-dy1,0,0.5)
						end
					end
					for i=1,int(self.sc_left-1-8*m) do
						Render('boss_sc_left',-194+i*12,207-m*12-dy1,0,0.5)
					end
				end
			end
		end
	end
	if self.pointer_x and self.drawpointer then
		SetViewMode'ui'
		Render('boss_pointer',WorldToScreen(max(min(self.pointer_x,lstg.world.r-24),lstg.world.l+24),lstg.world.b+16))--适配宽屏
		SetViewMode'world'
	end
	
	if self.boss.ex then
		if self.boss.ex.status==0 then	
			return 
		end
	end
	
	--local ax,ay=0,0
--	if IsValid(lstg.player) then
--		ax=min(max(lstg.player.x*0.05,0),0.9)
--		ay=min(max((lstg.player.y-160)*0.05,0),0.9)
--	end
--	local alpha=1-ax*ay
	
	local axy=0
	for _,p in pairs(Players(self)) do
		local ax,ay=0,0
		if IsValid(p) then
			ax=min(max(p.x*0.05,0),0.9)
			ay=min(max((p.y-160)*0.05,0),0.9)
		end
		if ax*ay>axy then axy=ax*ay end
	end
	local alpha=1-axy
	SetFontState('time','',Color(alpha*255,255,255,255))
	local xoffset=384
	if self.boss.sc_bonus then xoffset=max(384-self.boss.timer*7,0) else xoffset=min(384,(self.boss.timer+1)*7) end
	if self.drawspell then
		if self.sc_name~='' then
			SetImageState('boss_spell_name_bg','',Color(alpha*255,255,255,255))
			Render('boss_spell_name_bg',192+xoffset,236-dy2)
			RenderTTF('sc_name',self.sc_name,193+xoffset,193+xoffset,226-dy2,226-dy2,Color(alpha*255,0,0,0),'right','noclip')
			RenderTTF('sc_name',self.sc_name,192+xoffset,192+xoffset,227-dy2,227-dy2,Color(alpha*255,255,255,255),'right','noclip')
		end

		if self.boss.sc_bonus and self.sc_hist then
			local b
			if self.boss.sc_bonus>0 then b=string.format('%.0f',self.boss.sc_bonus-self.boss.sc_bonus%10) else b='FAILED ' end
			SetFontState('bonus','',Color(alpha*255,0,0,0))
			RenderText('bonus',b,187+xoffset,207-dy2,0.5,'right')
			RenderText('bonus',string.format('%d/%d',self.sc_hist[1],self.sc_hist[2]),97+xoffset,207-dy2,0.5,'right')
			RenderText('bonus','HISTORY       BONUS',137+xoffset,207-dy2,0.5,'right')
			SetFontState('bonus','',Color(alpha*255,255,255,255))
			RenderText('bonus',b,186+xoffset,208-dy2,0.5,'right')
			RenderText('bonus',string.format('%d/%d',self.sc_hist[1],self.sc_hist[2]),96+xoffset,208-dy2,0.5,'right')
			RenderText('bonus','HISTORY       BONUS',136+xoffset,208-dy2,0.5,'right')
		end	
	end
	if self.is_combat and self.drawtime then
		local cd=(self.countdown-int(self.countdown))*100
		local yoffset
		if self.boss.sc_bonus then yoffset=max(20-self.boss.timer,0) else yoffset=min(20,(self.boss.timer+1)) end
		if self.countdown>=10.0 then
		--	RenderText('score',string.format('%.2f',min(99.99,self.countdown)),0,188,0.5,'centerpoint')
--			SetFontState('time','',Color(alpha1*255,0,0,0))
--			RenderText('time',string.format('%d',min(180.99,int(self.countdown))),0,193+yoffset+_dy,0.5,'centerpoint')
--			RenderText('time','            .'..string.format('%d%d',min(9,cd/10),min(9,cd%10)),0,190+yoffset+_dy,0.3,'centerpoint')
			SetFontState('time','',Color(alpha1*255,255,255,255))
			RenderText('time',string.format('%d',int(self.countdown)),4,192+yoffset+_dy-dy2,0.5,'vcenter','right')
			RenderText('time','.'..string.format('%d%d',min(9,cd/10),min(9,cd%10)),4,189+yoffset+_dy-dy2,0.3,'vcenter','left')
		else
--			SetFontState('time','',Color(alpha1*255,0,0,0))
--			RenderText('time',string.format('0%d',min(99.99,int(self.countdown))),0,193+yoffset+_dy,0.5,'centerpoint')
--			RenderText('time','            .'..string.format('%d%d',min(9,cd/10),min(9,cd%10)),0,190+yoffset+_dy,0.3,'centerpoint')
			SetFontState('time','',Color(alpha1*255,255,30,30))
			RenderText('time',string.format('0%d',min(99.99,int(self.countdown))),4,192+yoffset+_dy-dy2,0.5,'vcenter','right')
			RenderText('time','.'..string.format('%d%d',min(9,cd/10),min(9,cd%10)),4,189+yoffset+_dy-dy2,0.3,'vcenter','left')
		end
	end
end

function boss_ui:render_hpbar_ex()
	SetViewMode'world'
	
	local alpha1=1-self.boss.hp_flag/30
	
	local ex=self.boss.ex
	if ex==nil then	return end
	local lifes=ex.lifes
	local lifesmax=ex.lifesmax
	local modes=ex.modes
	local rate=min(1,self.boss.ex.timer/60)
	
	SetImageState('base_hp','',Color(alpha1*255,255,0,0))
	SetImageState('hpbar1','',Color(alpha1*255,255,100,100))
	SetImageState('hpbar2','',Color(alpha1*255,255,255,255))
	SetImageState('life_node','',Color(alpha1*255,255,255,255))
	local maxlife=0
	local life=0
	for i, z in ipairs(lifesmax) do
	   maxlife=maxlife+z
	end
	for i, z in ipairs(lifes) do
	   life=life+z
	end
	life=min(maxlife*rate,life)

	local start=90
	local startlife=0
	local stop=90
	
	local ddy=0
	--RenderText('bonus',ex.cardcount,0,0,0.5,'right')
	
	for i, z in ipairs(lifesmax) do
		stop=90+360*(startlife+z)/maxlife
		if life>startlife then	
			local d=life-startlife
			local r=min(d/z,1)
			
			--RenderText('bonus',d,187,207-ddy,0.5,'right')
			--RenderText('bonus',z,187,207-ddy-20,0.5,'right')
			--ddy=ddy+50
			
			 if modes[i]==0 then
				 misc.Renderhpbar(self.boss.x,self.boss.y,start,stop-start,60,64,int(stop-start),r)
			 else
				 misc.Renderhp(self.boss.x,self.boss.y,start,stop-start,60,64,int(stop-start),r)
			 end
			--misc.Renderhpbar(self.boss.x,self.boss.y,90,360,60,64,360,1)
			--misc.Renderhp(self.boss.x,self.boss.y,90,360,60,64,360,1)
			Render('life_node',self.boss.x+61*cos(stop),self.boss.y+61*sin(stop),stop-90,0.55)

		end
		startlife=startlife+z
		start=stop
	end
	Render('base_hp',self.boss.x,self.boss.y,0,0.274,0.274)
	Render('base_hp',self.boss.x,self.boss.y,0,0.256,0.256)
	start=90
	startlife=0
	stop=90
	
	for i, z in ipairs(lifesmax) do
		stop=90+360*(startlife+z)/maxlife
		Render('life_node',self.boss.x+61*cos(stop),self.boss.y+61*sin(stop),stop-90,0.55)
		startlife=startlife+z
		start=stop
	end


	
end


function boss_ui:frame()
	task.Do(self)
	if self.countdown then
		if self.countdown>5 and self.countdown<=10 and self.countdown%1==0 then PlaySound('timeout',0.6) end
		if self.countdown>0 and self.countdown<=5 and self.countdown%1==0 then PlaySound('timeout2',0.8) Print(self.timer) end
	end
end

function boss_ui:kill()
	Del(self.sc_image)
	boss_ui.active_count=boss_ui.active_count-1
end
boss_ui.del = boss_ui.kill

spell_card_ef=Class(object)

function spell_card_ef:init()
	self.layer=LAYER_BG+1
	self.group=GROUP_GHOST
	self.alpha=0
	task.New(self,function()
		for i=1,50 do
			task.Wait()
			self.alpha=self.alpha+0.02
		end
		task.Wait(60)
		for i=1,50 do
			task.Wait()
			self.alpha=self.alpha-0.02
		end
		Del(self)
	end)
end

function spell_card_ef:frame()
	task.Do(self)
end

function spell_card_ef:render()
	SetImageState('spell_card_ef','',Color(255*self.alpha,255,255,255))
	for j=1,10 do
		local h=(j-5.5)*32
		for i=-2,2 do
			local l=i*128+((self.timer*2)%128)*(2*(j%2)-1)
			Render('spell_card_ef',l*cos(30),l*sin(30)+h,-60)
		end
	end
end

boss_cast_ef_unit=Class(object)
function boss_cast_ef_unit:init(x,y,v,angle,lifetime,size)
	self.x=x self.y=y self.rot=ran:Float(0,360)
	SetV(self,v,angle)
	self.lifetime=lifetime
	self.omiga=5
	self.layer=LAYER_ENEMY-50
	self.group=GROUP_GHOST
	self.bound=false
	self.img='leaf'
	self.hscale=size
	self.vscale=size
end

function boss_cast_ef_unit:frame()
	if self.timer==self.lifetime then Del(self) end
end

function boss_cast_ef_unit:render()
	if self.timer>self.lifetime-15 then
		SetImageState('leaf','mul+add',Color((self.lifetime-self.timer)*12,255,255,255))
	else
		SetImageState('leaf','mul+add',Color((self.timer/(self.lifetime-15))^6*180,255,255,255))
	end
	DefaultRenderFunc(self)
end

boss_cast_ef=Class(object)
function boss_cast_ef:init(x,y)
	self.hide=true
	PlaySound('ch00',0.5,0)
	for i=1,50 do
		local angle=ran:Float(0,360)
		local lifetime=ran:Int(50,80)
		local l=ran:Float(300,500)
		New(boss_cast_ef_unit,x+l*cos(angle),y+l*sin(angle),l/lifetime,angle+180,lifetime,ran:Float(2,3))
	end
	Del(self)
end

boss_death_ef_unit=Class(object)
function boss_death_ef_unit:init(x,y,v,angle,lifetime,size)
	self.x=x self.y=y self.rot=ran:Float(0,360)
	SetV(self,v,angle)
	self.lifetime=lifetime
	self.omiga=3
	self.layer=LAYER_ENEMY+50
	self.group=GROUP_GHOST
	self.bound=false
	self.img='leaf'
	self.hscale=size
	self.vscale=size
end

function boss_death_ef_unit:frame()
	if self.timer==self.lifetime then Del(self) end
end

function boss_death_ef_unit:render()
	if self.timer<15 then
		SetImageState('leaf','mul+add',Color(self.timer*12,255,255,255))
	else
		SetImageState('leaf','mul+add',Color(((self.lifetime-self.timer)/(self.lifetime-15))*180,255,255,255))
	end
	DefaultRenderFunc(self)
end

boss_death_ef=Class(object)
function boss_death_ef:init(x,y)
	PlaySound('enep01',0.4,0)
	self.hide=true
	misc.ShakeScreen(30,15)
	for i=1,70 do
		local angle=ran:Float(0,360)
		local lifetime=ran:Int(40,120)
		local l=ran:Float(100,500)
		New(boss_death_ef_unit,x,y,l/lifetime,angle,lifetime,ran:Float(2,4))
	end
end

---------------------------render----------------------------------
function Render_RIng_4(angle,r,angle_offset,x0,y0,r_,imagename)
	local A_1 = angle+angle_offset
	local A_2 = angle-angle_offset
	local R_1 = r+r_
	local R_2 = r-r_
	local x1,x2,x3,x4,y1,y2,y3,y4
	x1=x0+(R_1)*cos(A_1)
	y1=y0+(R_1)*sin(A_1)

	x2=x0+(R_1)*cos(A_2)
	y2=y0+(R_1)*sin(A_2)

	x3=x0+(R_2)*cos(A_2)
	y3=y0+(R_2)*sin(A_2)

	x4=x0+(R_2)*cos(A_1)
	y4=y0+(R_2)*sin(A_1)
	Render4V(imagename,x1,y1,0.5,x2,y2,0.5,x3,y3,0.5,x4,y4,0.5)
end
kill_timer=Class(object)
function kill_timer:init(x,y,t)
  self.t=t
  self.x=x
  self.y=y
  self.yy=y
  self.alph=0
end
function kill_timer:frame()
  if self.timer<=30 then self.alph=self.timer/30 self.y=self.yy-30*cos(3*self.timer) end
  if self.timer>120 then self.alph=1-(self.timer-120)/30 end
  if self.timer>=150 then Del(self) end
end
function kill_timer:render()
  SetViewMode'world'
  local alpha=self.alph
  SetFontState('time','',Color(alpha*255,0,0,0))
  RenderText('time',string.format("%.2f", self.t/60)..'s',41,self.y-1,0.5,'centerpoint')
	SetFontState('time','',Color(alpha*255,200,200,200))
  RenderText('time',string.format("%.2f", self.t/60)..'s',40,self.y,0.5,'centerpoint')
  SetImageState('kill_time','',Color(alpha*255,255,255,255))
  Render('kill_time',-40,self.y-2,0.6,0.6)
end

hinter_bonus=Class(object)

function hinter_bonus:init(img,size,x,y,t1,t2,fade,bonus)
	self.img=img
	self.x=x
	self.y=y
	self.t1=t1
	self.t2=t2
	self.fade=fade
	self.group=GROUP_GHOST
	self.layer=LAYER_TOP
	self.size=size
	self.t=0
	self.hscale=self.size
	self.bonus=bonus
end

function hinter_bonus:frame()
	if self.timer<self.t1 then
		self.t=self.timer/self.t1
	elseif self.timer<self.t1+self.t2 then
		self.t=1
	elseif self.timer<self.t1*2+self.t2 then
		self.t=(self.t1*2+self.t2-self.timer)/self.t1
	else
		Del(self)
	end
end

function hinter_bonus:render()
	if self.fade then
		SetImageState(self.img,'',Color(self.t*255,255,255,255))
		self.vscale=self.size
		SetFontState('score3','',Color(self.t*255,255,255,255))
		RenderScore('score3',self.bonus,self.x+1,self.y-41,0.7,'centerpoint')
		object.render(self)
	else
		SetImageState(self.img,'',Color(0xFFFFFFFF))
		self.vscale=self.t*self.size
		SetFontState('score3','',Color(255,255,255,255))
		RenderScore('score3',self.bonus,self.x+1,self.y-41,0.7,'centerpoint')
		object.render(self)
	end
end

