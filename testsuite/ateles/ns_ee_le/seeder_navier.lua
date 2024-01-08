-- Use this file as template. Do not modify this file for running some testcases

outputname = 'navier'
outputpreview = true 
folder = 'mesh_navier/'

level = 6
maxlevel = level
minlevel = level

cubeLength = 64.0

-- the element size of the largest elements (belonging to minlevel)
eps = cubeLength/(2^level+1)
elemSize = cubeLength/(2^level)
-- boundingbox: two entries: origin and length in this
-- order, if no keys are used
bounding_cube = {
                 origin = {-elemSize,cubeLength/(-2.0),cubeLength/(-2.0)},
                 length = cubeLength
                }



spatial_object = {
  {
    attribute = {kind = 'seed' },
    geometry = {
      kind   = 'canoND',
      object = {origin = {0.0,0.0,0.0} },
    },
  },
  {
    attribute = {
      kind = 'boundary',
      label = 'fluid_east',
      level = level,
    },
    geometry = {
      kind = 'canoND',
      object = {
        vec= {
          {0.0,10.0+2*eps,0.0},
          {0.0,0.0,elemSize+2*eps},
        },
        origin={15+eps,-5.0-eps,-eps}
      },
    },
  },
  {
    attribute = {
      kind = 'boundary',
      label = 'fluid_west',
      level = level,
    },
    geometry = {
      kind = 'canoND',
      object = {
        vec= {
          {0.0,10.0+2*eps,0.0},
          {0.0,0.0,elemSize+2*eps},
        },
        origin={-eps,-5.0-eps,-eps}
      },
    },
  },
  {
    attribute = {
      kind = 'boundary',
      label = 'fluid_north',
      level = level,
    },
    geometry = {
      kind = 'canoND',
      object = {
        vec= {
          {15+2*eps,0.0,0.0},
          {0.0,0.0,elemSize+2*eps},
        },
        origin={-eps,5.0+eps,-eps}
      },
    },
  },
  {
    attribute = {
      kind = 'boundary',
      label = 'fluid_south',
      level = level,
    },
    geometry = {
      kind = 'canoND',
      object = {
        vec= {
          {15.0+2*eps,0.0,0.0},
          {0.0,0.0,elemSize+2*eps},
        },
        origin={-eps,-5.0-eps,-eps}
      },
    },
  },
  {
    attribute = {
      kind = 'boundary',
      label = 'fluid_bottom',
      level = level,
    },
    geometry = {
      kind = 'canoND',
      object = {
        vec= {
          {15.0+2*eps,0.0,0.0},
          {0.0,10.0+2*eps,0.0},
        },
        origin={-eps,-5.0-eps,-eps}
      },
    },
  },
  {
    attribute = {
      kind = 'boundary',
      label = 'fluid_top',
      level = level,
    },
    geometry = {
      kind = 'canoND',
      object = {
        vec= {
          {15.0+2*eps,0.0,0.0},
          {0.0,10.0+2*eps,0.0},
        },
        origin={-eps,-5.0-eps,elemSize+eps}
      },
    },
  },
}
