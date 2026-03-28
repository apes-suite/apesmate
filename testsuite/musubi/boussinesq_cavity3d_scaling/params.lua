require "args"
---------------- General parameters -------------------
simulation_name = 'cavity3d'
tracking_folder = './tracking/'
if_print = false
log_level = 0
---------------- General parameters -------------------
---
---
------------------- Geoemtric parameter -------------------
dx          = 1 / num_lattices
dx_eps = dx/2^20
nLength     = num_lattices
level       = math.ceil(math.log(nLength)/math.log(2))
length_bnd  = 1 -- real length of the bounding box
--BC
bc_origin = { 0, 0, 0 } 
bc_length = length_bnd
seed_orig = { 0.5, 0.5, 0.5 }
---------------- Geoemtric parameter -------------------
---
---
------------------- Physical and lattice parameters -------------------
Ra_factor = 5
Pr = 0.71   -- Prantel number
Ra = 10^Ra_factor   -- Rayleigh number
u_max = 68.59
u_L = 0.05
dt = dx * u_L / u_max 
Pr_L = Pr * dt / (dx^2)
tau_f = 3 * Pr_L + 0.5
tau_g = (tau_f - 0.5) / Pr + 0.5
if if_print then
    print("tau_g = "..tau_g)
    print("tau_f = "..tau_f)
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
interval           = 100 * dt
------------------ Iteration parameters -------------------
