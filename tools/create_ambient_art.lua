-- Derives a clean backdrop from the editable room and creates only ambient masters.
local root=assert(app.params["root"])
local function color(hex,alpha)
 return app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),alpha or 255)
end
local function pixel(im,x,y,c)
 x=math.floor(x+0.5);y=math.floor(y+0.5)
 if x>=0 and x<im.width and y>=0 and y<im.height then im:drawPixel(x,y,c) end
end
local function line(im,x,y,xx,yy,c)
 local n=math.ceil(math.max(math.abs(xx-x),math.abs(yy-y)))
 for i=0,n do local t=n==0 and 0 or i/n;pixel(im,x+(xx-x)*t,y+(yy-y)*t,c) end
end
local function ellipse(im,x,y,rx,ry,c)
 for yy=-math.ceil(ry),math.ceil(ry) do for xx=-math.ceil(rx),math.ceil(rx) do
  if xx*xx/(rx*rx)+yy*yy/(ry*ry)<=1 then pixel(im,x+xx,y+yy,c) end
 end end
end
local function export(s,name,animated)
 app.fs.makeAllDirectories(root.."/assets/source/aseprite/ambient")
 app.fs.makeAllDirectories(root.."/assets/exported/ambient")
 s:saveAs(root.."/assets/source/aseprite/ambient/"..name..".aseprite")
 app.activeSprite=s
 if animated then
  app.command.ExportSpriteSheet{ui=false,askOverwrite=false,type=SpriteSheetType.HORIZONTAL,textureFilename=root.."/assets/exported/ambient/"..name..".png",dataFilename=root.."/assets/exported/ambient/"..name..".json",listTags=true}
 else s:saveCopyAs(root.."/assets/exported/ambient/"..name..".png") end
 s:close()
end
local room=app.open(root.."/assets/source/aseprite/environment/room.aseprite")
for _,layer in ipairs(room.layers) do
 if layer.name=="Candle and small comforts" then
  local cel=layer:cel(1);local im=cel.image:clone()
  for y=0,im.height-1 do for x=0,im.width-1 do
   local gx,gy=x+cel.position.x,y+cel.position.y;local p=im:getPixel(x,y)
   local is_flame=gy>=26 and gy<=36 and ((gx>=24 and gx<=32) or (gx>=357 and gx<=365)) and (p==color("da9147") or p==color("f5db9f"))
   local is_leaf=gx>=350 and gx<=384 and gy>=249 and gy<=275 and p==color("82ad96")
   if is_flame or is_leaf then im:drawPixel(x,y,0) end
  end end
  cel.image=im
 end
end
export(room,"room_base",false)
local function animate(name,w,h,count,draw)
 local s=Sprite(w,h);s.layers[1].name=name
 for f=1,count do
  if f>1 then s:newEmptyFrame() end
  local im=Image(w,h);draw(im,(f-1)/count)
  if f==1 then s.cels[1].image=im else s:newCel(s.layers[1],f,im) end
  s.frames[f].duration=0.16
 end
 local tag=s:newTag(1,count);tag.name="Loop"
 export(s,name,true)
end
animate("flame",16,20,8,function(im,t)
 local lean=math.sin(t*2*math.pi)*0.8
 local height=4+math.sin(t*4*math.pi)*0.7
 ellipse(im,8+lean,10,2,height,color("da9147"))
 line(im,8,12,8+lean,8-height*0.2,color("f5db9f"))
 pixel(im,8+lean,10-height,color("f5db9f"))
end)
animate("steam",28,32,16,function(im,t)
 for strand=0,1 do
  local phase=(t+strand*0.5)%1
  local alpha=math.floor(math.sin(phase*math.pi)*90)
  local y=27-phase*23
  for i=0,7 do
   local x=13+strand*4+math.sin(phase*math.pi*2+i*0.4)*2
   pixel(im,x,y+i*0.7,color("d4dacb",alpha*(1-i/10)))
  end
 end
end)
animate("plant",40,36,12,function(im,t)
 for i=0,4 do
  local sway=math.sin(t*2*math.pi+i*0.35)*0.9
  local x=6+i*5+sway;local y=15-math.abs(2-i)*2
  line(im,19,29,x,y+1,color("82ad96"))
  ellipse(im,x,y,3,2,color("82ad96"))
  pixel(im,x-1,y-1,color("9cbea0"))
 end
end)
print("Exported editable candle, steam, plant and clean backdrop masters")
