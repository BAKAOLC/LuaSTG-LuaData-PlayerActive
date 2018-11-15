--======================================
--UI
--======================================

----------------------------------------
--加载资源

LoadTexture('hint','THlib\\ui\\hint.png',true)
LoadImage('hint.bonusfail','hint',0,64,256,64)
LoadImage('hint.getbonus','hint',0,128,396,64)
LoadImage('hint.extend','hint',0,192,160,64)
LoadImage('hint.power','hint',0,12,84,32)
LoadImage('hint.graze','hint',86,12,74,32)
LoadImage('hint.point','hint',160,12,120,32)
LoadImage('hint.life','hint',288,0,16,15)
LoadImage('hint.lifeleft','hint',304,0,16,15)
LoadImage('hint.bomb','hint',320,0,16,16)
LoadImage('hint.bombleft','hint',336,0,16,16)
LoadImage('kill_time','hint',232,200,152,56,16,16)
SetImageCenter('hint.power',0,16)
SetImageCenter('hint.graze',0,16)
SetImageCenter('hint.point',0,16)
LoadImageGroup('lifechip','hint',288,16,16,15,4,1,0,0)
LoadImageGroup('bombchip','hint',288,32,16,16,4,1,0,0)
LoadImage('hint.hiscore','hint',424,8,80,20)
LoadImage('hint.score','hint',424,30,64,20)
LoadImage('hint.Pnumber','hint',352,8,56,20)
LoadImage('hint.Bnumber','hint',352,30,72,20)
LoadImage('hint.Cnumber','hint',352,52,40,20)
SetImageCenter('hint.hiscore',0,10)
SetImageCenter('hint.score',0,10)
SetImageCenter('hint.Pnumber',0,10)
SetImageCenter('hint.Bnumber',0,10)

LoadTexture('ui_rank','THlib\\ui\\rank.png')
LoadImage('rank_Easy','ui_rank',0,0,144,32)
LoadImage('rank_Normal','ui_rank',0,32,144,32)
LoadImage('rank_Hard','ui_rank',0,64,144,32)
LoadImage('rank_Lunatic','ui_rank',0,96,144,32)
LoadImage('rank_Extra','ui_rank',0,128,144,32)

--自机活使用
--系统槽
LoadTexture('pa_psybar','THlib\\ui\\ui_psybar.png',false)
LoadImageGroup('pa_psybar_','pa_psybar',0,0,90,900,3,1,0,0)
--world阴影
LoadTexture('pa_world_back','THlib\\ui\\pa_world_back.png',false)
LoadImageGroup('pa_world_back_','pa_world_back',0,0,32,480,3,1,0,0)
--空白地图
LoadImageFromFile('pa_blank_map','THlib\\ui\\blankmap.png')

----------------------------------------
--ui

ui={}

Include'THlib\\ui\\font.lua'
Include'THlib\\ui\\title.lua'
Include'THlib\\ui\\sc_pr.lua'

ui.menu={
	font_size=0.625,
	line_height=24,
	char_width=20,
	num_width=12.5,
	title_color={255,255,255},
	unfocused_color={128,128,128},
--	unfocused_color={255,255,255},
	focused_color1={255,255,255},
	focused_color2={255,192,192},
	blink_speed=7,
	shake_time=9,
	shake_speed=40,
	shake_range=3,
	sc_pr_line_per_page=12,
	sc_pr_line_height=22,
	sc_pr_width=320,
	sc_pr_margin=8,
	rep_font_size=0.6,
	rep_line_height=20,
}

function ui.DrawMenu(title,text,pos,x,y,alpha,timer,shake,align)
	align=align or 'center'
	local yos
	if title=='' then yos=(#text+1)*ui.menu.line_height*0.5 else
		yos=(#text-1)*ui.menu.line_height*0.5
		SetFontState('menu','',Color(alpha*255,unpack(ui.menu.title_color)))
		RenderText('menu',title,x,y+yos+ui.menu.line_height,ui.menu.font_size,align,'vcenter')
	end
	for i=1,#text do
		if i==pos then
			local color={}
			local k=cos(timer*ui.menu.blink_speed)^2
			for j=1,3 do color[j]=ui.menu.focused_color1[j]*k+ui.menu.focused_color2[j]*(1-k) end

			local xos=ui.menu.shake_range*sin(ui.menu.shake_speed*shake)

			SetFontState('menu','',Color(alpha*255,unpack(color)))
			RenderText('menu',text[i],x+xos,y-i*ui.menu.line_height+yos,ui.menu.font_size,align,'vcenter')
		--	RenderTTF('menuttf',text[i],x+xos+2,x+xos+2,y-i*ui.menu.line_height+yos,y-i*ui.menu.line_height+yos,Color(alpha*255,0,0,0),'centerpoint')
		--	RenderTTF('menuttf',text[i],x+xos,x+xos,y-i*ui.menu.line_height+yos,y-i*ui.menu.line_height+yos,Color(alpha*255,unpack(color)),'centerpoint')
		else
			SetFontState('menu','',Color(alpha*255,unpack(ui.menu.unfocused_color)))
			RenderText('menu',text[i],x,y-i*ui.menu.line_height+yos,ui.menu.font_size,align,'vcenter')
		--	RenderTTF('menuttf',text[i],x+2,x+2,y-i*ui.menu.line_height+yos,y-i*ui.menu.line_height+yos,Color(alpha*255,0,0,0),'centerpoint')
		--	RenderTTF('menuttf',text[i],x,x,y-i*ui.menu.line_height+yos,y-i*ui.menu.line_height+yos,Color(alpha*255,unpack(ui.menu.unfocused_color)),'centerpoint')
		end
	end
end

function ui.DrawMenuTTF(ttfname,title,text,pos,x,y,alpha,timer,shake,align)
	align=align or 'center'
	local yos
	if title=='' then yos=(#text+1)*ui.menu.sc_pr_line_height*0.5 else
		yos=(#text-1)*ui.menu.sc_pr_line_height*0.5
		RenderTTF(ttfname,title,x,x,y+yos+ui.menu.sc_pr_line_height,y+yos+ui.menu.sc_pr_line_height,Color(alpha*255,unpack(ui.menu.title_color)),align,'vcenter','noclip')
	end
	for i=1,#text do
		if i==pos then
			local color={}
			local k=cos(timer*ui.menu.blink_speed)^2
			for j=1,3 do color[j]=ui.menu.focused_color1[j]*k+ui.menu.focused_color2[j]*(1-k) end
			local xos=ui.menu.shake_range*sin(ui.menu.shake_speed*shake)
			RenderTTF(ttfname,text[i],x+xos,x+xos,y-i*ui.menu.sc_pr_line_height+yos,y-i*ui.menu.sc_pr_line_height+yos,Color(alpha*255,unpack(color)),align,'vcenter','noclip')
		else
			RenderTTF(ttfname,text[i],x,x,y-i*ui.menu.sc_pr_line_height+yos,y-i*ui.menu.sc_pr_line_height+yos,Color(alpha*255,unpack(ui.menu.unfocused_color)),align,'vcenter','noclip')
		end
	end
end

function ui.DrawMenuTTFBlack(ttfname,title,text,pos,x,y,alpha,timer,shake,align)
	align=align or 'center'
	local yos
	if title=='' then yos=(#text+1)*ui.menu.sc_pr_line_height*0.5 else
		yos=(#text-1)*ui.menu.sc_pr_line_height*0.5
		RenderTTF(ttfname,title,x,x,y+yos+ui.menu.sc_pr_line_height,y+yos+ui.menu.sc_pr_line_height,Color(0xFF000000),align,'vcenter','noclip')
	end
	for i=1,#text do
		if i==pos then
			local xos=ui.menu.shake_range*sin(ui.menu.shake_speed*shake)
			RenderTTF(ttfname,text[i],x+xos,x+xos,y-i*ui.menu.sc_pr_line_height+yos,y-i*ui.menu.sc_pr_line_height+yos,Color(0xFF000000),align,'vcenter','noclip')
		else
			RenderTTF(ttfname,text[i],x,x,y-i*ui.menu.sc_pr_line_height+yos,y-i*ui.menu.sc_pr_line_height+yos,Color(0xFF000000),align,'vcenter','noclip')
		end
	end
end

function ui.DrawRepText(ttfname,title,text,pos,x,y,alpha,timer,shake)
	local yos
	if title=='' then yos=(#text+1)*ui.menu.sc_pr_line_height*0.5 else
		yos=(#text-1)*ui.menu.sc_pr_line_height*0.5
		Render(title,x,y+ui.menu.sc_pr_line_height+yos)
--		RenderTTF(ttfname,title,x,x,y+yos+ui.menu.sc_pr_line_height+1,y+yos+ui.menu.sc_pr_line_height-1,Color(0xFF000000),'center','vcenter','noclip')
--		RenderTTF(ttfname,title,x,x,y+yos+ui.menu.sc_pr_line_height,y+yos+ui.menu.sc_pr_line_height,Color(255,unpack(ui.menu.title_color)),'center','vcenter','noclip')
	end
	local _text=text
	local xos={-300,-240,-120,20,130,240}
	for i=1,#_text do
		if i==pos then
			local color={}
			local k=cos(timer*ui.menu.blink_speed)^2
			for j=1,3 do color[j]=ui.menu.focused_color1[j]*k+ui.menu.focused_color2[j]*(1-k) end
--			local xos=ui.menu.shake_range*sin(ui.menu.shake_speed*shake)
			SetFontState('replay','',Color(0xFFFFFF30))
--			RenderTTF(ttfname,text[i],x+xos,x+xos,y-i*ui.menu.sc_pr_line_height+yos,y-i*ui.menu.sc_pr_line_height+yos,Color(alpha*255,unpack(color)),align,'vcenter','noclip')
			for m=1,6 do
				RenderText('replay',_text[i][m],x+xos[m],y-i*ui.menu.rep_line_height+yos,ui.menu.rep_font_size,'vcenter','left')
			end
		else
			SetFontState('replay','',Color(0xFF808080))
--			RenderTTF(ttfname,text[i],x,x,y-i*ui.menu.sc_pr_line_height+yos,y-i*ui.menu.sc_pr_line_height+yos,Color(alpha*255,unpack(ui.menu.unfocused_color)),align,'vcenter','noclip')
			for m=1,6 do
				RenderText('replay',_text[i][m],x+xos[m],y-i*ui.menu.rep_line_height+yos,ui.menu.rep_font_size,'vcenter','left')
			end
		end
	end
end

function ui.DrawRepText2(ttfname,title,text,pos,x,y,alpha,timer,shake)
	local yos
	if title=='' then yos=(#text+1)*ui.menu.sc_pr_line_height*0.5 else
		yos=(#text-1)*ui.menu.sc_pr_line_height*0.5
		Render(title,x,y+ui.menu.sc_pr_line_height+yos)
--		RenderTTF(ttfname,title,x,x,y+yos+ui.menu.sc_pr_line_height+1,y+yos+ui.menu.sc_pr_line_height-1,Color(0xFF000000),'center','vcenter','noclip')
--		RenderTTF(ttfname,title,x,x,y+yos+ui.menu.sc_pr_line_height,y+yos+ui.menu.sc_pr_line_height,Color(255,unpack(ui.menu.title_color)),'center','vcenter','noclip')
	end
	local _text=text
	local xos={-80,120}
	for i=1,#_text do
		if i==pos then
			local color={}
			local k=cos(timer*ui.menu.blink_speed)^2
			for j=1,3 do color[j]=ui.menu.focused_color1[j]*k+ui.menu.focused_color2[j]*(1-k) end
--			local xos=ui.menu.shake_range*sin(ui.menu.shake_speed*shake)
			SetFontState('replay','',Color(0xFFFFFF30))
--			RenderTTF(ttfname,text[i],x+xos,x+xos,y-i*ui.menu.sc_pr_line_height+yos,y-i*ui.menu.sc_pr_line_height+yos,Color(alpha*255,unpack(color)),align,'vcenter','noclip')
			RenderText('replay',_text[i][1],x+xos[1],y-i*ui.menu.rep_line_height+yos,ui.menu.rep_font_size,'vcenter','center')
			RenderText('replay',_text[i][2],x+xos[2],y-i*ui.menu.rep_line_height+yos,ui.menu.rep_font_size,'vcenter','right')
		else
			SetFontState('replay','',Color(0xFF808080))
--			RenderTTF(ttfname,text[i],x,x,y-i*ui.menu.sc_pr_line_height+yos,y-i*ui.menu.sc_pr_line_height+yos,Color(alpha*255,unpack(ui.menu.unfocused_color)),align,'vcenter','noclip')
			RenderText('replay',_text[i][1],x+xos[1],y-i*ui.menu.rep_line_height+yos,ui.menu.rep_font_size,'vcenter','center')
			RenderText('replay',_text[i][2],x+xos[2],y-i*ui.menu.rep_line_height+yos,ui.menu.rep_font_size,'vcenter','right')
		end
	end
end

function RenderScore(fontname,score,x,y,size,mode)
	if score<1000 then
		RenderText(fontname,string.format('%d',score),x,y,size,mode)
	elseif score<1000000 then
		RenderText(fontname,string.format('%d,%03d',math.floor(score/1000),score%1000),x,y,size,mode)
	elseif score<1000000000 then
		RenderText(fontname,string.format('%d,%03d,%03d',math.floor(score/1000000),math.floor(int(score/1000))%1000,score%1000),x,y,size,mode)
	elseif score<100000000000 then
		RenderText(fontname,string.format('%d,%03d,%03d,%03d',math.floor(score/1000000000),math.floor(int(score/1000000))%1000,math.floor(score/1000)%1000,score%1000),x,y,size,mode)
	else
		RenderText(fontname,string.format('99,999,999,999'),x,y,size,mode)
	end
end
--
diff_render_obj=Class(object)
function diff_render_obj:init(x,y,_type,img)
	self.group=GROUP_GHOST
	self.bound=false
	self.x=x
	self.y=y
	self.rot,self.
	self.layer=LAYER_TOP
	self.img=_type..img
	self._a,self._r,self._g,self._b=255,255,255,255
	ui_diff=self
end
function diff_render_obj:render()
	Render(self.img,self.x,self.y,self.rot,self.hscale,self.vscale)
end

--
function oldResetUI()
	if setting.resx>setting.resy then
		if not CheckRes('img','image:UI_img') 	then LoadImageFromFile('ui_bg','THlib\\ui\\ui_bg.png') end
		if not CheckRes('img','image:LOGO_img') then LoadImageFromFile('logo','THlib\\ui\\logo.png') end
		SetImageCenter('logo',0,0)
		LoadImageFromFile('menu_bg','THlib\\ui\\menu_bg.png')

		function ui.DrawFrame()
			if CheckRes('img','image:UI_img') then Render('image:UI_img',320,240) else Render('ui_bg',320,240) end
			if CheckRes('img','image:LOGO_img') then Render('image:LOGO_img',400,150,0,0.5,0.5) else Render('logo',400,150,0,0.5,0.5) end
			SetFontState('menu','',Color(0xFFFFFFFF))
			RenderText('menu',string.format('%.1ffps',GetFPS()),636,1,0.25,'right','bottom')
		end

		function ui.DrawMenuBG()
			SetViewMode'ui'
			Render('menu_bg',320,240)
			SetFontState('menu','',Color(0xFFFFFFFF))
			RenderText('menu',string.format('%.1ffps',GetFPS()),636,1,0.25,'right','bottom')
		end
		function ui.DrawScore()
			SetFontState('score3','',Color(0xFFADADAD))
			local diff=string.match(stage.current_stage.name,"[%w_][%w_ ]*$")
			local diffimg=CheckRes('img','image:diff_'..diff)
			if diffimg then
				Render('image:diff_'..diff,528,448)
			else
				--by OLC，难度显示加入符卡练习
				if ext.sc_pr and diff=="Spell Practice" and lstg.var.sc_index then
					diff=_editor_class[_sc_table[lstg.var.sc_index][1]].difficulty
					if diff=="All" then diff="SpellCard" end
				end
				if diff=='Easy' or diff=='Normal' or diff=='Hard' or diff=='Lunatic' or diff=='Extra' then
					Render('rank_'..diff,528,448,0.5,0.5)
				else
					RenderText('score',diff,528,466,0.5,'center')
				end
			end
			Render('line_1',525,419,0,1,1)
			Render('line_2',525,397,0,1,1)
			Render('line_3',525,349,0,1,1)
			Render('line_4',525,311,0,1,1)
			Render('line_5',525,247,0,1,1)
			Render('line_6',525,224,0,1,1)
			Render('line_7',525,202,0,1,1)
			Render('hint.hiscore',428,425,0,1,1)
			Render('hint.score',428,403,0,1,1)
			Render('hint.Pnumber',428,371,0,1,1)
			Render('hint.Bnumber',428,334,0,1,1)
			Render('hint.Cnumber',554,316,0,0.85,0.85)
			Render('hint.Cnumber',554,354,0,0.85,0.85)
			Render('hint.power',455,253,0,0.5,0.5)
			Render('hint.point',455,230,0,0.5,0.5)
			Render('hint.graze',470,208,0,0.5,0.5)
			--RenderText('score','HiScore\nScore\nPlayer\nSpell\nGraze',432,424,0.5,'left')
			for i=1,8 do
				Render('hint.life',505+13*i,371,0,1,1)
			end
			for i=1,lstg.var.lifeleft do
				Render('hint.lifeleft',505+13*i,371,0,1,1)
			end
			for i=1,8 do
				Render('hint.bomb',505+13*i,334,0,1,1)
			end
			for i=1,lstg.var.bomb do
				Render('hint.bombleft',505+13*i,334,0,1,1)
			end
			local Lchip=int(lstg.var.chip/20)
			if Lchip>0 and Lchip<5 then
				Render('lifechip'..Lchip,505+13*(lstg.var.lifeleft+1),371,0,1,1)
			end
			local Bchip=int(lstg.var.chip/20)
			if Bchip>0 and Bchip<5 then
				Render('bombchip'..Bchip,505+13*(lstg.var.bomb+1),334,0,1,1)
			end
			SetFontState('score3','',Color(0xFFADADAD))
			RenderScore('score3',max(lstg.tmpvar.hiscore or 0,lstg.var.score),622,436,0.43,'right')
			SetFontState('score3','',Color(0xFFFFFFFF))
			RenderScore('score3',lstg.var.score,622,414,0.43,'right')
			RenderText('score3',string.format('%.1f',lstg.var.chip)..'%',620,361,0.35,'right')--596,left
			RenderText('score3',string.format('%.1f',lstg.var.bombchip)..'%',620,323,0.35,'right')
			--Render('hint.power',450,258,0,0.5)
			--Render('hint.point',452,240,0,0.5)
			--Render('hint.graze',466,222,0,0.5)
			SetFontState('score1','',Color(0xFFCD6600))
			SetFontState('score2','',Color(0xFF22D8DD))
			---
			RenderText('score1',string.format('%d.    /4.    ',math.floor(lstg.var.power/100)),610,262,0.4,'right')
			RenderText('score1',string.format('      %d%d        00',math.floor((lstg.var.power%100)/10),lstg.var.power%10),611,258.5,0.3,'right')
			RenderText('score2',string.format('%d,%d%d%d',math.floor(lstg.var.pointrate/1000),math.floor(lstg.var.pointrate/100)%10,math.floor(lstg.var.pointrate/10)%10,lstg.var.pointrate%10),610,239,0.4,'right')
			SetFontState('score3','',Color(0xFFADADAD))
			RenderText('score3',string.format('%d',lstg.var.graze),610,216,0.4,'right')
		end
	else
		LoadImageFromFile('ui_bg2','THlib\\ui\\ui_bg_2.png')
		LoadImageFromFile('ui_bg','THlib\\ui\\ui_bg.png')
		LoadImageFromFile('logo','THlib\\ui\\logo.png')
		SetImageCenter('logo',0,0)
		LoadImageFromFile('menu_bg2','THlib\\ui\\menu_bg_2.png')
		LoadImageFromFile('menu_bg','THlib\\ui\\menu_bg.png')
		function ui.DrawFrame()
			Render('ui_bg2',198,264)
		end

		function ui.DrawMenuBG()
			SetViewMode'ui'
			Render('menu_bg2',198,264)
			SetFontState('menu','',Color(0xFFFFFFFF))
			RenderText('menu',string.format('%.1ffps',GetFPS()),392,1,0.25,'right','bottom')
		end

		function ui.DrawScore()
			RenderText('score','HiScore',8,520,0.5,'left','top')
			RenderText('score',string.format('%d',max(lstg.tmpvar.hiscore or 0,lstg.var.score)),190,520,0.5,'right','top')
			RenderText('score','Score',206,520,0.5,'left','top')
			RenderText('score',string.format('%d',lstg.var.score),388,520,0.5,'right','top')
			SetFontState('score','',Color(0xFFFF4040))
			RenderText('score',string.format('%1.2f',lstg.var.power/100),8,496,0.5,'left','top')
			SetFontState('score','',Color(0xFF40FF40))
			RenderText('score',string.format('%d',lstg.var.faith),84,496,0.5,'left','top')
			SetFontState('score','',Color(0xFF4040FF))
			RenderText('score',string.format('%d',lstg.var.pointrate),160,496,0.5,'left','top')
			SetFontState('score','',Color(0xFFFFFFFF))
			RenderText('score',string.format('%d',lstg.var.graze),236,496,0.5,'left','top')
			RenderText('score',string.rep('*',max(0,lstg.var.lifeleft)),388,496,0.5,'right','top')
			RenderText('score',string.rep('*',max(0,lstg.var.bomb)),380,490,0.5,'right','top')
		end
	end
end

function ResetUI()--自机活使用
	if setting.resx>setting.resy then
		LoadImageFromFile('ui_bg_big','THlib\\ui\\ui_bg_big.png')
		LoadImageFromFile('menu_bg','THlib\\ui\\menu_bg.png')
		
		function ui.DrawFrame()
			SetViewMode'ui'
			Render('ui_bg_big',427,240,0,480/1080)
			local w=lstg.world
			RenderRect('pa_world_back_1',w.scrl-32,w.scrl,0,480)
			RenderRect('pa_world_back_2',w.scrl,w.scrr,0,480)
			RenderRect('pa_world_back_3',w.scrr,w.scrr+32,0,480)
			SetFontState('menu','',Color(0xFFFFFFFF))
			RenderText('menu',string.format('%.1ffps',GetFPS()),screen.width-4,1,0.25,'right','bottom')
			SetViewMode'world'
		end
		function ui.DrawMenuBG()
			SetViewMode'ui'
			Render('menu_bg',screen.width/2,240,0,1.5)
			SetFontState('menu','',Color(0xFFFFFFFF))
			RenderText('menu',string.format('%.1ffps',GetFPS()),screen.width-4,1,0.25,'right','bottom')
			SetViewMode'world'
		end
		function ui.DrawScore()
			local w=lstg.world
			
			--多玩家UI
			local pl,pl2,pls=player,player,1
			if jstg.players then
				pls=0
				if jstg.players[1] then
					if IsValid(jstg.players[1]) then
						pl=jstg.players[1]
						pls=pls+1
					end
				end
				if jstg.players[2] then
					if IsValid(jstg.players[2]) then
						pl2=jstg.players[2]
						pls=pls+1
					end
				end
			end
			--各种要用到的变量，储存了玩家槽位，和自机系统数据
			local slot1,slot2=1,1
			slot1=GetCurrentPlayerSlot(pl)
			if pls==2 then slot2=GetCurrentPlayerSlot(pl2) end
			local maxpsy,expsy=pl.maxpsy*pl.psyuse,pl.expsy*pl.psyuse
			local maxpsy2,expsy2=maxpsy,expsy
			if pls==2 then maxpsy2,expsy2=pl2.maxpsy*pl2.psyuse,pl2.expsy*pl2.psyuse end
			
			SetViewMode'ui'
			----------灵力槽
			do
				local dx,dy=w.scrl-36,240--总体偏移
				if pls==1 then
					--底图
					Render('pa_psybar_1',dx,dy,0,0.5)
					--灵力条渲染
					local rk=max(0,min(lstg.var.psychic[slot1]/maxpsy,1))
					SetImageState('white','mul+add',Color(255,200,64,208))--Color(255,255,128,128)
					RenderRect('white',dx-12,dx+19,dy-200,dy-200+400*rk)
					--溢出值
					rk=max(0,min(lstg.var.expsychic[slot1]/expsy,1))
					SetImageState('white','mul+add',Color(255,64,80,200))--Color(255,255,128,0)
					RenderRect('white',dx-19,dx-12,dy-200,dy-200+400*rk)
					--渲染分割
					SetImageState('white','',Color(64,0,0,0))
					local dh=400/pl.maxpsy
					for i=1,(pl.maxpsy-1) do
						RenderRect('white',dx-12,dx+19,dy-200+i*dh,dy-200+1+i*dh)
					end
					dh=400/pl.expsy
					for i=1,(pl.expsy-1) do
						RenderRect('white',dx-19,dx-12,dy-200+i*dh,dy-200+1+i*dh)
					end
					--外框
					Render('pa_psybar_2',dx,dy,0,0.5)
					--数值显示
					SetFontState('score1','',Color(255,255,128,128))--Color(0xFFCD6600))
					RenderText('score1',string.format('%d',math.floor(lstg.var.psychic[slot1])),dx,dy-200-6,0.4,'center')
					local rk2=1.0+rk*3.0
					if rk2==1.0 then
						SetFontState('score1','',Color(255,255,255,255))
						RenderText('score1',string.format('x%.1f',rk2),dx+4,dy+200+20,0.4,'center')
					else
						SetFontState('score1','',rk*Color(255,224,80,80)+(1-rk)*Color(255,255,255,255))--颜色平滑过渡
						RenderText('score1',string.format('x%.1f',rk2),dx+4,dy+200+20,0.4+rk*0.02*(1+sin(6*pl.ani)),'center')--跳动效果
					end
					RenderText('score1',string.format('%.0f',lstg.var.expsychic[slot1]),dx-20,dy+200+24,0.20,'left')
				else
					--底图
					Render('pa_psybar_3',dx,dy,0,0.5)
					--灵力条渲染
					SetImageState('white','mul+add',Color(255,200,64,208))--Color(255,255,128,128)
					--1
					local rk=max(0,min(lstg.var.psychic[slot1]/maxpsy,1))
					RenderRect('white',dx-12,dx+0,dy-200,dy-200+400*rk)
					--2
					local rk=max(0,min(lstg.var.psychic[slot2]/maxpsy2,1))
					RenderRect('white',dx+0,dx+12,dy-200,dy-200+400*rk)
					--溢出值
					SetImageState('white','mul+add',Color(255,64,80,200))--Color(255,255,128,0)
					--1
					local rk=max(0,min(lstg.var.expsychic[slot1]/expsy,1))
					RenderRect('white',dx-19,dx-12,dy-200,dy-200+400*rk)
					--2
					local rk=max(0,min(lstg.var.expsychic[slot2]/expsy2,1))
					RenderRect('white',dx+12,dx+19,dy-200,dy-200+400*rk)
					--渲染分割
					SetImageState('white','',Color(64,0,0,0))
					--1
					local dh=400/pl.maxpsy
					for i=1,(pl.maxpsy-1) do
						RenderRect('white',dx-12,dx+0,dy-200+i*dh,dy-200+1+i*dh)
					end
					dh=400/pl.expsy
					for i=1,(pl.expsy-1) do
						RenderRect('white',dx-19,dx-12,dy-200+i*dh,dy-200+1+i*dh)
					end
					--2
					local dh=400/pl2.maxpsy
					for i=1,(pl2.maxpsy-1) do
						RenderRect('white',dx-0,dx+12,dy-200+i*dh,dy-200+1+i*dh)
					end
					dh=400/pl2.expsy
					for i=1,(pl2.expsy-1) do
						RenderRect('white',dx+12,dx+19,dy-200+i*dh,dy-200+1+i*dh)
					end
					--3
					RenderRect('white',dx-0.5,dx+0.5,dy-200,dy+200)
					--外框
					Render('pa_psybar_2',dx,dy,0,0.5)
					--数值显示
					--1
					SetFontState('score1','',Color(255,255,128,128))--Color(0xFFCD6600))
					RenderText('score1',string.format('%d',math.floor(lstg.var.psychic[slot1])),dx,dy-200-0,0.35,'center')
					local rk=max(0,min(lstg.var.expsychic[slot1]/expsy,1))
					local rk2=1.0+rk*3.0
					if rk2==1.0 then
						SetFontState('score1','',Color(255,255,255,255))
						RenderText('score1',string.format('x%.1f',rk2),dx+4,dy+200+28,0.35,'center')
					else
						SetFontState('score1','',rk*Color(255,224,80,80)+(1-rk)*Color(255,255,255,255))--颜色平滑过渡
						RenderText('score1',string.format('x%.1f',rk2),dx+4,dy+200+28,0.35+rk*0.02*(1+sin(6*pl.ani)),'center')--跳动效果
					end
					--RenderText('score1',string.format('%.0f',lstg.var.expsychic[slot1]),dx-20,dy+200+24,0.20,'left')
					--2
					SetFontState('score1','',Color(255,128,128,255))--Color(0xFFCD6600))
					RenderText('score1',string.format('%d',math.floor(lstg.var.psychic[slot2])),dx,dy-200-12,0.35,'center')
					local rk=max(0,min(lstg.var.expsychic[slot2]/expsy2,1))
					local rk2=1.0+rk*3.0
					if rk2==1.0 then
						SetFontState('score1','',Color(255,255,255,255))
						RenderText('score1',string.format('x%.1f',rk2),dx+4,dy+200+16,0.35,'center')
					else
						SetFontState('score1','',rk*Color(255,224,80,80)+(1-rk)*Color(255,255,255,255))--颜色平滑过渡
						RenderText('score1',string.format('x%.1f',rk2),dx+4,dy+200+16,0.35+rk*0.02*(1+sin(6*pl2.ani)),'center')--跳动效果
					end
					--RenderText('score1',string.format('%.0f',lstg.var.expsychic[slot2]),dx-20,dy+200+24,0.20,'left')
				end
			end
			
			----------分数 TODO:多玩家分数
			do
				local dx,dy=w.scrr+16,240+88
				SetImageState('white','',Color(192,0,0,0))
				RenderRect('white',dx,dx+96,dy,dy+128)
				dy=240+80
				SetFontState('item','',Color(0xFFADADAD))
				RenderScore('item',max(lstg.tmpvar.hiscore or 0,lstg.var.score),dx+94,dy+128-14,0.6,'right')
				RenderText('item',string.format('High Score:'),dx+2,dy+128,0.6,'left')
				SetFontState('item','',Color(0xFFFFFFFF))
				RenderText('item',string.format('Score:'),dx+2,dy+128-2*14,0.6,'left')
				RenderScore('item',lstg.var.score,dx+94,dy+128-3*14,0.6,'right')
				--graze
				RenderText('item',string.format('Graze:'),dx+2,dy+128-4*14,0.6,'left')
				if pls==1 then
					RenderText('item',string.format('%d',lstg.var.graze),dx+94,dy+128-5*14,0.6,'right')
				elseif pls==2 then
					RenderText('item',string.format('%d/%d',lstg.var.grazes[slot1],lstg.var.grazes[slot2]),dx+94,dy+128-5*14,0.6,'right')
				end
				--已走地图
				RenderText('item',string.format('Mileage:'),dx+2,dy+128-6*14,0.6,'left')
				RenderText('item',string.format('%d blocks',0),dx+94,dy+128-7*14,0.6,'right')
			end
			
			----------难度
			do
				local dx,dy=w.scrr+64,240-36
				SetFontState('score3','',Color(0xFFADADAD))
				local diff=string.match(stage.current_stage.name,"[%w_][%w_ ]*$")
				local diffimg=CheckRes('img','image:diff_'..diff)
				if diffimg then
					Render('image:diff_'..diff,dx,dy)
				else
					--by OLC，难度显示加入符卡练习
					if ext.sc_pr and diff=="Spell Practice" and lstg.var.sc_index then
						diff=_editor_class[_sc_table[lstg.var.sc_index][1]].difficulty
						if diff=="All" then diff="SpellCard" end
					end
					if diff=='Easy' or diff=='Normal' or diff=='Hard' or diff=='Lunatic' or diff=='Extra' then
						Render('rank_'..diff,dx,dy,0.5,0.5)
					else
						RenderText('score',diff,dx,dy-16,0.5,'center','bottom')
					end
				end
			end
			
			----------地图
			do
				local dx,dy=w.scrr+16,240-56
				SetImageState('white','',Color(192,0,0,0))
				RenderRect('white',dx,dx+96,dy-160,dy)
				if (w.scrr+16)<(screen.width-16) then--防止有人手欠把游戏炸了
					SetPlayerActMap(w.scrr+16,240-56-160,96,160)
				end
				--地图不存在时渲染默认空白地图
				if lstg.tmpvar.playermap_host==nil then
					SetViewMode'map'
					do
						local img='pa_blank_map'
						local world=lstg.act_player_map
						local timer=stage.current_stage.timer or 0
						local w,h=GetTextureSize(img)
						local x,y=timer/4,timer/2
						for i=-int((world.r+16+x)/w+0.5),int((world.r+16-x)/w+0.5) do
							for j=-int((world.t+16+y)/h+0.5),int((world.t+16-y)/h+0.5) do
								Render(img,x+i*w,y+j*h)
							end
						end
					end
					SetViewMode'ui'
				end
			end
			
			SetViewMode'world'
		end
	else
		LoadImageFromFile('ui_bg2','THlib\\ui\\ui_bg_2.png')
		LoadImageFromFile('menu_bg2','THlib\\ui\\menu_bg_2.png')
		function ui.DrawFrame()
			Render('ui_bg2',198,264)
		end

		function ui.DrawMenuBG()
			SetViewMode'ui'
			Render('menu_bg2',198,264)
			SetFontState('menu','',Color(0xFFFFFFFF))
			RenderText('menu',string.format('%.1ffps',GetFPS()),392,1,0.25,'right','bottom')
		end

		function ui.DrawScore()
			RenderText('score','HiScore',8,520,0.5,'left','top')
			RenderText('score',string.format('%d',max(lstg.tmpvar.hiscore or 0,lstg.var.score)),190,520,0.5,'right','top')
			RenderText('score','Score',206,520,0.5,'left','top')
			RenderText('score',string.format('%d',lstg.var.score),388,520,0.5,'right','top')
			SetFontState('score','',Color(0xFFFF4040))
			RenderText('score',string.format('%1.2f',lstg.var.power/100),8,496,0.5,'left','top')
			SetFontState('score','',Color(0xFF40FF40))
			RenderText('score',string.format('%d',lstg.var.faith),84,496,0.5,'left','top')
			SetFontState('score','',Color(0xFF4040FF))
			RenderText('score',string.format('%d',lstg.var.pointrate),160,496,0.5,'left','top')
			SetFontState('score','',Color(0xFFFFFFFF))
			RenderText('score',string.format('%d',lstg.var.graze),236,496,0.5,'left','top')
			RenderText('score',string.rep('*',max(0,lstg.var.lifeleft)),388,496,0.5,'right','top')
			RenderText('score',string.rep('*',max(0,lstg.var.bomb)),380,490,0.5,'right','top')
		end
	end
end

ResetUI()