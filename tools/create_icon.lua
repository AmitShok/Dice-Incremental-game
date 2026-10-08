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
local s=Sprite(128,128)
s.layers[1].name="Die depth and outline"
local im=s.cels[1].image
rounded(im,16,18,98,98,13,color("171f25"))
rounded(im,21,23,88,87,9,color("927655"))
rect(im,30,97,70,8,color("b99b70"))
local face=s:newLayer();face.name="Ivory face and bevel"
im=Image(128,128)
rounded(im,12,10,98,94,13,color("171f25"))
rounded(im,17,15,88,84,9,color("c9b18b"))
rounded(im,19,16,84,78,8,color("f0dfbd"))
rect(im,29,18,62,3,color("fff0d0"));rect(im,20,27,3,53,color("fff0d0"))
rect(im,31,92,58,3,color("d3bb91"))
s:newCel(face,1,im)
local symbol=s:newLayer();symbol.name="Infinity engraving"
im=Image(128,128)
for i=0,720 do
 local t=i*math.pi*2/720
 local x=61+30*math.cos(t)/(1+math.sin(t)^2)
 local y=55+30*math.cos(t)*math.sin(t)/(1+math.sin(t)^2)
 dot(im,x,y+1,4.5,color("c5ab82"))
end
for i=0,720 do
 local t=i*math.pi*2/720
 local x=61+30*math.cos(t)/(1+math.sin(t)^2)
 local y=55+30*math.cos(t)*math.sin(t)/(1+math.sin(t)^2)
 dot(im,x,y,3.8,color("203b37"))
end
s:newCel(symbol,1,im)
app.activeSprite=s
app.command.SpriteSize{ui=false,width=256,height=256,method="nearest-neighbor"}
app.fs.makeAllDirectories(root.."/assets/source/aseprite/branding")
app.fs.makeAllDirectories(root.."/assets/exported/branding")
s:saveAs(root.."/assets/source/aseprite/branding/d_infinity_icon.aseprite")
s:saveCopyAs(root.."/assets/exported/branding/d_infinity_icon.png")
s:close()
print("Exported D- infinity icon and layered Aseprite master")
