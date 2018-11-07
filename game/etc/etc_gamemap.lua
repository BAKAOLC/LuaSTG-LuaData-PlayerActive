--======================================
--自机活额外辅助库
--game map
--code by Xiliusha
--======================================

----------------------------------------
--game map
--if not etc then etc={} end

etc.gamemap={}

function etc.gamemap.New(existing)--创建一个地图
	local m=etc.map.New(existing)
	m.SetBlock=etc.gamemap.SetBlock
	m.SetCross=etc.gamemap.SetCross
	m.SetCrossIndex=etc.gamemap.SetCrossIndex
	m.GetRenderList=etc.gamemap.GetRenderList
	m.GetRenderList2=etc.gamemap.GetRenderList2
	return m
end

function etc.gamemap:SetCross(cross_id,cross_x,cross_y,activeset,hideset,index_number)--设置路口
	self:SetPoint(cross_id,cross_x,cross_y,index_number)
	self.points[cross_id].active=activeset or true
	self.points[cross_id].hide=hideset or false
end

function etc.gamemap:SetCrossIndex(cross_id,index_id,target_cross_id,entrance)--设置与路口连通的所有道路的信息
	self:SetPointIndex(cross_id,index_id,target_cross_id)
	self.points[cross_id].index[index_id].enter=entrance
end

function etc.gamemap:SetBlock(block_name,cross_id_1,cross_id_2,rankset,activeset,hideset)--设置区块
	self:SetLine(block_name,cross_id_1,cross_id_2,{
		rank=rankset or 0,
		active=activeset or true,
		hide=hideset or false,
	})
end

function etc.gamemap:GetRenderList(cross_id,eyeshot)--相对某个路口，以一定的嗅探范围获取所有需要渲染的区块
	local info=self:Sniff2(cross_id,eyeshot)
	local renderlist={}
	local func=function(self,index,list,func)
		if index.id and index.child then
			local c1,c2,line
			for k,v in pairs(index.child) do
				if v then
					c1=self:GetPoint(index.id)
					c2=self:GetPoint(v.id)
					line=self:GetLine(index.id,v.id)
					if line.hide==false and line.active==true then
						table.insert(list,{
							x1=c1.x,
							x2=c2.x,
							y1=c1.y,
							y2=c2.y,
							rank=line.rank,
						})
					end
					if v.child then
						func(self,index.child[k],list,func)
					end
				end
			end
		end
	end
	func(self,info,renderlist,func)
	return renderlist
end

function etc.gamemap:GetRenderList2(cross_id)--相对某个路口，遍历整个图获取所有需要渲染的区块
	local info=self:Sniff2L(cross_id)
	local renderlist={}
	local func=function(self,index,list,func)
		if index.id and index.child then
			local c1,c2,line
			for k,v in pairs(index.child) do
				if v then
					c1=self:GetPoint(index.id)
					c2=self:GetPoint(v.id)
					line=self:GetLine(index.id,v.id)
					if line.hide==false and line.active==true then
						table.insert(list,{
							x1=c1.x,
							x2=c2.x,
							y1=c1.y,
							y2=c2.y,
							rank=line.rank,
						})
					end
					if v.child then
						func(self,index.child[k],list,func)
					end
				end
			end
		end
	end
	func(self,info,renderlist,func)
	return renderlist
end
