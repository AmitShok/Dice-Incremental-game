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
  heavy=function() r(4,6,8,8,INK); r(5,7,6,6,GREY); r(6,3,4,4,INK); r(7,4,2,2,GREY); r(5,8,6,1,WHITE) end,
  sixes=function() die(1,4,CREAM,{{2,2},{6,2},{2,4},{6,4},{2,6},{6,6}}); star(12,4,GOLD) end,
  loaded=function() die(2,5,CREAM,{{2,2},{6,6},{4,4}}); ln(12,13,12,3,GOLD); p(11,4,GOLD); p(13,4,GOLD); p(10,5,GOLD); p(14,5,GOLD) end,
  combos=function() die(1,6,CREAM,{{4,4}}); die(6,2,hex("e8a0a0"),{{4,4}}); star(13,12,GOLD) end,
  hands=function() r(3,9,9,4,INK); r(4,10,7,2,hex("7a4e2f")); r(9,7,3,3,INK); ln(1,6,5,6,CREAM); ln(0,9,3,9,CREAM); ln(2,12,4,12,CREAM) end,
  rhythm=function() ln(4,14,8,2,INK); ln(12,14,8,2,INK); ln(4,14,12,14,INK); ln(5,13,8,4,BRASS); ln(11,13,8,4,BRASS); ln(8,12,11,5,GOLD); circ(11,5,1,GOLD,true) end,
  chain=function() circ(5,8,3,GREY,false); circ(10,8,3,GOLD2,false); p(5,8,INK); p(10,8,INK) end,
  momentum=function() r(6,4,4,10,hex("e0703a")); r(5,7,6,6,hex("e0703a")); r(7,8,2,5,GOLD); p(7,3,hex("e0703a")); p(9,2,hex("e0703a")); p(4,9,hex("e0703a")); p(11,9,hex("e0703a")) end,
  strong_arms=function() arm(hex("e6b48c")) end,
  sharp_eyes=function() for x=1,14 do local h=math.floor(3*math.sin((x-1)/13*math.pi)+0.5); p(x,8-h,INK); p(x,8+h,INK) end; circ(8,8,2,BLUE,true); p(8,8,INK); p(7,7,WHITE) end,
  many_hands=function() for i=0,1 do local x=2+i*6; r(x,6,5,7,INK); r(x+1,7,3,5,hex("e6b48c")); for f=0,2 do r(x+f+1,3+(f%2),1,4,hex("e6b48c")) end end end,
  hire=function() circ(8,8,6,hex("e6b48c"),true); circ(8,8,6,INK,false); r(2,1,3,5,hex("d88a9a")); r(11,1,3,5,hex("d88a9a")); p(6,8,INK); p(10,8,INK); r(7,11,3,1,INK) end,
  fortune=function() for _,c in ipairs({{5,5},{10,5},{5,10},{10,10}}) do circ(c[1],c[2],3,GREEN,true) end; ln(8,8,12,15,hex("4f8a4c")); p(8,8,hex("cfe8c0")) end,
  crit=function() for a=0,7 do local ang=a/8*math.pi*2; ln(8,8,math.floor(8+7*math.cos(ang)+0.5),math.floor(8+7*math.sin(ang)+0.5),a%2==0 and GOLD or RED) end; circ(8,8,2,WHITE,true) end,
  stride=function() r(4,9,8,4,INK); r(5,10,6,2,hex("6d5f8f")); r(4,5,4,5,INK); r(5,6,2,4,hex("6d5f8f")); ln(9,3,14,6,WHITE); ln(10,6,14,8,WHITE) end,
  echo=function() circ(8,8,2,GOLD,true); circ(8,8,5,GOLD2,false); circ(8,8,7,BRASS,false) end,
  head_start=function() r(4,6,9,8,INK); r(5,7,7,6,hex("b88a50")); r(6,4,5,3,INK); r(7,5,3,1,hex("b88a50")); r(7,9,3,2,GOLD) end,
  heirloom=function() die(3,4,hex("c9a46a"),{{2,2},{6,6},{4,4}}); p(2,13,BRASS); p(13,3,GOLD); p(14,2,WHITE) end,
  patience=function() r(4,1,8,2,BRASS); r(4,13,8,2,BRASS); ln(5,3,10,12,CREAM); ln(10,3,5,12,CREAM); r(6,10,4,2,GOLD); p(8,6,GOLD) end,
  long_nights=function() circ(8,8,6,GOLD,true); circ(11,6,5,hex("1a2445"),true); p(3,3,WHITE); p(13,13,WHITE) end,
  old_friend=function() heart(8,7,RED); p(6,6,WHITE) end,
  muscle_memory=function() for i=0,2 do circ(3+i*5,6,2,hex("e6b48c"),true); r(1+i*5,9,5,5,hex("3f6a5a")) end end,
  house_edge=function() r(4,6,9,6,GOLD2); for _,x in ipairs({4,8,12}) do r(x,3,1,3,GOLD2) end; r(4,11,9,1,BRASS); p(6,8,RED); p(10,8,BLUE) end,
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
  golden_touch=function() die(2,5,GOLD,{{2,2},{6,2},{4,4},{2,6},{6,6}}); star(12,3,WHITE); p(14,6,GOLD) end,
  crit_chance=function() circ(8,8,6,RED,false); circ(8,8,4,CREAM,false); circ(8,8,2,RED,true); p(8,8,WHITE) end,
  crit_power=function() for a=0,7 do local ang=a/8*math.pi*2; ln(7,9,math.floor(7+5*math.cos(ang)+0.5),math.floor(9+5*math.sin(ang)+0.5),a%2==0 and GOLD or RED) end; r(12,1,1,5,WHITE); r(10,3,5,1,WHITE) end,
  deep_fortune=function() circ(8,10,5,hex("b88a50"),true); circ(8,10,5,INK,false); r(6,3,5,3,hex("b88a50")); r(5,5,7,1,INK); r(7,8,3,1,GOLD); r(8,7,1,5,GOLD); r(7,11,3,1,GOLD) end,
  endless_favor=function() for t=0,47 do local a=t/48*math.pi*2; p(math.floor(8+6*math.sin(a)+0.5),math.floor(8+3*math.sin(2*a)+0.5),GOLD) end; star(8,3,WHITE) end,
  destiny=function() star(8,8,LILAC); ln(8,2,8,14,LILAC); ln(2,8,14,8,LILAC); p(8,8,WHITE); p(4,4,LILAC); p(12,12,LILAC); p(12,4,LILAC); p(4,12,LILAC) end,
  well_paid=function() circ(6,9,5,GOLD,true); circ(6,9,5,INK,false); r(5,7,2,5,BRASS); r(11,2,4,4,hex("e6b48c")); r(10,6,6,5,hex("3f6a5a")) end,
  bargain=function() r(3,4,10,8,GOLD2); r(3,4,10,1,WHITE); p(5,6,INK); r(7,7,5,1,INK); r(7,9,4,1,INK); ln(12,4,14,2,BRASS); p(14,2,BRASS); p(2,13,RED); ln(2,13,6,13,RED) end,
  haggler=function() r(3,2,10,12,CREAM); r(3,2,10,1,WHITE); r(3,13,10,1,BRASS); for y=4,10,2 do r(5,y,6,1,GREY) end; r(6,12,5,1,RED) end,
  born_harmony=function() die(1,6,CREAM,{{4,4}}); die(6,6,CREAM,{{4,4}}); circ(8,4,2,GREEN,true); p(8,4,WHITE) end,
  perfect_harmony=function() die(1,7,CREAM,{{2,2},{6,6}}); die(6,7,CREAM,{{2,2},{6,6}}); r(4,2,8,3,GOLD); p(4,1,GOLD); p(8,1,GOLD); p(11,1,GOLD) end,
  chip_collector=function() for i=0,2 do r(3,11-i*3,10,3,INK); r(4,12-i*3,8,1,RED); r(4,11-i*3,8,1,CREAM) end; star(13,2,GOLD) end,
  hot_hands=function() r(6,5,4,9,hex("e0703a")); r(5,8,6,5,hex("e0703a")); r(7,9,2,4,GOLD); p(7,4,hex("e0703a")); r(12,3,1,4,WHITE); r(13,4,1,1,WHITE); ln(1,10,3,10,WHITE) end,
  fire_within=function() r(6,4,4,10,BLUE); r(5,7,6,6,BLUE); r(7,8,2,5,WHITE); p(7,3,BLUE); p(9,2,BLUE); p(4,9,BLUE); p(11,9,BLUE) end,
  quick_hands=function() die(6,4,CREAM,{{4,4},{2,2},{6,6}}); ln(0,6,4,6,WHITE); ln(1,9,4,9,WHITE); ln(0,12,4,12,WHITE) end,
  night_shift=function() circ(6,6,5,GOLD,true); circ(9,4,4,hex("1a2445"),true); circ(11,11,3,GOLD2,true); circ(11,11,3,INK,false); p(11,11,BRASS) end,
  weighted_fate=function() ln(8,2,8,13,BRASS); ln(2,5,14,5,BRASS); ln(2,5,1,10,GREY); ln(2,5,4,10,GREY); r(0,10,5,1,GREY); ln(14,5,12,8,GREY); ln(14,5,15,8,GREY); r(11,8,5,1,GREY); r(1,7,3,3,CREAM); r(5,13,7,2,BRASS) end,
  chip_hoard=function() for i=0,3 do r(1+i%2*7,10-math.floor(i/2)*4,7,3,INK); r(2+i%2*7,10-math.floor(i/2)*4,5,1,RED); r(2+i%2*7,11-math.floor(i/2)*4,5,1,CREAM) end; r(4,1,8,2,GOLD) end,
  hat_trick=function() r(4,9,8,2,INK); r(5,4,6,6,hex("2b2b38")); r(5,8,6,1,RED); r(2,11,12,2,hex("2b2b38")); star(13,3,GOLD) end,
  divine=function() circ(8,3,4,GOLD,false); r(6,7,4,7,WHITE); r(4,8,2,4,CREAM); r(10,8,2,4,CREAM); p(7,9,INK); p(9,9,INK) end,
}
for i,id in ipairs(ORDER) do ox=(i-1)*16; draw[id]() end
s.layers[1].name="Icons"
s:newCel(s.layers[1],1,im)
app.fs.makeAllDirectories(root.."/assets/source/aseprite/icons")
s:saveAs(root.."/assets/source/aseprite/icons/shop_icons.aseprite")
s:saveCopyAs(root.."/assets/exported/icons/shop_icons.png")
print("ICONS: "..#ORDER.." shop icons exported")
