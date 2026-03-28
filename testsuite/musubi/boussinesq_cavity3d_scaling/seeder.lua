require 'params'

folder    = 'mesh/'

minlevel  = level
logging = {level=10, filename = 'log_seeder'}

bounding_cube = { origin = bc_origin,
                  length = length_bnd }

-- debug = {debugMode = true, debugFiles = true, debugMesh='debug/' }
spatial_object = {
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
        origin = { 0, 0, 0 },
        vec = { {0.0, 1, 0.0}, 
                {0, 0.0, 1}
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
        origin = { 1., 0, 0 },
        vec = { {0.0, 1, 0.0}, 
                {0, 0.0, 1}
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
        origin = { 0, 1, 0 },
        vec = { {1.0, 0, 0.0}, 
                {0, 0.0, 1}
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
        origin = { 0., 0, 0 },
        vec = { {1, 0, 0.0}, 
                {0, 0.0, 1}
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
      kind    = 'canoND',
      object  = {
        origin = { 0, 0, 1 },
        vec = { {1.0, 0, 0.0}, 
                {0, 1.0, 0}
        },
        only_surface = true,
      }
    }
  },
  {
    attribute   = {
      kind      = 'boundary',
      label     = 'back',
      level     = minlevel,
      calc_dist = true,
    },
    geometry  = { 
      kind    = 'canoND',
      object  = {
        origin = { 0., 0, 0 },
        vec = { {1, 0, 0.0}, 
                {0, 1, 0}
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
