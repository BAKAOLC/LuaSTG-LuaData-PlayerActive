-- luastg ex 

ex = {}

ex.signals = {}
ex.labels = {}--由OLC添加，用于储存指向object的标签，编辑器功能

function ex.Reset()
	ex.coops = {}
	ex.boss = {}
	ex.signals = {}
	ex.stageframe = 0
	ex._item1 = 0
    ex.labels = {}--由OLC添加，重置ex全局变量时，顺带清除object标签
end

function ex.SetLabelToObject(label,obj)--由OLC添加，用于把一个obj添加进某个表里面，编辑器功能
	ex.labels[label] = obj
end

function ex.GetObjectFromLabel(label)--由OLC添加，从某个表取出一个object，编辑器功能
	if IsValid(ex.labels[label]) then
		return ex.labels[label]
	end
end

function ex.SetSignal(slot,value)
	ex.signals[slot] = value
end

function ex.ResetSignals()
	ex.signals = {}
end

function ex.WaitForSignal(slot,value)
	while ex.signals[slot]~=value do
		task.Wait(1)
	end
end

function ex.GetCardObject(name)
	return _editor_cards[name]
end

ex.coops = {}

function ex:coopSpellCard(coopname,mode,waittime)
	--init
	local a=ex.coops[coopname]
	if ex.coops[coopname] == nil then 
		a={}
		ex.coops[coopname]=a
		a.cardcount=0
		a.firstfinish=0
		a.finishcount=0
		a.status={}
	end
	
	--join
	
	
	local finishcount=0
	a.cardcount=a.cardcount+1
	local b=a.cardcount
	a.status[b]=self.ex.status
	task.Wait(1)
	--waitforfinish
	while true do
		finishcount=0
		a.status[b]=self.ex.status
		if self.ex.status==0 then
			finishcount=finishcount+1
			
			break
		end		
		
		for i=1,a.cardcount do
			finishcount=finishcount+a.status[i]
		end
		finishcount=a.cardcount-finishcount
		if mode==0 then
			if finishcount~=0 then
				finishcount=finishcount+1
				boss.finishSpellC(self,true)
				break
			end
		end
		if mode==1 then
			if finishcount==a.cardcount-1 then
				finishcount=finishcount+1
				boss.finishSpellC(self,true)
				break
			end
		end
		task.Wait(1)
	end	
	a.finishcount=a.finishcount+1
	if a.firstfinish==0 then a.firstfinish=stage.current_stage.timer end
	waittime=waittime+a.firstfinish-stage.current_stage.timer
	if a.finishcount==a.cardcount then
		a.cardcount=0
		a.firstfinish=0
		a.finishcount=0
		a.status={}
	end
	if waittime>0 then
		task.Wait(waittime)
	end

end



function ex.UnitListUpdate(lst)
	local r={}
	local n=#lst
	local j=0
	for i=1,n do
		local z=lst[i]
		if IsValid(z) then
			j=j+1
			lst[j]=z;
			if i~=j then
				lst[i]=nil;
			end
		else
			lst[i]=nil;
		end
	end
	return j
end

function ex.UnitListAppend(lst,obj)
	if IsValid(obj) then
		local n=#lst
		lst[n+1]=obj
		return n+1
	elseif IsValid(obj[1]) then
		return ex.UnitListAppendList(lst,obj)
	else 
		return #lst
	end
end

function ex.UnitListAppendList(lst,objlist)
	local n=#lst
	local n2=#objlist
	for i=1,n2 do
		lst[n+i]=objlist[i]
	end
	return n+i
end


function ex.UnitListFindUnit(lst,obj)
	local n=#lst
	for i=1,n do
		local z=lst[i]
		if z==obj then return i end
	end
	return 0
end

function ex.UnitListInsertEx(lst,obj)
	local l=ex.UnitListFindUnit(lst,obj)
	if l==0 then
		return ex.UnitListInsert(lst,obj)
	else
		return l
	end
end

function ex.LaserSampleByLength(laser,l)
	return laser.data:SampleByLength(l)
end

function ex.LaserSampleByTime(laser,l)
	return laser.data:LaserSampleByTime(l)
end

function ex:LaserFormByList(list,rev)
	local l=#list
	if l<2 then 
		Del(self)
	end
	self.data=BentLaserData()
	--防止因_data删除导致老mod内重写的曲光使用该函数出错
	if self._data then self._data=BentLaserData() end
	local _l=self._l
	if rev==nil then
		for i=l,2,-1 do
			self.x=list[i].x
			self.y=list[i].y
			self.timer=self.timer+1
			if self.timer%4==0 then
				self.listx[(self.timer/4)%_l]=self.x
				self.listy[(self.timer/4)%_l]=self.y
			end
			self.data:Update(self,self.l,self.w)
			if self._data then self._data:Update(self,self.l,self.w+48) end
		end
		self.x=list[1].x
		self.y=list[1].y
		self.vx=self.x-list[2].x
		self.vy=self.y-list[2].y	
		self.rot=self._angle
	else
		for i=1,l-1,1 do
				self.x=list[i].x
				self.y=list[i].y
				self.timer=self.timer+1
				if self.timer%4==0 then
					self.listx[(self.timer/4)%_l]=self.x
					self.listy[(self.timer/4)%_l]=self.y
				end
				self.data:Update(self,self.l,self.w)
				if self._data then self._data:Update(self,self.l,self.w+48) end
		end
		self.x=list[l].x
		self.y=list[l].y
		self.vx=self.x-list[l-1].x
		self.vy=self.y-list[l-1].y	
	end
end

function ex:LaserUpdateByList(list,rev)
	local l=#list
	if l<2 then 
		return
	end
	self.data:UpdatePositionByList(list,l,self._w)
    --兼容性接口
    if self._data then self._data:UpdatePositionByList(list,l,self._w+48) end
end


ex.boss={}
function ex.GetRandomBoss() 
	local n=#ex.boss
	n=ran:Int(1,n)
	return ex.boss[n]
end

function ex.GetFirstBoss() 
	return ex.boss[1]
end

function ex.AddBoss(boss) 
	ex.UnitListAppend(ex.boss,boss)
	_boss=boss
end

function ex.RemoveBoss(boss)
	local i=ex.UnitListFindUnit(ex.boss,boss)
	if i>0 then
		ex.boss[i]=0
	end
	ex.UnitListUpdate(ex.boss);
end

function ex.ClearBonus(spell,chip)
	ex.UnitListUpdate(ex.boss);
	for i=1,#ex.boss do
		local z=ex.boss[i]
		if z.sc_bonus then z.sc_bonus=0 end
		if spell then z.chip_bonus=false end
		if chip then z.bombchip_bonus=false end
	end	
end
MODE_SET=0
MODE_ADD=1
MODE_MUL=2


function ex.SmoothSetValueTo(valname,y,t,mode,setter,starttime,vmode)
	local self=task.GetSelf()
	if starttime then
		task.Wait(starttime)
	end
	t=int(t)
	t=max(1,t)
	local ys=0 
	if setter then
		ys=valname()
	else
		ys=self[valname]
	end
	local dy=y-ys
	if vmode==nil then vmode=MODE_SET end
	if vmode==MODE_ADD then
		dy=y
	elseif vmode==MODE_MUL then
		dy=ys*y-ys
	end
	if setter then
		if mode==1 then
			for s=1/t,1+0.5/t,1/t do
				s=s*s
				setter(ys+s*dy)
				coroutine.yield()
			end
		elseif mode==2 then
			for s=1/t,1+0.5/t,1/t do
				s=s*2-s*s
				setter(ys+s*dy)
				coroutine.yield()
			end
		elseif mode==3 then
			for s=1/t,1+0.5/t,1/t do
				if s<0.5 then s=s*s*2 else s=-2*s*s+4*s-1 end
				setter(ys+s*dy)
				coroutine.yield()
			end
		else
			for s=1/t,1+0.5/t,1/t do
				setter(ys+s*dy)
				coroutine.yield()
			end
		end
	else
		if mode==1 then
			for s=1/t,1+0.5/t,1/t do
				s=s*s
				self[valname]=ys+s*dy
				coroutine.yield()
			end
		elseif mode==2 then
			for s=1/t,1+0.5/t,1/t do
				s=s*2-s*s
				self[valname]=ys+s*dy
				coroutine.yield()
			end
		elseif mode==3 then
			for s=1/t,1+0.5/t,1/t do
				if s<0.5 then s=s*s*2 else s=-2*s*s+4*s-1 end
				self[valname]=ys+s*dy
				coroutine.yield()
			end
		else
			for s=1/t,1+0.5/t,1/t do
				self[valname]=ys+s*dy
				coroutine.yield()
			end
		end
	end
end

function ex.SmoothSetValueToEx(valname,y,t,mode,setter,starttime,vmode)
	local self=task.GetSelf()
	if starttime then
		task.Wait(starttime)
	end
	t=int(t)
	t=max(1,t)
	
	local ys=0 
	if setter then
		ys=valname()
	else
		ys=self[valname]
	end
	local dy=y-ys
	if vmode==nil then vmode=MODE_SET end
	if vmode==MODE_ADD then
		dy=y
	elseif vmode==MODE_MUL then
		dy=ys*y-ys
	end
	local lasts=0
	if setter then
		if mode==1 then
			for s=1/t,1+0.5/t,1/t do
				s=s*s
				setter(valname()+(s-lasts)*dy)
				lasts=s
				coroutine.yield()
			end
		elseif mode==2 then
			for s=1/t,1+0.5/t,1/t do
				s=s*2-s*s
				setter(valname()+(s-lasts)*dy)
				lasts=s
				coroutine.yield()
			end
		elseif mode==3 then
			for s=1/t,1+0.5/t,1/t do
				if s<0.5 then s=s*s*2 else s=-2*s*s+4*s-1 end
				setter(valname()+(s-lasts)*dy)
				lasts=s
				coroutine.yield()
			end
		else
			for s=1/t,1+0.5/t,1/t do
				setter(valname()+(s-lasts)*dy)
				lasts=s
				coroutine.yield()
			end
		end
	else
		if mode==1 then
			for s=1/t,1+0.5/t,1/t do
				s=s*s
				self[valname]=self[valname]+(s-lasts)*dy
				lasts=s
				coroutine.yield()
			end
		elseif mode==2 then
			for s=1/t,1+0.5/t,1/t do
				s=s*2-s*s
				self[valname]=self[valname]+(s-lasts)*dy
				lasts=s
				coroutine.yield()
			end
		elseif mode==3 then
			for s=1/t,1+0.5/t,1/t do
				if s<0.5 then s=s*s*2 else s=-2*s*s+4*s-1 end
				self[valname]=self[valname]+(s-lasts)*dy
				lasts=s
				coroutine.yield()
			end
		else
			for s=1/t,1+0.5/t,1/t do
				self[valname]=self[valname]+(s-lasts)*dy
				lasts=s
				coroutine.yield()
			end
		end
	end
end

ex.stageframe = 0
ex._item1=0

function ex.Frame()
	ex.stageframe=ex.stageframe+1
	player=jstg.players[ex.stageframe%#jstg.players+1]
end

UNIT_SECOND = 0
UNIT_FRAME = 1
UNIT_MUSIC = 2

ex.meterstart = 0
ex.meterclock = 1

function ex.GetMusicMeter(a)
	return a*ex.meterclock+meterstart
end
function ex.GetMusicFrame(a)
	return int(a*ex.meterclock*60+0.5)
end

function ex.WaitTo(t,u,d,a)
	if u==UNIT_SECOND then
		t=t*60
	end
	if u==UNIT_MUSIC then
		t=(t*ex.meterclock+ex.meterstart)*60
	end
	if a then
		t=int(t+0.5)
	else
		t=int(t-ex.stageframe)
	end
	if t<0 and d then return false end
	task.Wait(t)
	return true
end
