----------------------- PLEASE READ THIS ---------------------------!!!

-- This input file is set up to run for regression check
-- Please make sure you DO NOT MODIFY AND PUSH it to the repository

--------------------------------------------------------------------!!!


-- Use this file as template. Do not modify this file for running some testcases
require "common"

folder = 'mesh_right/'--..subprefix
NOdebug = { debugMode = true, debugMesh = 'debug/' }
logging = {level=10}
timing_file = 'sdr_timing.res'

-- boundingbox: two entries: origin and length in this
-- order, if no keys are used
bounding_cube = {origin = {-dx/1.,-dx/1.,-dx/1.},
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
        origin = { dx, dx, zpos },
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
               {0.0,0.0,height+2*dx}}
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
        origin = {length/2.0+dx/2.0,-dx,-dx},
        vec = {{0.0,height+2*dx,0.0},
               {0.0,0.0,height+2*dx}}
        }
    }
  },
}
