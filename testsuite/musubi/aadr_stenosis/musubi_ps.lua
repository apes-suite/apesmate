require 'params_ps'

mesh = './mesh/'  
io_buffer_size = 16
logging = {level=1, filename = 'log_ps_axis_flow'}
simulation_name = 'T'
timing_file = 'timing_ps_axis_flow.res'

Dxx = D
Dyy = D*diff_ratio
Dzz = D*diff_ratio
-------------------------------------------------------------------------------
-- Imposing a gradually increasing pressure at the middle boundary, which is the stenosis region, to avoid numerical instability at the beginning of the simulation. The pressure will reach the target value at time_point * dt + t_needed.
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
-- For any future use related to geometry
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
  relaxation= {
    -- bgk, trt, mrt are supported for anisotropic diffusion
    name = 'trt',
    -- There are some models for anisotropic diffusion, e.g.,
    -- Emodel, EmodelCorr, Lmodel
    variant = 'EmodelCorr'
  },
  layout     = 'd3q19'
}

transport_velocity = 'velocity_fluid'

glob_source = {
  varname = 'T_source',
  source = 'term_source'
}

variable = {
  {
    name = 'velocity_fluid',
    ncomponents = 3,
    vartype = 'st_fun',
    -- st_fun = {0., 0.0, 0.0} -- uniform zero velocity, for debugging
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
  }
}

field = { 
  label   = 'T',
  species = {
    -- diff_coeff controls the free parameter of diffusion, 
    -- which is set to the average of the tensor components
    -- if test fails e.g. with bgk model, try setting diff_coeff with the given tau
    -- i.e. diff_coeff = (tau - 0.5) / 3
    diff_coeff = (Dxx+Dyy+Dzz)/3,
    -- diff_tensor sets the anisotropic diffusion tensor
    diff_tensor = {
      Dxx = Dxx, -- Dxx is the diffusion coefficient in the axial direction
      Dyy = Dyy, -- Dyy and Dzz are the diffusion coefficients in the transverse direction
      Dzz = Dzz
    }
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
        kind = 'pressure_antibounceback',
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
-------------------------------------------------------------------------------
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
  }
}
-------------------------------------------------------------------------------