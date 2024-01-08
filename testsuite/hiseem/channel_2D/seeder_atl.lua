-- Use this file as template. Do not modify this file for running some testcases
require "common"

folder = 'mesh_atl/'--..subprefix
ebug = {debugMode = true, debugFiles=true}
logging = {level=5}
timing_file = 'sdr_atl_timing.res'

-- boundingbox: two entries: origin and length in this
-- order, if no keys are used
bounding_cube = {origin = {-dx/1.,-dx/1.,-dx/1.},
               length = length_bnd}

minlevel = level

spatial_object = {
  {
    attribute = {
      kind = 'seed',
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { length*0.5, height*0.5, zpos },
        }
    }
  }
,
  {
    attribute = {
      kind = 'boundary',
      label = 'north'
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { -dx,height+dx_half,-dx },
        vec = {{length+4*dx,0.0,0.0},
               {0.0,0.0,4.*dx}}
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
        vec = {{length+4*dx,0.0,0.0},
               {0.0,0.0,4.*dx}}
        }
    }
  },
  {
    attribute = {
      kind = 'boundary',
      label = 'east'
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = {length+dx/2.0,-dx,-dx},
        vec = {{0.0,height+2*dx,0.0},
               {0.0,0.0,4.*dx}}
        }
    }
  },
  {
    attribute = {
      kind = 'boundary',
      label = 'west'
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = {-dx/2.0,-dx,-dx},
        vec = {{0.0,height+2*dx,0.0},
               {0.0,0.0,4.*dx}}
        }
    }
  },
  {
    attribute = {
      kind = 'periodic',
    },
    geometry = {
      kind = 'periodic',
      object = {
        plane1 = {
          origin = {-dx,-dx,dx+dx/2.0},
          vec = {{length+4*dx,0.0,0.0},
               {0.0,height+2*dx,0.0}}
        },
        plane2 = {
          origin = {-dx,-dx,-dx/2.0},
          vec = {{0.0,height+2*dx,0.0},
                 {length+4*dx,0.0,0.0}}
        }         
      }  
    }
  }
}


