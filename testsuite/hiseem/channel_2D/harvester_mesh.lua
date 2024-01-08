simulation_name = 'taylorDispersion'

-- define the input
mesh = 'mesh/'

-- define the output
tracking = {
    label = 'vtk',
    variable = {
                'treeid'
                },
    folder='mesh/',
    shape = {kind='all'},
    output={format='vtk'},
}
