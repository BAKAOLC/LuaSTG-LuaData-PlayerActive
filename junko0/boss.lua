--======================================
--th style boss
--======================================

----------------------------------------
--用到的资源

LoadTexture('boss','THlib\\enemy\\boss.png')
--LoadImageGroup('bossring1','boss',80,0,16,8,1,16)
--for i=1,16 do SetImageState('bossring1'..i,'mul+add',Color(0x80FFFFFF)) end
--LoadImageGroup('bossring2','boss',48,0,16,8,1,16)
--for i=1,16 do SetImageState('bossring2'..i,'mul+add',Color(0x80FFFFFF)) end
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
LoadImageFromFile('dialog_box','THlib\\enemy\\dialog_box.png')

--自机活
LoadImageFromFile('boss_aura','THlib\\enemy\\boss_aura.png')
LoadTexture('boss_effect_par','THlib\\enemy\\boss_effect_par.png')
LoadImageGroup('boss_effect_par','boss_effect_par',0,0,64,64,4,1)
SetImageCenter("boss_effect_par2",32,64)
LoadTexture('boss_magicline','THlib\\enemy\\magicline.png')
LoadImageGroup('bossring1','boss_magicline',320,0,64,32,1,16)
LoadImageGroup('bossring2','boss_magicline',192,0,64,32,1,16)

--boss ui
DoFile('THlib\\enemy\\boss_ui.lua')

----------------------------------------
--boss

boss=Class(enemybase)

function boss:init(x,y,name,cards,bg,dif)
	--
	enemybase.init(self,999999999)
	self.x=x
	self.y=y
	self.cardlinex=x
	self.cardliney=y
	self.img='undefined'
	--boss魔法阵
	self.aura_alpha=255
	self.aura_alpha_d=4
	self.aura_scale=1--by OLC，允许调节魔法阵大小
	--boss ui
	self.ui=New(boss_ui,self)
	self.ui.name=name or ''
	self.ui.sc_left=0--会在SpellCardSystem中再初始化一次
	self.lifepoint=160--血条分割
	self.hp_flag=0--player靠近boss时ui透明度降低
	self.sp_point={}--阶段点
	--伤害相关
	self.dmg_factor=0
	self.sc_pro=0
	self.spell_damage=0
	--分数与游戏系统相关
	self.sc_bonus_max=item.sc_bonus_max
	self.sc_bonus_base=item.sc_bonus_base
	self.spell_get=false
	self.spell_timeout=false
	self.difficulty=dif or 'All'
	--boss卡背
	self.bg=bg
	--boss移动、对话、非符、符卡
	self.timeout=0--全避
	self._cardsys=SpellCardSystem(self, cards)--by OLC,boss符卡系统
	--boss行走图
	self._wisys = BossWalkImageSystem(self)--by OLC，行走图系统
	--boss骚气
	self.firehost=New(boss_fire,self)
	--boss ex
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
	elseif self.ex==nil then--ETC：？？？
		Kill(self) -- open the first spell card. (= =|||)
	end
	ex.AddBoss(self)
	--
	lstg.tmpvar.boss=self
end

--~细节：已适配多玩家，但是可能不兼容以前的replay
--~细节：已开启死亡爆炸特效
function boss:frame()
	--
	SetAttr(self,'colli',BoxCheck(self,lstg.world.boundl,lstg.world.boundr,lstg.world.boundb,lstg.world.boundt) and self._colli)
	self.hp=max(0,self.hp)
	if self.hp<=0 then
		if self.card_num==self.last_card and not(self.no_killeff) and not(self.killed) and (not self.ex) then
			boss.explode(self,true)
		else
			if not(self.killed) then
				Kill(self)
			end
		end
	end
	--boss ex
	if self.ex then
		if self.hp<=0 then
			if not(self.killed) then
				Kill(self)
			end
		end
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
	--执行自身task
	task.Do(self)
	--by OLC，行走图系统
	self._wisys:frame()
	--受击闪烁
	if self.dmgt then self.dmgt = max(0, self.dmgt - 1) end
	--boss高防
	if self.sc_pro>0 then self.sc_pro=self.sc_pro-1 end
	--位置指示
	if abs(self.x)<lstg.world.r then self.ui.pointer_x=self.x else self.ui.pointer_x=nil end--适配宽屏
	--魔法阵透明度更新
	self.aura_alpha=self.aura_alpha+self.aura_alpha_d
	self.aura_alpha=min(max(0,self.aura_alpha),128)
	--boss行为逻辑
	if not(self.current_card) then
		self.current_card = self.cards[self.card_num]
	end
	local c=self.current_card
	if self.ex then
		if self.ex.status==1 then
			c=self.ex.cards[self.ex.nextcard]
		end
	end
	if c then
		--
		c.frame(self)
		--受击伤害调整
		local players=Players(self)--多玩家适配
		--
		--[=[
		if player.nextspell>0 and self.timer<=0 then
			self.sc_pro=player.nextspell
		end
		--]=]
		if self.timer<=0 then
			local nextspell=0
			for i=1,#players do
				if IsValid(players[i]) then
					nextspell=max(nextspell,players[i].nextspell)
				end
			end
			if nextspell>0 then
				self.sc_pro=nextspell
			end
		end
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
		end
		--[=[
		if c.is_extra and lstg.player.nextspell>0 then
			self.dmg_factor=0
		end
		--]=]
		if c.is_extra then
			for i=1,#players do
				if IsValid(players[i]) then
					if players[i].nextspell>0 then
						self.dmg_factor=0
						break
					end
				end
			end
		end
		if c.t1==c.t3 then--耐久或者正常
			self.dmg_factor=0
			self.time_sc=true
		else
			self.time_sc=false
		end
		--符卡分数更新
		if self.sc_bonus and self.sc_bonus>0 and c.t1~=c.t3 and not(self.killed) then
			self.sc_bonus=self.sc_bonus-(self.sc_bonus_max-self.sc_bonus_base)/c.t3
		end
		--符卡ui更新
		self.ui.hpbarlen=self.hp/self.maxhp
		self.ui.countdown=(c.t3-self.timer)/60
		--player靠近boss时ui透明度更新
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
		self.hp_flag=min(max(0,self.hp_flag),18)
		--卡背透明度和关卡背景更新
		if self.bg then
			if c.is_sc then
				self.bg.alpha=min(1,self.bg.alpha+(1/60))
			else
				self.bg.alpha=max(0,self.bg.alpha-(1/60))
			end
			if lstg.tmpvar.bg then
				if self.bg.alpha==1 then
					lstg.tmpvar.bg.hide=true
				else
					lstg.tmpvar.bg.hide=false
				end
			end
		end
	end
	--符卡环位置更新
	self.cardlinex=self.x+(self.cardlinex-self.x)*0.9
	self.cardliney=self.y+(self.cardliney-self.y)*0.9
end

function boss:render()
	boss.renderaura(self)
	
	if self.ex then
		if self.ex.status==1 then
			self.ex.cards[self.ex.nextcard].render(self)
		end
	end
	
	if self.current_card then--by OLC，新增current_card
		self.current_card.render(self)
	end
	
	self._wisys:render(self.dmgt, self.dmgmaxt)--by OLC，行走图系统
end

function boss:renderaura()
	SetImageState('boss_aura','mul+add',Color(self.aura_alpha,255,255,255))
	Render('boss_aura',self.x,self.y,self.ani*0.6,0.5+0.02*sin(self.ani*2))
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

function boss:kill()
	--
	_kill_servants(self)
	self.sp_point={}
	if IsValid(self.cardlinehost) then--自机活符卡环
		self.cardlinehost.killed=true
	end
	--boss ex
	if self.ex then
		boss.killex(self)
		return--为boss ex时，不执行下方的逻辑
	end
	--执行boss行为的末尾处理
	if self.current_card then--OLC，新增current_card
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
	--boss行为更新
	if self._cardsys:next(self) then--切换到下一个行为
		PreserveObject(self)
	else--没有下一个行为了，清除自身和附属的组件
		boss.del(self)
	end
end

function boss:del()
	if self.ex then
		task.Clear(self.ex)
	end
	if self.ui then Del(self.ui) end
	if self.bg then Del(self.bg) self.bg=nil end
	if self.dialog_displayer then Del(self.dialog_displayer) end
	if lstg.tmpvar.bg then lstg.tmpvar.bg.hide=false end
	if self.class.defeat then self.class.defeat(self) end
	if IsValid(self.firehost) then self.firehost.death=true end--boss骚气
	ex.RemoveBoss(self)
end

--~细节：现在击破非或符后消弹圈已经改为从boss身上展开
function boss:PopSpellResult(c)--弹出提示文字等
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
			--local players=Players()
			--Print("Clear ",#players)
			--for _,p in pairs(players) do
				--New(bullet_killer,p.x,p.y,true)
			--end
			local w=lstg.world
			local x=max(w.l,min(self.x,w.r))
			local y=max(w.b,min(self.y,w.t))
			New(bullet_killer,x,y,true)
		end
	end
	if c.is_sc then self.ui.sc_left=self.ui.sc_left-1 end
end

function boss:explode(a)--boss死亡特效--自机活版本
	if a then
		self.killed=true
		self.no_killeff=true
		task.Clear(self)
		if self.ex then task.Clear(self.ex) end
		self.colli=false
		self.hp=0
		task.New(self,function()
			self.vx=ran:Sign()*0.501
			self.vy=ran:Float(0.1,0.5)
			New(boss_death_ef,self.x,self.y)
			New(bullet_cleaner,self.x,self.y, 1500, 120, 60, true, true, 0)
			
			lstg.var.timeslow=2
			for i=1,60 do
				self.hp=0
				self.timer=self.timer-1
				local lifetime=ran:Int(60,90)
				local l=ran:Float(200,500)
				New(boss_death_ef_unit,self.x,self.y,l/lifetime,ran:Float(0,360),lifetime,ran:Float(2,3))
				task.Wait(1)
			end
			lstg.var.timeslow=1
			
			PlaySound("enep01",0.5,self.x/256)
			New(deatheff,self.x,self.y,'first')
			New(deatheff,self.x,self.y,'second')
			
			Kill(self)
		end)
	else
		Kill(self)
	end
end

function boss:show_aura(show)
	if show then self.aura_alpha_d=4 else self.aura_alpha_d=-4 end
end

function boss:cast(cast_t)
	self.cast_t=cast_t+0.5
	self.cast=1
end

--boss ex

function boss:killex()
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
		boss.del(self)
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

function boss:_castcard(c)
	if c.is_sc then
		if not c.fake then
			self.sc_bonus=self.sc_bonus_max
		end
		
	--	self.ui.hpbarcolor=Color(0xFFFF8080)
		--New(spell_card_ef)
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

--ui

function boss:SetUIDisplay(hp,name,cd,spell,pos,pointer)
	self.ui.drawhp=hp
	self.ui.drawname=name
	self.ui.drawtime=cd
	self.ui.drawspell=spell
	self.ui.needposition=pos
	self.ui.drawpointer=pointer or 1
end

----------------------------------------
--boss 行为
--包括移动、对话、非符、符卡

--随机移动--似乎没有使用上

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

--符卡

boss.card={}
function boss.card.New(name,t1,t2,t3,hp,drop,is_extra)
	local c={}
	c.frame=boss.card.frame
	c.render=boss.card.render
	c.init=boss.card.init
	c.del=boss.card.del
	c.name=tostring(name)
	if t1>t2 or t2>t3 then error('t1<=t2<=t3 must be satisfied.') end--emmmm……这个提示应该有等号的
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
	--boss.card.cardline(self)
	_boss=last
end
function boss.card:cardline()--带有跟随效果的样式
	local c=self.current_card--by OLC，新增current_card
	local x,y=self.cardlinex,self.cardliney
	if c and c.is_sc and c.t1~=c.t3 then
		for i=1,16 do SetImageState('bossring1'..i,'mul+add',Color(self.aura_alpha,255,255,255)) end
		if self.timer<90 then
			for i=1,16 do SetImageState('bossring2'..i,'mul+add',Color(self.aura_alpha,255,255,255)) end
			misc.RenderRing('bossring1',x,y,self.timer*2+270*sin(self.timer*2),self.timer*2+270*sin(self.timer*2)+16, self.ani*3,32,16)
			misc.RenderRing('bossring2',x,y,90+self.timer*1,-180+self.timer*4-16,-self.ani*3,32,16)
		else
			for i=1,16 do SetImageState('bossring2'..i,'mul+add',Color(self.aura_alpha,255,255,255)) end
			local t=c.t3
			misc.RenderRing('bossring1',x,y,(t-self.timer)/(t-90)*180,(t-self.timer)/(t-90)*180+16, self.ani*3,32,16)
			misc.RenderRing('bossring2',x,y,(t-self.timer)/(t-90)*180,(t-self.timer)/(t-90)*180-16,-self.ani*3,32,16)
		end
	end
end
function boss.card:cardline_old()--旧样式
	local c=self.current_card--by OLC，新增current_card
	if c and c.is_sc and c.t1~=c.t3 then
		for i=1,16 do SetImageState('bossring1'..i,'mul+add',Color(self.aura_alpha,255,255,255)) end
		if self.timer<90 then
			if self.fxr and self.fxg and self.fxb then
				local of=1-self.timer/180
				for i=1,16 do SetImageState('bossring2'..i,'mul+add',Color(1.9*self.aura_alpha,self.fxr*of,self.fxg*of,self.fxb*of)) end
			else
				for i=1,16 do SetImageState('bossring2'..i,'mul+add',Color(self.aura_alpha,255,255,255)) end
			end
			misc.RenderRing('bossring1',self.x,self.y,self.timer*2+270*sin(self.timer*2),self.timer*2+270*sin(self.timer*2)+16, self.ani*3,32,16)
			misc.RenderRing('bossring2',self.x,self.y,90+self.timer*1,-180+self.timer*4-16,-self.ani*3,32,16)
		else
			if self.fxr and self.fxg and self.fxb then
				for i=1,16 do SetImageState('bossring2'..i,'mul+add',Color(1.9*self.aura_alpha,self.fxr/2,self.fxg/2,self.fxb/2)) end
			else
				for i=1,16 do SetImageState('bossring2'..i,'mul+add',Color(self.aura_alpha,255,255,255)) end
			end
			local t=self.current_card.t3
			misc.RenderRing('bossring1',self.x,self.y,(t-self.timer)/(t-90)*180,(t-self.timer)/(t-90)*180+16, self.ani*3,32,16)
			misc.RenderRing('bossring2',self.x,self.y,(t-self.timer)/(t-90)*180,(t-self.timer)/(t-90)*180-16,-self.ani*3,32,16)
		end
	end
end
function boss.card:init() end
function boss.card:del() end

--自机活符卡环
boss_card_cardline=Class(object)
function boss_card_cardline:init(boss)
	self.boss=boss
	self.boss.cardlinehost=self
	self.group=GROUP_GHOST
	self.layer=LAYER_BG+1
	self.x=self.boss.x
	self.y=self.boss.y
	self.active=true
	self.bound=false
	local c=self.boss.current_card
	if not(c and c.is_sc and c.t1~=c.t3) then
		self.active=false
		Del(self)
	end
	--[=[--各项数据参考
	self.r11=128
	self.r12=144
	self.r21=144
	self.r22=160
	self.r11=224
	self.r12=240
	self.r21=240
	self.r22=256
	--]=]
	self.r11=224
	self.r12=-224
	self.r21=0
	self.r22=0
	if self.active then
		task.New(self,function()--内圈展开
			for t=1,90 do
				self.r11=-224+448*sin(t)
				self.r12=224+16*sin(t)
				task.Wait(1)
			end
		end)
		task.New(self,function()--外圈展开和收回处理
			for t=1,120 do
				self.r21=240*(t/120)+192*sin(180*(t/120))
				self.r22=self.r21+16
				task.Wait(1)
			end
			if c.t3>120 then
				for t=121,c.t3 do
					if self.killed then break end
					self.r11=224-96*((t-120)/(c.t3-120))
					self.r12=self.r11+16
					self.r21=self.r12
					self.r22=self.r21+16
					task.Wait(1)
				end
			end
			while self.r12>0 do
				self.r11=self.r11-9.6
				self.r12=self.r11+16
				self.r21=self.r12
				self.r22=self.r21+16
				task.Wait(1)
			end
			Del(self)
		end)
	end
end
function boss_card_cardline:frame()
	if self.active then
		if IsValid(self.boss) then
			self.x=self.boss.x+(self.x-self.boss.x)*0.9
			self.y=self.boss.y+(self.y-self.boss.y)*0.9
		end
		task.Do(self)
	end
end
function boss_card_cardline:render()
	if self.active then
		local b=self.boss
		for i=1,16 do
			SetImageState('bossring1'..i,'mul+add',Color(b.aura_alpha,255,255,255))
			SetImageState('bossring2'..i,'mul+add',Color(b.aura_alpha,255,255,255))
		end
		misc.RenderRing('bossring2',self.x,self.y,self.r11,self.r12,-self.ani*2,48,16)
		misc.RenderRing('bossring1',self.x,self.y,self.r21,self.r22, self.ani*2,48,16)
	end
end

--对话
--~细节：现在已经适配jstg
--~细节：已适配宽屏，对话气泡样式稍微模仿了hzc以后的样式，没有做成气泡对话（太难了……）

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
	_dialog_can_skip=can_skip--全局变量是因为对话sentence并没有传入，要访问全局的can_skip
	return c
end
function boss.dialog:frame()
	if self.task and coroutine.status(self.task[1])=='dead' then Kill(self) end
end
function boss.dialog:render() end
function boss.dialog:init()--目前该方法会被编辑器的覆盖……好sb，编辑器生成的对话init目前还没有适配多玩家
	lstg.player.dialog=true
	self.dialog_displayer=New(dialog_displayer)
end
function boss.dialog:del()--已适配多玩家
	--lstg.player.dialog=false
	local players=Players(self)--多玩家适配
	for i=1,#players do
		if IsValid(players[i]) then
			players[i].dialog=false
		end
	end
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
		if ((KeyIsPressed('shoot',1) or KeyIsPressed('shoot',2)) or self.dialog_displayer.jump_dialog>60) and _dialog_can_skip then
			PlaySound('plst00',0.35,0,true)
			break
		end
		task.Wait()
	end
	task.Wait(2)
end

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
		if KeyIsDown('shoot',1) or KeyIsDown('shoot',2) then
			self.jump_dialog=self.jump_dialog+1
		else
			self.jump_dialog=0
		end
	end
end
function dialog_displayer:render()--已适配宽屏
	if self.active then
		SetViewMode'ui'
			local w=lstg.world
			local dx=w.scrl+(w.scrr-w.scrl)/2
			local dy=screen.height/2
			if self.char[-self.active] then
				SetImageState(self.char[-self.active],'',Color(0xFF404040)+(  self.t/16)*Color(0xFFC0C0C0)-(self.death/30)*Color(0xFF000000))
				local t=(1-self.t/16)^3
				Render(
					self.char[-self.active],
					dx+self.active*(-(1-2*t)*16+128)+self.death*self.active*12,
					dy-65-t*16-25,
					0,
					self._hscale[-self.active],
					self._vscale[-self.active]
				)
			end
			if self.char[self.active] then
				SetImageState(self.char[ self.active],'',Color(0xFF404040)+(1-self.t/16)*Color(0xFFC0C0C0)-(self.death/30)*Color(0xFF000000))
				local t=(self.t/16)^3
				Render(
					self.char[ self.active],
					dx+self.active*( (1-2*t)*16-128)-self.death*self.active*12,
					dy-65-t*16-25,
					0,
					self._hscale[self.active],
					self._vscale[self.active]
				)
			end
		SetViewMode'world'
	end
	if self.text and self.active then
		local kx,ky1,ky2,dx,dy1,dy2
		kx=168
		ky1=-210
		ky2=-90
		dx=160
		dy1=-144
		dy2=-126
		--[=[
		SetImageState('dialog_box','',Color(225,195-self.co,150,195+self.co))
		Render('dialog_box',0,-144-self.death*8)
		RenderTTF('dialog',self.text,-dx,dx,dy1-self.death*8,dy2-self.death*8,Color(0xFF000000),'paragraph')
		if self.active>0 then
			RenderTTF('dialog',self.text,-dx,dx,dy1-self.death*8,dy2-self.death*8,Color(255,255,200,200),'paragraph')
		else
			RenderTTF('dialog',self.text,-dx,dx,dy1-self.death*8,dy2-self.death*8,Color(255,200,200,255),'paragraph')
		end
		--]=]
		local img='dialog_box'
		SetImageState(img,'',Color(225,255,255,255))
		Render(img,0,-144-self.death*8,0,0.5)
		RenderTTF('dialog',self.text,-dx,dx,dy1-self.death*8,dy2-self.death*8,Color(0xFF000000),'paragraph')
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

--boss移动

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
	local c=self.current_card
	task.New(self,function()
		task.MoveTo(c.x,c.y,c.t,c.m)
		Kill(self)
	end)
end
function boss.move:del() end

boss.escape={}--这个和boss.move有什么区别？？？

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
	local c=self.current_card
	task.New(self,function()
		task.MoveTo(c.x,c.y,c.t,c.m)
		Kill(self)
	end)
end
function boss.escape:del() end

----------------------------------------
--boss 特效
--一些华丽的效果（

--开卡文字
--！警告：未适配宽屏

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

--蓄力

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

--死亡爆炸

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
	Del(self)--哪个傻吊把这个漏了……
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

--非或符结束时弹出的文字

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

--背后骚气
boss_fire=Class(object)
function boss_fire:init(boss)
	self.bound=false
	self.layer=LAYER_ENEMY-1
	self.group=GROUP_GHOST
	self.boss=boss
	self.imgs={}
end
function boss_fire:frame()
	if IsValid(self.boss) and not(self.death) then
		--正常时跟随boss
		self.x,self.y=self.boss.x,self.boss.y
		--并生成粒子
		if self.timer%6==0 then
			local tmp={
				img="boss_effect_par2",
				rot=ran:Float(-5,5),
				hscale=ran:Float(1.2,1.6),
				vscale=0,
				timer=0,
				['type']=1,
				a=255,
				x=self.x,
				y=self.y,
			}
			table.insert(self.imgs,tmp)
			local tmp2={
				img="boss_effect_par3",
				rot=ran:Float(0,360),
				hscale=2.5,
				vscale=2.5,
				timer=0,
				['type']=2,
				a=0,
				x=self.x,
				y=self.y,
			}
			table.insert(self.imgs,tmp2)
		elseif self.imgs[#self.imgs].timer>=40 then--等待粒子特效全部消失
			Del(self)
		end
	end
	--粒子更新
	for i=#self.imgs,(#self.imgs-13),-1 do
		if i>=1 then
			if self.imgs[i].timer<40 then
				if self.imgs[i].type==1 then--骚气粒子更新
					self.imgs[i].vscale=self.imgs[i].vscale+0.06
					if self.imgs[i].timer>=20 and self.imgs[i].timer<40 then
						self.imgs[i].a=self.imgs[i].a-12.75
					end
				elseif self.imgs[i].type==2 then--灵气粒子更新
					self.imgs[i].hscale,self.imgs[i].vscale=self.imgs[i].hscale-0.0375,self.imgs[i].vscale-0.0375
					if self.imgs[i].timer<10 then
						self.imgs[i].a=self.imgs[i].a+25.5
					end
				end
				self.imgs[i].timer=self.imgs[i].timer+1
			end
		end
	end
end
function boss_fire:render()
	local v
	for i=#self.imgs,(#self.imgs-13),-1 do
		if i>=1 then
			v=self.imgs[i]
			if v.timer<40 then
				local b=self.boss
				if IsValid(b) then
					if b.fxr then
						SetImageState(v.img,"mul+add",Color(v.a,b.fxr,b.fxg,b.fxb))
					else
						SetImageState(v.img,"mul+add",Color(v.a,96,32,128))
					end
				else
					SetImageState(v.img,"mul+add",Color(v.a,96,32,128))
				end
				Render(v.img,v.x,v.y,v.rot,v.hscale,v.vscale)
			end
		end
	end
end

--杂项

function Render_RIng_4(angle,r,angle_offset,x0,y0,r_,imagename)--未使用
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

----------------------------------------
--boss 行为更新
--by OLC

SpellCardSystem = plus.Class()
---@param boss object @要执行符卡组的boss
---@param cards table @符卡表
function SpellCardSystem:init(boss, cards)
	boss.cards = cards
	boss.card_num = 0
	boss.ui.sc_left = 0
	boss.last_card = 0
	for i = 1, #boss.cards do
		if boss.cards[i].is_combat then
			boss.last_card = i
		end
		if boss.cards[i].is_sc then
			boss.ui.sc_left = boss.ui.sc_left + 1
		end
	end
end
---帧逻辑适配
---@param boss object @要执行符卡组的boss
function SpellCardSystem:frame(boss)
	local card = boss.current_card or boss.cards[boss.card_num]
	if card then card.frame(boss) end
end
---渲染逻辑适配
---@param boss object @要执行符卡组的boss
function SpellCardSystem:render(boss)
	local card = boss.current_card or boss.cards[boss.card_num]
	if card then card.render(boss) end
end
---结束逻辑适配
---@param boss object @要执行符卡组的boss
function SpellCardSystem:del(boss)
	local card = boss.current_card or boss.cards[boss.card_num]
	if card then card.del(boss) end
end
---执行通常符卡
---@param boss object @要执行符卡组的boss
---@param card table @通常boss符卡
---@param mode number @血条样式
function SpellCardSystem:DoCard(boss, card, mode)
	boss.current_card = card
	if card.is_sc then
		self:CastCard(boss, card)
	elseif not card.fake then
		boss.sc_bonus = nil
	end
	self:SetHPBar(boss, mode)
	if card.is_combat then
		item.StartChipBonus(boss)
		boss.spell_damage = 0
	end
	task.Clear(boss)
	task.Clear(boss.ui)
	boss.ui.countdown = card.t3 / 60
	boss.ui.is_combat = card.is_combat
	boss.timer = -1
	boss.hp = card.hp
	boss.maxhp = card.hp
	boss.dmg_factor = 0
	card.init(boss)
	New(boss_card_cardline,boss)--自机活符卡环
end
---执行下一张符卡
---@param boss object @要执行符卡组的boss
function SpellCardSystem:next(boss)
	boss.card_num = boss.card_num + 1
	if not(boss.cards[boss.card_num]) then
		self.is_finish = true
		return false
	end
	local last, now, next, mode
	for n = boss.card_num - 1, 1, -1 do
		if boss.cards[n] and boss.cards[n].is_combat then
			last = boss.cards[n]
			break
		end
	end
	now = boss.cards[boss.card_num]
	for n = boss.card_num + 1, #boss.cards do
		if boss.cards[n] and boss.cards[n].is_combat then
			next = boss.cards[n]
			break
		end
	end
	if now.is_sc then
		if last and last.is_sc then
			mode = 0
		elseif last and not(last.is_sc) then
			if (last.t1 ~= last.t3) then mode = 2 else mode = 0 end
		elseif not(last) then
			mode = 0
		end
	elseif not(now.is_sc) then
		if next and next.is_sc then
			if (next.t1 ~= next.t3) then mode = 1 else mode = 0 end
		elseif next and not(next.is_sc) then
			mode = 0
		elseif not(next) then
			mode = 0
		end
	end
	if now.t1 == now.t3 then mode = -1 end
	self:DoCard(boss, now, mode)
	return true
end
---设置血条类型
---@param boss object @要执行符卡组的boss
---@param mode number @血条样式(0完整，1非&符中的非，2非&符中的符)
function SpellCardSystem:SetHPBar(boss, mode)
	local color1, color2 = Color(0xFFFF8080), Color(0xFFFFFFFF)
	if mode == 0 then
		boss.ui.hpbarcolor1 = color1
		boss.ui.hpbarcolor2 = nil
	elseif mode == 1 then
		boss.ui.hpbarcolor1 = color1
		boss.ui.hpbarcolor2 = color2
	elseif mode == 2 then
		boss.ui.hpbarcolor1 = color1
		boss.ui.hpbarcolor2 = color1
	end
end
---宣言符卡
---@param boss object @要执行符卡组的boss
---@param card table @目标符卡
function SpellCardSystem:CastCard(boss, card)

	if not card.fake then
		boss.sc_bonus = boss.sc_bonus_max
	end
	--New(spell_card_ef)

	PlaySound('cat00', 0.5)

	if scoredata.spell_card_hist == nil then
		scoredata.spell_card_hist = {}
	end

	local sc_hist = scoredata.spell_card_hist
	local player = lstg.var.player_name
	local diff = boss.difficulty
	local name = card.name
	if sc_hist[player] == nil then
		sc_hist[player] = {}
	end

	if sc_hist[player][diff] == nil then
		sc_hist[player][diff]={}
	end

	if sc_hist[player][diff][name] == nil then
		sc_hist[player][diff][name] = {0, 0}
	end

	if not ext.replay.IsReplay() then

		sc_hist[player][diff][name][2] = sc_hist[player][diff][name][2] + 1

	end

	boss.ui.sc_hist = sc_hist[player][diff][name]

	if name ~= '' then boss.ui.sc_name = name end
end
