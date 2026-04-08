require 'params'

folder    = 'mesh/'

minlevel  = level

bounding_cube = { origin = bc_origin,
                  length = length_bnd }

NOdebug = {debugMode = true, debugFiles = true, debugMesh='debug/' }

spatial_object = {
  {
    attribute   = {
      kind      = 'periodic',
    },
    geometry  = { 
      kind    = 'periodic',
      object  = {
        plane1 = {
            origin = { 0, 0, -dx-dx_eps },
            vec = { {1., 0.0, 0}, 
                  {0.0, 1.0, 0.0}
          },
        },
        plane2 = {
          origin = { 0, 0, dx+dx_eps },
          vec = { {1.0, 0., 0.0}, 
                {0., 1., 0.0}
        },
      },
      }
    }
  },
  {
    attribute   = {
      kind      = 'boundary',
      label     = 'left',
      level     = minlevel,
      calc_dist = true,
    },
    geometry  = { 
      kind    = 'canoND',
      object  = {
        origin = { 0, 0, -dx-dx_eps },
        vec = { {0.0, 1, 0.0}, 
                {0, 0.0, 2*dx + 2*dx_eps}
        },
        only_surface = true,
      }
    }
  },
  {
    attribute   = {
      kind      = 'boundary',
      label     = 'right',
      level     = minlevel,
      calc_dist = true,
    },
    geometry  = { 
      kind    = 'canoND',
      object  = {
        origin = { 1., 0, -dx - dx_eps },
        vec = { {0.0, 1, 0.0}, 
                {0, 0.0, 2*dx + 2*dx_eps}
        },
        only_surface = true,
      }
    }
  },
  {
    attribute   = {
      kind      = 'boundary',
      label     = 'up',
      level     = minlevel,
      calc_dist = true,
    },
    geometry  = { 
      kind    = 'canoND',
      object  = {
        origin = { 0, 1, -dx - dx_eps },
        vec = { {1.0, 0, 0.0}, 
                {0, 0.0, 2*dx + 2*dx_eps}
        },
        only_surface = true,
      }
    }
  },
  {
    attribute   = {
      kind      = 'boundary',
      label     = 'down',
      level     = minlevel,
      calc_dist = true,
    },
    geometry  = { 
      kind    = 'canoND',
      object  = {
        origin = { 0., 0, -dx - dx_eps },
        vec = { {1, 0, 0.0}, 
                {0, 0.0, 2*dx + 2*dx_eps}
        },
        only_surface = true,
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
