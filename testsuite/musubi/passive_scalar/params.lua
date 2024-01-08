--Dimensions and refinement level
length      = 5.5                --cm
dx          = 0.0128              --cm
nLength     = length/dx 
level       = math.ceil(math.log(nLength)/math.log(2))
length_bnd  = (2^level)*dx
Dia         = 1.0                 --cm
Dia_L       = Dia/dx
radius      = Dia/2.0             --cm

--Physical parameters
mu_phy      = 5e-6*(math.pi)      --kg/cm/s
rho_phy     = 2250e-6             --Kg/cm^3
uc          = mu_phy/rho_phy  --cm/s 
umax        = uc*166.2854         --cm/s
nu_phy      = mu_phy/rho_phy      --cm2/s   

Re          = (Dia*uc)/nu_phy

--Lattice parameters with diffusive scaling
omega       = 1.85
nu_L        = (1.0/omega-0.5)/3.0
dt          = nu_L*dx^2/nu_phy
u_mean_L    = uc*dt/dx
u_in_L      = 2.0*u_mean_L

--Lattice pressure is cs^2*rho_L = 1./3.
press_phy   = 1.0*rho_phy*(dx^2)/(3*dt^2)
press_phy   = 1000
Re_L        = (Dia_L*u_mean_L)/nu_L

--BC
bc_origin = { -length/2.0-4*dx, -0.5-4*dx, -0.5-4*dx } 
bc_length = length + 8*dx
seed_orig = { 0., 0., 0. }
