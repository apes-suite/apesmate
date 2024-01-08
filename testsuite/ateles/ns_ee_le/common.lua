--Important parameter for physical testcase************
----------- from seeder ------------------------------!
cubeLength = 64.0
level = 8
-- the largest element
elemsize = cubeLength/(2^level)
eps = cubeLength/(2^(11))

-----------physial parameter--------------------------!
--material
gamma = 1.4
r = 280.0
therm_cond = 1.4e-4
mu = 1.0e-7
ip = 4.0

press = 1.0
dens = 1.4
velocityX = 0.0
velocityY = 0.0
mach = 0.4
-- the velocity amplitude in x direction
velAmpl = mach*math.sqrt(gamma*press/dens) 
densAmpl = 2.0

jet_radius = 0.1
jet_center = 1e-4
momentum_thickness = jet_radius/20

------------------ function ------ --------------------!
function tanh(x)
nu = 1 - math.exp(-2*x)
de = 1 + math.exp(-2*x)
return nu/de
end

function velX_inlet(x,y,z,t)
  if ( y < -2 or y > 2 ) then 
    return 0
  else
    r = math.sqrt( (y-jet_center)*(y-jet_center) )
    return velAmpl * (1/2) * ( 1 +  tanh((jet_radius-r)/(2*momentum_thickness) ) )
  end
end 

function dens_inlet(x,y,z,t)
  if ( y < -2 or y > 2 ) then 
    return dens
  else
    tmpVel = velX_inlet(x,y,z,t)/velAmpl
    return densAmpl / ( 1 + (gamma-1)/2*mach*mach*tmpVel*(1-tmpVel)  )
  end
end

-----------simulation parameter ----------------------!
filter_order = 10
filter_order_le = 16
adaptive=true
damp_factor = 0.125
dt = 1.5e-4
tmax = 500.0
track_dt= 0.5

--------physical check -------------------------------!
check = { interval = 1 }

---------generel simulation parameter------------------!

sim_control = {
  time_control  = {
    min = 0.0,
    max = {iter=1000}, 
--    interval = { iter=10000 },
  },
}

-- ...the general projection table
projection = {
  kind = 'fpt',  
  factor = 1.0,          
}

