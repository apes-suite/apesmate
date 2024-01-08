useObstacle = true 
height =  0.41
nHeight = 50--os.getenv("nHeight")
l_h = 5--os.getenv("l_h")
nLength = nHeight*l_h 
dx = height/nHeight
length = nLength*dx
--length = 2.2
nLength_bnd = 2*nLength+4
--nLength = 200
--dx = length_bnd/(2^level)
--dx_ini = length/nLength 
level = math.ceil(math.log(nLength_bnd)/math.log(2))
length_bnd = (2^level)*dx
--level = 9
--dx = length_bnd/2^level
--nLength = math.ceil((length)/dx)
--nHeight = math.ceil((height)/dx)
dx_half = dx*0.5
zpos = dx_half
sph_pos = {0.2,0.2,zpos}
radius = 0.05
Dia = radius*2.0

--flow parameters
Re = 100
nu_phy = 1e-3 --m^2/s
rho0_p = 1000.0
u_mean_phy = Re*nu_phy/Dia
u_in_phy = 3.0*u_mean_phy/2.0

nL = math.ceil(Dia/dx)
Re_check = u_mean_phy*Dia/nu_phy
-- set true for acoustic scaling, false for diffusive scaling
acoustic_scaling = false
rho0_l = 1.0
cs2_l = 1./3.
p0_l = rho0_l*cs2_l
if acoustic_scaling == true then
--acoustic scaling
  u_in_L = 0.05--os.getenv('u_in_L')
  dt = u_in_L*dx/u_in_phy
  u_mean_L = 2.0*u_in_L/3.0
  nu_L = nu_phy*dt/dx^2.
  omega = 1.0/(3.0*nu_L+0.5)
else
--diffusive scaling
  omega = 1.9--os.getenv('omega')
  nu_L = (1.0/omega-0.5)/3.0
  dt = nu_L*dx^2/nu_phy
  u_in_L = u_in_phy*dt/dx
  u_mean_L = 2.0*u_in_L/3.0
end

press_p = rho0_p*dx^2/dt^2
p0_p = press_p--*cs2_l
p0_p = 0
--print (press_p, dx^2,dt^2,dx^2/dt^2)

function u_inflow(x,y,z,t) 
  return 4.0*u_in_phy*y*(height-y)/height^2.0
end

tmax = 10 -- real time in seconds
