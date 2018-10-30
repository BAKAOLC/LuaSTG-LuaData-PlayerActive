local path=''
for i=1,52 do
	path='mod\\block'..i..'.zip'
	if not (lfs.attributes(path)==nil) then
		LoadPack(path)
		DoFile('_editor_output.lua')
	end
end
