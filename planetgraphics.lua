function shadowGradient(diam, contrast, inset, color) -- TODO: shadows as GLSL effect?
  -- Limit gradient size at 50
  diam = math.min(diam, 50)
  local imageData = love.image.newImageData( diam, diam )
  local center = Vector(diam/2, diam/2)

  imageData:mapPixel( function ( x, y, r, g, b, a )
    r,g,b = color[1],color[2],color[3]
    a = Vector(x, y):dist(center)*inset/diam*255
    
    -- apply contrast
    local factor = (259 * (contrast + 255)) / (255 * (259 - contrast))
    a = math.max(math.min(factor * (a - 128) + 128, 255), 0)
        
    return r,g,b,a
  end )
  
  return love.graphics.newImage(imageData)
end

function blendColor(src, dst)
  -- http://en.wikipedia.org/wiki/Alpha_compositing#Alpha_blending
  -- sooooo ugly
  src[1] = src[1]/255
  src[2] = src[2]/255
  src[3] = src[3]/255
  src[4] = src[4]/255
  dst[1] = dst[1]/255
  dst[2] = dst[2]/255
  dst[3] = dst[3]/255
  dst[4] = dst[4]/255
  
  out = {}
  out[4] = src[4]+(dst[4]*(1-src[4]))
  out[1] = ( (src[1]*src[4])+(dst[1]*dst[4]*(1-src[4])) ) / out[4]
  out[2] = ( (src[2]*src[4])+(dst[2]*dst[4]*(1-src[4])) ) / out[4]
  out[3] = ( (src[3]*src[4])+(dst[3]*dst[4]*(1-src[4])) ) / out[4]
  
  src[1] = src[1]*255
  src[2] = src[2]*255
  src[3] = src[3]*255
  src[4] = src[4]*255
  dst[1] = dst[1]*255
  dst[2] = dst[2]*255
  dst[3] = dst[3]*255
  dst[4] = dst[4]*255
  out[1] = out[1]*255
  out[2] = out[2]*255
  out[3] = out[3]*255
  out[4] = out[4]*255
  return out
end

function blendColorOverlay(src, dst)
  -- http://en.wikipedia.org/wiki/Alpha_compositing#Alpha_blending
  -- sooooo ugly
  src[1] = src[1]/255
  src[2] = src[2]/255
  src[3] = src[3]/255
  src[4] = src[4]/255
  dst[1] = dst[1]/255
  dst[2] = dst[2]/255
  dst[3] = dst[3]/255
  dst[4] = dst[4]/255
  
  out = {}
  if src[1] < 0.5 then
    out[1]=2*src[1]*dst[1]
  else
    out[1]=1-(2*(1-src[1])*(1-dst[1]))
  end
  if src[2] < 0.5 then
    out[2]=2*src[2]*dst[2]
  else
    out[2]=1-(2*(1-src[2])*(1-dst[2]))
  end
  if src[3] < 0.5 then
    out[3]=2*src[3]*dst[3]
  else
    out[3]=1-(2*(1-src[3])*(1-dst[3]))
  end
  out[4] = 255
  
  src[1] = src[1]*255
  src[2] = src[2]*255
  src[3] = src[3]*255
  src[4] = src[4]*255
  dst[1] = dst[1]*255
  dst[2] = dst[2]*255
  dst[3] = dst[3]*255
  dst[4] = dst[4]*255
  out[1] = out[1]*255
  out[2] = out[2]*255
  out[3] = out[3]*255
  out[4] = out[4]*255
  return out
end

function gasGiantTexture(diam, props)  
  local imageData = love.image.newImageData( 1, diam )
  local stripesA = props.stripesA
  local pixelRatio = diam/props.visualDiam
  
  local stripes = {}
  for y=0,props.visualDiam do
    stripes[y] = math.random(0,255)
  end
  
  imageData:mapPixel(function ( x, y, r, g, b, a )   
    -- Base color
    r,g,b = props.color[1],props.color[2],props.color[3]
    a = 255
    
    -- Blend in stripes
    local visualY = math.floor(y/pixelRatio)
    local visualYCeil = math.ceil(y/pixelRatio)
    local function interpolate(t, startV, endV, duration)
      return (endV-startV)*t/duration + startV;
    end
    -- interpolate between stripe values
    local stripe = interpolate(y-(visualY*pixelRatio), stripes[visualY], stripes[visualYCeil], pixelRatio)
    r,g,b = unpack( blendColor({stripe, stripe, stripe, stripesA}, {r,g,b,255}) )
    -- r = ((stripe*stripesA)+(r*(255-stripesA)))/(stripesA+(255-stripesA))
    -- g = ((stripe*stripesA)+(g*(255-stripesA)))/(stripesA+(255-stripesA))
    -- b = ((stripe*stripesA)+(b*(255-stripesA)))/(stripesA+(255-stripesA))
        
    r,g,b = math.min(r,255),math.min(g,255),math.min(b,255)
    return r,g,b,a
  end)
    
  return love.graphics.newImage(imageData)
end

local perlin2D = require 'noise'
function sunTexture(diam, props)
  local imageData = love.image.newImageData( props.visualDiam,props.visualDiam )
  local perlin = perlin2D(os.time(), props.visualDiam, props.visualDiam, 0.55, 5, 127)
  
  imageData:mapPixel(function ( x, y, r, g, b, a )
    local c = perlin[x+1][y+1]+127
    c = blendColorOverlay({c,c,c,100}, {255, 121, 18, 255})
    
    r,g,b = c[1],c[2],c[3]
    r,g,b = math.min(r,255),math.min(g,255),math.min(b,255)
    return r,g,b,255
  end)
    
  return love.graphics.newImage(imageData)
end

function sunGradient(diam, contrast, inset, color)
  -- Limit gradient size at 50
  diam = math.min(diam, 50)
  local imageData = love.image.newImageData( diam, diam )
  local center = Vector(diam/2, diam/2)

  imageData:mapPixel( function ( x, y, r, g, b, a )
    r,g,b = color[1],color[2],color[3]
    a = Vector(x, y):dist(center)*inset/diam*255
    
    -- apply contrast
    local factor = (259 * (contrast + 255)) / (255 * (259 - contrast))
    a = math.max(math.min(factor * (a - 128) + 128, 255), 0)
        
    return r,g,b,a
  end )
  
  return love.graphics.newImage(imageData)
end

-- http://www.love2d.org/wiki/HSL_color
-- Converts HSL to RGB. (input and output range: 0 - 255)
function HSL(h, s, l, a)
    if s<=0 then return l,l,l,a end
    h, s, l = h/256*6, s/255, l/255
    local c = (1-math.abs(2*l-1))*s
    local x = (1-math.abs(h%2-1))*c
    local m,r,g,b = (l-.5*c), 0,0,0
    if h < 1     then r,g,b = c,x,0
    elseif h < 2 then r,g,b = x,c,0
    elseif h < 3 then r,g,b = 0,c,x
    elseif h < 4 then r,g,b = 0,x,c
    elseif h < 5 then r,g,b = x,0,c
    else              r,g,b = c,0,x
    end return (r+m)*255,(g+m)*255,(b+m)*255,a
end

function ringsCanvas(diam, props)
  local canvas = love.graphics.newCanvas(diam, diam/2)
  local pixelRatio = diam/props.visualDiam
  love.graphics.setLineWidth(pixelRatio*props.thickness)

  canvas:renderTo(function()
    for i=1,props.rings do
      local color = Class.clone(props.color)
      color[4] = 255
      local ringDarkness = math.random(0,255)
      local ringColor = blendColor({ringDarkness, ringDarkness, ringDarkness, 100}, color)
      ringColor[4] = math.random(0,255)
      
      love.graphics.setColor(unpack(ringColor))
      love.graphics.circle('line', diam/2,diam/2, diam/2-(i*pixelRatio*props.thickness), diam/2)
    end
  end)
  
  return canvas
end

silhouetteEffect=love.graphics.newPixelEffect([[
  vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
  {
    vec4 sample = texture2D(texture, texture_coords);
    sample.r = 0;
    sample.g = 0;
    sample.b = 0;
    sample.a = sample.a*0.5;
    return sample;
  }]])

-- local prop = love.mouse.getX()/love.graphics.getWidth()*225