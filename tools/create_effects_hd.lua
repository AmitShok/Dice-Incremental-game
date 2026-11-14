-- Effect sprites on the 2x art grid: the dice contact shadow (22x6, a felt-green oval with a
-- darker core, like the shadows painted under Moss and the table) and the payout spark (9x9,
-- a four-point sparkle with a white heart). Both are drawn at scale 2 in game.
-- Run: ASEPRITE -b --script-param root=PROJECT_PATH --script tools/create_effects_hd.lua
local root = assert(app.params["root"], "Pass --script-param root=PROJECT_PATH")
local function hex(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
local function export(name,w,h,draw)
  local s=Sprite(w,h)
  local im=Image(w,h)
  draw(function(x,y,c) if x>=0 and y>=0 and x<w and y<h then im:drawPixel(x,y,c) end end)
  s.layers[1].name="Effect"
  s:newCel(s.layers[1],1,im)
  app.fs.makeAllDirectories(root.."/assets/source/aseprite/effects")
  s:saveAs(root.."/assets/source/aseprite/effects/"..name..".aseprite")
  s:saveCopyAs(root.."/assets/exported/effects/"..name..".png")
  s:close()
end

export("shadow",22,6,function(p)
  local rows={{5,16},{2,19},{1,20},{1,20},{2,19},{5,16}}
  for y,span in ipairs(rows) do for x=span[1],span[2] do p(x,y-1,hex("172c2b")) end end
  for y=2,3 do for x=5,16 do p(x,y,hex("0f1f1e")) end end
end)

export("spark",9,9,function(p)
  local tip,arm,core,heart=hex("d8b874"),hex("f5db9f"),hex("fff3c4"),hex("ffffff")
  for i=1,3 do
    local c=(i==3) and tip or arm
    p(4,4-i,c); p(4,4+i,c); p(4-i,4,c); p(4+i,4,c)
  end
  p(4,0,tip); p(4,8,tip); p(0,4,tip); p(8,4,tip)
  for _,q in ipairs({{3,3},{5,3},{3,5},{5,5},{4,3},{3,4},{5,4},{4,5}}) do p(q[1],q[2],core) end
  p(4,4,heart)
  for _,q in ipairs({{2,2},{6,2},{2,6},{6,6}}) do p(q[1],q[2],tip) end
end)
print("EFFECTS HD: shadow and spark exported")
