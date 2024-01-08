--           2 
--          /
--       -------    
--      /      /|
--     /  5   / |
--     -------  | 4
--    |  |   |  |
-- 3  |  |   |  | 
--    |   ---|---
--    | /  6 | /
--    |/     |/
--     ------
--     /
--    1      
--       
--       4 is precice boundary
--
--
printRuntimeInfo = false
outputname= 'mesh_right'
comment = 'mesh_right'
minlevel = 6
folder = 'mesh_right/'
level = 6
NOdebug = {debugMode=true, debugFiles=true, debugMesh='debug/'}
logging = {level=10}
length= 4.0
elemSize = length/(2^level)
bounding_cube = { origin = {-1.0, -1.0, -1.0-elemSize/2.0}, length = length }
--elemSize = bounding_cube.length/(2^level)
print (elemSize,'=dx')
eps=bounding_cube.length/(2^(level+1))

print (eps,'=eps')
-------------------------------------------------------------------
 spatial_object = {
  { attribute = { kind = 'seed', label = 'seed', },
    geometry = {
      kind = 'canoND',
      object = { origin = { 0.125, -0.125, 0.0 },
     }
    }
  }, -- seed
  { attribute = {
      kind = 'boundary', label = 'top',
      level = level, calc_dist = false,
  },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { (0.0-eps), (-0.25-eps), -(elemSize/2.0)-eps }, -- left down front 
        vec = { { (0.25+2*eps), 0.0, 0.0 },
               { 0.0, (0.25+2*eps), 0.0 },
        },
      } -- object
    },
  },
  --------------------------------------------
  { attribute = {
      kind = 'boundary', label = 'bottom',
      level = level, calc_dist = false,
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { (0.0-eps), (-0.25-eps), (elemSize/2.0)+eps }, -- left down back
        vec = { { (0.25+2*eps), 0.0, 0.0 },
                { 0.0, (0.25+2*eps), 0.0 },
        },
      } -- object
    },
  },
  --------------------------------------------
  { attribute = {
      kind = 'boundary', label = 'west',
      level = level, calc_dist = false,
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { (0.0-eps), (-0.25-eps), -(elemSize/2.0)-eps }, -- left, down, front
        vec = { { 0.0, 0.0, (1*elemSize+2*eps) },
                { 0.0, (0.25+2*eps), 0.0 },
        },
      } -- object
    },
  },
  --------------------------------------------
  { attribute = {
      kind = 'boundary', label = 'east', --'wall 4''
      level = level, calc_dist = false,
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { (0.25+eps), (-0.25-eps), -(elemSize/2.0)-eps }, --right, down, front
        vec = { { 0.0, 0.0, (1*elemSize+2*eps) },
                { 0.0, (0.25+2*eps), 0.0 },
        },
      } -- object
    },
  }, 
  --------------------------------------------
  { attribute = {
      kind = 'boundary', label = 'north',
      level = level, calc_dist = false,
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = {(0.0-eps), (0.0+eps),-(elemSize/2.0)-eps }, -- left, up, front
        vec = { { (0.25+2*eps), 0.0, 0.0 },
                { 0.0, 0.0, (1*elemSize+2*eps) },
        },
      } -- object
    },
  }, 
  --------------------------------------------
  { attribute = {
      kind = 'boundary', label = 'south',
      level = level, calc_dist = false,
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { (0.0-eps), (-0.25-eps),-(elemSize/2.0)-eps}, -- left, down, front
        vec = { { (0.25+2*eps), 0.0, 0.0 },
                { 0.0, 0.0, (1*elemSize+2*eps) },
        },
      } -- object
    },
  }, 
} -- spatial object
