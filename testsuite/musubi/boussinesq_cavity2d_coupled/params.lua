require "args"
---------------- General parameters -------------------
simulation_name = 'cavity2d'
tracking_folder = './tracking/'
if_print = false
---------------- General parameters -------------------
---
---
------------------- Geoemtric parameter -------------------
mesh_level = 0
resolution = 2 ^ mesh_level

dx          = 0.01 / resolution
dx_eps = dx/2^20
nLength     = 2 / dx 
level       = math.ceil(math.log(nLength)/math.log(2))
length_bnd  = (2^level)*dx -- real length of the bounding box
--BC
bc_origin = { -2*dx, -2*dx, -5*dx-dx/2 } 
bc_length = length_bnd
seed_orig = { 0.5, 0.5, 0 }
---------------- Geoemtric parameter -------------------
---
---
------------------- Physical and lattice parameters -------------------
Pr = 0.71   -- Prantel number
Ra = 10^Ra_factor   -- Rayleigh number
tau_f = 0.6
tau_g = (tau_f - 0.5) / Pr + 0.5
Pr_L = (tau_f - 0.5) / 3    -- Prantel number in lattice unit
dt = Pr_L * dx^2 / Pr

if if_print then
    print("tau_g = "..tau_g)
    print("dt = "..dt)
end
------------------- Physical and lattice parameters -------------------
---
---
-------------------- Lattice pressure ---------------------
rho_phy = 1.
press_ref   = rho_phy*(dx^2)/(3.*dt^2)  -- kg/(mm*s^2)
press_phy   = 0.+press_ref
press_phy_low = 0.01 * press_phy
if if_print then
    print("press_ref = "..press_ref)
    print("press_phy_low = "..press_phy_low)
end
-------------------- Lattice pressure ---------------------
---
---
------------------- Iteration parameters -------------------
tstart             = 0
tmax               = 5000 * dt
interval           = 5000 * dt
------------------ Iteration parameters -------------------
