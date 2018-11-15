

myplayer=Class(player_class)

function myplayer:init(slot)
	--调用父类回调函数
	player_class.init(self,slot)
	--自机高低速时移动速度
	self.hspeed=4.5
	self.lspeed=2
	--自机收点线高度，自机的y坐标高于它时会自动收点
	self.collect_line=256
	--下一次射击、丢雷的冷却时间（帧），每帧会自减1
	--当值为0的时候可以进行下一次射击、丢雷
	self.nextshoot=60
	self.nextspell=60
	--自机判定大小
	self.A=0.5
	self.B=0.5
	--自机状态，为0时是正常状态，大于90则处于决死状态，等于90触发miss
	--大于0小于90就是自机的死亡动画过程了
	--每帧会自减1
	self.death=0
	--自机保护时间（帧），每帧会自减1
	self.protect=360
	--自机贴图
	LoadTexture('reimu_player','THlib\\player\\reimu\\reimu.png')
	LoadImageGroup('reimu_player','reimu_player',0,0,32,48,8,3,0.5,0.5)
	self.imgs={}
	for i=1,24 do
		self.imgs[i]='reimu_player'..i
	end
end

function myplayer:shoot()

end

function myplayer:spell()

end

function myplayer:frame()
	player_class.frame(self)
end

function myplayer:render()
	player_class.render(self)
end

function myplayer:colli(other)

end



reimu_bullet_red=Class(player_bullet_straight)
function reimu_bullet_red:kill()
	New(reimu_bullet_red_ef,self.x,self.y,self.rot+180)
end

reimu_bullet_red_ef=Class(object)
function reimu_bullet_red_ef:init(x,y)
	self.x=x self.y=y self.rot=90 self.img='reimu_bullet_red_ef' self.layer=LAYER_PLAYER_BULLET+50 self.group=GROUP_GHOST
	self.vy=2.25
end
function reimu_bullet_red_ef:frame()
	if self.timer>14 then self.y=600 Del(self) end
end