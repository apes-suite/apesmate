require 'params'

folder    = 'mesh/'
comment   = simulation_name

minlevel  = level
print(minlevel)

bounding_cube = { origin = bc_origin,
                  length = length_bnd }

ebug = {debugMode = true, debugFiles = false, debugMesh='debug/' }
spatial_object = {
  {
    attribute   = {
      kind      = 'boundary',
      label     = 'vessel',
      level     = minlevel,
    },
    geometry  = { 
      kind    = 'stl',
      object  = {filename = 'pipe.stl'} 
    }
  },
  {
    attribute   = {
      kind      = 'boundary',
      label     = 'inlet',
      level     = minlevel,
    },
    geometry  = { 
      kind    = 'canoND',
      object  = {
        origin = { -length/2.0+2*dx, -1.0*Dia, -1.0*Dia },
        vec = { {0.0, 2*Dia, 0.},
                {0., 0.0, 2.*Dia}
        }       
      }
    }
  },
  {
    attribute   = {
      kind      = 'boundary',
      label     = 'outlet',
      level     = minlevel,
    },
    geometry  = { 
      kind    = 'canoND',
      object  = {
        origin = { length/2.0-2*dx, -1.0*Dia, -1.0*Dia },
        vec = { {0.0, 2.*Dia, 0.},
                {0., 0.0, 2.*Dia}
        }       
      }
    }
  },
  {
    attribute = { 
      kind    = 'seed',
      label   = 'seed',
    },
    geometry  = {
      kind    = 'canoND', 
      object  = { origin = seed_orig }
    }                
  }
}
