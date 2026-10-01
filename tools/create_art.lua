local root = app.params["root"]
local function color(hex)
 hex=hex:gsub("#","")
 return app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255)
end
local C={}
for k,v in pairs({ink="171921",dark="20252d",wood="493530",grain="624337",gold="b98b51",light="f5db9f",cream="f0dfbd",felt="254942",felt2="2a5047",felt3="203e39",shadow="172c2b",pink="c68380",jade="82ad96"}) do C[k]=color(v) end
local function rect(im,x,y,w,h,c)
 for yy=math.max(0,y),math.min(im.height-1,y+h-1) do for xx=math.max(0,x),math.min(im.width-1,x+w-1) do im:drawPixel(xx,yy,c) end end
end
local function line(im,x1,y1,x2,y2,c)
 local steps=math.max(math.abs(x2-x1),math.abs(y2-y1))
 for t=0,steps do local a=steps==0 and 0 or t/steps; local x=math.floor(x1+(x2-x1)*a); local y=math.floor(y1+(y2-y1)*a); if x>=0 and x<im.width and y>=0 and y<im.height then im:drawPixel(x,y,c) end end
end
local function ellipse(im,x,y,rx,ry,c)
 for yy=-ry,ry do for xx=-rx,rx do if xx*xx/(rx*rx)+yy*yy/(ry*ry)<=1 then rect(im,x+xx,y+yy,1,1,c) end end end
end
local function roundrect(im,x,y,w,h,r,c)
 rect(im,x+r,y,w-2*r,h,c); rect(im,x,y+r,w,h-2*r,c)
 ellipse(im,x+r,y+r,r,r,c);ellipse(im,x+w-r-1,y+r,r,r,c);ellipse(im,x+r,y+h-r-1,r,r,c);ellipse(im,x+w-r-1,y+h-r-1,r,r,c)
end
local function layer(s,name,draw)
 local l=s:newLayer(); l.name=name; local im=Image(s.width,s.height); draw(im); s:newCel(l,1,im)
end
local function export(s,category,name,animated)
 app.fs.makeAllDirectories(root.."/assets/source/aseprite/"..category)
 app.fs.makeAllDirectories(root.."/assets/exported/"..category)
 s:saveAs(root.."/assets/source/aseprite/"..category.."/"..name..".aseprite")
 app.activeSprite=s
 if animated then app.command.ExportSpriteSheet{ui=false,askOverwrite=false,type=SpriteSheetType.HORIZONTAL,textureFilename=root.."/assets/exported/"..category.."/"..name..".png",dataFilename=root.."/assets/exported/"..category.."/"..name..".json",listTags=true}
 else s:saveCopyAs(root.."/assets/exported/"..category.."/"..name..".png") end
 s:close()
end
math.randomseed(38)
local s=Sprite(480,300)
s.layers[1].name="Room foundation"
local im=s.cels[1].image
rect(im,0,0,480,300,C.ink)
layer(s,"Walnut floor",function(im)
 rect(im,0,41,392,259,C.wood)
 for y=41,300,19 do line(im,0,y,391,y,C.ink);line(im,0,y+1,391,y+1,C.grain)
 for x=0,392,65 do line(im,x+(y%3)*8,y,x+(y%3)*8,y+18,C.ink) end end
 for i=1,900 do local x=math.random(0,390);local y=math.random(44,299);line(im,x,y,x+math.random(1,7),y,C.grain) end
end)
layer(s,"Table silhouette",function(im)
 roundrect(im,15,69,369,205,24,C.ink)
 roundrect(im,10,59,369,204,24,C.grain)
 roundrect(im,12,57,365,200,22,C.gold)
 roundrect(im,14,58,361,197,21,C.wood)
 roundrect(im,19,64,351,185,18,C.ink)
 roundrect(im,21,64,347,182,17,C.gold)
 roundrect(im,23,66,343,178,16,C.felt3)
 roundrect(im,25,67,339,174,15,C.felt)
 for x=46,345,16 do rect(im,x,61,2,1,C.light);rect(im,x,247,2,1,C.gold) end
end)
layer(s,"Felt weave and stitching",function(im)
 for y=81,228 do for x=38,350 do
 if (x*13+y*7)%47==0 then rect(im,x,y,1,1,C.felt2) end
 end end
 roundrect(im,32,74,325,160,12,C.felt3)
 roundrect(im,33,75,323,158,11,C.felt)
 for i=1,1200 do local x=math.random(36,352);local y=math.random(78,229);if (x+y)%3==0 then rect(im,x,y,1,1,C.felt2) end end
 -- Faded central diamond, leaves and brass corner flourishes.
 line(im,198,132,221,155,C.felt2);line(im,221,155,198,178,C.felt2);line(im,198,178,175,155,C.felt2);line(im,175,155,198,132,C.felt2)
 for _,v in ipairs({{39,83,1,1},{351,83,-1,1},{39,224,1,-1},{351,224,-1,-1}}) do
 local x,y,dx,dy=table.unpack(v)
 line(im,x,y,x+16*dx,y,C.gold);line(im,x,y,x,y+16*dy,C.gold)
 rect(im,x+4*dx,y+4*dy,2,2,C.gold)
 end
end)
layer(s,"Candle and small comforts",function(im)
 -- Brass candleholders, wax and flame.
 for _,v in ipairs({{28,51},{361,51}}) do
 local x,y=table.unpack(v)
 ellipse(im,x,y+5,10,3,C.ink);ellipse(im,x,y+2,7,2,C.gold)
 rect(im,x-3,y-12,6,14,C.cream);rect(im,x+2,y-12,1,13,C.gold)
 rect(im,x-2,y-13,5,2,C.light);rect(im,x,y-16,1,3,C.ink)
 ellipse(im,x,y-19,2,4,color("da9147"));rect(im,x,y-21,1,4,C.light)
 end
 -- Ledger and pencil resting below the table.
 rect(im,32,268,36,23,C.ink);rect(im,30,266,35,22,color("8b5f48"));rect(im,33,266,29,20,C.cream)
 line(im,47,267,47,285,C.gold)
 for y=270,282,4 do line(im,36,y,44,y,C.gold);line(im,50,y,58,y,C.gold) end
 line(im,69,283,80,268,C.gold);line(im,70,284,81,269,C.light)
 -- Ceramic coffee with ring and handle.
 ellipse(im,346,278,11,4,C.ink);ellipse(im,349,273,9,7,C.gold);ellipse(im,349,271,7,5,C.cream);ellipse(im,349,270,5,3,C.wood)
 ellipse(im,359,273,4,4,C.cream);ellipse(im,359,273,2,2,C.wood)
 -- Leaves in an earthenware pot.
 rect(im,366,277,10,9,C.grain);rect(im,364,275,14,3,C.gold)
 for i=0,4 do line(im,371,275,358+i*5,261-math.abs(2-i)*2,C.jade);ellipse(im,358+i*5,260-math.abs(2-i)*2,3,2,C.jade) end
 -- A few scattered brass chips.
 for i=1,4 do ellipse(im,296+i*7,280+(i%2)*3,4,2,C.ink);ellipse(im,296+i*7,278+(i%2)*3,4,2,C.gold);line(im,294+i*7,277+(i%2)*3,297+i*7,277+(i%2)*3,C.light) end
end)
export(s,"environment","room",false)
for _,spec in ipairs({{"panel","242b32","566258"},{"button","34453f","9b865c"},{"button_hover","475c50","ebc783"},{"button_disabled","242d2d","455248"}}) do
 local a=Sprite(16,16);local ii=a.cels[1].image
 roundrect(ii,0,1,16,15,2,C.ink);roundrect(ii,0,0,16,14,2,color(spec[3]));roundrect(ii,1,1,14,12,1,color(spec[2]));line(ii,3,1,12,1,color(spec[3]))
 export(a,"ui",spec[1],false)
end
local digits={["0"]={"111","101","101","101","111"},["1"]={"010","110","010","010","111"},["2"]={"111","001","111","100","111"},["3"]={"111","001","111","001","111"},["4"]={"101","101","111","001","001"},["5"]={"111","100","111","001","111"},["6"]={"111","100","111","101","111"},["7"]={"111","001","010","010","010"},["8"]={"111","101","111","101","111"},["9"]={"111","101","111","001","111"}}
local function number(im,n,c)
 local txt=tostring(n);local x=16-#txt*4+1
 for char in txt:gmatch(".") do
 for y,row in ipairs(digits[char]) do for xx=1,3 do if row:sub(xx,xx)=="1" then rect(im,x+(xx-1)*2,9+(y-1)*2,2,2,c) end end end
 x=x+8
 end
end
local specs={
 {"d4",4,"efba69","9d663d"},{"d6",6,"f0dfbd","ab956f"},{"d8",8,"8ec4ab","477d6a"},{"d10",10,"9bbada","566b9b"},{"d12",12,"dc9ca7","965466"},
 {"d20",20,"d68878","904d4d"},{"golden_d6",6,"efc66d","b88137"},{"lucky_d6",6,"b4cf94","648453"},{"exploding_d6",6,"eeab6d","b9684c"},{"multiplier_d6",6,"c6b5e5","80749e"}}
for _,spec in ipairs(specs) do
 local d=Sprite(32,32);d.layers[1].name="Faces"
 for face=1,spec[2] do
 if face>1 then d:newEmptyFrame() end
 local ii=Image(32,32)
 ellipse(ii,17,27,12,3,C.shadow)
 roundrect(ii,4,5,25,23,4,C.ink);roundrect(ii,5,5,23,21,3,color(spec[4]));roundrect(ii,5,3,23,21,3,color(spec[3]))
 line(ii,8,3,24,3,C.cream);line(ii,5,6,5,19,C.cream);line(ii,8,24,24,24,C.ink)
 if spec[2]~=6 then
 -- Distinct polyhedral silhouettes, each with a small raised lower facet.
 local pts={}
 if spec[2]==4 then pts={{16,2},{29,24},{3,24}}
 elseif spec[2]==8 then pts={{16,2},{29,14},{16,26},{3,14}}
 elseif spec[2]==10 then pts={{10,3},{23,3},{29,14},{20,25},{9,25},{3,14}}
 elseif spec[2]==12 then pts={{10,2},{23,2},{29,9},{29,21},{22,27},{9,27},{3,20},{3,9}}
 else pts={{10,2},{22,2},{30,10},{30,20},{22,28},{10,28},{2,20},{2,10}} end
 ii=Image(32,32)
 ellipse(ii,17,28,12,3,C.shadow)
 local function poly(points,fill)
 for yy=0,31 do
 local intersections={}
 for k=1,#points do local a=points[k];local b=points[k%#points+1]
 if (a[2]<=yy and b[2]>yy) or (b[2]<=yy and a[2]>yy) then table.insert(intersections,a[1]+(yy-a[2])/(b[2]-a[2])*(b[1]-a[1])) end end
 table.sort(intersections)
 for k=1,#intersections-1,2 do rect(ii,math.ceil(intersections[k]),yy,math.floor(intersections[k+1])-math.ceil(intersections[k])+1,1,fill) end
 end
 for k=1,#points do local a=points[k];local b=points[k%#points+1];line(ii,a[1],a[2],b[1],b[2],C.ink) end
 end
 poly(pts,color(spec[3]))
 for k=1,#pts do local a=pts[k];local b=pts[k%#pts+1]; if a[2]>18 and b[2]>18 then line(ii,a[1],a[2]-1,b[1],b[2]-1,color(spec[4])) end end
 line(ii,pts[1][1]+1,pts[1][2]+1,pts[2][1]-1,pts[2][2]+1,C.cream)
 end
 if spec[2]==6 then
 local points={}
 if face%2==1 then table.insert(points,{16,13}) end
 if face>=2 then table.insert(points,{10,7});table.insert(points,{22,19}) end
 if face>=4 then table.insert(points,{22,7});table.insert(points,{10,19}) end
 if face==6 then table.insert(points,{10,13});table.insert(points,{22,13}) end
 for _,pt in ipairs(points) do rect(ii,pt[1]-1,pt[2]-1,3,3,C.ink);rect(ii,pt[1]-1,pt[2]-1,1,1,color(spec[4])) end
 else number(ii,face,C.ink) end
 d:newCel(d.layers[1],face,ii)
 d.frames[face].duration=0.09
 end
 local tag=d:newTag(1,spec[2]);tag.name="faces"
 export(d,"dice",spec[1],true)
end
local h=Sprite(24,32);h.layers[1].name="Moss the croupier"
for f=1,12 do
 if f>1 then h:newEmptyFrame() end
 local ii=Image(24,32);local bob=(f%2);local lift=(f>=11 and -3 or 0)
 ellipse(ii,12,29,8,2,C.shadow)
 rect(ii,7,25+bob,4,3,C.ink);rect(ii,15,25+(1-bob),4,3,C.ink)
 roundrect(ii,5,14+lift,15,13,3,C.ink);roundrect(ii,6,15+lift,13,11,2,C.jade)
 rect(ii,9,17+lift,7,8,C.felt);rect(ii,10,18+lift,5,1,C.gold);rect(ii,10,24+lift,5,1,C.gold)
 ellipse(ii,12,11+bob+lift,8,7,C.ink);ellipse(ii,12,10+bob+lift,7,6,C.cream)
 ellipse(ii,5,4+bob+lift,3,5,C.ink);ellipse(ii,5,4+bob+lift,2,4,C.pink)
 ellipse(ii,19,4+bob+lift,3,5,C.ink);ellipse(ii,19,4+bob+lift,2,4,C.pink)
 rect(ii,8,8+bob+lift,2,2,C.ink);rect(ii,16,8+bob+lift,2,2,C.ink);rect(ii,12,12+bob+lift,2,1,C.pink)
 rect(ii,8,3+bob+lift,10,2,C.gold);rect(ii,10,1+bob+lift,7,2,C.felt)
 local ay= f>=9 and 13 or 20
 rect(ii,3,ay+lift,4,4,C.cream);rect(ii,19,ay+lift,3,4,C.cream)
 if f==9 or f==10 then rect(ii,20,ay-3,3,3,C.gold) end
 h:newCel(h.layers[1],f,ii);h.frames[f].duration=.12
end
for _,spec in ipairs({{"idle",1,2},{"walk",3,6},{"interact",7,8},{"roll",9,10},{"celebrate",11,12}}) do local t=h:newTag(spec[2],spec[3]);t.name=spec[1] end
export(h,"helpers","moss",true)
local fx=Sprite(16,16);fx.layers[1].name="Gold spark"
local ii=fx.cels[1].image
line(ii,8,2,8,13,C.light);line(ii,2,8,13,8,C.light);rect(ii,6,6,5,5,C.gold);rect(ii,7,7,3,3,C.cream)
export(fx,"effects","spark",false)
local shadow=Sprite(32,12);ellipse(shadow.cels[1].image,16,6,14,4,C.shadow);export(shadow,"effects","shadow",false)
local coin=Sprite(16,16);ellipse(coin.cels[1].image,8,9,6,6,C.ink);ellipse(coin.cels[1].image,8,7,6,6,C.gold);ellipse(coin.cels[1].image,8,7,4,4,C.light);rect(coin.cels[1].image,7,4,2,7,C.gold);export(coin,"icons","coin",false)
print("Aseprite assets exported successfully")
