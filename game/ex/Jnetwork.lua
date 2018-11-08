--======================================
--javastg network
--======================================

----------------------------------------
--JavaStage网络

jstg.network={}
jstg.network.status=0
jstg.network.host="127.0.0.1"
jstg.network.port=26033
jstg.network.slots={}
jstg.network.delay=0
jstg.devices={}
jstg.network.playerkeymask={0,0,0,0,0,0}
jstg.pingframe = 0

jstg.NETSTATES={'Connecting','Wait for reply','Wait for player','Wait for sync','Connected'}

function jstg.SendData(...)
	local arg={...}
	return SendData('O'..Serialize(arg))
end

--触发联机的函数
function jstg.CreateConnect(ctype)
	if ctype==0 then
		jstg.SinglePlayer()
	elseif jstg.network.status==0 then
		jstg.network.type=ctype
		jstg.network.status=1
		jstg.network.host=network.server
		jstg.network.port=network.port
		jstg.network.delay=network.delay or -1
		if jstg.network.type==1 then
			jstg.network.delay=0
		end
	end
end

function jstg.ProceedConnect()

	--已连接的情况下
	if jstg.network.status>1 then
		--获得传送的数据
		local dt=ReceiveData()
		while dt do
			Print(jstg.network.status,dt)
			--由服务器发送的数据
			if string.sub(dt,1,1)=='S' then
				--服务器发送该游戏副本的Slot号，如果是1则认为是房主，负责处理其他信息
				dt=string.sub(dt,2,string.len(dt))
				jstg.network.slot=tonumber(dt)
				jstg.network.slots={}
				jstg.network.is_host=(jstg.network.slot==1)
				jstg.network.status=3
				if not jstg.network.is_host then
					--如果不是房主，则广播一则消息告诉大家“我进来了”
					jstg.SendData('client',jstg.network.slot)
				else
					jstg.network.slots[1]='local'
				end
			end		
			
			--由其他客户端广播的数据
			if string.sub(dt,1,1)=='O' then
				--得到用户发送的lua对象
				dt=string.sub(dt,2,string.len(dt))
				local da=DeSerialize(dt)
				if da[1]=='client' and jstg.network.is_host and jstg.network.status==3 then
					--房主收到其他玩家加入房间的信息
					jstg.network.slots[da[2]]='remote'
					--该玩家的slot是2，说明已经有两个人了，可以开始游戏了
					if da[2]==2 then
						--如果没有设置延迟，发送一个ping包，等back包，再设置延迟开始
						if jstg.network.delay==-1 then
							--send a ping package
							jstg.pingframe = ex.stageframe
							jstg.SendData('ping')
						else 
							--if we have enough players ,send message to start
							jstg.network.status=4
							jstg.network.ran_seed = ((os.time() % 65536) * 877) % 65536							
							--send players,delay,ran,type seed to sync game status
							jstg.SendData('server',2,jstg.network.delay,jstg.network.ran_seed,jstg.network.type)
						end
					end
				end	
				
				--客户端接收到同步参数，准备开始游戏
				if da[1]=='server' and not jstg.network.is_host then
					--receive players,delay,ran seed to sync game status
					jstg.network.status=4
					for i=1,da[2] do
						jstg.network.slots[i]='remote'
					end
					jstg.network.slots[jstg.network.slot]='local'
					jstg.network.delay=da[3]
					jstg.network.ran_seed=da[4]
					jstg.network.type=da[5]
				end
				
				--响应Ping包
				if da[1]=='ping' then
					jstg.SendData('back',jstg.network.slot)
				end
				--响应Back包
				if da[1]=='back' and da[2]==2 and jstg.network.is_host and jstg.network.status==3 then
					jstg.network.delay = ex.stageframe - jstg.pingframe
					jstg.network.status=4
					jstg.network.ran_seed = ((os.time() % 65536) * 877) % 65536
					
					--send players,delay,ran,type seed to sync game status
					jstg.SendData('server',2,jstg.network.delay,jstg.network.ran_seed,jstg.network.type)
				end
			end			
			
			dt=ReceiveData()
		end
	end

	--尝试连接指定IP
	if jstg.network.status==1 then
		local host=jstg.network.host
		local rt=ConnectTo(jstg.network.host,jstg.network.port)
		if rt then
			jstg.network.status=2
		else
			ConnectTo('',0)
			jstg.network.status=0
		end
	end
	
	--后处理：开始游戏
	if jstg.network.status==4 then 
		--选择游戏类型
		if jstg.network.type==1 then
			jstg.WatchSinglePlayer()
		elseif jstg.network.type==2 then
			jstg.CoopSinglePlayer()
		elseif jstg.network.type==3 then
			jstg.MultiPlayer()
		end
		jstg.network.status=5
		
		--修改联机菜单标题，返回主菜单
		jstg.nettitle[1]='Disconnect'
		stage_menu.update(jstg.menu_title)
		menu.FlyIn(jstg.menu_title,'left')
		menu.FlyOut(jstg.menu_network,'right')	
		ran:Seed(jstg.network.ran_seed)
	end
end

--游戏类型
function jstg.SinglePlayer()
	if jstg.network.status>1 then
		--break connection
		for i=1,#jstg.devices do
			BindInput(0,i,0,0)--unbind input
			ReleaseInputDevice(jstg.devices[i])--release data
		end
		jstg.devices={}
		ConnectTo('',0)
	end
	--reset network
	jstg.network.slots={'local'}
	jstg.network.delay=0
	jstg.network.status=0
	jstg.network.ran_seed=nil
	--update input
	jstg.ChangeInput()
	--set key usage
	jstg.network.playerkeymask={0,0,0,0,0,0} --same as 1 
	Print('Single')
end
function jstg.WatchSinglePlayer()
	--update input
	jstg.ChangeInput2()
	--set key usage
	jstg.network.playerkeymask={0,0,0,0,0,0} --same as 1 
	Print('Single')
end
function jstg.CoopSinglePlayer()
	--update input
	jstg.ChangeInput()
	--set key usage
	jstg.network.playerkeymask={0,0,0,0,0,0} --same as 1 
	Print('Single')
end
function jstg.MultiPlayer()
	--update input
	jstg.ChangeInput()
	--set key usage
	jstg.network.playerkeymask={1,2,3,4,5,6} 
	Print('Multi')
end
function jstg.TwoPlay()
	--update input
	jstg.ChangeInput()
	--set key usage
	jstg.network.playerkeymask={0,0,0,0,0,0} 
	Print('Single')
end

