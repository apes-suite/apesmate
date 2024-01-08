-- Use the configuration of the original simulation run.

--write the name of your ateles config-file
require 'ateles_right_visu'
logging = {level = 10}

-- Set the restart data to harvest.
restart.read = 'restart/right/ateles_right_header_120.000E-03.lua'

-- Subsampling
--set the refinement level for your vtks
ply_sampling = { nlevels = 4,
                 method = 'adaptive',
                 dof_reduction = 1.0 }

-- Example tracking to generate vtk file:
tracking = {
  { label = 'visu_right',
    variable = {'pressure', 'velocity', 'density'},
    shape = {kind='all'},
    folder = 'harvester/',
    output = {format = 'vtk', write_pvd=false , iter_filename=true}
  }
}
