-- Use this file as template. Do not modify this file for running some testcases

outputname = 'lineuler'
outputpreview = true 
folder = 'mesh_lineuler/'

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

ystart = -15.0
yend = 15.0
ylen = math.abs(ystart) + math.abs(yend)
print (ylen)
spatial_object = {
  {
    attribute = {kind = 'seed' },
    geometry = {
      kind   = 'canoND',
      object = {origin = {0.0,ystart+elemSize,0.0} },
    },
  },
  {
    attribute = {kind = 'seed' },
    geometry = {
      kind   = 'canoND',
      object = {origin = {0.0,yend-elemSize,0.0} },
    },
  },
  {
    attribute = {
      kind = 'boundary',
      label = 'euler',
      level = level,
    },
    geometry = {
      kind = 'canoND',
      object = {
        vec= {
          {15.0-2*eps,0.0,0.0},
          {0.0,20.0-2*eps,0.0},
          {0.0,0.0,elemSize-2*eps},
        },
        origin={eps,-10.0+eps,eps}
      },
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
          {0.0,ylen+2*eps,0.0},
          {0.0,0.0,elemSize+2*eps},
        },
        origin={15+eps,ystart-eps,-eps}
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
          {0.0,ylen+2*eps,0.0},
          {0.0,0.0,elemSize+2*eps},
        },
        origin={-eps,ystart-eps,-eps}
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
        origin={-eps,ystart+ylen+eps,-eps}
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
        origin={-eps,ystart-eps,-eps}
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
          {0.0,ylen+2*eps,0.0},
        },
        origin={-eps,ystart-eps,-eps}
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
          {0.0,ylen+2*eps,0.0},
        },
        origin={-eps,ystart-eps,elemSize+eps}
      },
    },
  },
}
