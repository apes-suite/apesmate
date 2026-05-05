require 'params_ps'

mesh               = './mesh/'  
io_buffer_size = 16
logging = {level=3, filename = 'log_ps_axis_flow'}
simulation_name = 'T'
timing_file = 'timing_ps_axis_flow.res'
-------------------------------------------------------------------------------
function pressureOnBnd(x, y, z, t)
  local t_fold = 5 -- fold of time needed going over the length
  local t_needed = length / dx * t_fold * dt
  -- t_needed = 0

  if t < (time_point * dt + t_needed) then
    return con_press_ref * (t - time_point * dt) / t_needed
  else 
    return con_press_ref
  end
end
-------------------------------------------------------------------------------
-- Stenosis geometry function
function stenosis_geometry(x, y, z, t)
    local origin = {}

    if x > -1.0 and x < 1.0 then
        -- Stenosis geometry, cylindrical coordinates
        origin = {x, 0.0, 0.0}
        origin[2] = 0.025 * (1 + math.cos(math.pi * x))
    else
        -- Straight pipe, Cartesian coordinates
        origin = {x, 0.0, 0.0}
    end

    local dx2 = (z - origin[3])^2
    local dx1 = (y - origin[2])^2
    local r = math.sqrt(dx2 + dx1)

    local cos_theta = (y - origin[2]) / r
    local sin_theta = (z - origin[3]) / r

    return {r, cos_theta, sin_theta}
end

----------------------------------------------------------------------------
sim_control        = {
  time_control     = {
    min      = { iter = 0        },
    max      = { iter = tmax     },
    interval = { iter = 1 }
  }
}

physics  = { dt = dt,  rho0 = con_ref }
-------------------------------------------------------------------------------
identify = {
  label      = 'species',
  kind       = 'passive_scalar',
  relaxation = 'trt',
  layout     = 'd3q19',
  order      = 'Emodel_Corr'
}
transport_velocity = 'velocity_fluid'
-- cylindrical_coord = 'stenosis_geo_param'

glob_source = {
  varname = 'T_source',
  source = 'term_source'
}

variable = {
  {
    name = 'velocity_fluid',
    ncomponents = 3,
    vartype = 'st_fun',
    -- st_fun = {0., 0.0, 0.0}
    st_fun = {
      predefined = 'apesmate',
      domain_from = 'dom_fluid',
      input_varname = {'velocity_phy'}
    }
  },
  {
    name = 'lambda',
    ncomponents = 1,
    vartype = 'st_fun',
    st_fun = -h_2 * source_rate
  },
  {
    name = 'term_source',
    ncomponents = 1,
    vartype = "operation",
    operation = {
      kind='multiplication',
      input_varname={'lambda', 'T_density'},
                }
  }, 
  -- {
  --   name = 'stenosis_geo_param',
  --   ncomponents = 3,
  --   vartype = 'st_fun',
  --   st_fun = stenosis_geometry
  -- }
}

field = { 
  label   = 'T',
  species = {
    -- lambda = 3/4,
    diff_coeff = {
      
      Dxx = D*0.1,
      Dyy = D*diff_ratio,
      Dzz = D*diff_ratio,
      -- omega = 1.5
    }, 
    
  },
  initial_condition = { pressure  = con_press_init,
                        velocityX = 0.0,
                        velocityY = 0.0,
                        velocityZ = 0.0 
                      },
  boundary_condition = { 
      { 
        label = 'front', 
        kind = 'wall'
      },
      { 
        label = 'middle', 
        kind = 'pressure_antiBounceBack_pasScal',
        pressure = pressureOnBnd
      },
      { 
        label = 'end', 
        kind = 'wall'
      },
      { label     = 'inlet',
        kind      = 'flekkoy_outlet'
      },
      { label     = 'outlet',
        kind      = 'flekkoy_outlet'
      }
    
  }
}

tracking = { 
  { 
    label     = 'T',
    variable  = {'T_density'},
    shape = {
      kind = 'all'
    },
    folder    = tracking_folder,
    output    = {format = 'vtk'},  
    time_control     = { 
      min = { iter = tstart }, max = { iter = tmax }, interval = { iter = interval } }
  },
  -- {
  --   label   = 'vel_ave',
  --   variable = {'vel_Lx'},
  --   shape = {
  --     kind = 'all'
  --   },
  --   folder    = 'tracking/',
  --   output    = {format = 'ascii'},  
  --   time_control     = { 
  --     min = { iter = 0 }, max = { iter = tmax }, interval = { iter = interval } }
  -- }
  -- {
  --   label = 'spc1',
  --   variable = {'c_diff'},
  --   reduction = {'l2norm'},
  --   shape = {
  --     kind = 'all'
  --   },
  --   folder = 'tracking/',
  --   output = {format = 'ascii'},
  --   time_control     = { 
  --     min = { iter = t_total }, max = { iter = t_total }, interval = { iter = t_total } }
  -- }
}

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- restart = {
--   -- read  = 'restart/colace_ps_lastHeader.lua',
--   write = 'restart_2/',
--   time_control = {
--     min      = { iter = tmax  },
--     max      = { iter = tmax  },
--     interval = { iter = tmax  }
--   },
-- }
-------------------------------------------------------------------------------
-- start = math.ceil(1/dt*13/12)
