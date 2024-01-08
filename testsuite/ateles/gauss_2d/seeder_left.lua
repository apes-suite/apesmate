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
outputname= 'mesh_left'
comment = 'mesh_left'
minlevel = 8
folder = 'mesh_left/'
level = 8
--debug = {debugMode=true, debugFiles=true, debugMesh='debug/'}
bounding_cube = { origin = {-4.0, -4.0, -4.0}, length = 8.0 }
elemSize = bounding_cube.length/(2^level)
eps=bounding_cube.length/(2^(level+1))

-------------------------------------------------------------------
 spatial_object = {
  { attribute = { kind = 'seed', label = 'seed', },
    geometry = {
      kind = 'canoND',
      object = { origin = { -1.0, 0.0, eps },
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
        origin = { (-2.0-eps), (-2.0-eps), elemSize+eps }, -- left down front 
        vec = { { (2.0+2*eps), 0.0, 0.0 },
               { 0.0, (4.0+2*eps), 0.0 },
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
        origin = { (-2.0-eps), (-2.0-eps), -eps }, -- left down back
        vec = { { (2.0+2*eps), 0.0, 0.0 },
                { 0.0, (4.0+2*eps), 0.0 },
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
        origin = { (-2.0-eps), (-2.0-eps), -eps }, -- left, down, front
        vec = { { 0.0, 0.0, (elemSize+2*eps) },
                { 0.0, (4.0+2*eps), 0.0 },
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
        origin = { (0.0+eps), (-2.0-eps), -eps }, --right, down, front
        vec = { { 0.0, 0.0, (elemSize+2*eps) },
                { 0.0, (4.0+2*eps), 0.0 },
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
        origin = {(-2.0-eps), (2.0+eps), -eps }, -- left, up, front
        vec = { { (2.0+2*eps), 0.0, 0.0 },
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
        origin = { (-2.0-eps), (-2.0-eps), -eps}, -- left, down, front
        vec = { { (2.0+2*eps), 0.0, 0.0 },
                { 0.0, 0.0, (elemSize+2*eps) },
        },
      } -- object
    },
  }, 
} -- spatial object
