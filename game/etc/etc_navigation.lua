--======================================
--自机活额外辅助库
--小地图
--code by Xiliusha
--======================================

----------------------------------------
--小地图辅助函数
--if not etc then etc={} end

etc.navigation={}

local RANK_COLOR_INDEX={
	Color(128,0,255,0),
	Color(128,255,255,0),
	Color(128,255,0,0),
} RANK_COLOR_INDEX[0]=Color(128,0,0,255)

function etc.navigation.render1(renderlist,scale,width)--渲染可视部分
	local u,a,s,w=nil,0,scale or 16,width or 8
	for i=1,#renderlist do
		u=renderlist[i]
		a=Angle(u.x1,u.y1,u.x2,u.y2)
		SetImageState('white','',RANK_COLOR_INDEX[u.rank])
		Render4V('white',
			s*u.x1+(w/2)*cos(a-90),s*u.y1+(w/2)*sin(a-90),0.5,
			s*u.x1+(w/2)*cos(a+90),s*u.y1+(w/2)*sin(a+90),0.5,
			s*u.x2+(w/2)*cos(a+90),s*u.y2+(w/2)*sin(a+90),0.5,
			s*u.x2+(w/2)*cos(a-90),s*u.y2+(w/2)*sin(a-90),0.5
		)
	end
end

function etc.navigation.render2(renderlist,scale,width)--渲染整个地图，地图详细情况不显示
	local u,a,s,w=nil,0,scale or 16,width or 8
	for i=1,#renderlist do
		u=renderlist[i]
		a=Angle(u.x1,u.y1,u.x2,u.y2)
		SetImageState('white','',Color(128,255,255,255))
		Render4V('white',
			s*u.x1+(w/2)*cos(a-90),s*u.y1+(w/2)*sin(a-90),0.5,
			s*u.x1+(w/2)*cos(a+90),s*u.y1+(w/2)*sin(a+90),0.5,
			s*u.x2+(w/2)*cos(a+90),s*u.y2+(w/2)*sin(a+90),0.5,
			s*u.x2+(w/2)*cos(a-90),s*u.y2+(w/2)*sin(a-90),0.5
		)
	end
end

function etc.navigation.New()--创建一个高德导航
end

function etc.navigation:init()
end

function etc.navigation:frame()--每帧更新所有区块的可见性
end

function etc.navigation:update()--刷新可见性
end

function etc.navigation:render()
end
