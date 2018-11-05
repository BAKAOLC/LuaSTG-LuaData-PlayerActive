--======================================
--自机活额外辅助库
--map
--code by Xiliusha
--======================================

----------------------------------------
--map
if not etc then etc={} end
etc.map={}

function etc.map.New(existing)
	local m={
		SetCross=etc.map.SetCross,
		SetCrossIndex=etc.map.SetCrossIndex,
		Sniff=etc.map.Sniff,
	}
	--复制表，而不是直接赋值
	if type(existing)=='table' then
		for k,v in pairs(existing) do
			m[k]=v
		end
	end
	return m
end

function etc.map:SetCross(cross_id,cross_x,cross_y,index_number)--新增节点（路口）
	local tmp={}
	local n=index_number or 4
	for i=1,n do
		tmp[i]=false
	end
	self[cross_id]={
		cross=cross_id,
		index=tmp,
		enter=false,
		x=cross_x,
		y=cross_y,
	}
end

function etc.map:SetCrossIndex(cross_id,index_id,target_cross_id,entrance)--设置节点（路口）的连通
	self[cross_id].index[index_id]={
		cross=target_cross_id,
		enter=entrance,
	}
end

local CROSS_INDEX={}--用于储存嗅探时重复的节点

function etc.map:Sniff(crossid,maxd)--嗅探与指定节点（路口）所连接的连通道路的信息，可指定嗅探的遍历深度
	CROSS_INDEX={}
	local sf=function(self,crossid,maxd,d,sf)--辅助函数
		if CROSS_INDEX[crossid]==true then--避免重复
			return false
		else
			CROSS_INDEX[crossid]=true--标记
			local info={}
			local index=self[crossid].index
			for i=1,#index do
				if type(index[i])=='table' then
					local cross_id=index[i].cross
					if CROSS_INDEX[cross_id]==true then--避免重复
						info[i]=false
					else
						--CROSS_INDEX[cross_id]=true--这个位置标记可能会导致一些连通段缺失
						info[i]={
							cross=cross_id
						}
						if d<maxd then
							info[i].child=sf(self,cross_id,maxd,d+1,sf)
						end
					end
				else
					info[i]=false
				end
			end
			return info
		end
	end
	return sf(self,crossid,maxd,1,sf)
end

function etc.map:SetBlock(block_name,cross_id_1,cross_id_2,rank,active)
	--
end

function etc.map:FindBlock(block_name)
	--
end

----------------------------------------
--map test

local mymap

do
mymap=etc.map.New()
mymap:SetCross(2,1,0)
	mymap:SetCrossIndex(2,2,5,4)
	mymap:SetCrossIndex(2,3,3,1)
mymap:SetCross(3,2,0)
	mymap:SetCrossIndex(3,1,2,3)
	mymap:SetCrossIndex(3,2,6,4)
mymap:SetCross(4,0,1)
	mymap:SetCrossIndex(4,2,7,4)
	mymap:SetCrossIndex(4,3,5,1)
mymap:SetCross(5,1,1)
	mymap:SetCrossIndex(5,1,4,3)
	mymap:SetCrossIndex(5,2,8,4)
	mymap:SetCrossIndex(5,3,6,1)
	mymap:SetCrossIndex(5,4,2,2)
mymap:SetCross(6,2,1)
	mymap:SetCrossIndex(6,1,5,3)
	mymap:SetCrossIndex(6,4,3,2)
mymap:SetCross(7,0,2)
	mymap:SetCrossIndex(7,3,8,1)
	mymap:SetCrossIndex(7,4,4,2)
mymap:SetCross(8,1,2)
	mymap:SetCrossIndex(8,1,7,3)
	mymap:SetCrossIndex(8,4,5,2)
end

local info=mymap:Sniff(7,3)
