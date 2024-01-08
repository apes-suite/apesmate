simulation_name = 'gausspulse'

mesh = 'mesh_right/'
--output={format ='vtk'}
--output_folder = 'mesh_right/'
tracking = {
  label = 'vtk',
  folder = 'mesh_right/',
  variable = {'process','treeid'},
  shape = {kind='all'},
  output={format ='vtk'}
}
