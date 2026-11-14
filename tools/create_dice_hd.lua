-- HD dice: renders every die from a real 3D solid and flattens it into chunky, outlined,
-- cel-shaded pixel art (flat tone bands, bright bevel edges, near-black outline, pixel-font
-- numerals). Writes the resting face sheet (one 32x32 frame per face, frame N-1 shows N) and a
-- 32-frame looping tumble sheet for each die, plus editable .aseprite masters.
-- Run: ASEPRITE -b --script-param root=PROJECT_PATH --script tools/create_dice_hd.lua
local root = assert(app.params["root"], "Pass --script-param root=PROJECT_PATH")
local SIZE, TUMBLE = 32, 32
local BODY = 21 -- largest body extent in pixels before the 1px outline (x2 on screen ≈ 46 px)
local ROUND = 2.3 -- corner rounding radius in pixels

-- ---------------------------------------------------------------- vectors
local function v(x,y,z) return {x,y,z} end
local function add(a,b) return {a[1]+b[1],a[2]+b[2],a[3]+b[3]} end
local function sub(a,b) return {a[1]-b[1],a[2]-b[2],a[3]-b[3]} end
local function mul(a,s) return {a[1]*s,a[2]*s,a[3]*s} end
local function dot(a,b) return a[1]*b[1]+a[2]*b[2]+a[3]*b[3] end
local function cross(a,b) return {a[2]*b[3]-a[3]*b[2],a[3]*b[1]-a[1]*b[3],a[1]*b[2]-a[2]*b[1]} end
local function norm(a) local l=math.sqrt(dot(a,a)); return {a[1]/l,a[2]/l,a[3]/l} end
-- 3x3 matrices as rows
local function mv(m,a) return {dot(m[1],a),dot(m[2],a),dot(m[3],a)} end
local function mm(a,b)
  local r={}
  for i=1,3 do r[i]={} for j=1,3 do r[i][j]=a[i][1]*b[1][j]+a[i][2]*b[2][j]+a[i][3]*b[3][j] end end
  return r
end
local function axis_rot(axis,ang)
  local x,y,z=axis[1],axis[2],axis[3]; local c,s=math.cos(ang),math.sin(ang); local t=1-c
  return {{t*x*x+c,t*x*y-s*z,t*x*z+s*y},{t*x*y+s*z,t*y*y+c,t*y*z-s*x},{t*x*z-s*y,t*y*z+s*x,t*z*z+c}}
end

-- ---------------------------------------------------------------- solids
local phi=(1+math.sqrt(5))/2
local function solid(verts, normals)
  local faces={}
  for _,n0 in ipairs(normals) do
    local n=norm(n0); local best=-1e9
    for _,p in ipairs(verts) do best=math.max(best,dot(p,n)) end
    local ids={}
    for i,p in ipairs(verts) do if dot(p,n)>best-1e-6 then ids[#ids+1]=i end end
    local c={0,0,0}; for _,i in ipairs(ids) do c=add(c,verts[i]) end; c=mul(c,1/#ids)
    local e1=norm(sub(verts[ids[1]],c)); local e2=cross(n,e1)
    table.sort(ids,function(a,b)
      local pa,pb=sub(verts[a],c),sub(verts[b],c)
      return math.atan(dot(pa,e2),dot(pa,e1))<math.atan(dot(pb,e2),dot(pb,e1)) end)
    faces[#faces+1]={n=n,ids=ids,c=c}
  end
  return {verts=verts,faces=faces}
end
local function signs(list) -- expand sign patterns
  local out={}
  for _,p in ipairs(list) do
    for sx=-1,1,2 do for sy=-1,1,2 do for sz=-1,1,2 do
      local q={p[1]*sx,p[2]*sy,p[3]*sz}; local key=q[1]..","..q[2]..","..q[3]
      if not out[key] then out[key]=q end
    end end end
  end
  local r={}; for _,q in pairs(out) do r[#r+1]=q end
  table.sort(r,function(a,b) return a[1]*100+a[2]*10+a[3] < b[1]*100+b[2]*10+b[3] end)
  return r
end
-- Face normals of a convex solid: every plane through three corners with all corners behind it.
local function hull_normals(verts)
  local found={}
  for i=1,#verts do for j=i+1,#verts do for k=j+1,#verts do
    local n=cross(sub(verts[j],verts[i]),sub(verts[k],verts[i]))
    if dot(n,n)>1e-9 then
      n=norm(n); local d=dot(n,verts[i]); local pos,neg=false,false
      for _,p in ipairs(verts) do local s=dot(n,p)-d; if s>1e-6 then pos=true elseif s<-1e-6 then neg=true end end
      if not (pos and neg) then
        if pos then n=mul(n,-1) end
        local dup=false
        for _,m in ipairs(found) do if dot(m,n)>0.9999 then dup=true break end end
        if not dup then found[#found+1]=n end
      end
    end
  end end end
  return found
end
local SOLIDS={}
do
  local t={{1,1,1},{1,-1,-1},{-1,1,-1},{-1,-1,1}}
  local n={}; for i,p in ipairs(t) do n[i]=mul(p,-1) end
  SOLIDS[4]=solid(t,n)
  SOLIDS[6]=solid(signs({{1,1,1}}),{{1,0,0},{-1,0,0},{0,1,0},{0,-1,0},{0,0,1},{0,0,-1}})
  SOLIDS[8]=solid({{1,0,0},{-1,0,0},{0,1,0},{0,-1,0},{0,0,1},{0,0,-1}},signs({{1,1,1}}))
  local d10={}; local e=(1-math.cos(math.pi/5))/(1+math.cos(math.pi/5))
  d10[1]={0,0,1}; d10[2]={0,0,-1}
  for k=0,4 do
    local a=k*2*math.pi/5
    d10[#d10+1]={math.cos(a),math.sin(a),e}
    d10[#d10+1]={math.cos(a+math.pi/5),math.sin(a+math.pi/5),-e}
  end
  local n10={}
  for k=0,4 do
    local a=k*2*math.pi/5
    local T,U0,U1={0,0,1},{math.cos(a),math.sin(a),e},{math.cos(a+2*math.pi/5),math.sin(a+2*math.pi/5),e}
    local nt=norm(cross(sub(U0,T),sub(U1,T))); if nt[3]<0 then nt=mul(nt,-1) end
    n10[#n10+1]=nt; n10[#n10+1]={-nt[1],-nt[2],-nt[3]}
  end
  SOLIDS[10]=solid(d10,n10)
  local ico=signs({{0,1,phi},{1,phi,0},{phi,0,1}})
  local dod=signs({{1,1,1},{0,1/phi,phi},{1/phi,phi,0},{phi,0,1/phi}})
  SOLIDS[12]=solid(dod,hull_normals(dod))
  SOLIDS[20]=solid(ico,hull_normals(ico))
end
-- Number faces so opposite faces sum to sides+1 (d4 simply in order).
local function number_faces(s)
  local n=#s.faces; local next_value=1
  for i,f in ipairs(s.faces) do
    if not f.value then
      f.value=next_value; next_value=next_value+1
      if n~=4 then
        local best,bj=2,nil
        for j,g in ipairs(s.faces) do if not g.value and dot(f.n,g.n)<best then best,bj=dot(f.n,g.n),j end end
        s.faces[bj].value=n+1-f.value
      end
    end
  end
  for _,f in ipairs(s.faces) do
    -- Glyph "up": apex for triangles and kites, an edge midpoint for squares and pentagons.
    local far,fv=-1,nil
    for _,i in ipairs(f.ids) do local d=dot(sub(s.verts[i],f.c),sub(s.verts[i],f.c)); if d>far+1e-6 then far,fv=d,i end end
    if #f.ids==3 or #f.ids==4 and n==10 then f.up=norm(sub(s.verts[fv],f.c))
    else f.up=norm(sub(mul(add(s.verts[f.ids[1]],s.verts[f.ids[2]]),0.5),f.c)) end
  end
end
for _,s in pairs(SOLIDS) do number_faces(s) end

-- ---------------------------------------------------------------- palettes
local function hex(h) return {tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16)} end
-- The game's shared palette: the near-black outline, cream highlight and felt-green contact
-- shadow used by the helpers, old dice and table art, so the dice sit in the same family.
local OUTLINE=hex("0e0b10")
local INK="0e0b10"
local CREAM="f0dfbd"
local function mix(a,b,t) local x,y=hex(a),hex(b); return string.format("%02x%02x%02x",
  math.floor(x[1]+(y[1]-x[1])*t+0.5),math.floor(x[2]+(y[2]-x[2])*t+0.5),math.floor(x[3]+(y[3]-x[3])*t+0.5)) end
-- Each die keeps its original soft body colour, its original shade and highlight. Ramps run
-- dark -> light: 1 crease, 2 shade, 3 body, 4 lit, 5 highlight.
local function ramp(body,shade,hi)
  hi=hi or CREAM
  return {mix(shade,INK,0.38),shade,body,mix(body,hi,0.42),hi}
end
local DICE={
  {id="d4",sides=4,ramp=ramp("efba69","9d663d"),ink=INK},
  {id="d6",sides=6,ramp=ramp("f0dfbd","ab956f","fff8e8"),ink=INK},
  {id="d8",sides=8,ramp=ramp("8ec4ab","4f8571"),ink=INK},
  {id="d10",sides=10,ramp=ramp("9bbada","566b9b"),ink=INK},
  {id="d12",sides=12,ramp=ramp("dc9ca7","965466"),ink=INK},
  {id="d20",sides=20,ramp=ramp("d68878","904d4d"),ink=INK},
  {id="golden_d6",sides=6,ramp=ramp("efc66d","b88137"),ink=INK,glint=true},
  {id="lucky_d6",sides=6,ramp=ramp("b4cf94","648453"),ink=INK},
  {id="exploding_d6",sides=6,ramp=ramp("eeab6d","b9684c"),ink=INK},
  {id="multiplier_d6",sides=6,ramp=ramp("c6b5e5","80749e"),ink=INK},
  {id="spark_d8",sides=8,ramp=ramp("84c5d3","4a7f8e","b5f1ff"),ink=INK},
  {id="blast_d10",sides=10,ramp=ramp("e4a184","a25939","fcc5ae"),ink=INK},
  {id="gild_d12",sides=12,ramp=ramp("f6d88a","a88839","ffe8ad"),ink=INK,glint=true},
}
local PRISM={{"382a6a","684eae","987ede","c8b8f6","fff4ff"},{"5a2048","9c3c7c","d26ab0","f2a6d8","fff0fa"},{"1c4a5a","2c7a90","4cb2c8","92e2ee","f0ffff"}}

-- ---------------------------------------------------------------- font
local GLYPH={["0"]={"111","101","101","101","111"},["1"]={"010","110","010","010","111"},["2"]={"111","001","111","100","111"},
  ["3"]={"111","001","011","001","111"},["4"]={"101","101","111","001","001"},["5"]={"111","100","111","001","111"},
  ["6"]={"111","100","111","101","111"},["7"]={"111","001","001","010","010"},["8"]={"111","101","111","101","111"},["9"]={"111","101","111","001","111"}}

-- ---------------------------------------------------------------- renderer
local L=norm({-0.45,-0.7,0.6})
local function inside(px,py,poly)
  local inside_=false; local j=#poly
  for i=1,#poly do
    local a,b=poly[i],poly[j]
    if ((a[2]>py)~=(b[2]>py)) and (px<(b[1]-a[1])*(py-a[2])/(b[2]-a[2])+a[1]) then inside_=not inside_ end
    j=i
  end
  return inside_
end
-- The face turned to the viewer keeps the body colour exactly; only faces tipped towards the lamp lighten.
local function tone_for(b) if b>0.86 then return 4 elseif b>0.42 then return 3 elseif b>0.1 then return 2 else return 1 end end

-- Renders one frame. Returns a SIZExSIZE grid of {r,g,b} or false.
local function render(spec, s, R, rest_value, fix)
  fix=fix or 1
  -- project, then rescale so the body always spans BODY pixels (no size pulsing while tumbling)
  local P={}
  local minx,maxx,miny,maxy=1e9,-1e9,1e9,-1e9
  for i,p in ipairs(s.verts) do local q=mv(R,p); P[i]=q; minx=math.min(minx,q[1]); maxx=math.max(maxx,q[1]); miny=math.min(miny,q[2]); maxy=math.max(maxy,q[2]) end
  local scale=BODY/math.max(maxx-minx,maxy-miny)*fix
  local ox,oy=SIZE/2-(minx+maxx)/2*scale, SIZE/2-(miny+maxy)/2*scale
  local function screen(q) return {ox+q[1]*scale, oy+q[2]*scale} end
  local faces={}
  for fi,f in ipairs(s.faces) do
    local n=mv(R,f.n)
    if n[3]>1e-4 then
      local poly={}; for k,i in ipairs(f.ids) do poly[k]=screen(P[i]) end
      local ramp=spec.ramp
      if spec.prism then ramp=PRISM[(fi%3)+1] end
      faces[#faces+1]={fi=fi,n=n,poly=poly,tone=tone_for(dot(n,L)),ramp=ramp,face=f}
    end
  end
  local id,grid={}, {}
  for y=0,SIZE-1 do id[y]={} for x=0,SIZE-1 do
    id[y][x]=false
    for k,f in ipairs(faces) do if inside(x+0.5,y+0.5,f.poly) then id[y][x]=k break end end
  end end
  -- Soft corners: a morphological opening with a small disc rounds every sharp tip of the
  -- silhouette, like a real die's worn corners, without touching straight edges.
  local radius=spec.round or ROUND
  local disc={}
  for dy=-3,3 do for dx=-3,3 do if dx*dx+dy*dy<=radius*radius then disc[#disc+1]={dx,dy} end end end
  local function filled(x,y) return x>=0 and y>=0 and x<SIZE and y<SIZE and id[y][x] end
  local core={}
  for y=0,SIZE-1 do core[y]={} for x=0,SIZE-1 do
    local all=id[y][x] and true or false
    if all then for _,d in ipairs(disc) do if not filled(x+d[1],y+d[2]) then all=false break end end end
    core[y][x]=all
  end end
  local bx0,bx1,by0,by1=SIZE,-1,SIZE,-1
  for y=0,SIZE-1 do for x=0,SIZE-1 do
    if id[y][x] then
      local near=false
      for _,d in ipairs(disc) do
        local cx,cy=x+d[1],y+d[2]
        if cx>=0 and cy>=0 and cx<SIZE and cy<SIZE and core[cy][cx] then near=true break end
      end
      if not near then id[y][x]=false else bx0,bx1,by0,by1=math.min(bx0,x),math.max(bx1,x),math.min(by0,y),math.max(by1,y) end
    end
  end end
  local extent=math.max(bx1-bx0+1,by1-by0+1)
  local function at(x,y) if x<0 or y<0 or x>=SIZE or y>=SIZE then return false end return id[y][x] end
  for y=0,SIZE-1 do grid[y]={} for x=0,SIZE-1 do
    local k=id[y][x]
    if k then
      local f=faces[k]; local t=f.tone
      -- Facet seams: the edge between two faces is a rounded bevel. Lit seams flash the
      -- highlight tone; seams turned away from the light read as a darker crease.
      for _,d in ipairs({{1,0},{0,1},{-1,0},{0,-1}}) do
        local o=at(x+d[1],y+d[2])
        if o and o~=k then
          local m=norm(add(f.n,faces[o].n))
          if dot(m,L)>0.62 and (d[1]>0 or d[2]>0) then t=5 elseif f.tone<=faces[o].tone then t=math.max(1,f.tone-1) end
        end
      end
      -- Rim light on the upper-left silhouette, the way a lamp catches a rounded edge.
      if (not at(x-1,y) or not at(x,y-1)) and f.tone>=3 then t=5 end
      grid[y][x]=hex(f.ramp[t])
    else grid[y][x]=false end
  end end
  -- Glyphs: numerals or pips, crisp and upright, on faces turned towards the viewer.
  local function stamp(x,y,c) if x>=0 and y>=0 and x<SIZE and y<SIZE and grid[y][x] then grid[y][x]=c end end
  local ink=hex(spec.ink)
  -- Each d6 variant inks its pips in a deep shade of its own colour, so the family reads as
  -- different dice rather than recoloured boxes.
  if spec.sides==6 then ink=hex(mix(spec.ramp[1],INK,0.45)) end
  local glow=spec.glow and hex(spec.glow)
  -- Numbered dice show one numeral: the result at rest, the face nearest the camera mid-tumble.
  -- Pips are small enough that a d6 keeps them on every face turned towards the viewer.
  local facing=nil
  for _,f in ipairs(faces) do if not facing or f.n[3]>facing.n[3] then facing=f end end
  for _,f in ipairs(faces) do
    local front=f.n[3]
    local main=(rest_value and f.face.value==rest_value) or (not rest_value and f==facing and front>0.7)
    if (spec.sides==6 and front>0.22) or main then
      if spec.sides==6 then
        local pips={[1]={{0,0}},[2]={{-1,-1},{1,1}},[3]={{-1,-1},{0,0},{1,1}},[4]={{-1,-1},{1,-1},{-1,1},{1,1}},
          [5]={{-1,-1},{1,-1},{0,0},{-1,1},{1,1}},[6]={{-1,-1},{1,-1},{-1,0},{1,0},{-1,1},{1,1}}}
        local up=f.face.up; local right=cross(up,f.face.n)
        for _,p in ipairs(pips[f.face.value]) do
          local w=add(f.face.c,add(mul(right,p[1]*0.52),mul(up,p[2]*0.52)))
          local q=screen(mv(R,w)); local px,py=math.floor(q[1]),math.floor(q[2])
          if front>0.8 then
            if glow then for _,o in ipairs({{-1,0},{2,0},{0,-1},{0,2},{-1,1},{2,1},{1,-1},{1,2}}) do stamp(px-1+o[1]+1,py-1+o[2]+1,glow) end end
            stamp(px,py,ink); stamp(px-1,py,ink); stamp(px,py-1,ink); stamp(px-1,py-1,ink)
          else stamp(px,py,ink) end
        end
      else
        local text=tostring(f.face.value)
        local q=screen(mv(R,f.face.c))
        local w=#text*4-1
        local gx,gy=math.floor(q[1]-w/2+0.5),math.floor(q[2]-2.5+0.5)
        if not main then gy=gy end
        for ci=1,#text do
          local g=GLYPH[text:sub(ci,ci)]
          for row=1,5 do for col=1,3 do
            if g[row]:sub(col,col)=="1" then
              local x,y=gx+(ci-1)*4+col-1,gy+row-1
              if glow then stamp(x+1,y,glow); stamp(x,y+1,glow) end
            end
          end end
          for row=1,5 do for col=1,3 do
            if g[row]:sub(col,col)=="1" then stamp(gx+(ci-1)*4+col-1,gy+row-1,ink) end
          end end
        end
        -- Tell 6 from 9 on the bigger dice.
        if spec.sides>=8 and (text=="6" or text=="9") then stamp(gx+1,gy+6,ink) end
      end
    end
  end
  -- Golden dice get a couple of hard specular glints.
  if spec.glint then
    for _,f in ipairs(faces) do
      if f.tone>=4 then
        local q=f.poly[1]; local c=screen(mv(R,f.face.c))
        local gx,gy=math.floor((q[1]*0.3+c[1]*0.7)),math.floor((q[2]*0.3+c[2]*0.7))
        stamp(gx,gy,{255,255,255}); stamp(gx+1,gy,hex(f.ramp[5])); stamp(gx,gy+1,hex(f.ramp[5]))
      end
    end
  end
  -- One-pixel near-black outline around the silhouette.
  local out={}
  for y=0,SIZE-1 do out[y]={} for x=0,SIZE-1 do
    out[y][x]=grid[y][x]
    if not grid[y][x] then
      for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
        local nx,ny=x+d[1],y+d[2]
        if nx>=0 and ny>=0 and nx<SIZE and ny<SIZE and grid[ny][nx] then out[y][x]=OUTLINE break end
      end
    end
  end end
  return out, extent
end

-- Rounding trims sharp tips (a d4 most of all) by different amounts on different poses, so
-- search nearby scales and keep the render whose footprint is exactly BODY pixels: every
-- resting and tumbling frame then has the same size.
local function draw(spec, s, R, rest_value)
  -- Symmetric poses can only land on odd or even widths, so BODY or BODY+1 both count: every
  -- frame then sits within one pixel of every other.
  local function gap(e) if e<BODY then return BODY-e elseif e>BODY+1 then return e-BODY-1 end return 0 end
  local out,extent=render(spec,s,R,rest_value,1)
  if gap(extent)==0 then return out end
  local base=BODY/extent
  local best,best_gap=out,gap(extent)
  for k=0,16 do
    local f=base*(1+(k%2==0 and 1 or -1)*math.floor((k+1)/2)*0.012)
    local o,e=render(spec,s,R,rest_value,f)
    if gap(e)<best_gap then best,best_gap=o,gap(e) end
    if gap(e)==0 then return o end
  end
  return best
end

-- Rotation that shows face `value` to the camera with a sliver of the near side below it,
-- numeral upright: the classic top-down three-quarter dice view.
local VIEW=norm({0.06,-0.34,1})
-- Cubes read best in the classic three-quarter view: result face forward, a lit top lid above
-- it and a shaded right side.
local VIEW_D6=norm({-0.3,0.3,1})
local function rest_rotation(s,value,view)
  local f; for _,g in ipairs(s.faces) do if g.value==value then f=g end end
  local n,up=f.n,f.up
  local r=cross(up,n)
  local t=view or VIEW
  local tu=norm(sub({0,-1,0},mul(t,dot({0,-1,0},t))))
  local tr=cross(tu,t)
  -- R = T * S^T, with S and T as column frames (right, up, normal)
  local S={{r[1],up[1],n[1]},{r[2],up[2],n[2]},{r[3],up[3],n[3]}}
  local T={{tr[1],tu[1],t[1]},{tr[2],tu[2],t[2]},{tr[3],tu[3],t[3]}}
  local St={{S[1][1],S[2][1],S[3][1]},{S[1][2],S[2][2],S[3][2]},{S[1][3],S[2][3],S[3][3]}}
  return mm(T,St)
end

local function save(grid_list, path_master, path_png)
  local s=Sprite(SIZE*#grid_list,SIZE)
  local im=Image(s.width,s.height)
  for fi,g in ipairs(grid_list) do
    for y=0,SIZE-1 do for x=0,SIZE-1 do
      local c=g[y][x]
      if c then im:drawPixel((fi-1)*SIZE+x,y,app.pixelColor.rgba(c[1],c[2],c[3],255)) end
    end end
  end
  s.layers[1].name="Dice"
  s:newCel(s.layers[1],1,im)
  app.fs.makeAllDirectories(app.fs.filePath(path_master))
  s:saveAs(path_master)
  s:saveCopyAs(path_png)
  s:close()
end

local A1=norm({1,0.35,0.15})
local A2=norm({-0.2,1,0.4})
for _,spec in ipairs(DICE) do
  local s=SOLIDS[spec.sides]
  local rest={}
  for value=1,spec.sides do rest[value]=draw(spec,s,rest_rotation(s,value,spec.sides==6 and VIEW_D6 or nil),value) end
  save(rest, root.."/assets/source/aseprite/dice/"..spec.id..".aseprite", root.."/assets/exported/dice/"..spec.id..".png")
  -- Tumble: two full turns about two axes, so frame 32 meets frame 1 and the loop is seamless.
  local base=rest_rotation(s,1,spec.sides==6 and VIEW_D6 or nil)
  local rolls={}
  for k=0,TUMBLE-1 do
    local a=2*math.pi*k/TUMBLE
    local R=mm(mm(axis_rot(A1,a),axis_rot(A2,a)),base)
    rolls[k+1]=draw(spec,s,R,nil)
  end
  save(rolls, root.."/assets/source/aseprite/rolls/"..spec.id..".aseprite", root.."/assets/exported/rolls/"..spec.id..".png")
end
print("DICE HD: "..#DICE.." dice rendered, "..TUMBLE.."-frame tumbles")

-- Shop icons: every die again, showing its highest face, in a 16x16 frame so dice icons share
-- the pixel size of every other 16 px icon (all icons draw at exactly 2x in game). Frame order
-- matches ShopIcons.DICE_ORDER.
SIZE,BODY,ROUND=16,13,1.5
local icons={}
for i,spec in ipairs(DICE) do
  local s=SOLIDS[spec.sides]
  icons[i]=draw(spec,s,rest_rotation(s,spec.sides,spec.sides==6 and VIEW_D6 or nil),spec.sides)
end
save(icons, root.."/assets/source/aseprite/icons/dice_icons.aseprite", root.."/assets/exported/icons/dice_icons.png")
print("DICE HD: "..#DICE.." 16 px dice icons")
