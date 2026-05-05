require 'args'

---------------- General parameters -------------------
simulation_name = 'stenosis'
-- tracking_folder = './tracking_1/'
if_print = false
---------------- General parameters -------------------
---
---
------------------- Geoemtric parameter -------------------
length = 16 -- mm, set length for the bounding box
diameter = 1 -- (-0.2 ~ 0.3) at stenosis
mesh_level = 2
resolution = 2 ^ mesh_level

pts_dia = 32 -- number of points on diameter
dx          = diameter / pts_dia / resolution     -- mm
dx_eps = dx/2^20
nLength     = 2 * length / dx 
level       = math.ceil(math.log(nLength)/math.log(2))
length_bnd  = (2^level)*dx -- real length of the bounding box
--BC
bc_origin = { -8-4*dx, -1-4*dx, -1-4*dx } 
bc_length = length_bnd
seed_orig = { 0, 0, 0 }
---------------- Geoemtric parameter -------------------
---
---
------------------- Iteration parameters -------------------
time_point         = 0
tstart             = 0
tmax               = 400000
interval           = 5000

time_point = tmax
tstart = tmax
interval = 500 * 2
tmax = tstart + 22000
------------------ Iteration parameters -------------------
---
---
------------------- Physical parameters -------------------
Re = 5
rho_phy     = 1.121e-6     -- kg/mm^3
mu_phy      = 1.5e-6      -- kg/(mm*s)
nu_phy      = mu_phy/rho_phy
u_ave       = Re * nu_phy / diameter -- mm/s

if if_print then
    print("u_ave = "..u_ave)
end
------------------- Physical parameters -------------------
---
---
---------- Lattice parameters with diffusive scaling -----------
tau = 0.8
nu_L        = (tau-0.5)/3.0
dt          = nu_L*dx^2/nu_phy
u_L = u_ave * dt / dx
if if_print then
    print("dt = "..dt)
    print("u_L = "..u_L)
end

-- tau_D = 0.55
-- D_L = (tau_D - 0.5) / 3.0
-- D = D_L * dx^2 / dt
-- if if_print then
--   print("D = "..D)
--   print("tau_D = "..tau_D)
-- end
----------- Lattice parameters with diffusive scaling -----------
---
---
-----Lattice pressure is cs^2*rho_L = 1./3.
press_ref   = rho_phy*(dx^2)/(3.*dt^2)  -- kg/(mm*s^2)
press_phy   = 0.+press_ref
dia_L = diameter / dx
Re_L        = (dia_L*u_L)/nu_L
if if_print then
  print("Re_L = "..Re_L)
end
