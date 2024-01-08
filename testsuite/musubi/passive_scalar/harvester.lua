simulation_name = 'pipe'

input   = { read = 'tracking/pipe_ps_spc1_pipe_ps_lastHeader.lua' }

NOtracking  = { 
  label     = 'all', 
  output    = { format = 'vtk'}, 
  variable  = { 'spc1_density'}, 
  shape     = { kind='all'  },
  folder    = 'harvest/',
}

output = { 
  folder = 'harvest/', 
  {format = 'VTU'}
}  
