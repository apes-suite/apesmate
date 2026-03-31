require 'params'

folder    = 'mesh/'

minlevel  = level
bounding_cube = { origin = bc_origin,
                  length = length_bnd }

NOdebug = {debugMode = true, debugFiles = true, debugMesh='debug/' }
spatial_object = {
  {
    attribute   = {
      kind      = 'boundary',
      label     = 'inlet',
      level     = minlevel,
      calc_dist = true,
    },
    geometry  = { 
      kind    = 'canoND',
      object  = {
        origin = { -8+dx_eps, -1-dx, -1.-dx },
        vec = { {0.0, 2+2*dx, 0.0}, 
                {0, 0.0, 2+2*dx}
        },
        only_surface = true,
      }
    }
  },
  {
    attribute   = {
      kind      = 'boundary',
      label     = 'outlet',
      level     = minlevel,
      calc_dist = true,
    },
    geometry  = { 
      kind    = 'canoND',
      object  = {
        origin = { 8-dx_eps, -1-dx, -1.-dx },
        vec = { {0.0, 2+2*dx, 0.0}, 
                {0, 0.0, 2.+2*dx}
        },
        only_surface = true,
      }
    }
  },
  {
    attribute   = {
      kind      = 'boundary',
      label     = 'front',
      level     = minlevel,
      calc_dist = true,
    },
    geometry  = { 
      kind    = 'stl',
      object  = {
        filename = 'front.stl'
      }
    }
  },
  {
    attribute   = {
      kind      = 'boundary',
      label     = 'middle',
      level     = minlevel,
      calc_dist = true,
    },
    geometry  = { 
      kind    = 'stl',
      object  = {
        filename = 'middle.stl'
      }
    }
  },
  {
    attribute   = {
      kind      = 'boundary',
      label     = 'end',
      level     = minlevel,
      calc_dist = true,
    },
    geometry  = { 
      kind    = 'stl',
      object  = {
        filename = 'end.stl'
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
