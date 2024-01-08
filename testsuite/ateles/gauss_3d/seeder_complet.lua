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
outputname= 'mesh_comp'
comment = 'mesh_comp'
minlevel = 4
folder = 'mesh_comp/'
level = 4
debug = {debugMode=true, debugFiles=true, debugMesh='debug/'}
bounding_cube = { origin = {-4.0, -4.0, -4.0}, length = 8.0 }
eps=bounding_cube.length/math.pow(2,level+1)

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
      kind = 'boundary', label = 'wall_1',
      level = level, calc_dist = false,
  },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { (-2.0-eps), (-2.0-eps), (2.0+eps) }, -- left down front 
        vec = { { (4.0+2*eps), 0.0, 0.0 },
               { 0.0, (4.0+2*eps), 0.0 },
        },
      } -- object
    },
  },
  --------------------------------------------
  { attribute = {
      kind = 'boundary', label = 'wall_2',
      level = level, calc_dist = false,
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { (-2.0-eps), (-2.0-eps), (-2.0-eps) }, -- left down back
        vec = { { (4.0+2*eps), 0.0, 0.0 },
                { 0.0, (4.0+2*eps), 0.0 },
        },
      } -- object
    },
  },
  --------------------------------------------
  { attribute = {
      kind = 'boundary', label = 'wall_3',
      level = level, calc_dist = false,
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { (-2.0-eps), (-2.0-eps), (2.0+eps) }, -- left, down, front
        vec = { { 0.0, 0.0, (-4.0-2*eps) },
                { 0.0, (4.0+2*eps), 0.0 },
        },
      } -- object
    },
  },
  --------------------------------------------
  { attribute = {
      kind = 'boundary', label = 'wall_4',
      level = level, calc_dist = false,
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { (2.0+eps), (-2.0-eps), (2.0+eps) }, --right, down, front
        vec = { { 0.0, 0.0, (-4.0-2*eps) },
                { 0.0, (4.0+2*eps), 0.0 },
        },
      } -- object
    },
  }, 
  --------------------------------------------
  { attribute = {
      kind = 'boundary', label = 'wall_5',
      level = level, calc_dist = false,
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = {(-2.0-eps), (2.0+eps),(2.0+eps) }, -- left, up, front
        vec = { { (4.0+2*eps), 0.0, 0.0 },
                { 0.0, 0.0, (-4.0-2*eps) },
        },
      } -- object
    },
  }, 
  --------------------------------------------
  { attribute = {
      kind = 'boundary', label = 'wall_6',
      level = level, calc_dist = false,
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { (-2.0-eps), (-2.0-eps), (2.0+eps) }, -- left, down, front
        vec = { { (4.0+2*eps), 0.0, 0.0 },
                { 0.0, 0.0, (-4.0-2*eps) },
        },
      } -- object
    },
  }, 
} -- spatial object
