-- Shop icon sheet: 16×16 icons in one row, order must match ui/shop_icons.gd.
-- Run: ASEPRITE -b --script-param root=PROJECT_PATH --script tools/create_icons.lua
-- Overwrites assets/source/aseprite/icons/shop_icons.aseprite; hand edits belong in that master.
local root = assert(app.params["root"], "Pass --script-param root=PROJECT_PATH")
local ORDER = {"heavy","sixes","loaded","combos","hands","rhythm","chain","momentum","strong_arms","sharp_eyes",
  "many_hands","hire","fortune","crit","stride","echo","head_start","heirloom","patience","long_nights",
  "old_friend","muscle_memory","house_edge","prestige","chip","capsule","lock","none","mix","up","table","book","gear",
  "golden_touch","crit_chance","crit_power","deep_fortune","endless_favor","destiny","well_paid","bargain","haggler",
  "born_harmony","perfect_harmony","chip_collector","hot_hands","fire_within","quick_hands","night_shift","weighted_fate",
  "chip_hoard","hat_trick","divine"}
local function hex(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
local INK,CREAM,GOLD,GOLD2,BRASS,RED,BLUE,GREEN,LILAC,WHITE,GREY=
  hex("0e0b10"),hex("f0dfbd"),hex("f5db9f"),hex("d8b874"),hex("8a6a40"),hex("d65a52"),hex("6fb6e0"),hex("7fbf7a"),hex("b6a2e0"),hex("ffffff"),hex("8c8a96")
local s=Sprite(16*#ORDER,16)
local im=Image(s.width,s.height)
local ox=0
local function p(x,y,c) if x>=0 and x<16 and y>=0 and y<16 then im:drawPixel(ox+x,y,c) end end
local function r(x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do p(xx,yy,c) end end end
local function ln(x1,y1,x2,y2,c) local n=math.max(math.abs(x2-x1),math.abs(y2-y1)); for t=0,n do local a=n==0 and 0 or t/n; p(math.floor(x1+(x2-x1)*a+0.5),math.floor(y1+(y2-y1)*a+0.5),c) end end
local function circ(cx,cy,rad,c,fill) for y=-rad,rad do for x=-rad,rad do local d=x*x+y*y; if (fill and d<=rad*rad+rad) or (not fill and d<=rad*rad+rad and d>=(rad-1)*(rad-1)+(rad-1)) then p(cx+x,cy+y,c) end end end end
-- outlined box helper: ink border, fill, top highlight
local function box(x,y,w,h,fill,hi) r(x,y,w,h,INK); r(x+1,y+1,w-2,h-2,fill); if hi then r(x+1,y+1,w-2,1,hi) end end
local function die(x,y,fill,pips) box(x,y,9,9,fill,WHITE); for _,q in ipairs(pips) do p(x+q[1],y+q[2],INK) end end
local function star(cx,cy,c) p(cx,cy-2,c); p(cx,cy+2,c); p(cx-2,cy,c); p(cx+2,cy,c); r(cx-1,cy-1,3,3,c) end
local function heart(cx,cy,c) r(cx-3,cy-1,3,2,c); r(cx+1,cy-1,3,2,c); r(cx-2,cy,5,2,c); r(cx-1,cy+2,3,1,c); p(cx,cy+3,c); p(cx-2,cy-2,c); p(cx+2,cy-2,c) end
local function arm(c) r(3,9,8,4,INK); r(4,10,6,2,c); r(9,4,4,7,INK); r(10,5,2,5,c); r(9,3,4,2,c) end

local draw = {
  heavy=function() circ(8,4,3,hex("8c8a96"),false); circ(8,4,2,hex("5c5a66"),false); circ(8,10,5,hex("5c5a66"),true); r(5,7,2,2,hex("a8a6b4")); p(7,6,hex("a8a6b4")); r(5,14,7,1,hex("3e3c46")) end,
  sixes=function() die(1,4,CREAM,{{2,2},{6,2},{2,4},{6,4},{2,6},{6,6}}); star(12,4,GOLD) end,
  loaded=function() die(2,5,CREAM,{{2,2},{6,6},{4,4}}); ln(12,13,12,3,GOLD); p(11,4,GOLD); p(13,4,GOLD); p(10,5,GOLD); p(14,5,GOLD) end,
  combos=function() die(1,6,CREAM,{{2,2},{6,6}}); die(6,1,CREAM,{{2,2},{6,6}}); p(14,12,GOLD); p(13,13,GOLD); p(15,13,GOLD); p(14,14,GOLD) end,
  hands=function() r(8,4,6,8,CREAM); r(8,3,5,1,CREAM); r(6,8,2,3,CREAM); r(9,4,1,3,hex("d6c09a")); r(11,4,1,3,hex("d6c09a")); ln(1,5,5,5,WHITE); ln(0,8,4,8,WHITE); ln(1,11,5,11,WHITE) end,
  rhythm=function() for i=0,10 do local half=math.floor(i/2.5)+1; r(8-half,2+i,half*2,1,hex("8a5236")) end; for i=2,9 do local half=math.max(0,math.floor(i/2.5)); r(8-half,2+i,half*2,1,CREAM) end; ln(8,11,12,3,INK); r(11,5,2,2,GOLD); r(3,13,10,2,BRASS); r(3,13,10,1,GOLD2) end,
  chain=function() circ(5,8,3,GREY,false); circ(10,8,3,GOLD2,false); p(5,8,INK); p(10,8,INK) end,
  momentum=function() r(6,4,4,10,hex("e0703a")); r(5,7,6,6,hex("e0703a")); r(7,8,2,5,GOLD); p(7,3,hex("e0703a")); p(9,2,hex("e0703a")); p(4,9,hex("e0703a")); p(11,9,hex("e0703a")) end,
  strong_arms=function() local skin,shade=hex("e6c49a"),hex("b98b51"); r(1,10,9,4,skin); circ(5,9,2,skin,true); r(9,4,4,8,skin); r(8,1,6,4,skin); ln(8,9,8,11,shade); p(10,1,shade); p(12,1,shade); r(9,4,4,1,shade); r(2,13,8,1,shade); p(4,7,hex("f6dcb4")); p(5,7,hex("f6dcb4")) end,
  sharp_eyes=function() for x=1,14 do local h=math.floor(3*math.sin((x-1)/13*math.pi)+0.5); p(x,8-h,INK); p(x,8+h,INK) end; circ(8,8,2,BLUE,true); p(8,8,INK); p(7,7,WHITE) end,
  many_hands=function() for _,x in ipairs({1,9}) do r(x+1,4,4,8,CREAM); r(x+1,3,4,1,CREAM); r(x,8,1,3,CREAM); p(x+2,4,hex("d6c09a")); p(x+2,5,hex("d6c09a")); p(x+4,4,hex("d6c09a")); p(x+4,5,hex("d6c09a")) end; r(7,13,2,1,GOLD) end,
  hire=function() circ(3,4,3,hex("c68380"),true); circ(12,4,3,hex("c68380"),true); circ(3,4,1,hex("e8a8a4"),true); circ(12,4,1,hex("e8a8a4"),true); circ(8,9,6,CREAM,true); r(4,6,3,2,hex("fff6e4")); r(11,12,2,2,hex("d6c09a")); r(5,8,1,2,INK); r(10,8,1,2,INK); p(4,8,WHITE); p(9,8,WHITE); p(4,11,hex("e8a0a0")); p(11,11,hex("e8a0a0")); p(7,11,hex("965466")); p(7,13,INK); p(6,12,INK); p(8,12,INK); r(7,3,2,1,hex("8a5236")) end,
  fortune=function() local leaf,vein=hex("56ac46"),hex("2f7a2a"); for _,c in ipairs({{5,5},{11,5},{5,10},{11,10}}) do circ(c[1],c[2],3,leaf,true) end; ln(8,8,3,3,vein); ln(8,8,13,3,vein); ln(8,8,3,12,vein); ln(8,8,13,12,vein); r(7,7,3,3,vein); ln(9,12,12,15,vein); p(3,4,hex("94d872")); p(9,3,hex("94d872")) end,
  crit=function() for a=0,7 do local ang=a/8*math.pi*2; ln(8,8,math.floor(8+7*math.cos(ang)+0.5),math.floor(8+7*math.sin(ang)+0.5),a%2==0 and GOLD or RED) end; circ(8,8,2,WHITE,true) end,
  stride=function() r(5,5,5,6,hex("6d5f8f")); r(5,11,8,2,hex("6d5f8f")); r(4,13,10,1,INK); r(11,10,3,2,hex("6d5f8f")); r(6,6,1,4,hex("a596cc")); for i=0,2 do ln(1,4+i*2,4,2+i*2,WHITE) end end,
  echo=function() circ(8,8,2,GOLD,true); circ(8,8,5,GOLD2,false); circ(8,8,7,BRASS,false) end,
  head_start=function() circ(6,9,5,GOLD2,true); r(5,6,2,1,BRASS); r(5,8,2,1,BRASS); r(5,10,2,1,BRASS); r(5,12,2,1,BRASS); p(4,7,BRASS); p(7,11,BRASS); for i=0,3 do r(12,6+i,1+i,1,GREEN); r(12,12-i,1+i,1,GREEN) end; r(12,9,4,1,GREEN) end,
  heirloom=function() die(3,4,hex("c9a46a"),{{2,2},{6,6},{4,4}}); p(2,13,BRASS); p(13,3,GOLD); p(14,2,WHITE) end,
  patience=function() r(4,1,8,2,BRASS); r(4,13,8,2,BRASS); ln(5,3,10,12,CREAM); ln(10,3,5,12,CREAM); r(6,10,4,2,GOLD); p(8,6,GOLD) end,
  long_nights=function() circ(8,8,6,GOLD,true); circ(11,6,5,hex("1a2445"),true); p(3,3,WHITE); p(13,13,WHITE) end,
  old_friend=function() circ(5,6,3,RED,true); circ(11,6,3,RED,true); for i=0,6 do r(2+i,8+i,13-2*i,1,RED) end; r(4,4,2,2,hex("f08a80")) end,
  muscle_memory=function() for _,x in ipairs({4,11}) do circ(x-2,5,1,hex("c68380"),true); circ(x+2,5,1,hex("c68380"),true); circ(x,8,3,CREAM,true); p(x-1,8,INK); p(x+1,8,INK); p(x,10,hex("965466")) end; r(1,13,14,2,hex("3f6a5a")); r(1,13,14,1,hex("82ad96")) end,
  house_edge=function() for i=0,5 do r(8-i-1,1+i,2+i*2,1,hex("b8433f")) end; r(2,7,12,7,GOLD2); r(2,7,12,1,GOLD); r(6,9,4,5,hex("6d5f8f")); p(8,10,LILAC); p(7,11,LILAC); p(9,11,LILAC); p(8,12,LILAC); r(1,14,14,1,BRASS) end,
  prestige=function() for t=0,47 do local a=t/48*math.pi*2; p(math.floor(8+6*math.sin(a)+0.5),math.floor(8+3*math.sin(2*a)+0.5),LILAC) end end,
  chip=function() circ(8,8,6,RED,true); circ(8,8,6,INK,false); circ(8,8,3,CREAM,false); for _,q in ipairs({{8,2},{8,14},{2,8},{14,8}}) do p(q[1],q[2],CREAM) end end,
  capsule=function() circ(8,6,5,hex("e07a9a"),true); r(3,7,11,1,INK); circ(8,9,5,CREAM,true); r(3,6,11,2,INK); r(3,6,11,1,hex("e07a9a")); p(5,3,WHITE) end,
  lock=function() circ(8,6,3,GREY,false); r(4,7,9,7,INK); r(5,8,7,5,GOLD2); p(8,10,INK); p(8,11,INK) end,
  none=function() circ(8,8,6,GREY,false); ln(4,4,12,12,GREY) end,
  mix=function() for i=0,3 do r(2+(i%2)*7,2+math.floor(i/2)*7,5,5,({RED,BLUE,GOLD,GREEN})[i+1]) end end,
  up=function() for i=0,5 do r(8-i,2+i,1+i*2,1,GOLD) end; r(6,8,5,6,GOLD2); r(6,13,5,1,BRASS) end,
  table=function() r(1,4,14,9,INK); r(2,5,12,7,hex("6b3d2b")); r(4,6,8,5,hex("2b5547")); p(5,7,hex("3c6b5c")); r(2,12,2,3,INK); r(12,12,2,3,INK) end,
  book=function() r(1,3,14,11,INK); r(2,4,5,9,CREAM); r(9,4,5,9,CREAM); r(7,4,2,9,hex("c9b996")); for y=6,11,2 do r(3,y,3,1,GREY); r(10,y,3,1,GREY) end end,
  gear=function() circ(8,8,5,GREY,true); for a=0,7 do local ang=a/8*math.pi*2; r(math.floor(8+6*math.cos(ang)+0.5)-1,math.floor(8+6*math.sin(ang)+0.5)-1,2,2,GREY) end; circ(8,8,2,INK,true) end,
  golden_touch=function() die(2,5,GOLD2,{{2,2},{6,2},{2,4},{6,4},{2,6},{6,6}}); r(3,6,7,1,GOLD); ln(11,4,14,1,WHITE); ln(12,5,15,5,WHITE); ln(10,3,10,0,WHITE) end,
  crit_chance=function() circ(8,8,6,RED,false); circ(8,8,4,CREAM,false); circ(8,8,2,RED,true); p(8,8,WHITE) end,
  crit_power=function() for a=0,7 do local ang=a/8*math.pi*2; ln(7,9,math.floor(7+5*math.cos(ang)+0.5),math.floor(9+5*math.sin(ang)+0.5),a%2==0 and GOLD or RED) end; r(12,1,1,5,WHITE); r(10,3,5,1,WHITE) end,
  deep_fortune=function() circ(8,10,5,hex("b88a50"),true); circ(8,10,5,INK,false); r(6,3,5,3,hex("b88a50")); r(5,5,7,1,INK); r(7,8,3,1,GOLD); r(8,7,1,5,GOLD); r(7,11,3,1,GOLD) end,
  endless_favor=function() for t=0,47 do local a=t/48*math.pi*2; p(math.floor(8+6*math.sin(a)+0.5),math.floor(8+3*math.sin(2*a)+0.5),GOLD) end; star(8,3,WHITE) end,
  destiny=function() star(8,8,LILAC); ln(8,2,8,14,LILAC); ln(2,8,14,8,LILAC); p(8,8,WHITE); p(4,4,LILAC); p(12,12,LILAC); p(12,4,LILAC); p(4,12,LILAC) end,
  well_paid=function() circ(5,6,3,CREAM,true); p(2,3,hex("c68380")); p(8,3,hex("c68380")); p(4,6,INK); p(6,6,INK); circ(10,10,4,GOLD2,true); r(10,8,1,5,BRASS); r(9,9,3,1,BRASS); r(9,11,3,1,BRASS); p(8,8,GOLD) end,
  bargain=function() die(1,6,CREAM,{{2,2},{4,4},{6,6}}); r(8,1,7,5,GOLD2); r(8,1,7,1,GOLD); p(9,3,INK); ln(10,5,14,1,RED); ln(11,5,14,2,RED); ln(9,6,10,8,BRASS) end,
  haggler=function() r(3,4,11,8,GOLD2); p(4,7,INK); p(4,8,INK); ln(12,5,7,10,RED); r(7,5,2,2,RED); r(11,9,2,2,RED); r(3,4,11,1,GOLD) end,
  born_harmony=function() die(1,6,CREAM,{{4,4}}); die(6,6,CREAM,{{4,4}}); circ(8,4,2,GREEN,true); p(8,4,WHITE) end,
  perfect_harmony=function() die(1,7,CREAM,{{2,2},{6,6}}); die(6,7,CREAM,{{2,2},{6,6}}); r(4,2,8,3,GOLD); p(4,1,GOLD); p(8,1,GOLD); p(11,1,GOLD) end,
  chip_collector=function() for i=0,2 do local y=11-i*3; r(2,y,9,2,hex("b8433f")); r(2,y+1,9,1,hex("6e2522")); p(4,y,CREAM); p(8,y,CREAM) end; r(3,4,7,1,hex("d65a52")); r(12,2,1,5,GREEN); r(10,4,5,1,GREEN) end,
  hot_hands=function() r(6,5,4,9,hex("e0703a")); r(5,8,6,5,hex("e0703a")); r(7,9,2,4,GOLD); p(7,4,hex("e0703a")); r(12,3,1,4,WHITE); r(13,4,1,1,WHITE); ln(1,10,3,10,WHITE) end,
  fire_within=function() r(6,4,4,10,BLUE); r(5,7,6,6,BLUE); r(7,8,2,5,WHITE); p(7,3,BLUE); p(9,2,BLUE); p(4,9,BLUE); p(11,9,BLUE) end,
  quick_hands=function() die(6,4,CREAM,{{4,4},{2,2},{6,6}}); ln(0,6,4,6,WHITE); ln(1,9,4,9,WHITE); ln(0,12,4,12,WHITE) end,
  night_shift=function() circ(6,6,5,GOLD,true); circ(9,4,4,hex("1a2445"),true); circ(11,11,3,GOLD2,true); circ(11,11,3,INK,false); p(11,11,BRASS) end,
  weighted_fate=function() ln(8,2,8,13,BRASS); ln(2,5,14,5,BRASS); ln(2,5,1,10,GREY); ln(2,5,4,10,GREY); r(0,10,5,1,GREY); ln(14,5,12,8,GREY); ln(14,5,15,8,GREY); r(11,8,5,1,GREY); r(1,7,3,3,CREAM); r(5,13,7,2,BRASS) end,
  chip_hoard=function() local function chip(x,y) r(x,y,5,2,hex("b8433f")); r(x,y+1,5,1,hex("6e2522")); p(x+2,y,CREAM); r(x+1,y-1,3,1,hex("d65a52")) end; chip(1,12); chip(6,12); chip(11,12); chip(3,9); chip(9,9); chip(6,6); p(8,3,GOLD); p(7,2,GOLD); p(9,2,GOLD) end,
  hat_trick=function() r(4,9,8,2,INK); r(5,4,6,6,hex("2b2b38")); r(5,8,6,1,RED); r(2,11,12,2,hex("2b2b38")); star(13,3,GOLD) end,
  divine=function() for t=0,23 do local a=t/24*math.pi*2; p(8+5*math.cos(a)+0.5,3+1.5*math.sin(a)+0.5,GOLD) end; die(4,6,WHITE,{{4,4}}); r(5,7,7,1,CREAM) end,
}
for i,id in ipairs(ORDER) do ox=(i-1)*16; draw[id]() end
-- Finishing pass, the same rules as the dice and helpers: every shape gets a one-pixel outline
-- in the shared ink, and solid areas (at least three pixels across) get a lit top-left edge and
-- a shaded bottom-right edge. Thin lines and single-pixel details are left as drawn.
local PC=app.pixelColor
local function read(x,y) if x<0 or y<0 or x>=16 then return nil end local v=im:getPixel(ox+x,y); if PC.rgbaA(v)==0 then return nil end return v end
local function is_ink(v) return v and PC.rgbaR(v)<40 and PC.rgbaG(v)<40 and PC.rgbaB(v)<48 end
local function solid(v) return v and not is_ink(v) end
local function tint(v,f)
  local function c(x) return math.max(0,math.min(255,math.floor(x*f+0.5))) end
  return PC.rgba(c(PC.rgbaR(v)),c(PC.rgbaG(v)),c(PC.rgbaB(v)),255)
end
for i,id in ipairs(ORDER) do
  ox=(i-1)*16
  local src={}
  for y=0,15 do src[y]={} for x=0,15 do src[y][x]=read(x,y) end end
  local function at(x,y) if x<0 or y<0 or x>15 or y>15 then return nil end return src[y][x] end
  for y=0,15 do for x=0,15 do
    local v=src[y][x]
    if v==nil then
      for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
        if solid(at(x+d[1],y+d[2])) then im:drawPixel(ox+x,y,INK) break end
      end
    elseif solid(v) then
      local up,left,down,right=at(x,y-1),at(x-1,y),at(x,y+1),at(x+1,y)
      local thick_v=solid(up) or solid(down)
      local thick_h=solid(left) or solid(right)
      if (not solid(up) or not solid(left)) and solid(down) and solid(right) and thick_v and thick_h then
        im:drawPixel(ox+x,y,tint(v,1.18))
      elseif (not solid(down) or not solid(right)) and solid(up) and solid(left) and thick_v and thick_h then
        im:drawPixel(ox+x,y,tint(v,0.78))
      end
    end
  end end
end
s.layers[1].name="Icons"
s:newCel(s.layers[1],1,im)
app.fs.makeAllDirectories(root.."/assets/source/aseprite/icons")
s:saveAs(root.."/assets/source/aseprite/icons/shop_icons.aseprite")
s:saveCopyAs(root.."/assets/exported/icons/shop_icons.png")
print("ICONS: "..#ORDER.." shop icons exported")
