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
	m.UpdateColor=etc.gamemap.UpdateColor
	m.UpdateBlocks=etc.gamemap.UpdateBlocks
	m.GetRenderList=etc.gamemap.GetRenderList
	m.GetRenderList2=etc.gamemap.GetRenderList2
	return m
end

function etc.gamemap:SetCross(cross_id,cross_x,cross_y,activeset,hideset,index_number)--设置路口
	self:SetPoint(cross_id,cross_x,cross_y,index_number)
	self.points[cross_id].active=activeset or true
	self.points[cross_id].hide=hideset or false
	self.points[cross_id].alpha=0
	self.points[cross_id].color={255,255,255}
end

function etc.gamemap:SetCrossIndex(cross_id,index_id,target_cross_id,entrance)--设置与路口连通的所有道路的信息
	self:SetPointIndex(cross_id,index_id,target_cross_id)
	self.points[cross_id].index[index_id].enter=entrance
end

function etc.gamemap:SetBlock(block_name,cross_id_1,cross_id_2,rankset,activeset,hideset,canseeset,alphaset)--设置区块
	self:SetLine(block_name,cross_id_1,cross_id_2,{
		rank=rankset or 0,
		active=activeset or false,
		hide=hideset or false,
		cansee=canseeset or false,
		alpha=alphaset or 0,
		color={0,0,0},
	})
end

--更新

local RANK_COLOR_INDEX={
	{0,255,0},
	{255,255,0},
	{255,0,0},
} RANK_COLOR_INDEX[0]={0,0,255}

function etc.gamemap:UpdateColor(cross_id)
	local info=self:Sniff2L(cross_id)
	local func=function(self,index,func)
		if index.id and index.child then
			--更新路口透明度
			local cross1=self:GetPoint(index.id)
			if not cross1.hide then
				if cross1.active then
					cross1.alpha=math.min(cross1.alpha+0.025,255)
				else
					cross1.alpha=math.max(cross1.alpha-0.025,0)
				end
			else
				cross1.alpha=math.max(cross1.alpha-0.025,0)
			end
			
			for k,v in pairs(index.child) do
				if v then
					--更新路口透明度
					local cross2=self:GetPoint(v.id)
					if not cross2.hide then
						if cross2.active then
							cross2.alpha=math.min(cross2.alpha+0.025,255)
						else
							cross2.alpha=math.max(cross2.alpha-0.025,0)
						end
					else
						cross2.alpha=math.max(cross2.alpha-0.025,0)
					end
					
					local line=self:GetLine(index.id,v.id)
					--更新透明度
					if not line.hide then
						if line.active then
							line.alpha=math.min(line.alpha+0.025,255)
						else
							line.alpha=math.max(line.alpha-0.025,0)
						end
					else
						line.alpha=math.max(line.alpha-0.025,0)
					end
					--更新颜色
					if line.active then
						if line.cansee then
							line.color=RANK_COLOR_INDEX[line.rank]
						else
							line.color={128,128,128}
						end
					else
						line.color={0,0,0}
					end
					if v.child then
						func(self,index.child[k],func)
					end
				end
			end
		end
	end
	func(self,info,func)
end

function etc.gamemap:UpdateBlocks(cross_id,eyeshot)
	--取消区块的cansee标记
	--刷新路口的可见性
	local info=self:Sniff2L(cross_id)
	local func=function(self,index,func)
		if index.id and index.child then
			--刷新路口的可见性
			local cross1=self:GetPoint(index.id)
			cross1.active=true
			for k,v in pairs(index.child) do
				if v then
					--刷新路口的可见性
					local cross2=self:GetPoint(v.id)
					cross2.active=true
					--取消区块的cansee标记
					local line=self:GetLine(index.id,v.id)
					line.cansee=false
					if v.child then
						func(self,index.child[k],func)
					end
				end
			end
		end
	end
	func(self,info,func)
	--根据eyeshot刷新active和cansee
	local info2=self:Sniff2(cross_id,eyeshot)
	local func2=function(self,index,func2)
		if index.id and index.child then
			for k,v in pairs(index.child) do
				if v then
					local line=self:GetLine(index.id,v.id)
					line.active=true
					line.cansee=true
					if v.child then
						func2(self,index.child[k],func)
					end
				end
			end
		end
	end
	func2(self,info2,func2)
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
