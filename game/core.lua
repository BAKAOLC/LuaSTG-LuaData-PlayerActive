--======================================
--core
--所有基础的东西都会在这里定义
--======================================

----------------------------------------
--各个模块

require "rebounding"--迟早要干掉这个

DoFile("lib\\Lmath.lua")--数学常量、数学函数、随机数系统
DoFile("plus\\plus.lua")--CHU神的plus库，replay系统、行走图系统、plusClass、NativeAPI
DoFile("ex\\ex.lua")--ESC神的ex库，多玩家支持、网络连接、多world、多输入槽位
DoFile("lib\\Lobject.lua")--Luastg的Class、object
DoFile("lib\\Lresources.lua")--资源的加载函数、资源枚举和判断
DoFile("lib\\Lscreen.lua")--world、3d、viewmode的参数设置
DoFile("lib\\Linput.lua")--按键状态更新
DoFile("lib\\Ltask.lua")--task
DoFile("lib\\Lstage.lua")--stage关卡系统
DoFile("lib\\Ltext.lua")--文字渲染
DoFile("lib\\Lscoredata.lua")--玩家存档
DoFile("sp\\sp.lua")--OLC神的sp加强库

----------------------------------------
--用户全局变量

lstg.var={username=setting.username}
lstg.tmpvar={}

function SetGlobal(k,v)
	lstg.var[k]=v
end

function GetGlobal(k,v)
	return lstg.var[k]
end

function ResetLstgtmpvar()
	lstg.tmpvar={}
end

----------------------------------------
--用户定义的一些函数

function UserSystemOperation()--模拟内核级操作
	--合并了三次遍历为一次，优化性能by ETC and OLC
	local polar,radius,angle,delta,omiga,center,
		alist,accelx,accely,gravity,
		forbid,vx,vy,v,ovx,ovy,cache
	for id = 0,15 do
		for _,obj in ObjList(id) do
			--assistance of Polar coordinate system
			polar=obj.polar
			if polar then
				radius = polar.radius or 0
				angle = polar.angle or 0
				delta = polar.delta
				if delta then polar.radius = radius + delta end
				omiga = polar.omiga
				if omiga then polar.angle = angle + omiga end
				center = polar.center or {x=0,y=0}
				radius = polar.radius
				angle = polar.angle
				obj.x = center.x + radius * cos(angle)
				obj.y = center.y + radius * sin(angle)
			end
			--acceleration and gravity
			alist = obj.acceleration
			if alist then
				accelx = alist.ax
				if accelx then obj.vx = obj.vx + accelx end
				accely = alist.ay
				if accely then obj.vy = obj.vy + accely end
				gravity = alist.g
				if gravity then obj.vy = obj.vy - gravity end
			end
			--limitation of velocity
			forbid = obj.forbidveloc
			if forbid then
				ovx = obj.vx
				ovy = obj.vy
				v = forbid.v
				if v and (v*v) < (ovx*ovx+ovy*ovy) then
					cache = v/hypot(ovx,ovy)
					obj.vx = cache*ovx
					obj.vy = cache*ovy
					ovx = obj.vx
					ovy = obj.vy
				end
				vx = forbid.vx
				vy = forbid.vy
				if vx and vx < abs(ovx) then obj.vx = vx end
				if vy and vy < abs(ovy) then obj.vy = vy end
			end
		end
	end
	--最傻吊的rebounder
	if not ReboundPause and rebounder.size ~= 0 then
		for _,obj in ObjList(GROUP_ENEMY_BULLET) do
			if IsValid(obj) and obj.colli and (obj.vx ~= 0 or obj.vy ~= 0) then
				local accel, ax, ay = obj.acceleration, 0, 0
				if accel then ax, ay = accel.ax, accel.ay end
				result = { rebounding.ReboundCheck(obj.x, obj.y, obj.vx, obj.vy, ax, ay) }
				if result[1] then
					obj.x,obj.y,obj.vx,obj.vy = unpack(result,1,4)
					if accel then accel.ax, accel.ay = result[5],result[6] end
					for i=7,#result do
						local self = rebounder.list[result[i]]
						self.class.colli(self, obj)
					end
				end
			end
		end
		for _,obj in ObjList(GROUP_INDES) do
			if IsValid(obj) and obj.colli and (obj.vx ~= 0 or obj.vy ~= 0) then
				local accel, ax, ay = obj.acceleration, 0, 0
				if accel then ax, ay = accel.ax, accel.ay end
				result = { rebounding.ReboundCheck(obj.x, obj.y, obj.vx, obj.vy, ax, ay) }
				if result[1] then
					obj.x,obj.y,obj.vx,obj.vy = unpack(result,1,4)
					if accel then accel.ax, accel.ay = result[5],result[6] end
					for i=7,#result do
						local self = rebounder.list[result[i]]
						self.class.colli(self, obj)
					end
				end
			end
		end
	end
end

function DoFrame()--行为帧动作(和游戏循环的帧动作分开)
	--标题设置
	local title=setting.mod..' | FPS='..GetFPS()..' | Objects='..GetnObj()..' | Luastg Ex Plus'
	if jstg.network.status>0 then
		title=title..' | '..jstg.NETSTATES[jstg.network.status]
		if jstg.network.status>4 then
			title=title..'('..jstg.network.delay..')'
		end
	end
	SetTitle(title)
	--切关处理
	if stage.next_stage then
		local w1=GetDefaultWorld()--by ETC，默认world参数由Lscreen提供
		jstg.ApplyWorld(w1)
		
		ResetLstgtmpvar()--重置lstg.tmpvar
		ex.Reset()--重置ex全局变量
		
		if lstg.nextvar then
			lstg.var=lstg.nextvar
			lstg.nextvar =nil
		end
		
		-- 初始化随机数
		if lstg.var.ran_seed then
			--Print('RanSeed',lstg.var.ran_seed)
			ran:Seed(lstg.var.ran_seed)
		end
		
		--lstg.var = DeSerialize(nextRecordStage.stageExtendInfo)
		--lstg.nextvar = DeSerialize(nextRecordStage.stageExtendInfo)
		--assert(lstg.var.ran_seed == nextRecordStage.randomSeed)  -- 这两个应该相等
		
		--刷新最高分
		if not stage.next_stage.is_menu then
			if scoredata.hiscore == nil then
				scoredata.hiscore = {}
			end
			lstg.tmpvar.hiscore = scoredata.hiscore[stage.next_stage.stage_name..'@'..tostring(lstg.var.player_name)]
		end
		
		jstg.enable_player=false
		
		--切换关卡
		stage.current_stage=stage.next_stage
		stage.next_stage=nil
		stage.current_stage.timer=0
		stage.current_stage:init()
		
		if not jstg.enable_player then
			jstg.Compatible()--创建自机，支持旧版本mod
		end
		
		ex.ResetSignals()--标记点清除，编辑器功能
		
		RunSystem('on_stage_init')
	end
	--刷新输入
	jstg.GetInputEx()
	--stage和object逻辑
	SetPlayer()--清除jstg.current_player指向的自机
	if GetCurrentSuperPause()<=0 or stage.nopause then
		ex.Frame()
		task.Do(stage.current_stage)
		stage.current_stage:frame()
		stage.current_stage.timer=stage.current_stage.timer+1
	end
	ObjFrame()
	if GetCurrentSuperPause()<=0 or stage.nopause then
		UserSystemOperation()
		for i=1,#jstg.worlds do
			jstg.SwitchWorld(i)
			SetWorldFlag(jstg.worlds[i].world)
			BoundCheck()
		end
	end
	if GetCurrentSuperPause()<=0 then
		CollisionCheck(GROUP_PLAYER,GROUP_ENEMY_BULLET)
		CollisionCheck(GROUP_PLAYER,GROUP_ENEMY)
		CollisionCheck(GROUP_PLAYER,GROUP_INDES)
		CollisionCheck(GROUP_ENEMY,GROUP_PLAYER_BULLET)
		CollisionCheck(GROUP_NONTJT,GROUP_PLAYER_BULLET)
		CollisionCheck(GROUP_ITEM,GROUP_PLAYER)
		--由OLC添加，可用于自机bomb
		CollisionCheck(GROUP_SPELL,GROUP_ENEMY)
		CollisionCheck(GROUP_SPELL,GROUP_NONTJT)
		CollisionCheck(GROUP_SPELL,GROUP_ENEMY_BULLET)
		CollisionCheck(GROUP_SPELL,GROUP_INDES)
	end
	UpdateXY()
	UpdateSound()
	AfterFrame()
	--切关时清空资源和回收对象
	if stage.next_stage and stage.current_stage then
		stage.current_stage:del()
		task.Clear(stage.current_stage)
		if stage.preserve_res then
			stage.preserve_res=nil
		else
			RemoveResource'stage'
		end
		ResetPool()
	end
end

function BeforeRender()
end

function AfterRender()
end

function GameExit()

end

----------------------------------------
--全局回调函数，底层调用

lstg.quit_flag=false
lstg.paused=false

function GameInit()
	SetViewMode'world'
	if stage.next_stage==nil then
		error('Entrance stage not set.')
	end
	SetResourceStatus'stage'
end

function FrameFunc()
	DoFrame(true,true)
	if lstg.quit_flag then GameExit() end
	return lstg.quit_flag
end

function RenderFunc()
	if stage.current_stage.timer>1 and stage.next_stage==nil then
		BeginScene()
		BeforeRender()
		stage.current_stage:render()
		ObjRender()
		AfterRender()
		EndScene()
	end
end

function FocusLoseFunc()

end

function FocusGainFunc()

end

----------------------------------------
--加载mod包

if setting.mod~='launcher' then
	Include 'root.lua'
else
	Include 'launcher.lua'
end

if setting.mod~='launcher' then
	_mod_version=_mod_version or 0
	if _mod_version>_luastg_version or _mod_version<_luastg_min_support then error(string.format("Mod version and engine version mismatch. Mod version is %.2f, LuaSTG version is %.2f.",_mod_version/100,_luastg_version/100)) end
end

----------------------------------------
--游戏循环开始前最后的准备

InitAllClass()--对所有class的回调函数进行整理，给底层调用
InitScoreData()--装载玩家存档
if _render_debug then DoFile("lib\\Erenderdebug.lua") end--性能监视
