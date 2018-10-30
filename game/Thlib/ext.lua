--======================================
--stagegroup|replay|pausemenu system
--======================================

----------------------------------------
--ext加强库
--现已被拆成3个部分

ext={}

local extpath="Thlib\\ext\\"

DoFile(extpath.."ext_pause_menu.lua")--暂停菜单和暂停菜单资源
DoFile(extpath.."ext_replay.lua")--CHU爷爷的replay系统以及切关函数重载
DoFile(extpath.."ext_stage_group.lua")--关卡组

ext.replayTicker=0--控制录像速度时有用
ext.slowTicker=0--控制时缓的变量
ext.time_slow_level={1, 2, 3, 4}--60/30/20/15 4个程度

function ext.ResetTicker()
	ext.replayTicker=0
	ext.slowTicker=0
end

function ext.GetPauseMenuOrder()
	return ext.pause_menu_order
end

----------------------------------------
--extra game loop

function GameStateChange()--？？？
end

function GetInput()--不再使用，已转为jstg.GetInputEX
	if stage.next_stage then
		-- 把一些转场的破事放到这里处理，NOT GOOD
		local w1=GetDefaultWorld()
		jstg.ApplyWorld(w1)
		
		ResetLstgtmpvar()--重置lstg.tmpvar
		ex.Reset()--重置ex全局变量
		
		if lstg.nextvar then
			lstg.var=lstg.nextvar
			lstg.nextvar =nil
		end
		-- 初始化随机数
		if lstg.var.ran_seed then
			Print('RanSeed',lstg.var.ran_seed)
			ran:Seed(lstg.var.ran_seed)
		end
		
		--lstg.var = DeSerialize(nextRecordStage.stageExtendInfo)
		--lstg.nextvar = DeSerialize(nextRecordStage.stageExtendInfo)
		--assert(lstg.var.ran_seed == nextRecordStage.randomSeed)  -- 这两个应该相等
		
		KeyStatePre = {}
		if not stage.next_stage.is_menu then
			if scoredata.hiscore == nil then
				scoredata.hiscore = {}
			end
			lstg.tmpvar.hiscore = scoredata.hiscore[stage.next_stage.stage_name..'@'..tostring(lstg.var.player_name)]
		end
	else
		-- 刷新KeyStatePre
		for k, v in pairs(setting.keys) do
			KeyStatePre[k] = KeyState[k]
		end
	end
	
	-- 不是录像时更新按键状态
	if not ext.replay.IsReplay() then
		for k,v in pairs(setting.keys) do
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

function FrameFunc()
	if jstg then jstg.ProceedConnect() end--刷新网络状态
	boss_ui.active_count=0--重设boss ui的槽位（多boss支持）
	if GetLastKey() == setting.keysys.snapshot and setting.allowsnapshot then
		Snapshot('snapshot\\'..os.date("!%Y-%m-%d-%H-%M-%S", os.time() + setting.timezone * 3600)..'.png')--支持时区
	end
	--无暂停时执行场景逻辑
	if ext.pause_menu == nil then
		--处理录像速度与正常更新逻辑
		if ext.replay.IsReplay() then
			--播放录像时
			ext.replayTicker = ext.replayTicker + 1
			ext.slowTicker = ext.slowTicker + 1
			if GetKeyState(setting.keysys.repfast) then
				for _=1,4 do
					DoFrame(true, false)
					ext.pause_menu_order = nil
				end
			elseif GetKeyState(setting.keysys.repslow) then
				if ext.replayTicker % 4 == 0 then
					DoFrame(true, false)
					ext.pause_menu_order = nil
				end
			else
				if lstg.var.timeslow then
					local tmp=min(4,max(1,lstg.var.timeslow))
					if ext.slowTicker%(ext.time_slow_level[tmp])==0 then
						DoFrame(true, false)
					end
				else
					DoFrame(true, false)
				end
				ext.pause_menu_order = nil
			end
		else
			--正常游戏时
			ext.slowTicker=ext.slowTicker+1
			if lstg.var.timeslow and lstg.var.timeslow>0 then
				local tmp=min(4,max(1,lstg.var.timeslow))
				if ext.slowTicker%(ext.time_slow_level[tmp])==0 then
					DoFrame(true, false)
				end
			else
				DoFrame(true, false)
			end
		end
		--按键弹出菜单
		if (GetLastKey() == setting.keysys.menu or ext.pop_pause_menu) and not stage.current_stage.is_menu then
			ext.pop_pause_menu = nil
			ext.rep_over=false
			PlaySound('pause', 0.5)
			if not(ext.sc_pr) then
			local _, bgm = EnumRes('bgm')
				for _,v in pairs(bgm) do
					if GetMusicState(v) ~= 'stopped' and v ~= 'deathmusic' then
						PauseMusic(v)
					end
				end
			end
			--[=[
			local sound, _ = EnumRes('snd')
			for _,v in pairs(sound) do
				if GetSoundState(v)~='stopped' and v ~= 'pause' then
					PauseSound(v)
				end
			end
			]=]
			ext.pause_menu=ext.pausemenu.New()--创建暂停菜单
		end
	else
		--暂停菜单部分
		--需要更新输入
		jstg.GetInputEx(true)
		
		--暂停菜单逻辑
		ext.pause_menu.frame(ext.pause_menu)
		if ext.pause_menu.kill then ext.pause_menu=nil end
	end
	if lstg.quit_flag then
		GameExit()
	end
	return lstg.quit_flag
end

function RenderFunc()
	--！更改：只有关卡和object的渲染丢到了if里面，其他的正常每帧渲染
	SetWorldFlag(1)
	BeginScene()
	BeforeRender()
	if stage.current_stage.timer and stage.current_stage.timer > 1 and stage.next_stage == nil then
		stage.current_stage:render()
		for i=1,#jstg.worlds do
			jstg.SwitchWorld(i)
			SetWorldFlag(jstg.worlds[i].world)
			ObjRender()
			SetViewMode'world'
			DrawCollider()
		end
		if not stage.current_stage.is_menu then RunSystem("on_stage_render") end
	end
	AfterRender()
	EndScene()
end

function AfterRender()
	if ext.pause_menu then
		--暂停菜单渲染
		ext.pause_menu.render(ext.pause_menu)
	end
	if _render_debug then
		lstg.RenderDebug.RenderDrawcallTimer()--用于制作者检查是否有渲染函数调用过多的问题
	end
end

function FocusLoseFunc()
	if ext.pause_menu==nil and stage.current_stage and jstg.network.status==0 then
		if not stage.current_stage.is_menu then
			ext.pop_pause_menu=true
		end
	end
end
