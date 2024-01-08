----------------------- PLEASE READ THIS ---------------------------!!!

-- This input file is set up to run for regression check
-- Please make sure you DO NOT MODIFY AND PUSH it to the repository

--------------------------------------------------------------------!!!


-- Use this file as template. Do not modify this file for running some testcases

require "common"

folder = 'mesh/'--..subprefix
NOdebug = { debugMode = true, debugMesh = 'debug/' }
logging = {level=10}
timing_file = 'sdr_timing.res'
printRuntimeInfo = true

-- boundingbox: two entries: origin and length in this
-- order, if no keys are used
bounding_cube = {origin = {-dx/1.,-dx/1.-offset,-dx/1.},
               length = length_bnd}

minlevel = level

spatial_object = {
  {
    attribute = {
      kind = 'seed',   ----seed
    },
    geometry = {
      kind = 'canoND',
      object = {
        --origin = { length*0.5, height*0.5, zpos },
        origin = { dx/2.0, height*0.5-offset, zpos },
        }
    }
  },
  { -- top wall
    attribute = {
      kind = 'boundary',
      label = 'north'
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = { -dx,height+dx_half-offset,-dx },
        vec = {{length+4*dx,0.0,0.0},
               {0.0,0.0,4.*dx}}
        }
    }
  },
  { -- bottom wall
    attribute = {
      kind = 'boundary',
      label = 'south'
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = {-dx,-dx/2.-offset,-dx},
        vec = {{length+4*dx,0.0,0.0},
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
          origin = {length+dx/2.0,-dx-offset,-dx},
          vec = {{0.0,height+2*dx,0.0},
                 {0.0,0.0,4.*dx}}
        },
        plane2 = {
          origin = {-dx/2.0,-dx-offset,-dx},
          vec = {{0.0,0.0,4.*dx}, 
                {0.0,height+2*dx,0.0}}
        }
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
          origin = {-dx,-dx-offset,dx+dx/2.0},
          vec = {{length+4*dx,0.0,0.0},
               {0.0,height+2*dx,0.0}}
        },
        plane2 = {
          origin = {-dx,-dx-offset,-dx/2.0},
          vec = {{0.0,height+2*dx,0.0},
                 {length+4*dx,0.0,0.0}}
        }         
      }  
    }
  },
}

