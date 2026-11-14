-- Moss the helper (12 frames of 24x32) and the eight helper hats (16x12 each), drawn in the
-- same style as the dice: one lamp to the upper left, flat cel-shaded bands, an automatic
-- one-pixel outline in the shared outline colour and a painted floor shadow.
-- Frames: 0-1 idle (breathing), 2-5 walk, 6-7 reach for a die, 8-9 throw, 10-11 celebrate.
-- Hat frame order matches Cosmetics.HATS[*].frame.
-- Run: ASEPRITE -b --script-param root=PROJECT_PATH --script tools/create_helpers_hd.lua
local root = assert(app.params["root"], "Pass --script-param root=PROJECT_PATH")
local function hex(h) return {tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16)} end
local OUTLINE=hex("0e0b10")
local SHADOW=hex("172c2b")
local C={
  cream=hex("f0dfbd"), cream_lit=hex("fff6e4"), cream_shade=hex("d6c09a"), cream_dark=hex("ab956f"),
  pink=hex("c68380"), pink_lit=hex("e8a8a4"), pink_shade=hex("965466"),
  green=hex("254942"), green_lit=hex("3f6a5a"),
  apron=hex("82ad96"), apron_lit=hex("a8cdb6"), apron_shade=hex("5f8a74"),
  brass=hex("b98b51"), brass_lit=hex("d8b874"), brass_dark=hex("8a6a40"),
  shoe=hex("4a3328"), shoe_lit=hex("6a4a36"),
  hair=hex("8a5236"), hair_lit=hex("a8683f"),
  white=hex("ffffff"), blush=hex("e8a0a0"),
}

-- ------------------------------------------------------------------ grid helpers
local W,H
local grid
local function new(w,h) W,H=w,h; grid={}; for y=0,h-1 do grid[y]={} end end
local function p(x,y,c) x=math.floor(x); y=math.floor(y); if x>=0 and y>=0 and x<W and y<H then grid[y][x]=c end end
local function r(x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do p(xx,yy,c) end end end
-- Cel-shaded ellipse: lit band to the upper left, shade band to the lower right.
local function blob(cx,cy,rx,ry,base,lit,shade)
  for y=math.floor(cy-ry),math.ceil(cy+ry) do for x=math.floor(cx-rx),math.ceil(cx+rx) do
    local dx,dy=(x+0.5-cx)/rx,(y+0.5-cy)/ry
    if dx*dx+dy*dy<=1.0 then
      local f=dx*0.6+dy*0.8
      p(x,y,(shade and f>0.42) and shade or ((lit and f<-0.62) and lit or base))
    end
  end end
end
-- Rectangle with a lit left/top edge and a shaded right/bottom edge.
local function slab(x,y,w,h,base,lit,shade)
  r(x,y,w,h,base)
  if lit then r(x,y,1,h,lit); r(x,y,w,1,lit) end
  if shade then r(x+w-1,y+1,1,h-1,shade); r(x+1,y+h-1,w-1,1,shade) end
end
-- One-pixel outline around everything drawn so far, then a floor shadow under the feet.
local function outline_and_shadow(shadow_y,shadow_w)
  local out={}
  for y=0,H-1 do out[y]={} for x=0,W-1 do
    out[y][x]=grid[y][x]
    if not grid[y][x] then
      for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
        local nx,ny=x+d[1],y+d[2]
        if nx>=0 and ny>=0 and nx<W and ny<H and grid[ny][nx] and grid[ny][nx]~=SHADOW then out[y][x]=OUTLINE break end
      end
    end
  end end
  grid=out
  if shadow_y then
    for x=math.floor(12-shadow_w/2),math.floor(12+shadow_w/2)-1 do
      for _,y in ipairs({shadow_y,shadow_y+1}) do
        local edge=(x==math.floor(12-shadow_w/2) or x==math.floor(12+shadow_w/2)-1)
        if not grid[y][x] and not (edge and y==shadow_y+1) then grid[y][x]=SHADOW end
      end
    end
  end
end

-- ------------------------------------------------------------------ Moss
-- pose: dy (whole body), feet = {left_lift, right_lift}, arms = "side"|"reach"|"reach2"|"raise"|"throw"|"cheer",
-- mouth = "smile"|"open", extras
local function moss(pose)
  new(24,32)
  local dy=pose.dy or 0
  local bob=pose.bob or 0 -- head-only breathing offset
  -- feet
  local lf,rf=pose.feet[1],pose.feet[2]
  slab(7,27-lf+dy,4,3,C.shoe,C.shoe_lit,nil)
  slab(13,27-rf+dy,4,3,C.shoe,C.shoe_lit,nil)
  -- body: dark shirt with the apron over it
  slab(6,19+dy,12,9,C.green,C.green_lit,nil)
  slab(8,20+dy,8,8,C.apron,C.apron_lit,C.apron_shade)
  r(11,22+dy,2,1,C.apron_shade) -- apron pocket seam
  r(9,24+dy,6,1,C.apron_shade)
  -- arms (raised arms are drawn after the head so they show in front of it)
  local a=pose.arms
  local function hand(x,y) blob(x,y,1.6,1.6,C.cream,C.cream_lit,C.cream_shade) end
  -- A sleeve from the shoulder to the hand: two pixels thick, lit on its upper-left side.
  local function sleeve(x1,y1,x2,y2)
    local n=math.max(math.abs(x2-x1),math.abs(y2-y1))
    for i=0,n do local t=n==0 and 0 or i/n; local x,y=x1+(x2-x1)*t,y1+(y2-y1)*t
      p(x,y,C.green_lit); p(x+1,y,C.green); p(x,y+1,C.green); p(x+1,y+1,C.green) end
  end
  local function arms(front)
  if (a=="raise" or a=="cheer")~=front then return end
  if a=="side" then
    r(4,20+dy,2,5,C.green); r(18,20+dy,2,5,C.green); hand(5,26+dy); hand(19,26+dy)
  elseif a=="reach" or a=="reach2" then
    local ext=(a=="reach2") and 2 or 0
    r(4,20+dy,2,5,C.green); hand(5,26+dy)
    r(18,21+dy,3+ext,2,C.green); hand(21.5+ext,22+dy)
  elseif a=="raise" then
    r(4,20+dy,2,5,C.green); hand(5,26+dy)
    sleeve(18,19+dy,21,13+dy); hand(22,12+dy)
    -- the die in hand
    slab(19,7+dy,4,4,C.cream,C.cream_lit,C.cream_shade); p(20,8+dy,OUTLINE); p(21,9+dy,OUTLINE)
  elseif a=="throw" then
    r(4,20+dy,2,5,C.green); hand(5,26+dy)
    r(18,20+dy,4,2,C.green); hand(22.5,20.5+dy)
  elseif a=="cheer" then
    sleeve(5,19+dy,2,13+dy); sleeve(18,19+dy,21,13+dy); hand(2,12+dy); hand(22,12+dy)
  end
  end
  arms(false)
  -- bow tie
  r(10,19+dy,4,2,C.brass); p(10,19+dy,C.brass_lit); p(11,19+dy,C.brass_lit); p(13,20+dy,C.brass_dark); p(12,19+dy,C.brass_dark)
  -- ears (behind the head)
  local hy=dy+bob
  blob(5.5,7+hy,3.6,3.6,C.pink,C.pink_lit,C.pink_shade)
  blob(18.5,7+hy,3.6,3.6,C.pink,C.pink_lit,C.pink_shade)
  blob(5.5,7.5+hy,1.8,2,C.pink_lit,nil,nil)
  blob(18.5,7.5+hy,1.8,2,C.pink_lit,nil,nil)
  -- head
  blob(12,12.5+hy,7.4,6.6,C.cream,C.cream_lit,C.cream_shade)
  -- hair tuft
  r(11,5+hy,3,1,C.hair); p(10,6+hy,C.hair); p(11,6+hy,C.hair_lit); p(12,6+hy,C.hair); p(13,6+hy,C.hair)
  -- eyes with a highlight, blush, nose and mouth
  for _,ex in ipairs({9,15}) do r(ex,11+hy,1,2,OUTLINE); p(ex,11+hy,hex("3a3542")); p(ex-1,11+hy,C.white) end
  p(7,14+hy,C.blush); p(8,14+hy,C.blush); p(16,14+hy,C.blush); p(17,14+hy,C.blush)
  p(12,13+hy,C.pink_shade)
  if pose.mouth=="open" then r(11,15+hy,2,2,C.pink_shade); p(11,15+hy,OUTLINE); p(12,15+hy,OUTLINE)
  else p(11,15+hy,OUTLINE); p(13,15+hy,OUTLINE); p(12,16+hy,OUTLINE) end
  arms(true)
  outline_and_shadow(30,pose.shadow or 12)
  -- celebration sparkles (after the outline so they float free)
  if pose.sparkle then
    for _,s in ipairs(pose.sparkle) do p(s[1],s[2],C.brass_lit); p(s[1]-1,s[2],C.brass); p(s[1]+1,s[2],C.brass); p(s[1],s[2]-1,C.brass); p(s[1],s[2]+1,C.brass) end
  end
  if pose.motion then for _,m in ipairs(pose.motion) do p(m[1],m[2],C.cream_lit) end end
  return grid
end

local POSES={
  {dy=0,bob=0,feet={0,0},arms="side"},                       -- 0 idle
  {dy=0,bob=1,feet={0,0},arms="side"},                       -- 1 idle, breath out
  {dy=0,bob=0,feet={1,0},arms="side"},                       -- 2 walk
  {dy=1,bob=0,feet={0,0},arms="side"},                       -- 3 walk
  {dy=0,bob=0,feet={0,1},arms="side"},                       -- 4 walk
  {dy=1,bob=0,feet={0,0},arms="side"},                       -- 5 walk
  {dy=0,bob=0,feet={0,0},arms="reach"},                      -- 6 reach
  {dy=0,bob=1,feet={0,0},arms="reach2"},                     -- 7 reach further
  {dy=0,bob=0,feet={0,1},arms="raise"},                      -- 8 wind up, die in hand
  {dy=0,bob=0,feet={1,0},arms="throw",motion={{22,15},{23,17},{21,13}}}, -- 9 release
  {dy=-3,bob=0,feet={1,1},arms="cheer",mouth="open",shadow=8,sparkle={{2,5},{21,3}}}, -- 10 jump
  {dy=0,bob=0,feet={0,0},arms="cheer",mouth="open",sparkle={{3,3},{20,6}}},          -- 11 land
}

-- ------------------------------------------------------------------ hats (16x12)
local HAT={}
local function hat_cone()
  for i=0,8 do local half=math.floor(i/2); r(8-half,2+i,1+half*2,1,hex((i%3==1) and "f5db9f" or "d86f8a")) end
  for i=0,8 do local half=math.floor(i/2); p(8+half,2+i,hex((i%3==1) and "d8b874" or "a84a66")) end
  p(8,1,hex("fff3c4")); p(7,1,hex("f5db9f")); p(9,1,hex("f5db9f")); p(8,0,hex("ffffff"))
end
local function hat_beret()
  blob(8,8,5.5,2.6,hex("d65a52"),hex("f08a80"),hex("8e2e2c"))
  r(4,10,9,1,hex("6e2522")); p(8,4,hex("6e2522")); p(8,5,hex("8e2e2c"))
end
local function hat_cap()
  blob(8,7.5,4.5,3.4,hex("5683a6"),hex("7ea6c6"),hex("2b4a63"))
  r(8,9,7,2,hex("3f6a8a")); r(8,9,7,1,hex("5683a6")); p(8,4,hex("f0dfbd"))
end
local function hat_daisy()
  for _,q in ipairs({{8,5},{5,7},{11,7},{6,10},{10,10}}) do blob(q[1],q[2],1.6,1.6,hex("ffffff"),nil,hex("d6d0c4")) end
  blob(8,8,1.6,1.6,hex("f2c14e"),hex("ffe08a"),hex("c8902a"))
  p(3,10,hex("6aa86a")); p(2,11,hex("4f8a4c"))
end
local function hat_tophat()
  slab(5,1,6,8,hex("2c2836"),hex("4a4458"),hex("1c1a22"))
  r(5,7,6,1,hex("b8433f")); r(5,6,6,1,hex("d65a52"))
  slab(2,9,12,2,hex("2c2836"),hex("4a4458"),hex("1c1a22"))
end
local function hat_wizard()
  for i=0,9 do local half=math.floor(i/2); r(8-half,1+i,1+half*2,1,hex("3c3a8a")); p(8+half,1+i,hex("2a2866")); p(8-half,1+i,hex("5654b0")) end
  r(2,10,13,1,hex("2a2866")); r(2,10,6,1,hex("3c3a8a"))
  p(7,6,hex("f5db9f")); p(9,8,hex("f5db9f")); p(8,1,hex("f5db9f")); p(6,9,hex("d8b874"))
end
local function hat_crown()
  slab(3,6,10,4,hex("d8b874"),hex("f5db9f"),hex("8a6a40"))
  for _,x in ipairs({3,6,9,12}) do r(x,3,1,3,hex("d8b874")); p(x,2,hex("f5db9f")) end
  r(3,9,10,1,hex("8a6a40"))
  p(5,7,hex("d65a52")); p(8,7,hex("5ab0d6")); p(11,7,hex("7fbf7a"))
end
local function hat_halo()
  for t=0,47 do local a=t/48*math.pi*2; local x,y=8+6*math.cos(a),6+2.2*math.sin(a)
    p(x,y,hex(math.sin(a)<0 and "fff3c4" or "d8b874")) end
end
local HATS={hat_cone,hat_beret,hat_cap,hat_daisy,hat_tophat,hat_wizard,hat_crown,hat_halo}

-- ------------------------------------------------------------------ export
local function save(frames,fw,fh,path_master,path_png)
  local s=Sprite(fw*#frames,fh)
  local im=Image(s.width,s.height)
  for fi,g in ipairs(frames) do
    for y=0,fh-1 do for x=0,fw-1 do
      local c=g[y][x]
      if c then im:drawPixel((fi-1)*fw+x,y,app.pixelColor.rgba(c[1],c[2],c[3],255)) end
    end end
  end
  s.layers[1].name="Art"
  s:newCel(s.layers[1],1,im)
  app.fs.makeAllDirectories(app.fs.filePath(path_master))
  s:saveAs(path_master)
  s:saveCopyAs(path_png)
  s:close()
end

local frames={}
for i,pose in ipairs(POSES) do frames[i]=moss(pose) end
save(frames,24,32,root.."/assets/source/aseprite/helpers/moss.aseprite",root.."/assets/exported/helpers/moss.png")
local hats={}
for i,draw in ipairs(HATS) do
  new(16,12); draw()
  -- the halo floats; every other hat gets the outline
  if i~=8 then outline_and_shadow(nil) end
  hats[i]=grid
end
save(hats,16,12,root.."/assets/source/aseprite/helpers/hats.aseprite",root.."/assets/exported/helpers/hats.png")
print("HELPERS HD: Moss (12 frames) and 8 hats exported")
