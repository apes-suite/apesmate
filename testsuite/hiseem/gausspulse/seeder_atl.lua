require "common_aps"
nHeight = math.ceil(8)
dx_atl = height/nHeight
mesh_folder = 'mesh_atl/'
nLength = nHeight*l_h 
dx = height/nHeight
dxdash = 0.0001*dx
nLength_bnd = nLength+2
level = math.ceil(math.log(nLength_bnd)/math.log(2))
length_bnd = (2^level)*dx
dx_half = dx*0.5
zpos = dx_half

folder = mesh_folder
minlevel = level
logging = {level=3}

-- in bounding cube we want origin and length

bounding_cube = {
    origin = {originX-dx, originY-dx, originZ},
    length = length_bnd
  }
-- spatial object is composed  by the attribute and geometry

spatial_object = {
  {
    attribute = {
       kind = 'seed',        --- kind is seed/boundary/refinement/periodic
    },               
    geometry = {
      kind = 'canoND',     --- canoND is nothing but the line/plane/point/box
      object = {
        origin = {0.0,0.0,0.0}
      } ---object
    } --- geometry
  }, --- attribute
  {
    attribute = {
       kind = 'periodic',
    },               
    geometry = {
      kind = 'periodic',
      object = {
        plane1 = {          --- plane is composed by the a origin and two vectors
          origin = {-length*0.5,-length*0.5,dx_atl+dx/2 },
          vec = {{length,0.0,0.0},
                 {0.0,length,0.0}}  
        },        
        plane2 = {
          origin = {-length*0.5,-length*0.5,-dx/2},
          vec = {{0.0,length,0.0},
                 {length,0.0,0.0}}  
        }        
      } --- object
    } -- geometry
  }, --- attribute
  {
    attribute = {
      kind = 'boundary',
      label = 'north',
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = {-length*0.5,length*0.5+dx/2.0,-dx/2.0},
        vec = {
          {length,0.0,0.0},
          {0.0,0.0,3*dx}
        }
      }
    }
  },
  {
    attribute = {
      kind = 'boundary',
      label = 'south',
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = {-length*0.5,-length*0.5-dx/2.0,-dx/2.0},
        vec = {
          {length,0.0,0.0},
          {0.0,0.0,3*dx}
        }
      }
    }
  },
  {
    attribute = {
      kind = 'boundary',
      label = 'east',
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = {length*0.5+dx/2.0,-length*0.5,-dx/2.0},
        vec = {
          {0.0,length,0.0},
          {0.0,0.0,3*dx}
        }
      }
    }
  },
  {
    attribute = {
      kind = 'boundary',
      label = 'west',
    },
    geometry = {
      kind = 'canoND',
      object = {
        origin = {-length*0.5-dx/2.0,-length*0.5,-dx/2.0},
        vec = {
          {0.0,length,0.0},
          {0.0,0.0,3*dx}
        }
      }
    }
  },
}  --- spatial object
  

