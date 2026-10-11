-- Resting faces and rolling frames share mesh, palette, lighting and a 26px footprint.
local root=assert(app.params["root"])
local specs={{"d4",4,"efba69"},{"d6",6,"f0dfbd"},{"d8",8,"8ec4ab"},{"d10",10,"9bbada"},{"d12",12,"dc9ca7"},{"d20",20,"d68878"},{"golden_d6",6,"efc66d"},{"lucky_d6",6,"b4cf94"},{"exploding_d6",6,"eeab6d"},{"multiplier_d6",6,"c6b5e5"}}
local function rgba(hex,m)
 return app.pixelColor.rgba(math.min(255,tonumber(hex:sub(1,2),16)*m),math.min(255,tonumber(hex:sub(3,4),16)*m),math.min(255,tonumber(hex:sub(5,6),16)*m),255)
end
local function pixel(im,x,y,c)
 x=math.floor(x); y=math.floor(y)
 if x>=0 and x<32 and y>=0 and y<32 then im:drawPixel(x,y,c) end
end
local function line(im,a,b,c)
 local steps=math.ceil(math.max(math.abs(a[1]-b[1]),math.abs(a[2]-b[2])))
 for i=0,steps do local t=steps==0 and 0 or i/steps; pixel(im,a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,c) end
end
local function polygon(im,points,c)
 for y=0,31 do for x=0,31 do
  local inside=false; local j=#points
  for i=1,#points do
   local a,b=points[i],points[j]
   if ((a[2]>y+0.5)~=(b[2]>y+0.5)) and (x+0.5<(b[1]-a[1])*(y+0.5-a[2])/(b[2]-a[2])+a[1]) then inside=not inside end
   j=i
  end
  if inside then pixel(im,x,y,c) end
 end end
end
local function rotate(v,t)
 local a,b,c=t*math.pi*2,t*math.pi*2+0.3,0.18
 local x,y,z=v[1],v[2]*math.cos(a)-v[3]*math.sin(a),v[2]*math.sin(a)+v[3]*math.cos(a)
 x,z=x*math.cos(b)+z*math.sin(b),-x*math.sin(b)+z*math.cos(b)
 return {x*math.cos(c)-y*math.sin(c),x*math.sin(c)+y*math.cos(c),z}
end
local function mesh(sides)
 if sides==6 then
  return {{-1,-1,-1},{1,-1,-1},{1,1,-1},{-1,1,-1},{-1,-1,1},{1,-1,1},{1,1,1},{-1,1,1}},{{1,2,3,4},{5,8,7,6},{1,5,6,2},{4,3,7,8},{1,4,8,5},{2,6,7,3}}
 end
 if sides==4 then return {{1,1,1},{-1,-1,1},{-1,1,-1},{1,-1,-1}},{{1,2,3},{1,4,2},{1,3,4},{2,4,3}} end
 if sides==8 or sides==10 then
  local n=sides/2; local v={{0,-1.5,0},{0,1.5,0}}; local f={}
  for i=0,n-1 do v[#v+1]={math.cos(i*2*math.pi/n)*1.25,0,math.sin(i*2*math.pi/n)*1.25} end
  for i=0,n-1 do local a,b=3+i,3+(i+1)%n; f[#f+1]={1,a,b}; f[#f+1]={2,b,a} end
  return v,f
 end
 -- Icosahedron and its dual dodecahedron.
 local p=(1+math.sqrt(5))/2; local v={}
 for _,a in ipairs({-1,1}) do for _,b in ipairs({-p,p}) do
  v[#v+1]={0,a,b}; v[#v+1]={a,b,0}; v[#v+1]={b,0,a}
 end end
 local f={}
 local function distance(a,b) return (a[1]-b[1])^2+(a[2]-b[2])^2+(a[3]-b[3])^2 end
 for a=1,#v do for b=a+1,#v do for c=b+1,#v do
  if math.abs(distance(v[a],v[b])-4)<0.01 and math.abs(distance(v[a],v[c])-4)<0.01 and math.abs(distance(v[b],v[c])-4)<0.01 then f[#f+1]={a,b,c} end
 end end end
 if sides==12 then
  local dv,df={},{}
  for _,face in ipairs(f) do local center={0,0,0}; for _,i in ipairs(face) do for axis=1,3 do center[axis]=center[axis]+v[i][axis]/3 end end; dv[#dv+1]=center end
  for i,n in ipairs(v) do
   local ids={}; for j,face in ipairs(f) do for _,k in ipairs(face) do if k==i then ids[#ids+1]=j end end end
   local length=math.sqrt(n[1]^2+n[2]^2+n[3]^2); local normal={n[1]/length,n[2]/length,n[3]/length}
   local u=math.abs(normal[1])<0.9 and {0,normal[3],-normal[2]} or {-normal[3],0,normal[1]}
   local w={normal[2]*u[3]-normal[3]*u[2],normal[3]*u[1]-normal[1]*u[3],normal[1]*u[2]-normal[2]*u[1]}
   local function angle(k) local a=dv[k]; return math.atan(a[1]*w[1]+a[2]*w[2]+a[3]*w[3],a[1]*u[1]+a[2]*u[2]+a[3]*u[3]) end
   table.sort(ids,function(a,b) return angle(a)<angle(b) end); df[#df+1]=ids
  end
  v,f=dv,df
 end
 for _,a in ipairs(v) do for i=1,3 do a[i]=a[i]*0.8 end end
 return v,f
end
local pips={{{0,0}},{{-.45,-.45},{.45,.45}},{{-.45,-.45},{0,0},{.45,.45}},{{-.45,-.45},{.45,-.45},{-.45,.45},{.45,.45}},{{-.45,-.45},{.45,-.45},{0,0},{-.45,.45},{.45,.45}},{{-.45,-.45},{.45,-.45},{-.45,0},{.45,0},{-.45,.45},{.45,.45}}}
local digits={['0']={'111','101','101','101','111'},['1']={'010','110','010','010','111'},['2']={'111','001','111','100','111'},['3']={'111','001','111','001','111'},['4']={'101','101','111','001','001'},['5']={'111','100','111','001','111'},['6']={'111','100','111','101','111'},['7']={'111','001','010','010','010'},['8']={'111','101','111','101','111'},['9']={'111','101','111','001','111'}}
for _,spec in ipairs(specs) do
 local vertices,faces=mesh(spec[2])
 for _,category in ipairs({'rolls','dice'}) do
 local resting=category=='dice'
 local count=resting and spec[2] or 24
 local s=Sprite(32,32); s.layers[1].name=resting and 'Shaded result faces' or 'Shaded tumbling faces'
 for frame=1,count do
  if frame>1 then s:newEmptyFrame() end
  local im=Image(32,32); local transformed={}; local projected={}
  local minx,miny,maxx,maxy=999,999,-999,-999
  for i,v in ipairs(vertices) do
   local r=rotate(v,resting and 0.025 or (frame-1)/24+0.025); transformed[i]=r
   minx=math.min(minx,r[1]);maxx=math.max(maxx,r[1]);miny=math.min(miny,r[2]);maxy=math.max(maxy,r[2])
  end
  local size=26/math.max(maxx-minx,maxy-miny)
  for i,r in ipairs(transformed) do projected[i]={15.5+(r[1]-(minx+maxx)/2)*size,15.5+(r[2]-(miny+maxy)/2)*size} end
  local order={}
  for i,face in ipairs(faces) do local depth=0; for _,k in ipairs(face) do depth=depth+transformed[k][3]/#face end; order[#order+1]={id=i,depth=depth} end
  table.sort(order,function(a,b) return a.depth<b.depth end)
  local primary=order[#order].id
  for _,entry in ipairs(order) do
   local face=faces[entry.id]; local points={}; local cx,cy=0,0
   for _,k in ipairs(face) do points[#points+1]=projected[k]; cx=cx+projected[k][1]/#face; cy=cy+projected[k][2]/#face end
   polygon(im,points,rgba(spec[3],entry.id==primary and 1.0 or (0.67+0.22*(entry.depth+1.5)/3)))
   for i=1,#points do line(im,points[i],points[i%#points+1],rgba(spec[3],0.48)) end
   if spec[2]==6 then
    for _,pip in ipairs(pips[resting and entry.id==primary and frame or entry.id]) do
     local u,v=(pip[1]+1)/2,(pip[2]+1)/2
     local a,b,c,d=points[1],points[2],points[3],points[4]
     local x=a[1]*(1-u)*(1-v)+b[1]*u*(1-v)+c[1]*u*v+d[1]*(1-u)*v
     local y=a[2]*(1-u)*(1-v)+b[2]*u*(1-v)+c[2]*u*v+d[2]*(1-u)*v
     pixel(im,x,y,rgba("171921",1))
     if resting and entry.id==primary then pixel(im,x+1,y,rgba("171921",1));pixel(im,x,y+1,rgba("171921",1));pixel(im,x+1,y+1,rgba("171921",1)) end
    end
   elseif not resting then pixel(im,cx,cy,rgba("171921",1)) end
  end
  if resting and spec[2]~=6 then
   -- The readable result is consistently centered on the body, never on a tiny edge face.
   local text=tostring(frame);local startx=16-(#text*4-1)
   for n=1,#text do for y,row in ipairs(digits[text:sub(n,n)]) do for x=1,3 do
    if row:sub(x,x)=='1' then
     for dy=0,1 do for dx=0,1 do pixel(im,startx+(n-1)*8+(x-1)*2+dx,11+(y-1)*2+dy,rgba('171921',1)) end end
    end
   end end end
  end
  if frame==1 then s.cels[1].image=im else s:newCel(s.layers[1],frame,im) end
  s.frames[frame].duration=1/24
 end
 local tag=s:newTag(1,count); tag.name=resting and "Results" or "Tumble"
 app.fs.makeAllDirectories(root.."/assets/source/aseprite/"..category)
 app.fs.makeAllDirectories(root.."/assets/exported/"..category)
 s:saveAs(root.."/assets/source/aseprite/"..category.."/"..spec[1]..".aseprite")
 app.activeSprite=s
 app.command.ExportSpriteSheet{ui=false,askOverwrite=false,type=SpriteSheetType.HORIZONTAL,textureFilename=root.."/assets/exported/"..category.."/"..spec[1]..".png",dataFilename=root.."/assets/exported/"..category.."/"..spec[1]..".json",listTags=true}
 s:close()
 end
end
print("Exported twenty matched resting and tumbling dice masters")
