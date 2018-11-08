--======================================
--switch mask
--code by ETC
--======================================

----------------------------------------
--切关幕布

ext.switchmask={}

function ext.switchmask.New()
	local sm={}
	ext.switchmask.init(sm)
	return sm
end

function ext.switchmask.init(self)
	self.x=0
	self.y=0
	self.tick=0
	self.tick_d=-0.05
	self.timer=0
end

function ext.switchmask.frame(self)
	task.Do(self)
	self.tick=self.tick+self.tick_d
	self.tick=max(0,min(1,self.tick))
	self.timer=self.timer+1
end

function ext.switchmask.render(self)
	if self.tick>0 then
		SetViewMode'ui'
		
		PushRenderTarget('_switch_mask_tex')
		RenderClear(Color(255,0,0,0))
		local img='_switch_mask_img'
		local timer=self.timer
		local w,h=GetTextureSize(img)
		local x,y=timer/4,timer/2
		for i=-int((0+16+x)/w+0.5),int((screen.width+16-x)/w+0.5) do
			for j=-int((0+16+y)/h+0.5),int((screen.height+16-y)/h+0.5) do
				Render(img,x+i*w,y+j*h)
			end
		end
		PopRenderTarget('_switch_mask_tex')
		
		PushRenderTarget('_switch_mask')
		RenderClear(Color(255,0,0,0))
		local k=sin(90*self.tick)
		Render4V('_switch_mask_eff1',
			(1-k)*(-screen.width)+           0,screen.height,0.5,
			(1-k)*(-screen.width)+screen.width,screen.height,0.5,
			(1-k)*(-screen.width)+screen.width,            0,0.5,
			(1-k)*(-screen.width)+           0,            0,0.5
		)
		Render4V('_switch_mask_eff2',
			(1-k)*screen.width+           0,screen.height,0.5,
			(1-k)*screen.width+screen.width,screen.height,0.5,
			(1-k)*screen.width+screen.width,            0,0.5,
			(1-k)*screen.width+           0,            0,0.5
		)
		PopRenderTarget('_switch_mask')
		
		PostEffect('_switch_mask_tex','texture_mask','',{tex='_switch_mask'})
		
		SetViewMode'world'
	end
end

function ext.switchmask.gethandle()--用于获得当前执行幕布逻辑的对象
	return ext.switch_mask
end


--target指向要执行幕布切换task的对象，填nil时会每帧执行，传入obj对象时会依靠obj的更新来执行（obj对象需要执行task.Do）--已弃用
--现在幕布不会被暂停
--t为变化的持续时间
function ext.switchmask.close(target,t)
	local sm=ext.switchmask.gethandle()
	sm.tick_d=1/t
	do return end
	if target==nil then
		target=sm
	end
	task.New(target,function()
		local sm=ext.switchmask.gethandle()
		for i=1,t do
			sm.tick=sin(90*(i/t))
			task.Wait(1)
		end
	end)
end

function ext.switchmask.open(target,t)
	local sm=ext.switchmask.gethandle()
	sm.tick_d=-1/t
	do return end
	if target==nil then
		target=sm
	end
	task.New(target,function()
		local sm=ext.switchmask.gethandle()
		for i=1,t do
			sm.tick=sin(90*(1-(i/t)))
			task.Wait(1)
		end
	end)
end

function ext.switchmask.set(n)
	local sm=ext.switchmask.gethandle()
	sm.tick=n
end

----------------------------------------
--资源加载

LoadFX('texture_mask','shader\\texture_mask.fx')
CreateRenderTarget('_switch_mask')
CreateRenderTarget('_switch_mask_tex')
LoadImageFromFile('_switch_mask_img','THlib\\ui\\switch_mask.png')
LoadImageFromFile('_switch_mask_eff1','THlib\\ui\\switch_mask_eff1.png')
LoadImageFromFile('_switch_mask_eff2','THlib\\ui\\switch_mask_eff2.png')
