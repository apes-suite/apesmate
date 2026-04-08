require 'args'

---------------- General parameters -------------------
simulation_name = 'stenosis'
if_print = false
---------------- General parameters -------------------
---
---
------------------- Geoemtric parameter -------------------
length = 16 -- mm, set length for the bounding box
diameter = 1 -- (-0.2 ~ 0.3) at stenosis
mesh_level = 1
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
-- Time point to start the coupled simulation, in unit of iteration,
--   set to 0 for starting from the beginning
time_point         = 107000

tstart             = 0 + time_point
tmax               = 10000 + time_point
interval           = 500

-- The time setup for steady flow ran by standalone Musubi solver.
-- It targets to reach the steady state before the coupled simulation starts.
-- tstart = 0
-- interval = 1000
-- tmax = 10000
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