--======================================
--pause menu
--code by Xiliusha
--======================================

----------------------------------------
--暂停菜单

ext.pausemenu={}

ext.pausemenu.rawtext={--各个选项的元字符串
	retrun_to_game='Return-To-Game',
	return_to_title='Return-To-Title',
	give_up_and_retry='Give-Up-And-Retry',
	save_replay_and_return_to_title='Save-Replay-And-Return-To-Title',
	save_replay='Save-Replay',--!!
	replay_again='Replay-Again',
	manual='Manual',--??
	retry='Retry',
	setting='Setting',--??
	continue_to_play_replay='Continue-To-Play-Replay',
	continue='Continue',
	
	yes='Yes',
	no='No',
}

local rtx=ext.pausemenu.rawtext
ext.pausemenu.order={--不同场景下的暂停菜单
	['game-pause']={--正常游戏时暂停
		rtx.retrun_to_game,
		rtx.give_up_and_retry,
		rtx.save_replay_and_return_to_title,
		rtx.return_to_title,
		rtx.manual,
		--rtx.setting,
	},
	['replay-pause']={--录像时暂停
		rtx.continue_to_play_replay,
		rtx.return_to_title,
		rtx.replay_again,
		--rtx.setting,
	},
	['continue-pause']={---续命后暂停
		rtx.retrun_to_game,
		rtx.give_up_and_retry,
		rtx.return_to_title,
		rtx.manual,
		--rtx.setting,
	},
	['game-over']={--正常游戏时疮痍
		rtx.continue,
		rtx.retry,
		rtx.save_replay_and_return_to_title,
		rtx.return_to_title,
		rtx.manual,
		--rtx.setting,
	},
	['continue-over']={--续命后疮痍
		rtx.continue,
		rtx.retry,
		rtx.return_to_title,
		rtx.manual,
		--rtx.setting,
	},
	['practice-over']={--关卡练习时疮痍
		rtx.retry,
		rtx.save_replay_and_return_to_title,
		rtx.return_to_title,
		rtx.manual,
		--rtx.setting,
	},
	['sc-over']={--符卡练习时疮痍
		rtx.continue,
		rtx.save_replay_and_return_to_title,
		rtx.return_to_title,
		rtx.manual,
		--rtx.setting,
	},
	['sc-finish']={--符卡练习收取
		rtx.continue,
		rtx.save_replay_and_return_to_title,
		rtx.return_to_title,
		rtx.manual,
		--rtx.setting,
	},
	['replay-finish']={--播放完录像
		rtx.replay_again,
		rtx.return_to_title,
		--rtx.setting,
	},
}

function ext.pausemenu.getorder(op)--用于和stage group对接
	local rtx=ext.pausemenu.rawtext
	if op==rtx.retrun_to_game or op==rtx.continue_to_play_replay then--返回游戏类型
		
	elseif op==rtx.retry or op==rtx.give_up_and_retry then--重开类型
		return 'Restart'
	elseif op==rtx.return_to_title then--直接回主菜单
		return 'Return to Title'
	elseif op==rtx.save_replay_and_return_to_title then--保存录像并回主菜单
		return 'Quit and Save Replay'
	elseif op==rtx.replay_again then--录像重放
		return 'Replay Again'
	elseif op==rtx.continue then--继续挑战
		return 'Continue'
	end
end


function ext.pausemenu.New()--生成暂停菜单
	local pm={}
	ext.pausemenu.init(pm)
	return pm
end

function ext.pausemenu.init(self)--暂停菜单初始化
	self.pos=1--当前选项位置
	self.pos2=2--二级菜单选项位置
	self.choose=false--开启二级选项
	self.timer=0--计时器
	self.t=40--按下选项后的缓冲时间
	self.omiga=4--底图旋转角速度
	self.rot=0--底图旋转角
	self.textposstart=-90--文字列表起始位置
	self.kill=false--标记自身是否需要清除
	--初始化标题和暂停菜单文字
	self.menutext=ext.GetPauseMenu()
	if type(self.menutext)~='table' then
		if ext.replay.IsReplay() then
			ext.SetPauseMenuType('replay-pause')
			self.menutext=ext.GetPauseMenu()
		elseif stage.continueflag then
			ext.SetPauseMenuType('continue-pause')
			self.menutext=ext.GetPauseMenu()
		else
			ext.SetPauseMenuType('game-pause')
			self.menutext=ext.GetPauseMenu()
		end
	end
	self.titletype=ext.GetPauseMenuType()
	self.lock=true--锁定
	task.New(self,function()--解锁
		task.Wait(40)
		self.lock=false
	end)
	--颜色和位置
	self.imgx=-280
	self.imgy=240
	self.imgcolor={0,255,255,255}
	task.New(self,function()--飞入
		local pm=ext.pausemenu
		for i=1,40 do
			self.imgx=-280+240*sin(i*(90/40))
			self.imgcolor[1]=i*(255/40)
			self.textposstart=-90+90*sin(i*(90/40))
			ext.pauseblur_radiu=2*(i/40)
			task.Wait(1)
		end
	end)
	--暂停关卡声音
	ext.pausemenu.pausesound()
	--播放音效
	PlaySound('pause', 0.5)
end

function ext.pausemenu.frame(self)
	do--底图旋转
		if self.omiga>=0 then
			if self.omiga>0.25 then
				self.omiga=self.omiga-0.0625
			elseif self.omiga<0.25 then
				self.omiga=self.omiga+0.0625
			end
			if abs(self.omiga-0.25)<=0.08 then
				self.omiga=0.25
			end
		elseif self.omiga<0 then
			if self.omiga>-0.25 then
				self.omiga=self.omiga-0.0625
			elseif self.omiga<-0.25 then
				self.omiga=self.omiga+0.0625
			end
			if abs(self.omiga+0.25)<=0.08 then
				self.omiga=-0.25
			end
		end
		self.rot=self.rot+self.omiga
	end
	--执行自身task
	task.Do(self)
	--执行选项操作
	if (not self.lock) then
		if GetLastKey()==setting.keysys.menu then--通过esc关闭处理
			if ext.IsReplay or ext.rep_over then
				PlaySound('invalid',1.0)
				--rep时防止录像放完后可以关闭暂停菜单
			else
				PlaySound('cancel00',0.3)
				ext.pausemenu.exit(self)
			end
		end
		do--检测按键切换槽位
			if self.t<=0 then
				if (GetLastKey()==setting.keys.up or GetLastKey()==setting.keys.left) then
					self.omiga=4
					if not self.choose then
						self.pos=self.pos-1
					else
						self.pos2=self.pos2-1
					end
					PlaySound('select00',0.3)
				end
				if (GetLastKey()==setting.keys.down or GetLastKey()==setting.keys.right) then
					self.omiga=-4
					if not self.choose then
						self.pos=self.pos+1
					else
						self.pos2=self.pos2+1
					end
					PlaySound('select00',0.3)
				end
			end
			self.pos2=(self.pos2-1)%(2)+1
			self.pos=(self.pos-1)%(#self.menutext)+1
		end
		if GetLastKey()==setting.keysys.retry then--快速retry处理
			PlaySound('ok00',0.3)
			lstg.tmpvar.death = false
			self.t=60
			if ext.replay.IsReplay() then
				ext.PushPauseMenuOrder('Replay Again')
			else
				ext.PushPauseMenuOrder('Give up and Retry')
			end
			ext.pausemenu.exit(self)
		end
		if GetLastKey()==setting.keys.shoot and self.t<=0 then--选择选项操作
			local trueorder--需要翻译得到可用的order
			self.t=15
			if self.choose then--处于二级菜单
				if self.pos2==1 then
					PlaySound('ok00',0.3)
					self.t=60
					lstg.tmpvar.death = false
					trueorder=ext.pausemenu.getorder(self.menutext[self.pos])--需要翻译得到可用的order
					ext.pausemenu.exit(self)
				else
					self.choose=false
					PlaySound('cancel00',0.3)
					self.t=15
				end
			else--处于一级菜单
				PlaySound('ok00',0.3)
				local rtx=ext.pausemenu.rawtext
				local order=self.menutext[self.pos]
				if self.pos==1 then
					lstg.tmpvar.death = false
					trueorder=ext.pausemenu.getorder(self.menutext[self.pos])--需要翻译得到可用的order
					ext.pausemenu.exit(self)
				elseif order==rtx.setting or order==rtx.manual then
					--留备以后使用
				else
					self.choose=true
				end
			end
			ext.PushPauseMenuOrder(trueorder)--这样才设置order
		end
		if GetLastKey()==setting.keys.spell and self.t<=0 then--取消操作处理
			if self.choose then--二级菜单
				self.choose=false
				self.t=15
				PlaySound('cancel00',0.3)
			elseif (not lstg.tmpvar.death) then--处于一级菜单时
				if ext.IsReplay or ext.rep_over then
					PlaySound('invalid',1.0)
					--rep时防止录像放完后可以关闭暂停菜单
				else
					PlaySound('cancel00',0.3)
					ext.pausemenu.exit(self)
				end
			end
		end
	end
	--后更新
	self.timer=self.timer+1
	if self.t>0 then self.t=self.t-1 end
end

function ext.pausemenu.render(self)
	SetViewMode'ui'
	
	--绘制黑色遮罩
	SetImageState('white','',Color(128*self.imgcolor[1]/255,0,0,0))
	RenderRect('white',0,screen.width,0,screen.height)
	--渲染底图
	SetImageState('pause_menu_circle','mul+add',Color(self.imgcolor[1],self.imgcolor[2],self.imgcolor[3],self.imgcolor[4]))
	Render('pause_menu_circle',self.imgx,self.imgy,self.rot,0.52,0.52)
	do--渲染标题
		if self.titletype=='game-pause' or self.titletype=='continue-pause' then--暂停
			SetImageState('pause_menu_gamepause','',Color(self.imgcolor[1],255,255,255))
			Render('pause_menu_gamepause',self.imgx+120,self.imgy+4*sin(2*self.timer),0,0.5)
		elseif self.titletype=='replay-pause' then--录像播放暂停
			SetImageState('pause_menu_replaypause','',Color(self.imgcolor[1],255,255,255))
			Render('pause_menu_replaypause',self.imgx+120,self.imgy+4*sin(2*self.timer),0,0.5)
		elseif self.titletype=='game-over' or self.titletype=='continue-over' or self.titletype=='sc-over' or self.titletype=='practice-over' then--疮痍
			SetImageState('pause_menu_gameover','',Color(self.imgcolor[1],255,255,255))
			Render('pause_menu_gameover',self.imgx+120,self.imgy+4*sin(2*self.timer),0,0.5)
		elseif self.titletype=='replay-finish' then--录像播放完
			SetImageState('pause_menu_replayfinish','',Color(self.imgcolor[1],255,255,255))
			Render('pause_menu_replayfinish',self.imgx+120,self.imgy+4*sin(2*self.timer),0,0.5)
		elseif self.titletype=='sc-finish' then--符卡收取
			SetImageState('pause_menu_scfinish','',Color(self.imgcolor[1],255,255,255))
			Render('pause_menu_scfinish',self.imgx+120,self.imgy+4*sin(2*self.timer),0,0.5)
		end
	end
	do--渲染选项
		local textlist=self.menutext
		local cirleR=450*0.52+16--位置半径
		local textn=#textlist--选项数量
		local da=9--位置角度差
		local ras=self.textposstart--(textn*da)/2--起始位置
		for i=1,textn do
			local x=self.imgx+cirleR*cos(ras-(i-1)*da)
			local y=self.imgy+cirleR*sin(ras-(i-1)*da)
			local img='pause_menu_'..textlist[i]
			if i==self.pos then
				if self.choose then--处于二级菜单
					SetImageState(img,'',Color(self.imgcolor[1],255,255,255))
					do--二级菜单
						local rtx=ext.pausemenu.rawtext
						local textlist={
							rtx.yes,
							rtx.no,
						}
						for j=1,2 do
							local img='pause_menu_'..textlist[j]
							if j==self.pos2 then
								local c=255-32+32*sin(self.timer*8)
								SetImageState(img,'',Color(self.imgcolor[1],c,c,255))
							else
								SetImageState(img,'',Color(self.imgcolor[1],128,128,128))
							end
							Render(img,x+192+(j-1)*48,y,0,0.3)
						end
					end
				else--处于一级菜单
					local c=255-32+32*sin(self.timer*8)
					SetImageState(img,'',Color(self.imgcolor[1],c,c,255))
				end
			else
				SetImageState(img,'',Color(self.imgcolor[1],128,128,128))
			end
			Render(img,x,y,0,0.3)
		end
	end
	
	SetViewMode'world'
end

function ext.pausemenu.exit(self)--离开
	self.lock=true
	task.New(self,function()
		task.Wait(10)
		
		--施放辅助幕布，在这里放是因为有些时候不适合在关卡里创建mask_fader
		if
			ext.GetPauseMenuOrder()=='Restart' or
			ext.GetPauseMenuOrder()=='Replay Again' or
			ext.GetPauseMenuOrder()=='Give up and Retry' or
			ext.GetPauseMenuOrder()=='Quit and Save Replay' or
			ext.GetPauseMenuOrder()=='Return to Title'
		then
			--直接重开的情况
			ext.switchmask.close(nil,30)
		elseif ext.GetPauseMenuOrder()=='Continue' and (ext.sc_pr or Extramode or lstg.var.is_practice) then
			--Continue有两种情况，一种是续关，续关不需要幕布，ex模式、单面练习、符卡练习需要
			ext.switchmask.close(nil,30)
		end
		Print(ext.GetPauseMenuOrder())
		task.Wait(30)
		task.New(stage.current_stage,function()
			task.Wait(1)
			ext.pausemenu.resumesound()--恢复关卡声音
		end)
		
		--不能在这里就直接把自身清除，因为还在执行自身task
		self.kill=true
	end)
	task.New(self,function()--离开
		for i=40,1,-1 do
			self.imgx=-280+240*sin(i*(90/40))
			self.imgcolor[1]=i*(255/40)
			self.textposstart=90-90*sin(i*(90/40))
			ext.pauseblur_radiu=2*(i-1)/40
			task.Wait(1)
		end
	end)
end

function ext.pausemenu.del(self)--暂停菜单删除函数
	ext.rep_over=false
	ext.pop_pause_menu = nil
	ext.ClearPauseMenuType()
end

function ext.pausemenu.pausesound()--暂停关卡声音
	--暂停音乐
	if not(ext.sc_pr) then
		local _, bgm = EnumRes('bgm')
		for _,v in pairs(bgm) do
			if GetMusicState(v) ~= 'stopped' and v ~= 'deathmusic' then
				PauseMusic(v)
			end
		end
	end
	--暂停声音
	--[=[
	local sound, _ = EnumRes('snd')
	for _,v in pairs(sound) do
		if GetSoundState(v)~='stopped' then
			PauseSound(v)
		end
	end
	]=]
end

function ext.pausemenu.resumesound()--恢复关卡声音
	--恢复音乐
	local _,bgm=EnumRes('bgm')
	for _,v in pairs(bgm) do
		if GetMusicState(v)~='stopped' then
			ResumeMusic(v)
		end
	end
	--恢复声音
	--[=[
	local sound,_=EnumRes('snd')
	for _,v in pairs(sound) do
		if GetSoundState(v)=='paused' then
			ResumeSound(v)
		end
	end
	]=]
	--实现音乐淡入
	--[=[
	if not(ext.sc_pr) then
		task.New(self,function()
			local _,bgm=EnumRes('bgm')
			for i=1,30 do
				for _,v in pairs(bgm) do
					if GetMusicState(v)=='playing' then
						SetBGMVolume(v,1-i/30)
					end
				end
				task.Wait(1)
			end
		end)
	end
	--]=]
end

----------------------------------------
--暂停菜单资源

local deathmusic='deathmusic'--疮痍曲
LoadMusic(deathmusic,'THlib\\music\\player_score.ogg',34.834,27.54)

--自机活使用
LoadTexture('pause_menu','THlib\\UI\\pause_menu.png',false)
--底图
LoadImage('pause_menu_circle','pause_menu',0,0,1024,1024)
--标题
LoadImage('pause_menu_gamepause','pause_menu',1024,0,192,512)
LoadImage('pause_menu_gameover','pause_menu',1216,0,192,512)
LoadImage('pause_menu_replayfinish','pause_menu',1024,512,192,512)
LoadImage('pause_menu_scfinish','pause_menu',1216,512,192,512)
LoadImage('pause_menu_replaypause','pause_menu',2688,512,192,512)
--选项
local rtx=ext.pausemenu.rawtext
--第一排
LoadImage('pause_menu_'..rtx.retrun_to_game,'pause_menu',1408,0,640,128)
SetImageCenter('pause_menu_'..rtx.retrun_to_game,0,64)
LoadImage('pause_menu_'..rtx.return_to_title,'pause_menu',1408,128,640,128)
SetImageCenter('pause_menu_'..rtx.return_to_title,0,64)
LoadImage('pause_menu_'..rtx.give_up_and_retry,'pause_menu',1408,256,640,128)
SetImageCenter('pause_menu_'..rtx.give_up_and_retry,0,64)
LoadImage('pause_menu_'..rtx.save_replay_and_return_to_title,'pause_menu',1408,384,640,128)
SetImageCenter('pause_menu_'..rtx.save_replay_and_return_to_title,0,64)
LoadImage('pause_menu_'..rtx.save_replay,'pause_menu',1408,512,640,128)
SetImageCenter('pause_menu_'..rtx.save_replay,0,64)
LoadImage('pause_menu_'..rtx.replay_again,'pause_menu',1408,640,640,128)
SetImageCenter('pause_menu_'..rtx.replay_again,0,64)
LoadImage('pause_menu_'..rtx.manual,'pause_menu',1408,768,320,128)
SetImageCenter('pause_menu_'..rtx.manual,0,64)
LoadImage('pause_menu_'..rtx.retry,'pause_menu',1408,896,320,128)
SetImageCenter('pause_menu_'..rtx.retry,0,64)
--第一排角落
LoadImage('pause_menu_'..rtx.setting,'pause_menu',1728,896,320,128)
SetImageCenter('pause_menu_'..rtx.setting,0,64)
LoadImage('pause_menu_'..rtx.yes,'pause_menu',1728,768,160,128)
SetImageCenter('pause_menu_'..rtx.yes,0,64)
LoadImage('pause_menu_'..rtx.no,'pause_menu',1888,768,160,128)
SetImageCenter('pause_menu_'..rtx.no,0,64)
--第二排
LoadImage('pause_menu_'..rtx.continue_to_play_replay,'pause_menu',2048,0,640,128)
SetImageCenter('pause_menu_'..rtx.continue_to_play_replay,0,64)
LoadImage('pause_menu_'..rtx.continue,'pause_menu',2048,128,640,128)
SetImageCenter('pause_menu_'..rtx.continue,0,64)
