-- Musubi configuration file. 
-- This is a LUA script.
require 'common'
--tracking_fol = prefix..subprefix..'tracking/'
--output_fol = prefix..subprefix..'output/'
--restart_fol = prefix..subprefix..'restart/'
tracking_fol = 'tracking/'
output_fol = 'output/'
restart_fol = 'restart/'

--dx = getdxFromLevel( {len_bnd=length_bnd, level=level})
--dt = getdtFromVel( {dx = dx, u_p = u_max_phy, u_l = u_max_L } )
--omega = getOmegaFromdt( {dx=dx, dt=dt, nu_p = nu_phy } )

-- Simulation name
simulation_name = 'spacer'
-- Mesh information
mesh = 'mesh/'

-- Time step settings
tmax_p = 0.3 --s
tmax           =  tmax_p/dt     -- total iteration number
sim_control = {
  time_control = {
    max = tmax_p, 
    interval = {iter=1}}
}    

-- needed to dump variable in physical unit
physics = { dt = dt, rho0 = rho0_p }            

-- physics setting
fluid = { 
--        omega_ramping = {predefined='smooth', min_factor = 0.5, max_factor=1.0, 
--        from_time=0, to_time=1000*dt}, 
       omega = omega, 
       rho0 = rho0_p }

interpolation_method = 'compact'                     
control_routine = 'fast'
                     
-- Initial condition 
initial_condition = { pressure = 0.0, 
                      velocityX = 0.0,
                      velocityY = 0.0,
                      velocityZ = 0.0 }


  identify = {label='spacer2D',layout='d3q19',relaxation='bgk', kind = 'lbm_incomp'}


-- Boundary conditions
boundary_condition = {  
 { label = 'south', 
  kind = 'wall'} 
,{ label = 'north', 
   kind = 'wall'} 
,{ label = 'inlet', 
   kind = 'inlet_ubb', 
   order = 1,
   velocity = { predefined = 'combined',
                temporal= {predefined='smooth', min_factor = 0.0, max_factor=u_max_phy, 
                           from_time=0, to_time=1000*dt
                }, 
                spatial = {predefined='parabol', 
                           shape = { kind = 'canoND', object = { origin={0.0,0.0,0.0},
                                                                 vec={0.0,h_ch,0.0}}
                                   },
                          amplitude = {1.0,0.0,0.0}         
               }         
	      },
 }
,{ label = 'outlet', 
   kind = 'outlet_expol',
   pressure = 1.0}
,{ label = 'spacer', 
   kind = 'wall'}
}



-- Tracking              
--tracking = {
--{
--  label = 'harvester', 
--  folder = tracking_fol,
--  variable = {{'density'},{'velocity'},{'shearstress'}}, 
--  shape = {kind = 'all' },
--  time_control = {min = tmax_p},
--  format = 'harvester'      
--},
--
--{ label = 'convergence',
--  variable = {{'pressure_phy'}}, 
--  shape = {kind = 'canoND', object= {origin ={l_ch/2.0,h_ch/2.0,w_ch/2.0},
--				     vec={{0.0,h_ch,0.0},{0.0,0.0,w_ch}} ,
--				     segments = {nHeight, nWidth} } },
--  time_control = {min = 0, max = tmax_p, interval = {iter=10}},
--  format='convergence',
--  convergence = {norm='average', nvals = 50, absolute = true,
--  condition = { threshold = 1.e-8, operator = '<=' }}
--}
--
--}
--
----tracking time_control
--trac_time = {min = 0, max= tmax_p, interval = {iter=100}}
--
-- --   table.insert(tracking, {label='line_pressure_',
--   --                         folder=tracking_fol,
--     --                       variable={{'pressure_phy'}},
--       --                     shape = {kind='canoND', object={origin={l_m,h_ch/2.0,w_ch/2.0},
--         --                                                  vec={{l_ch,0.0,0.0}},
--           --                                                segments = {nHeight, nWidth}}},
--             --               time_control = trac_time,
--               --             format = 'asciiSpatial'})
--
--
--if nFilament >= 2 then
--  for i = 1, nFilament  do
--    table.insert(tracking, {label='av_pressure_'..i,
--                            folder=tracking_fol,
--                            variable={{'pressure_phy'}},
--                            shape = {kind='canoND', object={origin={l_m*i,0.0,0.0},
--                                                           vec={{0.0,h_ch,0.0},{0.0,0.0,w_ch}},
--                                                           segments = {nHeight, nWidth}}},
--                            reduction = 'average',
--                            time_control = trac_time,
--                            format = 'asciiSpatial'})
--
--
--    table.insert(tracking, {label='planeReduction_'..i,
--                            folder=tracking_fol,
--                            variable={{'velMag_phy'}},
--                            shape = {kind='canoND', object={origin={l_m*i,0.0,0.0},
--                                                           vec={{0.0,h_ch,0.0},{0.0,0.0,w_ch}},
--                                                           segments = {nHeight, nWidth}}},
--                            reduction = 'average',
--                            time_control = trac_time,
--                            format = 'asciiSpatial'})
--
--
--    table.insert(tracking, {label='probe_w2_'..i,
--                            folder=tracking_fol,
--                            variable={{'pressure_phy'},{'velocity_phy'},{'velMag_phy'}},
--                            shape = {kind='canoND', object={origin={l_m*i,h_ch/2.0,w_ch/2.0}},
--							    vec={{0.0,h_ch,0.0},{0.0,0.0,w_ch}},
--							    segments = {nHeight,nWidth}},
--                            time_control = trac_time,
--                            format = 'ascii'})
--
----    for j = 1, 8, 2 do
--  --    table.insert(tracking, {label='probe_'..j..'w8_'..i,
--    --                          folder=tracking_fol,
--      --                        variable={{'pressure'},{'velocity'},{'velMag'}},
--        --                      shape = {kind='canoND', object={origin={2*l_m*i,h_ch/2.0,j*w_ch/8.0}}},
--          --                    time_control = trac_time,
--            --                  format = 'ascii'})
----    end                          
--  end
--end  
--           
--
---- restart 
--restart = {
--      ead = restart_fol..'/spacer_lastHeader.lua',
--      write = restart_fol,
--      time_control = { min = tmax_p}
--}



