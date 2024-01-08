-- commen file for coupled simulation


-- numerical method
filter_order = 24

-- for tracking
tmax = 1.0
track_dt = 0.005

-- ...the general projection table
projection = {
  kind = 'l2p',
  factor = 1.0,
}

-- physical state
dens = 1.0
press = 8.0
velocityX = 2.0

-- reference solution and initial condition
function gauss (x,y,z,t)
x0 = velocityX * t - 1 -- shifted by 1 to the left 
d = (x-x0)*(x-x0)+y*y 
return( dens + 1.0* math.exp(-d/0.02*math.log(2)) )
end 

function ic_gauss (x,y,z)
return( gauss(x,y,z,0.0) )
end 

-- Check for Nans and unphysical values
check =  {
           interval = 1,
         }

timestep_info = 1
