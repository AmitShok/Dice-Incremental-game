-- Original editable application icon, painted and exported inside Aseprite.
local root=assert(app.params["root"])
local function color(h)
 return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255)
end
local function dot(im,x,y,r,c)
 for yy=math.floor(y-r),math.ceil(y+r) do for xx=math.floor(x-r),math.ceil(x+r) do
  if xx>=0 and xx<128 and yy>=0 and yy<128 and (xx-x)^2+(yy-y)^2<=r*r then im:drawPixel(xx,yy,c) end
 end end
end
local function rect(im,x,y,w,h,c)
 for yy=y,y+h-1 do for xx=x,x+w-1 do im:drawPixel(xx,yy,c) end end
end
local function rounded(im,x,y,w,h,r,c)
 rect(im,x+r,y,w-2*r,h,c);rect(im,x,y+r,w,h-2*r,c)
 for _,p in ipairs({{x+r,y+r},{x+w-r-1,y+r},{x+r,y+h-r-1},{x+w-r-1,y+h-r-1}}) do dot(im,p[1],p[2],r,c) end
end
local function polygon(im,points,c)
 for y=0,127 do for x=0,127 do
  local inside=false;local j=#points
  for i=1,#points do local a,b=points[i],points[j]
   if ((a[2]>y+0.5)~=(b[2]>y+0.5)) and x+0.5<(b[1]-a[1])*(y+0.5-a[2])/(b[2]-a[2])+a[1] then inside=not inside end
   j=i
  end
  if inside then im:drawPixel(x,y,c) end
 end end
end
local function edge(im,a,b,c,width)
 local steps=math.ceil(math.max(math.abs(a[1]-b[1]),math.abs(a[2]-b[2])))
 for i=0,steps do local t=i/steps;dot(im,a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,width,c) end
end
local function point(face,u,v)
 local a,b,c,d=face[1],face[2],face[3],face[4]
 return a[1]*(1-u)*(1-v)+b[1]*u*(1-v)+c[1]*u*v+d[1]*(1-u)*v,a[2]*(1-u)*(1-v)+b[2]*u*(1-v)+c[2]*u*v+d[2]*(1-u)*v
end
local s=Sprite(128,128)
s.layers[1].name="Three ivory die faces"
local im=s.cels[1].image
local front={{17,43},{82,57},{82,114},{17,100}}
local top={{17,43},{47,13},{113,31},{82,57}}
local side={{82,57},{113,31},{113,88},{82,114}}
for _,entry in ipairs({{top,'fff0d0'},{side,'bda27c'},{front,'f0dfbd'}}) do
 polygon(im,entry[1],color(entry[2]))
 for i=1,4 do edge(im,entry[1][i],entry[1][i%4+1],color('26352f'),1.8) end
end
edge(im,{21,45},{79,58},color('fff4db'),1)
edge(im,{20,47},{20,97},color('fff4db'),1)
local symbols=s:newLayer();symbols.name="Infinity and recessed side pips"
im=Image(128,128)
for _,uv in ipairs({{.33,.30},{.67,.70}}) do local x,y=point(top,uv[1],uv[2]);dot(im,x,y+1,4,color('ddc7a3'));dot(im,x,y,3.4,color('203b37')) end
for _,uv in ipairs({{.5,.23},{.5,.5},{.5,.77}}) do local x,y=point(side,uv[1],uv[2]);dot(im,x,y+1,3.4,color('e0cba5'));dot(im,x,y,2.9,color('203b37')) end
for i=0,720 do
 local t=i*math.pi*2/720
 local u=.5+.33*math.cos(t)/(1+math.sin(t)^2)
 local v=.5+.33*math.cos(t)*math.sin(t)/(1+math.sin(t)^2)
 local x,y=point(front,u,v)
 dot(im,x,y,2.5,color('203b37'))
end
s:newCel(symbols,1,im)
app.activeSprite=s
app.command.SpriteSize{ui=false,width=256,height=256,method="nearest-neighbor"}
app.fs.makeAllDirectories(root.."/assets/source/aseprite/branding")
app.fs.makeAllDirectories(root.."/assets/exported/branding")
s:saveAs(root.."/assets/source/aseprite/branding/d_infinity_icon.aseprite")
s:saveCopyAs(root.."/assets/exported/branding/d_infinity_icon.png")
s:close()
print("Exported D- infinity icon and layered Aseprite master")
