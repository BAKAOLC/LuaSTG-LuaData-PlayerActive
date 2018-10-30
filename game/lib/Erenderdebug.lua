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

function lstg.RenderDebug.RenderDrawcallTimer()
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
	if _GetLastKey()==setting.keysys.renderdebug then
		onoff=not(onoff)
		if onoff then
			SwichRenderFunc()
		else
			ResetRenderFunc()
		end
	end
end


lstg.RenderDebug.obj=Class(object)
function lstg.RenderDebug.obj:init()
	self.layer=LAYER_TOP+1000
	self.group=GROUP_GHOST
	self.bound=false
	self.x,self.y=0,0
end
function lstg.RenderDebug.obj:render()
	lstg.RenderDebug.RenderDrawcallTimer()
end

