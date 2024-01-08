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
outputname= 'mesh_lineuler'
comment = 'mesh_lineuler'
minlevel = 3
folder = 'mesh_lineuler/'
level = minlevel
--debug = {debugMode=true, debugFiles=true, debugMesh='debug/'}
bounding_cube = { origin = {-3.0, -3.0, -3.0}, length = 8.0 }
elemSize = bounding_cube.length/(2^level)
eps=bounding_cube.length/(2^(level+1))

-------------------------------------------------------------------
 spatial_object = {
  { attribute = { kind = 'seed', label = 'seed', },
    geometry = {
      kind = 'canoND',
      object = { origin = { -2.0, -2.0, -2.0 },
     }
    }
  }, -- seed
  { attribute = {
      kind = 'boundary', label = 'lineuler',
      level = level, calc_dist = false,
  },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { (-2.0-eps), (-2.0-eps), 2.0+eps }, -- left down front 
        vec = { { (4.0+2*eps), 0.0, 0.0 },
               { 0.0, (4.0+2*eps), 0.0 },
        },
      } -- object
    },
  },
  --------------------------------------------
  { attribute = {
      kind = 'boundary', label = 'lineuler',
      level = level, calc_dist = false,
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { (-2.0-eps), (-2.0-eps), -2.0-eps }, -- left down back
        vec = { { (4.0+2*eps), 0.0, 0.0 },
                { 0.0, (4.0+2*eps), 0.0 },
        },
      } -- object
    },
  },
  --------------------------------------------
  { attribute = {
      kind = 'boundary', label = 'lineuler', --'wall_3'
      level = level, calc_dist = false,
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { (-2.0-eps), (-2.0-eps), -2.0-eps }, -- left, down, front
        vec = { { 0.0, 0.0, (4.0+2*eps) },
                { 0.0, (4.0+2*eps), 0.0 },
        },
      } -- object
    },
  },
  --------------------------------------------
  { attribute = {
      kind = 'boundary', label = 'lineuler',
      level = level, calc_dist = false,
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { (2.0+eps), (-2.0-eps), -2.0-eps }, --right, down, front
        vec = { { 0.0, 0.0, (4.0+2*eps) },
                { 0.0, (4.0+2*eps), 0.0 },
        },
      } -- object
    },
  }, 
  --------------------------------------------
  { attribute = {
      kind = 'boundary', label = 'lineuler',
      level = level, calc_dist = false,
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = {(-2.0-eps), (2.0+eps),-2.0-eps }, -- left, up, front
        vec = { { (4.0+2*eps), 0.0, 0.0 },
                { 0.0, 0.0, (4.0+2*eps) },
        },
      } -- object
    },
  }, 
  --------------------------------------------
  { attribute = {
      kind = 'boundary', label = 'lineuler',
      level = level, calc_dist = false,
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { (-2.0-eps), (-2.0-eps), -2.0-eps }, -- left, down, front
        vec = { { (4.0+2*eps), 0.0, 0.0 },
                { 0.0, 0.0, (4.0+2*eps) },
        },
      } -- object
    },
  }, 
  {
    attribute = {
      kind = 'boundary',
      label = 'coupling_euler',
      level = level,
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { (-1.0+eps), (-1.0+eps),-1.0+eps }, -- left, down, front
        vec= { {2.0-2*eps,0.0,0.0},
               {0.0,2.0-2*eps,0.0},
               {0.0,0.0,2.0-2*eps},
        },
      },
    }
  },
} -- spatial object
