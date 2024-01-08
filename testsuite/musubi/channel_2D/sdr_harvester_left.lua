simulation_name = 'channel2D'

mesh = 'mesh_left/'
tracking = {
  label = 'vtk',
  folder = 'mesh_left/',
  variable = {'process','treeid'},
  shape = {kind='all'},
  output={format ='vtk'}
}
