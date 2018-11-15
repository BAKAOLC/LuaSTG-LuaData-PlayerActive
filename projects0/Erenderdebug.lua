--======================================
--用于计数各个Draw Call的次数
--by Xiliusha
--======================================

----------------------------------------
--获取毫秒接口

--鸽了

----------------------------------------
--RenderDebug

lstg.RenderDebug={}

local SCALE=1.0 --全局缩放
local onoff=false
local collibox=false

local drawcall=0
local dfrcall=0
local rendercall=0
local rrectcall=0
local r4vcall=0
local rtxcall=0
local rtfcall=0
local rttfcall=0
local postrfcall=0
local postappcall=0

local colorcall=0
local setselfimg=0
local setimg=0
local setani=0
local setfnt=0

function lstg.RenderDebug.ResetDrawcallTimer()
	drawcall=0
	dfrcall=0
	rendercall=0
	rrectcall=0
	r4vcall=0
	rtxcall=0
	rtfcall=0
	rttfcall=0
	postrfcall=0
	postappcall=0

	colorcall=0
	setselfimg=0
	setimg=0
	setani=0
	setfnt=0
end

function lstg.RenderDebug.GetDrawcallTimer()
	return drawcall,dfrcall,rendercall,rrectcall,r4vcall,rtxcall,rtfcall,rttfcall,postrfcall,postappcall,
		colorcall,setselfimg,setimg,setani,setfnt
end


local OldDefaultRenderFunc=DefaultRenderFunc
local OldRender=Render
local OldRenderRect=RenderRect
local OldRender4V=Render4V
local OldRenderTexture=RenderTexture
local OldRenderText=RenderText
local OldRenderTTF=RenderTTF
local OldPostEffect=PostEffect
local OldPostEffectApply=PostEffectApply

local OldSetImgState=SetImgState
local OldSetImageState=SetImageState
local OldSetAnimationState=SetAnimationState
local OldSetFontState=SetFontState


--用于重载各种函数
local function SwichRenderFunc()
	function DefaultRenderFunc( ... )
		drawcall=drawcall+1
		dfrcall=dfrcall+1
		OldDefaultRenderFunc( ... )
	end
	function Render( ... )
		drawcall=drawcall+1
		rendercall=rendercall+1
		OldRender( ... )
	end
	function RenderRect( ... )
		drawcall=drawcall+1
		rrectcall=rrectcall+1
		OldRenderRect( ... )
	end
	function Render4V( ... )
		drawcall=drawcall+1
		r4vcall=r4vcall+1
		OldRender4V( ... )
	end
	function RenderTexture( ... )
		drawcall=drawcall+1
		rtxcall=rtxcall+1
		OldRenderTexture( ... )
	end
	function RenderText( ... )
		drawcall=drawcall+1
		rtfcall=rtfcall+1
		OldRenderText( ... )
	end
	function RenderTTF( ... )
		drawcall=drawcall+1
		rttfcall=rttfcall+1
		OldRenderTTF( ... )
	end
	function PostEffect( ... )
		drawcall=drawcall+1
		postrfcall=postrfcall+1
		OldPostEffect( ... )
	end
	function PostEffectApply( ... )
		drawcall=drawcall+1
		postappcall=postappcall+1
		OldPostEffectApply( ... )
	end
	
	function SetImgState( ... )
		colorcall=colorcall+1
		setselfimg=setselfimg+1
		OldSetImgState( ... )
	end
	function SetImageState( ... )
		colorcall=colorcall+1
		setimg=setimg+1
		OldSetImageState( ... )
	end
	function SetAnimationState( ... )
		colorcall=colorcall+1
		setani=setani+1
		OldSetAnimationState( ... )
	end
	function SetFontState( ... )
		colorcall=colorcall+1
		setfnt=setfnt+1
		OldSetFontState( ... )
	end
end

local function ResetRenderFunc()
	DefaultRenderFunc=OldDefaultRenderFunc
	Render=OldRender
	RenderRect=OldRenderRect
	Render4V=OldRender4V
	RenderTexture=OldRenderTexture
	RenderText=OldRenderText
	RenderTTF=OldRenderTTF
	PostEffect=OldPostEffect
	PostEffectApply=OldPostEffectApply

	SetImgState=OldSetImgState
	SetImageState=OldSetImageState
	SetAnimationState=OldSetAnimationState
	SetFontState=OldSetFontState
end

local keydownF5=false--colli box
local keydownF6=false--render call
local keydownF7=false--cheat

local keydownF3=false
local keydownF4=false

local Collision_Checker = {}
Collision_Checker.list = {
	{GROUP_PLAYER_BULLET, Color(255, 127, 127, 192)},
	{GROUP_PLAYER, Color(255, 50, 255, 50)},
	{GROUP_ENEMY, Color(255, 255, 255, 128)},
	{GROUP_NONTJT, Color(255, 128, 255, 255)},
	{GROUP_ENEMY_BULLET, Color(255, 255, 50, 50)},
	{GROUP_INDES, Color(255, 255, 165, 10)},
}

function lstg.RenderDebug.RenderDrawcallTimer()
	--timeslow
	if GetKeyState(114) then
		if not keydownF3 then
			keydownF3 = true
			if not lstg.var.timeslow then lstg.var.timeslow=1 end
			lstg.var.timeslow=lstg.var.timeslow-1
			lstg.var.timeslow=max(1,min(4,lstg.var.timeslow))
		end
	else
		keydownF3 = false
	end
	if GetKeyState(115) then
		if not keydownF4 then
			keydownF4 = true
			if not lstg.var.timeslow then lstg.var.timeslow=1 end
			lstg.var.timeslow=lstg.var.timeslow+1
			lstg.var.timeslow=max(1,min(4,lstg.var.timeslow))
		end
	else
		keydownF4 = false
	end
	--cheat
	if GetKeyState(118) then
		if not keydownF7 then
			keydownF7 = true
			cheat = not(cheat)
		end
	else
		keydownF7 = false
	end
	if cheat then
		SetViewMode'ui'
		SetFontState('item','',Color(0xFFFFFF00))
		RenderText('item', "Cheat", screen.width - 8, screen.height - 4, 1, "right", "top")
		SetViewMode'world'
	end
	--colli box
	if GetKeyState(116) then
		if not keydownF5 then
			keydownF5 = true
			collibox = not(collibox)
		end
	else
		keydownF5 = false
	end
	if collibox then
		SetViewMode'world'
		for i = 1, #Collision_Checker.list do
			SetImageState("collision_rect", '', Collision_Checker.list[i][2])
			SetImageState("collision_ring", '', Collision_Checker.list[i][2])
			for _, unit in ObjList(Collision_Checker.list[i][1]) do
				if unit.colli then
					if unit.rect == true then
						img = "collision_rect"
					else
						img = "collision_ring"
					end
					Render(img, unit.x, unit.y, unit.rot, 2 * unit.a / 128, 2 * unit.b / 128)
				end
			end
		end
	end
	--display info
	if onoff then
		SetViewMode'ui'
		local drawcall,dfrcall,rendercall,rrectcall,r4vcall,rtxcall,rtfcall,rttfcall,postrfcall,postappcall,
			colorcall,setselfimg,setimg,setani,setfnt=lstg.RenderDebug.GetDrawcallTimer()
		SetImageState("white","",Color(128,0,0,0))
		RenderRect("white",0,SCALE*128,0,SCALE*186)
		SetFontState('menu','',Color(0xFFFFFFFF))
		RenderText('menu',string.format('%d Darw call\
%d DefaultRenderFunc call\
%d Render call\
%d RenderRect call\
%d Render4V call\
%d RenderTexture call\
%d RenderText call\
%d RenderTTF call\
%d PostEffect call\
%d PostEffectApply call\
\
%d ColorSet call\
%d SetImgState call\
%d SetImageState call\
%d SetAnimationState call\
%d SetFontState call',drawcall+2,dfrcall,rendercall,rrectcall+1,r4vcall,rtxcall,rtfcall+1,rttfcall,postrfcall,postappcall,
			colorcall+2,setselfimg,setimg+1,setani,setfnt+1),SCALE*124,SCALE*1,SCALE*0.25,'right','bottom')
		lstg.RenderDebug.ResetDrawcallTimer()
		SetViewMode'world'
	end
	--render call time
	if GetKeyState(117) then
		if not keydownF6 then
			keydownF6 = true
			onoff = not(onoff)
		end
		if onoff then
			SwichRenderFunc()
		else
			ResetRenderFunc()
		end
	else
		keydownF6 = false
	end
end

----------------------------------------
--image res

if _render_debug then
	LoadTexture("Collision_render", "lib\\render_colli.png")
else
	LoadTexture("Collision_render", "render_colli.png")
end
LoadImage("collision_rect", "Collision_render", 0, 0, 128, 128)
LoadImage("collision_ring", "Collision_render", 130, 0, 128, 128)
