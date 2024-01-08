 format = 'ascii'
 solver = 'ATELES_v0.4'
 simname = 'ateles_lineuler'
 basename = './ateles_lineuler_point'
 glob_rank = 0
 glob_nprocs = 1
 sub_rank = 0
 sub_nprocs = 1
 resultfile = './ateles_lineuler_point_p*'
 nDofs = 1
 nElems = 1
 use_get_point = true
 nPoints = 1
 time_control = {
    min = {
        sim =    0.000000000000000E+00 
    },
    max = {
        sim =  250.000000000000000E-03 
    },
    interval = {
        sim =   10.000000000000000E-03 
    },
    check_iter = 1 
}
 shape = {
    {
        canonicalND = {
            {
                origin = {  562.500000000000000E-03,    0.000000000000000E+00,   31.250000000000000E-03 },
                distribution = 'equal' 
            } 
        } 
    } 
}
 varsys = {
    systemname = 'LinearEuler2d',
    variable = {
        {
            name = 'density',
            ncomponents = 1,
            state_varpos = { 1 } 
        },
        {
            name = 'velocity',
            ncomponents = 2,
            state_varpos = { 2, 3 } 
        },
        {
            name = 'pressure',
            ncomponents = 1,
            state_varpos = { 4 } 
        },
        {
            name = 'full_density',
            ncomponents = 1 
        },
        {
            name = 'full_velocity',
            ncomponents = 2 
        },
        {
            name = 'full_pressure',
            ncomponents = 1 
        } 
    },
    nScalars = 8,
    nStateVars = 6 
}
