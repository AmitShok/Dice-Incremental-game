-- D- infinity art pass 2: room backdrop, table surfaces, UI skin, sell tray and helper hats.
-- Run: ASEPRITE -b --script-param root=PROJECT_PATH --script tools/create_art_v2.lua
-- Writes layered .aseprite masters under assets/source/aseprite and PNGs under assets/exported.
-- WARNING: overwrites the masters it creates (room_base, tables/*, ui/*, helpers/hats).
-- Hand-edit the .aseprite masters afterwards and export with tools/export_art.lua instead.
local root = assert(app.params["root"], "Pass --script-param root=PROJECT_PATH")
math.randomseed(38)

-- Palette ------------------------------------------------------------------------
local P = {
  ink="0e0b10", night="141119", wall="1b1824", wall2="221d2c", wall3="2a2334", glow="3a2a26",
  wood0="2a1a14", wood1="3f2219", wood2="5b3426", wood3="6b3d2b", wood4="8a5236", wood5="a8683f",
  shelf1="3a2820", shelf2="4a3328", shelf3="6a4a36", shelf4="7d5a40",
  brass0="5e4526", brass1="8a6a40", brass2="b98b51", brass3="d8b874", brass4="f5db9f",
  cab="181a20", cab2="1d2027", cream="f0dfbd", wax="efe3c4", wax2="cdbf9c", paper="e9dcc0", paper2="c9b996",
  lilac0="2a2236", lilac1="6d5f8f", lilac2="a596cc",
}
local function rgb(h) h=h:gsub("#",""); return {tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16)} end
local function col(c,a) return app.pixelColor.rgba(math.floor(c[1]+0.5),math.floor(c[2]+0.5),math.floor(c[3]+0.5),a or 255) end
local function hex(h,a) return col(rgb(h),a) end
local function lerp(a,b,t) return {a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t} end
local BAYER = {{0,8,2,10},{12,4,14,6},{3,11,1,9},{15,7,13,5}}
local function dither(x,y,t) return t*16 > BAYER[y%4+1][x%4+1] + 0.5 end

-- Drawing primitives (all coordinates in art pixels; `S` scales each art pixel) ----
local S = 1
local function px(im,x,y,c)
  x=math.floor(x); y=math.floor(y)
  for dy=0,S-1 do for dx=0,S-1 do
    local X,Y=x*S+dx,y*S+dy
    if X>=0 and Y>=0 and X<im.width and Y<im.height then im:drawPixel(X,Y,c) end
  end end
end
local function rect(im,x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do px(im,xx,yy,c) end end end
local function inround(x,y,rx,ry,w,h,r)
  local cx = x<rx+r and rx+r or (x>rx+w-1-r and rx+w-1-r or x)
  local cy = y<ry+r and ry+r or (y>ry+h-1-r and ry+h-1-r or y)
  local dx,dy=x-cx,y-cy
  return x>=rx and y>=ry and x<rx+w and y<ry+h and dx*dx+dy*dy <= r*r+r*0.8
end
local function roundrect(im,x,y,w,h,r,c) for yy=y,y+h-1 do for xx=x,x+w-1 do if inround(xx,yy,x,y,w,h,r) then px(im,xx,yy,c) end end end end
local function roundline(im,x,y,w,h,r,c,step)
  for yy=y,y+h-1 do for xx=x,x+w-1 do
    if inround(xx,yy,x,y,w,h,r) and not inround(xx,yy,x+1,y+1,w-2,h-2,math.max(0,r-1)) then
      if not step or step==0 or ((xx+yy)%step)<math.ceil(step/2) then px(im,xx,yy,c) end
    end
  end end
end
local function line(im,x1,y1,x2,y2,c)
  local steps=math.max(math.abs(x2-x1),math.abs(y2-y1))
  for t=0,steps do local a=steps==0 and 0 or t/steps; px(im,x1+(x2-x1)*a,y1+(y2-y1)*a,c) end
end
local function ellipse(im,x,y,rx,ry,c) for yy=-ry,ry do for xx=-rx,rx do if xx*xx/(rx*rx)+yy*yy/(ry*ry)<=1 then px(im,x+xx,y+yy,c) end end end end

local function layer(s,name,draw)
  local l=s:newLayer(); l.name=name; local im=Image(s.width,s.height); draw(im); s:newCel(l,1,im)
end
local function finish(s,category,name)
  s:deleteLayer(s.layers[1]) -- the empty default layer
  app.fs.makeAllDirectories(root.."/assets/source/aseprite/"..category)
  app.fs.makeAllDirectories(root.."/assets/exported/"..category)
  s:saveAs(root.."/assets/source/aseprite/"..category.."/"..name..".aseprite")
  s:saveCopyAs(root.."/assets/exported/"..category.."/"..name..".png")
  s:close()
end

-- Table geometry shared by the room and the surfaces (room pixels; screen = ×2) ---
local FELT = {x=22,y=66,w=346,h=184,r=10}

-- 1. Room backdrop (560×320) ---------------------------------------------------------
do
  local s=Sprite(560,320); S=1
  layer(s,"Wallpaper and lamplight",function(im)
    local base,lat,dot,glow=rgb(P.wall),rgb(P.wall2),rgb(P.wall3),rgb(P.glow)
    for y=0,319 do for x=0,559 do
      local c=base
      if (x+y)%24==0 or (x-y+480)%24==0 then c=lat end
      if (x+12)%24==0 and (y)%24==0 then c=dot end
      local dx,dy=(x-196)/1.25,y-150
      local light=math.max(0,1-math.sqrt(dx*dx+dy*dy)/270)
      local level=math.floor(light*4)/4
      if dither(x,y,(light*4)%1) then level=math.min(1,level+0.25) end
      c=lerp(c,glow,level*0.55)
      im:drawPixel(x,y,col(c))
    end end
  end)
  layer(s,"Header ledge",function(im)
    rect(im,0,0,560,40,hex(P.night))
    for x=0,559 do if (x*7)%23<2 then px(im,x,math.random(0,38),hex(P.wall,255)) end end
    rect(im,0,40,560,2,hex(P.shelf3)); rect(im,0,42,560,3,hex(P.shelf1)); rect(im,0,45,560,1,hex(P.ink))
    for x=0,559,32 do rect(im,x,41,1,4,hex(P.wood0)) end
  end)
  layer(s,"Shop cabinet",function(im)
    roundrect(im,388,44,170,258,4,hex(P.ink))
    roundrect(im,389,45,168,256,4,hex(P.shelf1))
    rect(im,390,46,166,1,hex(P.shelf3))
    rect(im,393,49,160,248,hex(P.cab))
    for x=393,552,20 do rect(im,x,49,1,248,hex(P.cab2)) end
    for _,p in ipairs({{391,47},{553,47},{391,297},{553,297}}) do rect(im,p[1],p[2],3,3,hex(P.brass2)); px(im,p[1],p[2],hex(P.brass4)) end
  end)
  layer(s,"Shelf",function(im)
    rect(im,0,262,388,40,hex(P.shelf2))
    rect(im,0,262,388,2,hex(P.shelf4)); rect(im,0,264,388,2,hex(P.shelf3))
    for y=270,296,9 do for x=0,387 do if (x+y*3)%61>2 then else px(im,x,y,hex(P.shelf1)) end end end
    for x=0,387 do if math.random()<0.18 then px(im,x,math.random(268,296),hex(P.shelf1)) end end
    rect(im,0,298,388,3,hex(P.wood0)); rect(im,0,301,560,19,hex(P.ink))
  end)
  layer(s,"Table",function(im)
    -- drop shadow
    for y=58,272 do for x=14,392 do
      if inround(x,y,14,58,376,214,24) and dither(x,y,0.5) then px(im,x,y,hex(P.ink)) end
    end end
    roundrect(im,8,52,376,214,24,hex(P.ink))
    local rings={P.wood1,P.wood2,P.wood3,P.wood4,P.wood3,P.wood2}
    for i,c in ipairs(rings) do roundrect(im,8+i,52+i,376-2*i,214-2*i,24-i,hex(c)) end
    -- lamplight on the near rail: brighten the upper band
    for y=53,62 do for x=20,372 do if dither(x,y,0.35) then px(im,x,y,hex(P.wood5)) end end end
    roundline(im,14,58,364,202,18,hex(P.brass1))
    roundline(im,15,59,362,200,17,hex(P.brass2),6)
    -- felt lip and default felt (table surfaces draw over this)
    roundrect(im,FELT.x-2,FELT.y-2,FELT.w+4,FELT.h+4,FELT.r+2,hex(P.wood0))
    roundrect(im,FELT.x,FELT.y,FELT.w,FELT.h,FELT.r,hex("24493f"))
    -- brass studs along the rail
    for x=40,352,26 do for _,y in ipairs({56,258}) do rect(im,x,y,2,2,hex(P.brass3)); px(im,x+1,y+1,hex(P.brass1)) end end
    for y=88,232,24 do for _,x in ipairs({11,379}) do rect(im,x,y,2,2,hex(P.brass3)); px(im,x+1,y+1,hex(P.brass1)) end end
  end)
  layer(s,"Plaques",function(im)
    -- wallet plaque behind the money counter
    roundrect(im,214,3,136,34,3,hex(P.ink))
    roundrect(im,215,4,134,32,3,hex(P.brass1))
    rect(im,216,5,132,1,hex(P.brass3))
    roundrect(im,218,7,128,27,2,hex("16131a"))
    for _,p in ipairs({{217,6},{346,6},{217,33},{346,33}}) do px(im,p[1],p[2],hex(P.brass4)) end
    -- fate plaque
    roundrect(im,394,3,128,37,3,hex(P.ink))
    roundrect(im,395,4,126,35,3,hex(P.lilac1))
    rect(im,396,5,124,1,hex(P.lilac2))
    roundrect(im,398,7,120,30,2,hex(P.lilac0))
  end)
  layer(s,"Candles and book",function(im)
    for _,cx in ipairs({28,361}) do
      ellipse(im,cx,48,7,2,hex(P.brass1)); ellipse(im,cx,47,6,2,hex(P.brass2)); rect(im,cx-4,46,9,1,hex(P.brass3))
      rect(im,cx-3,33,7,13,hex(P.wax)); rect(im,cx+2,33,2,13,hex(P.wax2)); rect(im,cx-3,33,1,13,hex("fff6dc"))
      px(im,cx-1,34,hex(P.wax2)); px(im,cx,32,hex(P.ink))
      rect(im,cx+3,36,1,3,hex(P.wax)) -- drip
    end
    -- open ledger book and quill on the shelf
    rect(im,26,270,40,22,hex(P.ink)); rect(im,27,271,38,20,hex("6a3a2a"))
    rect(im,29,272,16,17,hex(P.paper)); rect(im,47,272,16,17,hex(P.paper)); rect(im,45,272,2,17,hex(P.paper2))
    for y=275,286,3 do line(im,31,y,42,y,hex(P.paper2)); line(im,49,y,60,y,hex(P.paper2)) end
    line(im,70,290,84,268,hex(P.cream)); line(im,71,290,85,268,hex(P.paper2)); px(im,70,291,hex(P.ink))
  end)
  finish(s,"ambient","room_base")
end

-- 2. Table surfaces (346×184 each) ---------------------------------------------------
local function surface(name,draw)
  local s=Sprite(FELT.w,FELT.h); S=1
  layer(s,"Surface",function(im)
    draw(im)
    -- round the corners to the felt cutout
    for y=0,FELT.h-1 do for x=0,FELT.w-1 do
      if not inround(x,y,0,0,FELT.w,FELT.h,FELT.r) then im:drawPixel(x,y,app.pixelColor.rgba(0,0,0,0)) end
    end end
  end)
  finish(s,"tables",name)
end
local function vignette(x,y,base,dark,amount)
  local ex=math.min(x,FELT.w-1-x)/40; local ey=math.min(y,FELT.h-1-y)/30
  local e=math.max(0,1-math.min(ex,ey)); local t=e*amount
  return dither(x,y,t) and dark or base
end
local function stitch(im,inset,c,step)
  roundline(im,inset,inset,FELT.w-2*inset,FELT.h-2*inset,math.max(2,FELT.r-inset+6),c,step)
end
local function brackets(im,c,hi)
  for _,p in ipairs({{10,10,1,1},{FELT.w-11,10,-1,1},{10,FELT.h-11,1,-1},{FELT.w-11,FELT.h-11,-1,-1}}) do
    for i=0,9 do px(im,p[1]+i*p[3],p[2],c); px(im,p[1],p[2]+i*p[4],c) end
    px(im,p[1],p[2],hi); px(im,p[1]+p[3],p[2]+p[4],c)
  end
end
local function emblem(im,cx,cy,c)
  -- a soft diamond with an infinity knot, the house mark
  for i=0,22 do px(im,cx-22+i,cy-i*0.6,c); px(im,cx+22-i,cy-i*0.6,c); px(im,cx-22+i,cy+i*0.6,c); px(im,cx+22-i,cy+i*0.6,c) end
  for t=0,63 do local a=t/64*math.pi*2; local r=math.cos(a); px(im,cx+9*math.sin(a), cy+4.5*math.sin(2*a)*0.9, c) end
end

surface("felt",function(im)
  local base,mid,dark,hi=rgb("24493f"),rgb("214439"),rgb("1b3a31"),rgb("2b5547")
  for y=0,FELT.h-1 do for x=0,FELT.w-1 do
    local c=((x+y)%2==0) and base or mid
    if (x*3+y*5)%17==0 then c=hi end
    c=vignette(x,y,c,dark,0.9)
    im:drawPixel(x,y,col(c))
  end end
  stitch(im,7,hex("3c6b5c"),4); brackets(im,hex("9b865c"),hex(P.brass4)); emblem(im,173,92,hex("2f5b4d"))
end)

surface("velvet",function(im)
  local base,dark,sheen=rgb("5a1f2b"),rgb("3e1520"),rgb("7a2c3a")
  for y=0,FELT.h-1 do for x=0,FELT.w-1 do
    local band=math.sin((x+y*1.7)/26)*0.5+0.5
    local n=math.random()*0.18
    local c=lerp(base,sheen,math.floor((band*0.55+n)*4)/4)
    c=vignette(x,y,c,dark,1.0)
    im:drawPixel(x,y,col(c))
  end end
  stitch(im,7,hex(P.brass2),3); stitch(im,10,hex("8a3a48"),5); brackets(im,hex(P.brass3),hex(P.brass4)); emblem(im,173,92,hex("74303e"))
end)

surface("workbench",function(im)
  local tones={"8a5a36","7f5231","92603a","845634","7a4e2f","8e5c37","805331"}
  local board=26
  for y=0,FELT.h-1 do
    local b=math.floor(y/board); local tone=rgb(tones[b%#tones+1]); local dark=lerp(tone,rgb("4a2e1c"),0.45)
    local seam=(y%board==0)
    for x=0,FELT.w-1 do
      local c=tone
      -- long, gently wavering grain streaks running along each plank
      local wave=(y%board)+1.6*math.sin(x/53+b*1.7)+0.8*math.sin(x/17+b*3.1)
      if math.floor(wave)%4==0 and ((x+b*31)%90)>6 then c=lerp(tone,dark,0.35) end
      if math.floor(wave*1.7)%11==0 then c=lerp(tone,dark,0.6) end
      if (y%board)==1 then c=lerp(tone,rgb("b07a4c"),0.35) end -- lit top edge of each plank
      if seam then c=rgb("3a2416") end
      local joint=((x+b*97)%173==0); if joint then c=rgb("3a2416") end
      im:drawPixel(x,y,col(c))
    end
  end
  for b=0,7 do for _,x in ipairs({8,FELT.w-10}) do local y=b*board+board/2; px(im,x,y,hex("c9c2b2")); px(im,x+1,y+1,hex("5c5448")) end end
  for _,k in ipairs({{96,40},{250,118}}) do ellipse(im,k[1],k[2],3,1,hex("5a3820")); px(im,k[1],k[2],hex("3a2416")) end
  brackets(im,hex("a9a9a9"),hex("e6e6e6"))
end)

surface("starlit",function(im)
  local top,bottom=rgb("1a2445"),rgb("0d1328")
  for y=0,FELT.h-1 do for x=0,FELT.w-1 do
    local t=y/FELT.h; local level=math.floor(t*5)/5
    if dither(x,y,(t*5)%1) then level=math.min(1,level+0.2) end
    im:drawPixel(x,y,col(vignette(x,y,lerp(top,bottom,level),rgb("090d1d"),0.8)))
  end end
  local stars={}
  for i=1,140 do local x,y=math.random(4,FELT.w-5),math.random(4,FELT.h-5); stars[#stars+1]={x,y}; px(im,x,y,hex(i%5==0 and "fff3c4" or "9fb0e0")) end
  for i=1,9 do local s=stars[i*7]; px(im,s[1]-1,s[2],hex("c8d4ff")); px(im,s[1]+1,s[2],hex("c8d4ff")); px(im,s[1],s[2]-1,hex("c8d4ff")); px(im,s[1],s[2]+1,hex("c8d4ff")); px(im,s[1],s[2],hex("ffffff")) end
  local cons={{60,40},{84,56},{110,48},{128,70},{150,62}}
  for i=1,#cons-1 do line(im,cons[i][1],cons[i][2],cons[i+1][1],cons[i+1][2],hex("2c3a6a")) end
  for _,s in ipairs(cons) do px(im,s[1],s[2],hex("fff3c4")) end
  ellipse(im,286,46,11,11,hex("f2e6c0")); ellipse(im,291,43,10,10,hex("17203f"))
  stitch(im,7,hex("6d7fb8"),4); brackets(im,hex("aab6d8"),hex("ffffff"))
end)

surface("gilded",function(im)
  local base,mid,dark=rgb("1f4a3a"),rgb("1c4435"),rgb("143328")
  for y=0,FELT.h-1 do for x=0,FELT.w-1 do
    local c=((x+y)%2==0) and base or mid
    if ((x+y)%12==0 or (x-y+400)%12==0) and (x%3~=0) then c=lerp(c,rgb("3c6a45"),0.5) end
    im:drawPixel(x,y,col(vignette(x,y,c,dark,0.9)))
  end end
  stitch(im,5,hex(P.brass2),0); stitch(im,8,hex(P.brass3),4)
  for _,p in ipairs({{14,14,1,1},{FELT.w-15,14,-1,1},{14,FELT.h-15,1,-1},{FELT.w-15,FELT.h-15,-1,-1}}) do
    for t=0,24 do local a=t/24*math.pi/2; px(im,p[1]+p[3]*(18*(1-math.cos(a))),p[2]+p[4]*(18*math.sin(a)*0.6),hex(P.brass3)) end
    for t=0,16 do local a=t/16*math.pi/2; px(im,p[1]+p[3]*(12*math.sin(a)*0.6),p[2]+p[4]*(12*(1-math.cos(a))),hex(P.brass2)) end
    ellipse(im,p[1]+p[3]*3,p[2]+p[4]*3,2,2,hex(P.brass4))
  end
  emblem(im,173,92,hex(P.brass2))
end)

-- 3. UI skin (16×16 art pixels exported at 2×, nine-slice margin 10px) ----------------
local function ui(name,draw)
  local s=Sprite(32,32); S=2
  layer(s,"Skin",function(im) draw(im) end)
  finish(s,"ui",name)
end
local function button(fill,top,bottom,rim,rimhi,pressed)
  return function(im)
    roundrect(im,0,0,16,16,2,hex(P.ink))
    roundrect(im,1,1,14,14,2,hex(rim))
    rect(im,2,1,12,1,hex(rimhi))
    rect(im,2,2,12,12,hex(fill))
    if pressed then rect(im,2,2,12,2,hex(bottom)); rect(im,2,13,12,1,hex(top))
    else rect(im,2,2,12,1,hex(top)); rect(im,2,12,12,2,hex(bottom)) end
    px(im,1,1,hex(rimhi)); px(im,14,1,hex(rimhi))
  end
end
ui("button",button("34503f","46694f","263a2f","8a6a40","d8b874",false))
ui("button_hover",button("3f614d","5a8162","2e4638","b98b51","f5db9f",false))
ui("button_pressed",button("2c4436","46694f","1f2f27","b98b51","f5db9f",true))
ui("button_disabled",button("252c2b","2e3735","1e2423","3e4844","56625b",false))
ui("panel",function(im)
  roundrect(im,0,0,16,16,2,hex(P.ink))
  roundrect(im,1,1,14,14,2,hex(P.shelf1))
  rect(im,2,1,12,1,hex(P.shelf3))
  rect(im,2,2,12,12,hex("1c2428"))
  rect(im,3,3,10,1,hex("232d31"))
  px(im,2,2,hex(P.brass2)); px(im,13,2,hex(P.brass2)); px(im,2,13,hex(P.brass1)); px(im,13,13,hex(P.brass1))
end)

-- 4. Sell tray (100×27 art pixels at 2×) ----------------------------------------------
do
  local s=Sprite(200,54); S=2
  layer(s,"Tray",function(im)
    roundrect(im,0,0,100,27,4,hex(P.ink))
    roundrect(im,1,1,98,25,4,hex(P.brass1))
    rect(im,3,1,94,1,hex(P.brass3))
    roundrect(im,3,3,94,21,3,hex(P.wood1))
    roundrect(im,5,5,90,17,2,hex("2a1e1a"))
    for x=7,93,6 do px(im,x,6,hex("352620")) end
    -- coin stack icon on the left
    for i=0,2 do ellipse(im,15,18-i*3,5,2,hex(P.brass1)); ellipse(im,15,17-i*3,5,2,hex(P.brass3)); px(im,13,17-i*3,hex(P.brass4)) end
  end)
  finish(s,"ui","sell_tray")
end

-- 5. Helper hats: 8 frames of 16×12, worn on Moss (frame order matches Cosmetics.HATS)
do
  local s=Sprite(16*8,12); S=1
  layer(s,"Hats",function(im)
    local function at(f,x,y,c) px(im,f*16+x,y,c) end
    local function fill(f,x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do at(f,xx,yy,c) end end end
    -- 0 party cone
    for i=0,8 do fill(0,8-math.floor(i/2),2+i,1+math.floor(i/2)*2,1,hex(i%3==0 and "f5db9f" or "d86f8a")) end
    at(0,8,1,hex("fff3c4")); at(0,8,0,hex("ffffff"))
    -- 1 beret
    fill(1,3,7,10,3,hex("b8433f")); fill(1,4,6,8,1,hex("d65a52")); at(1,8,5,hex("6e2522")); fill(1,3,10,10,1,hex("6e2522"))
    -- 2 felt cap
    fill(2,4,5,8,5,hex("3f6a8a")); fill(2,5,4,6,1,hex("5683a6")); fill(2,8,9,7,2,hex("2b4a63")); at(2,8,3,hex("f0dfbd"))
    -- 3 daisy
    for _,p in ipairs({{8,6},{6,7},{10,7},{7,9},{9,9}}) do fill(3,p[1]-1,p[2]-1,2,2,hex("ffffff")) end
    fill(3,7,7,2,2,hex("f2c14e")); at(3,5,10,hex("6aa86a")); at(3,4,11,hex("6aa86a"))
    -- 4 top hat
    fill(4,5,1,6,8,hex("23202a")); fill(4,5,7,6,1,hex("b8433f")); fill(4,3,9,10,2,hex("23202a")); fill(4,6,1,1,6,hex("3a3542"))
    -- 5 star hat
    for i=0,9 do fill(5,8-math.floor(i/2),1+i,1+math.floor(i/2)*2,1,hex("3c3a8a")) end
    fill(5,3,10,10,1,hex("2a2866")); at(5,7,6,hex("f5db9f")); at(5,9,8,hex("f5db9f")); at(5,8,1,hex("f5db9f"))
    -- 6 tiny crown
    fill(6,4,6,8,4,hex("d8b874")); fill(6,4,9,8,1,hex("8a6a40"))
    for _,x in ipairs({4,7,8,11}) do fill(6,x,4,1,2,hex("d8b874")) end
    at(6,6,7,hex("d65a52")); at(6,9,7,hex("5ab0d6")); at(6,4,3,hex("f5db9f")); at(6,11,3,hex("f5db9f"))
    -- 7 halo
    for t=0,31 do local a=t/32*math.pi*2; at(7,8+6*math.cos(a),5+2*math.sin(a),hex(t%4==0 and "ffffff" or "f5db9f")) end
  end)
  finish(s,"helpers","hats")
end

print("ART V2: room, five table surfaces, UI skin, sell tray and hats exported")
