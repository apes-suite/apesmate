simulation_name = 'channel2D'

-- define the input
mesh = 'mesh_atl/'

ply_sampling = {nlevels=3}
-- define the output
tracking = {
    label = 'vtk',
    variable = {
                'treeid'
                },
    folder='mesh_atl/',
    shape = {kind='all'},
    output={format='vtk'},
}
