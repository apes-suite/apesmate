--mesh parameters
--height of the spacer channel
h_ch = 0.4e-3 --m
--diameter of the spacer filament
d_f = h_ch*0.5
--radius of the filament
r_f = d_f*0.5
--mesh_length to height ratio
lm_hsp = 2.5
--mesh length or distance between spacer filament
l_m = h_ch*lm_hsp
--number of spacer filament in x-direction
nFilament = 2.0
--length of the channel
l_ch = l_m*nFilament
--width of the channel
w_ch = l_m*2.0
--Height of the channel in lattice unit/number of elements along the height
nHeight = 16
--discretization size
dx = h_ch/nHeight
dx_half = dx*0.5
--Find refinement level required for this dx
nLength = math.ceil(l_ch/dx)
nWidth = math.ceil(w_ch/dx) 
nLength_bnd = nLength+2
level = math.ceil(math.log(nLength_bnd)/math.log(2))
length_bnd = (2^level)*dx

-- Flow parameter
--compute hydralic diameter
voidage = 1.0 - (math.pi*d_f^2.0/(2.0*l_m*h_ch))
d_h = 4.0*voidage/(2./h_ch + (1.0-voidage)*(4.0/d_f))
--density of pure water
--taken from "Perry Handbook of chemical engineering"
rho0_p = 998.2071 --kg/m^3
--dynamic viscosity
mu = 1.08e-3 --Pa s
--kinematic viscosity
nu_phy = mu / rho0_p  --m^2/s
u_mean_phy = 0.05 --m/s
u_max_phy = u_mean_phy*3.0/2.0 --m/s

--nElements on filement diameter
nL = math.ceil(d_f/dx)
--nElements on hydralic diameter
nL_h = math.ceil(d_h/dx)
--Reynolds number
Re = d_h*u_mean_phy/nu_phy
-- acoustic scaling
u_max_L = 0.04
dt = u_max_L*dx/u_max_phy
u_mean_L = 2.0*u_max_L/3.0
nu_L = nu_phy*dt/dx^2.
omega = 1.0/(3.0*nu_L+0.5)


seedPoint = {l_m,d_f,w_ch/2.0} 

nSteps = math.ceil(1./dt*2)

