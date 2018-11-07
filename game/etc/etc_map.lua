--======================================
--自机活额外辅助库
--map
--code by Xiliusha
--======================================

----------------------------------------
--map
--if not etc then etc={} end

etc.map={}

function etc.map.New(existing)
	local m={
		['Copy']=etc.map.Copy,
		['SetPoint']=etc.map.SetPoint,
		['SetPointIndex']=etc.map.SetPointIndex,
		['GetPoint']=etc.map.GetPoint,
		['Sniff1']=etc.map.Sniff1,
		['Sniff1L']=etc.map.Sniff1L,
		['SetLine']=etc.map.SetLine,
		['FindLine']=etc.map.FindLine,
		['GetLine']=etc.map.GetLine,
		['Sniff2']=etc.map.Sniff2,
		['Sniff2L']=etc.map.Sniff2L,
		['points']={},
		['lines']={},
	}
	if type(existing)=='table' then
		m.points=existing.points
		m.lines=existing.lines
	end
	return m
end

function etc.map:Copy(existing)
	if existing then
		local m={
			['points']={},
			['lines']={},
		}
		for k,v in pairs(existing.points) do
			m.points[k]=v
		end
		for k,v in pairs(existing.lines) do
			m.lines[k]=v
		end
		return m
	else
		local m={
			['points']={},
			['lines']={},
		}
		for k,v in pairs(self.points) do
			m.points[k]=v
		end
		for k,v in pairs(self.lines) do
			m.lines[k]=v
		end
		return m
	end
end

function etc.map:SetPoint(point_id,point_x,point_y,index_number)--新增节点
	local tmp={}
	local n=index_number or 4
	for i=1,n do
		tmp[i]=false
	end
	self.points[point_id]={
		id=point_id,
		index=tmp,
		enter=false,
		x=point_x,
		y=point_y,
	}
end

function etc.map:SetPointIndex(point_id,index_id,target_point_id)--设置节点的连通
	self.points[point_id].index[index_id]={
		id=target_point_id,
	}
end

function etc.map:GetPoint(point_id)
	return self.points[point_id]
end

local POINT_INDEX={}--用于储存嗅探时重复的节点

function etc.map:Sniff1(pointid,maxd)--嗅探与指定节点所连接的节点的信息，可指定嗅探的遍历深度--点不重复
	POINT_INDEX={}
	local sf=function(self,pointid,maxd,d,sf)--辅助函数
		if POINT_INDEX[pointid]==true then--避免重复
			return false
		else
			POINT_INDEX[pointid]=true--标记
			local info={}
			local index=self.points[pointid].index
			for i=1,#index do
				if type(index[i])=='table' then
					local point_id=index[i].id
					if POINT_INDEX[point_id]==true then--避免重复
						info[i]=false
					else
						POINT_INDEX[point_id]=true--标记
						info[i]={
							id=point_id
						}
						if d<maxd then
							info[i].child=sf(self,point_id,maxd,d+1,sf)
						end
					end
				else
					info[i]=false
				end
			end
			return info
		end
	end
	return {
		id=pointid,
		child=sf(self,pointid,maxd,1,sf),
	}
end

function etc.map:Sniff1L(pointid)--嗅探与指定节点所连接的节点的信息--点不重复--无限遍历，直到遍历完整个图
	POINT_INDEX={}
	local sf=function(self,pointid,sf)--辅助函数
		if POINT_INDEX[pointid]==true then--避免重复
			return false
		else
			POINT_INDEX[pointid]=true--标记
			local info={}
			local index=self.points[pointid].index
			for i=1,#index do
				if type(index[i])=='table' then
					local point_id=index[i].id
					if POINT_INDEX[point_id]==true then--避免重复
						info[i]=false
					else
						POINT_INDEX[point_id]=true--标记
						info[i]={
							id=point_id
						}
						info[i].child=sf(self,point_id,sf)
					end
				else
					info[i]=false
				end
			end
			return info
		end
	end
	return {
		id=pointid,
		child=sf(self,pointid,sf),
	}
end

function etc.map:SetLine(line_name,point_id_1,point_id_2,index)
	local point_id_min=math.min(point_id_1,point_id_2)
	local point_id_max=math.max(point_id_1,point_id_2)
	if index==nil then index={} end
	index.name=line_name
	if type(self.lines[point_id_min])~='table' then
		self.lines[point_id_min]={}
	end
	self.lines[point_id_min][point_id_max]=index
end

function etc.map:FindLine(line_name)
	for k1,v1 in pairs(self.lines) do
		for k2,v2 in pairs(v1) do
			if v2.name==line_name then
				return v2,k1,k2
			end
		end
	end
	return false
end

function etc.map:GetLine(point_id_1,point_id_2)
	local point_id_min=math.min(point_id_1,point_id_2)
	local point_id_max=math.max(point_id_1,point_id_2)
	return self.lines[point_id_min][point_id_max]
end

local LINE_INDEX={}--用于储存嗅探时重复的边

function etc.map:Sniff2(pointid,maxd)--嗅探与指定节点所连接的节点的信息，可指定嗅探的遍历深度--边不重复
	LINE_INDEX={}
	local sf=function(self,pointid,maxd,d,sf)--辅助函数
			local info={}
			local index=self.points[pointid].index
			for i=1,#index do
				if type(index[i])=='table' then
					local point_id=index[i].id
					local min_id=math.min(pointid,point_id)
					local max_id=math.max(pointid,point_id)
					if type(LINE_INDEX[min_id])~='table' then
						LINE_INDEX[min_id]={}
					end
					if LINE_INDEX[min_id][max_id]==true then--避免重复
						info[i]=false
					else
						LINE_INDEX[min_id][max_id]=true--标记
						info[i]={
							id=point_id
						}
						if d<maxd then
							info[i].child=sf(self,point_id,maxd,d+1,sf)
						end
					end
				else
					info[i]=false
				end
			end
			return info
	end
	return {
		id=pointid,
		child=sf(self,pointid,maxd,1,sf),
	}
end

function etc.map:Sniff2L(pointid)--嗅探与指定节点所连接的节点的信息--边不重复--无限遍历，直到遍历完整个图
	LINE_INDEX={}
	local sf=function(self,pointid,sf)--辅助函数
			local info={}
			local index=self.points[pointid].index
			for i=1,#index do
				if type(index[i])=='table' then
					local point_id=index[i].id
					local min_id=math.min(pointid,point_id)
					local max_id=math.max(pointid,point_id)
					if type(LINE_INDEX[min_id])~='table' then
						LINE_INDEX[min_id]={}
					end
					if LINE_INDEX[min_id][max_id]==true then--避免重复
						info[i]=false
					else
						LINE_INDEX[min_id][max_id]=true--标记
						info[i]={
							id=point_id
						}
						info[i].child=sf(self,point_id,sf)
					end
				else
					info[i]=false
				end
			end
			return info
	end
	return {
		id=pointid,
		child=sf(self,pointid,sf),
	}
end
