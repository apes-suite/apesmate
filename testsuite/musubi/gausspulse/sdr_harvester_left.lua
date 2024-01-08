simulation_name = 'gausspulse'

mesh = 'mesh_left/'
tracking = {
  label = 'vtk',
  folder = 'mesh_left/',
  variable = {'process','treeid'},
  shape = {kind='all'},
  output={format ='vtk'}
}
