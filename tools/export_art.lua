local root=app.params["root"]
assert(root, "Pass --script-param root=PROJECT_PATH")
local base=root.."/assets/source/aseprite"
for _,category in ipairs(app.fs.listFiles(base)) do
 local folder=base.."/"..category
 if app.fs.isDirectory(folder) then
  for _,file in ipairs(app.fs.listFiles(folder)) do
   if file:match("%.aseprite$") then
    local sprite=app.open(folder.."/"..file)
    local name=file:gsub("%.aseprite$","")
    local output=root.."/assets/exported/"..category
    app.fs.makeAllDirectories(output)
    if #sprite.frames>1 then
     app.command.ExportSpriteSheet{ui=false,askOverwrite=false,type=SpriteSheetType.HORIZONTAL,textureFilename=output.."/"..name..".png",dataFilename=output.."/"..name..".json",listTags=true}
    else sprite:saveCopyAs(output.."/"..name..".png") end
    sprite:close()
   end
  end
 end
end
print("Exported editable Aseprite masters")
