require "common"
-- Location to write the mesh in.
-- Note the trailing path seperator, needed, if all mesh files should be in a
-- directory. This directory has to exist before running Seeder in this case!
folder = 'mesh/'

ebug = {debugMode = true, debugFiles = false, debugMesh='debug/' }

-- bounding cube: two entries: origin and length in this
-- order, if no keys are used
bounding_cube = {origin = {-dx, -dx, -dx},
                length = length_bnd}

-- minimum refinement level in fluid domain
minlevel = level

-- Laboratory scale spacer:
-- length=20 cm,width=10 cm,
-- filament, radius = 0.01 cm
-- spacer gap = 0.1 cm ! distance between two parallel filament
-- offset = 0.0 ! offset of spacer along its height in bounding box
-- default offset=0.0. create spacer in bounding box origin
-- boundary_label = 'spacer'. define boundary name
spatial_object = {
  {
    attribute = {
      kind = 'seed',
      label='seed'
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = {-dx,-dx,-dx},
        vec = { {l_ch, 0.0,0.0},
                {0.0, h_ch, 0.0},
                {0.0,0.0,w_ch}}


      }
    }
  },

  {
    -- Defining a domain boundary
    attribute = {
      kind = 'boundary', -- or seed, refinement
      label = 'spacer',   -- some label to identify the boundary condition
--      level = 1          -- level to refine this object with, default = 0
    },
    geometry = {
      kind = 'spacer',
      object = {
        length = {
          vec = {l_ch+2*dx,0.0,0.0},
          filament_gap = l_m,
          radius = r_f,
          origin = {-dx,d_f,l_m/2.}
        },
        width = { 
          vec = {0.0,0.0,w_ch+2*dx},
          filament_gap = l_m,
          radius = r_f,
          origin = {l_m/2,d_f,-dx}
        },
          interwoven = true
      }
    }
  },  
  {
    attribute = {
      kind = 'boundary',
      label = 'inlet'
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = {-dx/2.0,-dx,-dx},
        vec = { {0.0,h_ch+2*dx,0.0},
                {0.0,0.0,w_ch+2*dx}}
      }
    }
  },
  {
    attribute = {
      kind = 'boundary',
      label = 'outlet'
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = {l_ch+dx/2.,-dx,-dx},
        vec = { {0.0,h_ch+2*dx,0.0},
                {0.0,0.0,w_ch+2*dx}}
      }
    }
  },

--  {
--    attribute = {
--      kind = 'boundary',
--      label = 'left'
--    },
--    geometry = {
--      kind = 'canoND',
--      object = {
--        origin = {-dx,-dx,-dx/2.0},
--        vec = { {0.0,h_ch+2*dx,0.0},
--                {l_ch+4*dx,0.0,0.0} }
--      }
--    }
--  },  
--  {
--    attribute = {
--      kind = 'boundary',
--      label = 'right'
--    },
--    geometry = {
--      kind = 'canoND',
--      object = {
--        origin = {-dx,-dx,w_ch+dx/2.0},
--        vec = { {l_ch+4*dx,0.0,0.0},
--                {0.0,h_ch+2*dx,0.0}}
--      }
--    }
--  },
  {
    attribute = {
      kind = 'periodic'
    },
    geometry = {
      kind = 'periodic',
      object = {
        plane1 = { 
          origin = {-dx,-dx,-dx/2.0},
          vec = { {0.0,h_ch+2*dx,0.0},
                  {l_ch+4*dx,0.0,0.0} }
        },
        plane2 = {
          origin = {-dx,-dx,w_ch+dx/2.0},
          vec = { {l_ch+4*dx,0.0,0.0},
                  {0.0,h_ch+2*dx,0.0}}
        }
      }  
    }
  },
  {
    attribute = {
      kind = 'boundary',
      label = 'south'
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = {-dx,-dx/2.,-dx},
        vec = { {l_ch+4*dx,0.0,0.0},
                {0.0,0.0,w_ch+2*dx}}
      }
    }
  },  
  {
    attribute = {
      kind = 'boundary',
      label = 'north'
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = {-dx,h_ch+dx/2.0,-dx},
        vec = { {l_ch+4*dx,0.0,0.0},
                {0.0,0.0,w_ch+2*dx}}
      }
    }
  },                 
}
