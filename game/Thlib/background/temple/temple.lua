temple_background=Class(object)

function temple_background:init()
	--
	background.init(self,false)
	--resource
	LoadImageFromFile('temple_road','THlib\\background\\temple\\road.png')
	LoadImageFromFile('temple_ground','THlib\\background\\temple\\ground.png')
	LoadImageFromFile('temple_pillar','THlib\\background\\temple\\pillar.png')
	--set 3d camera and fog
	Set3D('eye',0,2,-4)
	Set3D('at',0,0,-0.3)
	Set3D('up',0,1,0)
	Set3D('z',1,10)
	Set3D('fovy',0.6)
	Set3D('fog',5,10,Color(0xFFFFFFFF))
	--
	self.speed=0.02
	self.z=0
end

function temple_background:frame()
	self.z=self.z+self.speed
end

function temple_background:render()
	SetViewMode'3d'

	local showboss = IsValid(_boss)
	if showboss then
        PostEffectCapture()
    end


	for j=-1,5,1 do
		local dz=j*2-math.mod(self.z,2)
		Render4V('temple_ground', 0.5,0,dz, 2.5,0,dz, 2.5,0,-2+dz, 0.5,0,-2+dz)
		Render4V('temple_ground',-0.5,0,dz,-2.5,0,dz,-2.5,0,-2+dz,-0.5,0,-2+dz)
		Render4V('temple_road',-1,0,dz,1,0,dz,1,0,-2+dz,-1,0,-2+dz)
		
		Render4V('temple_ground', 4.5,0,dz, 2.5,0,dz, 2.5,0,-2+dz, 4.5,0,-2+dz)
		Render4V('temple_ground',-4.5,0,dz,-2.5,0,dz,-2.5,0,-2+dz,-4.5,0,-2+dz)
	end
	for j=3,-1,-1 do
		local dz=j*2-math.mod(self.z,2)
		temple_background.draw_pillar( 0.85,dz+0.2,1.8,0,0.15)
		temple_background.draw_pillar( 3*0.85,dz+0.2,1.8,0,0.15)
		temple_background.draw_pillar(-0.85,dz+0.2,1.8,0,0.15)
		temple_background.draw_pillar(-3*0.85,dz+0.2,1.8,0,0.15)
	end


	if showboss then
		local x,y = WorldToScreen(_boss.x,_boss.y)
		local x1 = x * screen.scale
		local y1 = (screen.height - y) * screen.scale
		local fxr = _boss.fxr or 163
		local fxg = _boss.fxg or 73
		local fxb = _boss.fxb or 164
		PostEffectApply("boss_distortion", "", {
			centerX = x1,
			centerY = y1,
			size = _boss.aura_alpha*200*lstg.scale_3d,
			color = Color(125,fxr,fxg,fxb),
			colorsize = _boss.aura_alpha*200*lstg.scale_3d,
			arg=1500*_boss.aura_alpha/128*lstg.scale_3d,
			timer = self.timer
        })
	end
	SetViewMode'world'
end

function temple_background.draw_pillar(x,z,y1,y2,r)
	local a=0
	local d=r*cos(22.5)
	local eyex,eyez
	eyex=lstg.view3d.eye[1]-x
	eyez=lstg.view3d.eye[3]-z
	for _=1,8 do
		if d*cos(a)*eyex+d*sin(a)*eyez-d*d>0 then
			local blk=255*(((1-cos(a)*SQRT2_2+sin(a)*SQRT2_2)*0.5)+0.0625)
			SetImageState('temple_pillar','',Color(255,blk,blk,blk))
			Render4V('temple_pillar',
			x+r*cos(a-22.5),y1,z+r*sin(a-22.5),
			x+r*cos(a+22.5),y1,z+r*sin(a+22.5),
			x+r*cos(a+22.5),y2,z+r*sin(a+22.5),
			x+r*cos(a-22.5),y2,z+r*sin(a-22.5))
		end
		a=a+45
	end
end
