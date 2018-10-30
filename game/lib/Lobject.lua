--======================================
--luastg object
--======================================

----------------------------------------
--碰撞组(底层所需)
GROUP_GHOST=0
GROUP_ENEMY_BULLET=1
GROUP_ENEMY=2
GROUP_PLAYER_BULLET=3
GROUP_PLAYER=4
GROUP_INDES=5
GROUP_ITEM=6
GROUP_NONTJT=7
GROUP_SPELL=8--由OLC添加，可用于自机bomb
GROUP_ALL=16
GROUP_NUM_OF_GROUP=16
--层次结构
LAYER_BG=-700
LAYER_ENEMY=-600
LAYER_PLAYER_BULLET=-500
LAYER_PLAYER=-400
LAYER_ITEM=-300
LAYER_ENEMY_BULLET=-200
LAYER_ENEMY_BULLET_EF=-100
LAYER_TOP=0

----------------------------------------
--class

all_class={}
class_name={}

--base class of all classes
object={0,0,0,0,0,0;
	is_class=true,
	init=function()end,
	del=function()end,
	frame=function()end,
	render=DefaultRenderFunc,
	colli=function(other)end,
	kill=function()end
}

--define new class
function Class(base, define)
	base=base or object
	if (type(base)~='table') or not base.is_class then
		error('Invalid base class or base class does not exist.')
	end
	local result={0,0,0,0,0,0}
	result.is_class=true
	result.init=base.init
	result.del=base.del
	result.frame=base.frame
	result.render=base.render
	result.colli=base.colli
	result.kill=base.kill
	result.base=base
	if define then
		for k,v in pairs(define) do
			result[k] = v
		end
	end
	table.insert(all_class,result)
	return result
end

--对所有class的回调函数进行整理，给底层调用
function InitAllClass()
	for _,v in pairs(all_class) do
		v[1]=v.init
		v[2]=v.del
		v[3]=v.frame
		v[4]=v.render
		v[5]=v.colli
		v[6]=v.kill
	end
end

----------------------------------------
--单位管理

function RawDel(o)
	if o then
		o.status='del'
		if o._servants then _del_servants(o) end
	end
end

function RawKill(o)
	if o then
		o.status='kill'
		if o._servants then _kill_servants(o) end
	end
end

function PreserveObject(o)
	o.status='normal'
end


local OldKill = Kill
local OldDel = Del

function Kill(o)
	if o then
		if o._servants then _kill_servants(o) end
		OldKill(o)
	end
end

function Del(o)
	if o then
		if o._servants then _del_servants(o) end
		OldDel(o)
	end
end

--！潜在问题：多玩家适配
function SetV2(obj,v,angle,rot,aim)
	if aim then
		SetV(obj,v,angle+Angle(obj,_Player(obj)),rot)
	else
		SetV(obj,v,angle,rot)
	end
end
