--======================================
--Thlib
--======================================

----------------------------------------
--加载脚本

Include'THlib\\misc\\misc.lua'
Include'THlib\\se\\se.lua'
Include'THlib\\music\\music.lua'
Include'THlib\\item\\item.lua'
Include'THlib\\player\\player.lua'
Include'THlib\\player\\playersystem.lua'
Include'THlib\\enemy\\enemy.lua'
Include'THlib\\bullet\\bullet.lua'
Include'THlib\\laser\\laser.lua'
Include'THlib\\background\\background.lua'
Include'THlib\\ext.lua'
Include'THlib\\menu.lua'
Include'THlib\\editor.lua'
Include'THlib\\ui\\ui.lua'
Include'ex\\javastage.lua'
Include'ex\\crazystorm.lua'
Include'ex\\system.lua'
Include'ex\\systems\\act7\\system_act7.lua'

--在autorun文件夹下面的lua脚本会自动执行，加载时机为data和mod之间，可能会被mod里面的定义覆盖
local function autorun()
	local r=FindFiles('autorun\\','lua')
	for i,v in pairs(r) do
		local filename=v[1]
		local packname=v[2]
		Print('自动加载',filename)
		Include(''..filename)
	end
end autorun()
