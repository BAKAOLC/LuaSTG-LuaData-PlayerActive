-- javastage
jstg = {}

local jstgpath="ex\\"

DoFile(jstgpath.."Jnetwork.lua")--网络连接库
DoFile(jstgpath.."Jinput.lua")--输入控制库
DoFile(jstgpath.."Jplayer.lua")--多玩家场地库
--DoFile(jstgpath.."Jcompatible.lua")


--初始化默认的双输入
jstg.network.slots[2]='local'
jstg.network.slots[1]='local'
jstg.MultiPlayer()
jstg.CreateInput(2)




