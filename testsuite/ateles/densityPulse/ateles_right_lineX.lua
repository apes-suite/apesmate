 format = 'asciispatial'
 solver = 'ATELES_v0.4'
 simname = 'ateles_right'
 basename = './ateles_right_lineX'
 glob_rank = 0
 glob_nprocs = 1
 sub_rank = 0
 sub_nprocs = 1
 resultfile = './ateles_right_lineX_p*'
 nDofs = 1
 nElems = 4
 use_get_point = true
 nPoints = 299
 time_control = {
    min = {
        sim =    0.000000000000000E+00,
        iter = 0 
    },
    max = {
        iter = 2000 
    },
    interval = {
        iter = 2000 
    },
    check_iter = 1 
}
 shape = {
    {
        canonicalND = {
            {
                origin = {    0.000000000000000E+00, -125.000000000000000E-03,    0.000000000000000E+00 },
                vec = {
                    {  250.000000000000000E-03,    0.000000000000000E+00,    0.000000000000000E+00 } 
                },
                segments = {
                    300 
                },
                distribution = 'equal' 
            } 
        } 
    } 
}
 varsys = {
    systemname = 'euler_2d_conservative',
    variable = {
        {
            name = 'density',
            ncomponents = 1,
            state_varpos = { 1 } 
        },
        {
            name = 'ref_density',
            ncomponents = 1 
        },
        {
            name = 'error',
            ncomponents = 1 
        } 
    },
    nScalars = 3,
    nStateVars = 3 
}
