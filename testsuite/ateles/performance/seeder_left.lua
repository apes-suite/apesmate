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
timing_file = 'sdr_timing.res'
outputname= 'mesh_left'
comment = 'mesh_left'
minlevel = 6
folder = 'mesh_left/'
level = 6
--debug = {debugMode=true, debugFiles=true, debugMesh='debug/'}
bounding_cube = { origin = {-8.0, -8.0, -8.0}, length = 16.0 }
eps=bounding_cube.length/(2^(level+1))

-------------------------------------------------------------------
 spatial_object = {
  { attribute = { kind = 'seed', label = 'seed', },
    geometry = {
      kind = 'canoND',
      object = { origin = { -1.0, 0.0, 0.0 },
     }
    }
  }, -- seed
-------------------------------------------------------------------
-- boundaries west and east
  { attribute = {
      kind = 'boundary', label = 'west',
      level = level, calc_dist = false,
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { (-4.0-eps), (-2.0-eps), (2.0+eps) }, -- left, down, front
        vec = { { 0.0, 0.0, (-4.0-2*eps) },
                { 0.0, (4.0+2*eps), 0.0 },
        },
      } -- object
    },
  },
  { attribute = {
      kind = 'boundary', label = 'east', --'wall 4''
      level = level, calc_dist = false,
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { (0.0+eps), (-2.0-eps), (2.0+eps) }, --right, down, front
        vec = { { 0.0, 0.0, (-4.0-2*eps) },
                { 0.0, (4.0+2*eps), 0.0 },
        },
      } -- object
    },
  }, 
  --------------------------------------------
--periodic in z direction
  { attribute = {
      kind = 'periodic', 
      level = level,
      },
      geometry = {
        kind = 'periodic',
        object = { 
          plane1 = { 
            origin = { (-4.0-eps), (-2.0-eps), (2.0+eps) }, -- left down front 
            vec = { { (4.0+2*eps), 0.0, 0.0 },
                    { 0.0, (4.0+2*eps), 0.0 },
            },
          },
          plane2 = { 
            origin = { (-4.0-eps), (-2.0-eps), (-2.0-eps) }, -- left down back
            vec = { { (4.0+2*eps), 0.0, 0.0 },
                    { 0.0, (4.0+2*eps), 0.0 },
            },
          },  
        },
      },
    },
  --------------------------------------------
--periodic in y direction
  { attribute = {
      kind = 'periodic', 
      level = level,
      },
      geometry = {
        kind = 'periodic',
        object = { 
          plane1 = { 
            origin = {(-4.0-eps), (2.0+eps),(2.0+eps) }, -- left, up, front
            vec = { { (4.0+2*eps), 0.0, 0.0 },
                { 0.0, 0.0, (-4.0-2*eps) },
            },
          },
          plane2 = { 
            origin = { (-4.0-eps), (-2.0-eps), (2.0+eps) }, -- left, down, front
            vec = { { (4.0+2*eps), 0.0, 0.0 },
                    { 0.0, 0.0, (-4.0-2*eps) },
            },
          },  
        },
      },
    },
} -- spatial object
