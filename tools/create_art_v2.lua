-- D- infinity art pass 2: room backdrop, table surfaces, UI skin and sell tray (hats: create_helpers_hd.lua).
-- Run: ASEPRITE -b --script-param root=PROJECT_PATH --script tools/create_art_v2.lua
-- Writes layered .aseprite masters under assets/source/aseprite and PNGs under assets/exported.
-- WARNING: overwrites the masters it creates (room_base, tables/*, ui/*).
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
-- One lamp, up and to the left of the table, lights everything: top-left edges catch light,
-- bottom-right edges fall into shade, exactly like the dice. Lamplight on the wall is banded
-- (flat steps with a one-pixel checker seam) rather than dithered.
local LIGHT={x=196,y=150}
local function bevel_tone(nx,ny)
  -- nx,ny: outward direction of a sloped surface; returns +1 lit, -1 shaded, 0 neutral
  local f=-nx*0.55-ny*0.85
  if f>0.35 then return 1 elseif f<-0.35 then return -1 end
  return 0
end
-- Carved frame: a rounded-rectangle rail with an outer roll, a flat top with grain, a brass
-- inlay and an inner slope. `tones` = {dark, shade, mid, lit, highlight}.
local function carved_rail(im,x,y,w,h,r,width,tones,inlay)
  local cx,cy=x+w/2,y+h/2
  for yy=y,y+h-1 do for xx=x,x+w-1 do
    if inround(xx,yy,x,y,w,h,r) then
      local d=0
      while d<width and inround(xx,yy,x+d+1,y+d+1,w-2*d-2,h-2*d-2,math.max(0,r-d-1)) do d=d+1 end
      if d<width then
        -- outward normal of a rounded rectangle: from the nearest point of its inner core, so
        -- straight sides light evenly and only the corners turn
        local qx=math.max(x+r,math.min(x+w-1-r,xx)); local qy=math.max(y+r,math.min(y+h-1-r,yy))
        local nx,ny=xx-qx,yy-qy
        if nx==0 and ny==0 then nx,ny=xx-cx,yy-cy end
        local len=math.sqrt(nx*nx+ny*ny); if len>0 then nx,ny=nx/len,ny/len end
        local c
        if d==0 then c=P.ink
        elseif d<=2 then local b=bevel_tone(nx,ny); c=b>0 and tones[5] or (b<0 and tones[1] or tones[3])
        elseif d==width-1 then local b=bevel_tone(-nx,-ny); c=b>0 and tones[4] or (b<0 and tones[1] or tones[2])
        elseif inlay and d==inlay then local b=bevel_tone(nx,ny); c=b>0 and P.brass3 or (b<0 and P.brass1 or P.brass2)
        elseif inlay and d==inlay+1 then c=P.brass1
        else
          c=tones[3]
          -- grain runs along the rail: wavy streaks keyed to the position along each side
          local along=math.abs(ny)>math.abs(nx) and xx or yy
          local wave=d+0.9*math.sin(along/11+d)+0.6*math.sin(along/29)
          if math.floor(wave*1.3)%4==0 and (along+d*13)%37>4 then c=tones[2] end
          if (along*7+d*11)%53==0 then c=tones[1] end
          if d==3 and bevel_tone(nx,ny)>0 then c=tones[4] end
        end
        px(im,xx,yy,hex(c))
      end
    end
  end end
end
-- Outlined brass rosette (rail corners, cabinet corners).
local function rosette(im,cx,cy)
  ellipse(im,cx,cy,5,5,hex(P.ink)); ellipse(im,cx,cy,4,4,hex(P.brass1)); ellipse(im,cx-1,cy-1,3,3,hex(P.brass2))
  ellipse(im,cx-1,cy-1,2,2,hex(P.brass3)); px(im,cx-2,cy-3,hex(P.brass4)); px(im,cx-3,cy-2,hex(P.brass4))
  rect(im,cx-1,cy-1,2,2,hex(P.brass1)); px(im,cx,cy,hex(P.ink))
end
local function rivet(im,x,y)
  px(im,x,y,hex(P.brass3)); px(im,x+1,y,hex(P.brass2)); px(im,x,y+1,hex(P.brass2)); px(im,x+1,y+1,hex(P.ink))
end
-- Plaque: outlined plate with a lit top-left bevel, rivets and an inset screen.
local function plaque(im,x,y,w,h,face,lit,shade,screen)
  roundrect(im,x,y,w,h,3,hex(P.ink))
  roundrect(im,x+1,y+1,w-2,h-2,3,hex(face))
  rect(im,x+2,y+1,w-4,1,hex(lit)); rect(im,x+1,y+2,1,h-4,hex(lit))
  rect(im,x+2,y+h-2,w-4,1,hex(shade)); rect(im,x+w-2,y+2,1,h-4,hex(shade))
  roundrect(im,x+4,y+4,w-8,h-8,2,hex(P.ink))
  roundrect(im,x+5,y+5,w-10,h-10,2,hex(screen))
  rect(im,x+6,y+5,w-12,1,hex("0a080c")) -- inner shadow under the screen lip
  for _,p in ipairs({{x+2,y+2},{x+w-4,y+2},{x+2,y+h-4},{x+w-4,y+h-4}}) do rivet(im,p[1],p[2]) end
end
do
  local s=Sprite(560,320); S=1
  layer(s,"Wallpaper and lamplight",function(im)
    local base,lat,dot,glow=rgb(P.wall),rgb(P.wall2),rgb(P.wall3),rgb(P.glow)
    for y=0,319 do for x=0,559 do
      -- damask: a diamond lattice with a small lozenge at each centre
      local u,v=x%24,y%24
      local dist=math.abs(u-12)+math.abs(v-12)
      local c=base
      if dist==10 then c=lat elseif dist<=2 then c=dot elseif dist==5 and (u==12 or v==12) then c=lat end
      -- lamplight in flat bands, seamed with a one-pixel checker
      local dx,dy=(x-LIGHT.x)/1.25,y-LIGHT.y
      local light=math.max(0,1-math.sqrt(dx*dx+dy*dy)/280)*3
      local band=math.floor(light)
      if light-band>0.85 and (x+y)%2==0 then band=band+1 end
      c=lerp(c,glow,math.min(3,band)*0.2)
      im:drawPixel(x,y,col(c))
    end end
  end)
  layer(s,"Header cornice",function(im)
    -- crown moulding along the top, with dentils
    rect(im,0,0,560,3,hex(P.shelf1)); rect(im,0,3,560,1,hex(P.shelf3)); rect(im,0,4,560,1,hex(P.ink))
    for x=0,559,6 do rect(im,x,5,4,2,hex(P.shelf2)); px(im,x,5,hex(P.shelf3)); rect(im,x,7,4,1,hex(P.ink)) end
    -- picture rail under the header: lit top edge, dark underside
    rect(im,0,39,560,1,hex(P.ink)); rect(im,0,40,560,1,hex(P.shelf4)); rect(im,0,41,560,2,hex(P.shelf3))
    rect(im,0,43,560,2,hex(P.shelf1)); rect(im,0,45,560,1,hex(P.ink))
    for x=16,559,48 do rivet(im,x,41) end
  end)
  layer(s,"Shop cabinet",function(im)
    -- soft shadow the cabinet throws on the wall (offset down-right, one flat tone)
    roundrect(im,391,47,170,258,4,hex("120f17"))
    carved_rail(im,388,44,170,258,5,6,{P.wood0,P.wood1,P.wood2,P.wood3,P.wood4},nil)
    rect(im,394,50,158,246,hex(P.ink))
    rect(im,395,51,156,244,hex(P.cab))
    for x=395,550,13 do rect(im,x,51,1,244,hex(P.cab2)) end
    rect(im,395,51,156,1,hex("0a080c"))
    for _,p in ipairs({{392,48},{554,48},{392,298},{554,298}}) do rosette(im,p[1],p[2]) end
  end)
  layer(s,"Shelf",function(im)
    -- shelf board: lit nosing, grain along the plank, deep shadow under the lip
    rect(im,0,261,388,1,hex(P.ink))
    rect(im,0,262,388,2,hex(P.shelf4)); rect(im,0,264,388,1,hex(P.shelf3))
    for y=265,297 do for x=0,387 do
      local c=P.shelf2
      local wave=y+1.2*math.sin(x/23)+0.7*math.sin(x/7+y)
      if math.floor(wave)%5==0 and (x+y*7)%41>5 then c=P.shelf1 end
      if (x*3+y*13)%97==0 then c=P.shelf3 end
      px(im,x,y,hex(c))
    end end
    for x=0,387,64 do rect(im,x,265,1,33,hex(P.shelf1)) end
    rect(im,0,298,388,1,hex(P.shelf1)); rect(im,0,299,388,2,hex(P.wood0)); rect(im,0,301,560,19,hex(P.ink))
  end)
  layer(s,"Table",function(im)
    -- flat drop shadow on the wall and shelf
    roundrect(im,12,57,376,214,24,hex("120f17"))
    carved_rail(im,8,52,376,214,24,12,{P.wood1,P.wood2,P.wood3,P.wood4,P.wood5},6)
    -- felt lip: the rail's inner edge throws a little shadow on the top and left of the felt
    roundrect(im,FELT.x-2,FELT.y-2,FELT.w+4,FELT.h+4,FELT.r+2,hex(P.wood0))
    roundrect(im,FELT.x,FELT.y,FELT.w,FELT.h,FELT.r,hex("24493f"))
    -- brass rosettes at the corners and studs along the rails
    for _,p in ipairs({{20,64},{372,64},{20,254},{372,254}}) do rosette(im,p[1],p[2]) end
    for x=44,348,26 do for _,y in ipairs({56,260}) do rivet(im,x,y) end end
    for y=92,228,24 do for _,x in ipairs({12,378}) do rivet(im,x,y) end end
  end)
  layer(s,"Plaques",function(im)
    plaque(im,214,3,136,34,P.brass2,P.brass3,P.brass1,"16131a")
    plaque(im,394,3,128,37,P.lilac1,P.lilac2,"4a3f66",P.lilac0)
  end)
  layer(s,"Candles and props",function(im)
    for _,cx in ipairs({28,361}) do
      -- brass dish
      ellipse(im,cx,48,8,3,hex(P.ink)); ellipse(im,cx,48,7,2,hex(P.brass1)); ellipse(im,cx,47,6,2,hex(P.brass2))
      rect(im,cx-4,46,9,1,hex(P.brass3)); px(im,cx-5,47,hex(P.brass4))
      -- candle body: outline, lit left side, shaded right side, a wax drip
      rect(im,cx-4,32,9,15,hex(P.ink))
      rect(im,cx-3,33,7,13,hex(P.wax)); rect(im,cx+2,33,2,13,hex(P.wax2)); rect(im,cx-3,33,1,13,hex("fff6dc"))
      rect(im,cx-3,33,7,1,hex(P.wax2)); px(im,cx,32,hex(P.ink)); px(im,cx,31,hex(P.ink))
      rect(im,cx+3,35,1,4,hex(P.wax)); px(im,cx+3,39,hex(P.wax2))
    end
    -- open ledger: outlined leather cover, two pages with ruled lines, a ribbon
    rect(im,25,269,42,24,hex(P.ink)); rect(im,26,270,40,22,hex("6a3a2a")); rect(im,26,270,40,1,hex("8a4e38"))
    rect(im,28,271,17,19,hex(P.paper)); rect(im,47,271,17,19,hex(P.paper)); rect(im,45,271,2,19,hex(P.paper2))
    rect(im,28,271,1,19,hex("fff6e4")); rect(im,63,271,1,19,hex(P.paper2))
    for y=274,287,3 do line(im,30,y,42,y,hex(P.paper2)); line(im,49,y,61,y,hex(P.paper2)) end
    rect(im,52,290,2,5,hex("b8433f")); px(im,52,295,hex("6e2522"))
    -- quill with a feather vane
    line(im,70,291,86,267,hex(P.ink)); line(im,71,290,86,268,hex(P.cream)); line(im,72,290,87,268,hex(P.paper2))
    for i=0,9 do px(im,80+i*0.7,276-i*1.0,hex(P.cream)); px(im,82+i*0.6,277-i*1.0,hex(P.paper2)) end
    px(im,70,292,hex(P.ink))
    -- (the house chip stack on the shelf is drawn live by effects/room_life.gd: it grows with
    -- the chips you hold)
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
-- Edge darkening in one flat step with a one-pixel checker seam (no dithered gradient), plus
-- a slightly deeper band along the top and left where the rail shades the felt.
local function vignette(x,y,base,dark,amount)
  local ex=math.min(x,FELT.w-1-x)/40; local ey=math.min(y,FELT.h-1-y)/30
  local e=math.max(0,1-math.min(ex,ey)); local t=e*amount
  if t>0.5 or (t>0.42 and (x+y)%2==0) then return dark end
  if (y<=2 or x<=2) then return dark end
  return base
end
local function stitch(im,inset,c,step)
  roundline(im,inset,inset,FELT.w-2*inset,FELT.h-2*inset,math.max(2,FELT.r-inset+6),c,step)
end
-- Corner brackets: outlined metal L-plates with a lit outer edge and a rivet, set into
-- each corner of the playing surface.
local function brackets(im,c,hi)
  local ink=hex(P.ink)
  for _,p in ipairs({{9,9,1,1},{FELT.w-10,9,-1,1},{9,FELT.h-10,1,-1},{FELT.w-10,FELT.h-10,-1,-1}}) do
    local x,y,sx,sy=p[1],p[2],p[3],p[4]
    -- outline first (one pixel larger), then the plate
    for i=-1,14 do for j=-1,4 do px(im,x+i*sx,y+j*sy,ink); px(im,x+j*sx,y+i*sy,ink) end end
    for i=0,13 do for j=0,3 do px(im,x+i*sx,y+j*sy,c); px(im,x+j*sx,y+i*sy,c) end end
    -- lit outer edges (the edges facing the table rim)
    for i=0,13 do px(im,x+i*sx,y,hi); px(im,x,y+i*sy,hi) end
    -- rivet in the elbow
    px(im,x+1*sx,y+1*sy,ink); px(im,x+2*sx,y+2*sy,hi)
    -- end caps cut on a slant
    px(im,x+13*sx,y+3*sy,ink); px(im,x+3*sx,y+13*sy,ink)
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

-- 5. Helper hats now come from tools/create_helpers_hd.lua, alongside Moss.

print("ART V2: room, five table surfaces, UI skin and sell tray exported")
