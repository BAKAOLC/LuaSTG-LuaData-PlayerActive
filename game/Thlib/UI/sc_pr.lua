stage.group.New('menu',{},"Spell Practice",{lifeleft=0,power=400,faith=0,bomb=0},false)
stage.group.AddStage('Spell Practice','Spell Practice@Spell Practice',{lifeleft=0,power=400,faith=0,bomb=0},false)
stage.group.DefStageFunc('Spell Practice@Spell Practice','init',function(self)
	_init_item(self)
	New(mask_fader,'open')
	jstg.CreatePlayers()--New(_G[lstg.var.player_name])
	task.New(self,function()
		do--创建关卡背景
			if _editor_class[_sc_table[lstg.var.sc_index][1]].bgm ~= "" then
						LoadMusicRecord(_editor_class[_sc_table[lstg.var.sc_index][1]].bgm)
					else
						LoadMusic('spellcard',music_list.spellcard[1],music_list.spellcard[2],music_list.spellcard[3])
					end
			if _editor_class[_sc_table[lstg.var.sc_index][1]]._bg ~= nil then
				New(_editor_class[_sc_table[lstg.var.sc_index][1]]._bg)
			else
				New(bamboo_background)
			end
		end
		do--播放bgm
			task._Wait(30)
			local _,bgm=EnumRes('bgm')
			for _,v in pairs(bgm) do
				if GetMusicState(v)~='stopped' then
					ResumeMusic(v)
				else
					if _editor_class[_sc_table[lstg.var.sc_index][1]].bgm ~= "" then
						_play_music(_editor_class[_sc_table[lstg.var.sc_index][1]].bgm)
					else
						_play_music("spellcard")
					end
				end
			end
		end
		do--创建boss
			local _ref=nil--boss对象
			local _do_preaction=_sc_table[lstg.var.sc_index][5]--是否执行前一动作
			local _boss_class=_editor_class[_sc_table[lstg.var.sc_index][1]]--boss（编辑器）
			local _boss_sc=_sc_table[lstg.var.sc_index][3]--要练习的符卡
			local _boss_sc_index=_sc_table[lstg.var.sc_index][4]-1--当前练习的符卡在boss的cards中的位置
			if _do_preaction then
				_ref=New(_boss_class,{
					_boss_class.cards[_boss_sc_index],
					_boss_sc,
				})
			else
				_ref=New(_boss_class,{
					boss.move.New(0,144,60,MOVE_DECEL),
					_boss_sc,
				})
			end
			last=_ref
			while IsValid(_ref) do task.Wait(1) end
		end
		task._Wait(150)
		if ext.replay.IsReplay() then
			ext.pop_pause_menu=true
			ext.rep_over=true
			ext.SetPauseMenuType('replay-finish')
		else
			ext.pop_pause_menu=true
			lstg.tmpvar.death = false
			ext.SetPauseMenuType('sc-finish')
		end
		task._Wait(60)
	end)
	task.New(self,function()
		while coroutine.status(self.task[1])~='dead' do task.Wait(1) end
		New(mask_fader,'close')
		_stop_music()
		task.Wait(60)
		stage.group.FinishStage()
	end)
end)
