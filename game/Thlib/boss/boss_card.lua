--======================================
--th style boss card
--======================================

----------------------------------------
--boss card
--~细节：大多数时候只会用到New、init、render和del，其中init、del在编辑器中重载

boss.card = {}

function boss.card.New(name, t1, t2, t3, hp, drop, is_extra)
    local c = {}
    c.frame = boss.card.frame
    c.render = boss.card.render
    c.init = boss.card.init
    c.del = boss.card.del
    c.name = tostring(name)
    if t1 > t2 or t2 > t3 then
        error('t1<=t2<=t3 must be satisfied.')
    end
    c.t1 = int(t1) * 60
    c.t2 = int(t2) * 60
    c.t3 = int(t3) * 60
    c.hp = hp
    c.is_sc = (name ~= '')
    c.drop = drop
    c.is_extra = is_extra or false
    c.is_combat = true
    return c
end

function boss.card:frame() end

function boss.card:render()--自机活版本，符卡环绘制交给boss_card_cardline
    do return end
    local c = boss.GetCurrentCard(self)
    local alpha = self.aura_alpha or 255
    local timer = self.timer
    if c and c.is_sc and c.t1 ~= c.t3 then
        for i = 1, 16 do
            SetImageState('bossring1'..i, 'mul+add', Color(alpha, 255, 255, 255))
        end
        if timer < 90 then
            if self.fxr and self.fxg and self.fxb then
                local of = 1 - timer / 180
                for i = 1, 16 do
                    SetImageState('bossring2'..i, 'mul+add', Color(1.9 * alpha, self.fxr * of, self.fxg * of, self.fxb * of))
                end
            else
                for i = 1, 16 do
                    SetImageState('bossring2'..i, 'mul+add', Color(alpha, 255, 255, 255))
                end
            end
            misc.RenderRing('bossring1', self.x, self.y, timer * 2 + 270 * sin(timer * 2), timer * 2 + 270 * sin(timer * 2) + 16, self.ani * 3, 32, 16)
            misc.RenderRing('bossring2', self.x, self.y, 90 + timer * 1, -180 + timer * 4 - 16, -self.ani * 3, 32, 16)
        else
            if self.fxr and self.fxg and self.fxb then
                for i = 1, 16 do
                    SetImageState('bossring2'..i, 'mul+add', Color(1.9 * alpha, self.fxr / 2, self.fxg / 2, self.fxb / 2))
                end
            else
                for i = 1, 16 do
                    SetImageState('bossring2'..i, 'mul+add', Color( alpha, 255, 255, 255))
                end
            end
            local t = c.t3
            misc.RenderRing('bossring1', self.x, self.y, (t - timer) / (t - 90) * 180, (t - timer) / (t - 90) * 180 + 16, self.ani * 3, 32, 16)
            misc.RenderRing('bossring2', self.x, self.y, (t - timer) / (t - 90) * 180, (t - timer) / (t - 90) * 180 - 16, -self.ani * 3, 32, 16)
        end
    end
end

function boss.card:init() end

function boss.card:del() end

----------------------------------------
--自机活符卡环

boss_card_cardline=Class(object)
function boss_card_cardline:init(boss)
    self.boss=boss
    self.boss.cardlinehost=self
    self.group=GROUP_GHOST
    self.layer=LAYER_BG+1
    self.x=self.boss.x
    self.y=self.boss.y
    self.active=true
    self.bound=false
    local c=self.boss.current_card
    if not(c and c.is_sc and c.t1~=c.t3) then
        self.active=false
        Del(self)
    end
    --[=[--各项数据参考
    self.r11=128
    self.r12=144
    self.r21=144
    self.r22=160
    self.r11=224
    self.r12=240
    self.r21=240
    self.r22=256
    --]=]
    self.r11=224
    self.r12=-224
    self.r21=0
    self.r22=0
    if self.active then
        task.New(self,function()--内圈展开
            for t=1,90 do
                self.r11=-224+448*sin(t)
                self.r12=224+16*sin(t)
                task.Wait(1)
            end
        end)
        task.New(self,function()--外圈展开和收回处理
            for t=1,120 do
                self.r21=240*(t/120)+192*sin(180*(t/120))
                self.r22=self.r21+16
                task.Wait(1)
            end
            if c.t3>120 then
                for t=121,c.t3 do
                    if self.killed then break end
                    self.r11=224-96*((t-120)/(c.t3-120))
                    self.r12=self.r11+16
                    self.r21=self.r12
                    self.r22=self.r21+16
                    task.Wait(1)
                end
            end
            while self.r12>0 do
                self.r11=self.r11-9.6
                self.r12=self.r11+16
                self.r21=self.r12
                self.r22=self.r21+16
                task.Wait(1)
            end
            Del(self)
        end)
    end
end
function boss_card_cardline:frame()
    if self.active then
        if IsValid(self.boss) then
            self.x=self.boss.x+(self.x-self.boss.x)*0.9
            self.y=self.boss.y+(self.y-self.boss.y)*0.9
        end
        task.Do(self)
    end
end
function boss_card_cardline:render()
    if self.active then
        local b=self.boss
        for i=1,16 do
            SetImageState('bossring1'..i,'mul+add',Color(b.aura_alpha,255,255,255))
            SetImageState('bossring2'..i,'mul+add',Color(b.aura_alpha,255,255,255))
        end
        misc.RenderRing('bossring2',self.x,self.y,self.r11,self.r12,-self.ani*2,48,16)
        misc.RenderRing('bossring1',self.x,self.y,self.r21,self.r22, self.ani*2,48,16)
    end
end
