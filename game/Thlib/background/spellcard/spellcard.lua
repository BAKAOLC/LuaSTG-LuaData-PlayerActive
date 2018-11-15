--======================================
--boss spelllcard background
--======================================

----------------------------------------
--自机活符卡展开效果

--LoadFX('texture_mask','shader\\texture_mask.fx')
CreateRenderTarget('_boss_sc_mask')
CreateRenderTarget('_boss_sc_tex')

local function sc_bg_mask_capture(self)
	PushRenderTarget('_boss_sc_tex')
	RenderClear(Color(255,0,0,0))
end

local function sc_bg_mask_render(self)
	PopRenderTarget('_boss_sc_tex')
	PushRenderTarget('_boss_sc_mask')
	RenderClear(Color(255,0,0,0))
	local w=lstg.world
	if self.alpha<1 then
		local maxR=math.max(
			Dist(self.px,self.py,w.l,w.t),
			Dist(self.px,self.py,w.r,w.t),
			Dist(self.px,self.py,w.l,w.b),
			Dist(self.px,self.py,w.r,w.b)
		)
		rendercircle2(self.px,self.py,self.alpha*maxR,30,'',Color(255,255,255,255))
	else
		SetImageState('white','',Color(255,255,255,255))
		RenderRect('white',w.l,w.r,w.b,w.t)
	end
	PopRenderTarget('_boss_sc_mask')
	PostEffect('_boss_sc_tex','texture_mask','',{tex='_boss_sc_mask'})
end

----------------------------------------
--spelllcard background

_spellcard_background=Class(background)
function _spellcard_background:init()
	background.init(self,true)
	self.layers={}
	self.fxsize=0
	self.px,self.py=self.x,self.y
end
function _spellcard_background:AddLayer(img,tile,x,y,rot,vx,vy,omiga,blend,hscale,vscale,init,frame,render)
	table.insert(self.layers,{img=img,tile=tile,x=x,y=y,rot=rot,vx=vx,vy=vy,omiga=omiga,blend=blend,a=255,r=255,g=255,b=255,frame=frame,render=render,timer=0,hscale=hscale,vscale=vscale})
	if init then init(self.layers[#self.layers]) end
end
function _spellcard_background:frame()
	if IsValid(_boss) then
		self.px,self.py=_boss.x,_boss.y
	end
	for _,l in ipairs(self.layers) do
		l.x=l.x+l.vx
		l.y=l.y+l.vy
		l.rot=l.rot+l.omiga
		l.timer=l.timer+1
		if l.frame then l.frame(l) end
		if lstg.tmpvar.bg and lstg.tmpvar.bg.hide==true then
			self.fxsize=min(self.fxsize+2,200)
		else
			self.fxsize=max(self.fxsize-2,0)
		end
	end
end
function _spellcard_background:render()
	SetViewMode'world'
	if self.alpha>0 then
		sc_bg_mask_capture(self)
		
		local showboss = IsValid(_boss) and lstg.tmpvar.bg and lstg.tmpvar.bg.hide==true
		if showboss then
			PostEffectCapture()
		end
		for i=#(self.layers),1,-1 do
			local l=self.layers[i]
			--SetImageState(l.img,l.blend,Color(l.a*self.alpha,l.r,l.g,l.b))
			SetImageState(l.img,l.blend,Color(l.a,l.r,l.g,l.b))
			local world=lstg.world
			if l.tile then
				local w,h=GetTextureSize(l.img)
				for i=-int((world.r+16+l.x)/w+0.5),int((world.r+16-l.x)/w+0.5) do
					for j=-int((world.t+16+l.y)/h+0.5),int((world.t+16-l.y)/h+0.5) do
						Render(l.img,l.x+i*w,l.y+j*h)
					end
				end
			else
				Render(l.img,l.x,l.y,l.rot,l.hscale,l.vscale)
			end
			if l.render then l.render(l) end
		end
		if showboss then
		local x,y = WorldToScreen(_boss.x,_boss.y)
		local x1 = x * screen.scale
		local y1 = (screen.height - y) * screen.scale
		local fxa = _boss.fxa or 125
		local fxr = _boss.fxr or 163
		local fxg = _boss.fxg or 73
		local fxb = _boss.fxb or 164
		PostEffectApply("boss_distortion", "mul+alpha", {
			centerX = x1,
			centerY = y1,
			size = _boss.aura_alpha*self.fxsize*lstg.scale_3d,
			color = Color(fxa*self.fxsize/200,fxr,fxg,fxb),
			colorsize = _boss.aura_alpha*200*lstg.scale_3d,
			arg=1500*_boss.aura_alpha/128*lstg.scale_3d,
			timer = self.timer
        })
		end
		
		sc_bg_mask_render(self)
	end
end

----------------------------------------
--default style

LoadImageFromFile("_scbg","THlib\\background\\spellcard\\background.png",true,0,0,false)
LoadImageFromFile("_scbg_mask","THlib\\background\\spellcard\\mask.png",true,0,0,false)
spellcard_background=Class(_spellcard_background)
spellcard_background.init=function(self)
	_spellcard_background.init(self)
	--自适应缩放底图
	local w=lstg.world
	local tw=w.r-w.l
	local scale=tw/416
	_spellcard_background.AddLayer(self,"_scbg_mask",true,0,0,0,1,1,0,"",1,1,nil,nil)
	_spellcard_background.AddLayer(self,"_scbg",false,0,0,0,0,0,0,"",scale,scale,nil,nil)
end
