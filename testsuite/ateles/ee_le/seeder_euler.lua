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
outputname= 'mesh_euler'
comment = 'mesh_euler'
minlevel = 5
folder = 'mesh_euler/'
level = minlevel
--debug = {debugMode=true, debugFiles=true, debugMesh='debug/'}
bounding_cube = { origin = {-1.0, -1.0, -1.0}, length = 2.0 }
elemSize = bounding_cube.length/(2^level)
eps=bounding_cube.length/(2^(level+1))

-------------------------------------------------------------------
 spatial_object = {
  { attribute = { kind = 'seed', label = 'seed', },
    geometry = {
      kind = 'canoND',
      object = { origin = { 0.0, 0.0, 0.0 },
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
        origin = { (-0.5-eps), (-0.5-eps), elemSize+eps }, -- left down front 
        vec = { { (1.0+2*eps), 0.0, 0.0 },
               { 0.0, (1.0+2*eps), 0.0 },
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
        origin = { (-0.5-eps), (-0.5-eps), -eps }, -- left down back
        vec = { { (1.0+2*eps), 0.0, 0.0 },
                { 0.0, (1.0+2*eps), 0.0 },
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
        origin = { (-0.5-eps), (-0.5-eps), -eps }, -- left, down, front
        vec = { { 0.0, 0.0, (elemSize+2*eps) },
                { 0.0, (1.0+2*eps), 0.0 },
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
        origin = { (0.5+eps), (-0.5-eps), -eps }, --right, down, front
        vec = { { 0.0, 0.0, (elemSize+2*eps) },
                { 0.0, (1.0+2*eps), 0.0 },
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
        origin = {(-0.5-eps), (0.5+eps),-eps }, -- left, up, front
        vec = { { (1.0+2*eps), 0.0, 0.0 },
                { 0.0, 0.0, (elemSize+2*eps) },
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
        origin = { (-0.5-eps), (-0.5-eps), -eps}, -- left, down, front
        vec = { { (1.0+2*eps), 0.0, 0.0 },
                { 0.0, 0.0, (elemSize+2*eps) },
        },
      } -- object
    },
  }, 
} -- spatial object
