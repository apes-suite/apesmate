---- testcase setup------------------------------------------------------------
gamma      = 1.4
r          = 280.0
therm_cond = 0.015625
mu         = 1.0e-6
ip_param   = 4.0

dens = 1.0
velX = 0.0
velY = 0.0
velZ = 0.0
press = 1/gamma
c = math.sqrt(gamma* press / dens)
gp_center = {0.0, 0.0, 0.0}
gp_halfwidth = 0.25
gp_amplitude = 1.0
gp_background = press
gp_c = c

dt = 1.0e-3

-----simulation setup-----------------------------------------------------------
logging = {level=1}
timestep_info = 1
check =  { interval = 1 }
tmax = 0.8
sim_control = {
  time_control = {
    min = 0,
    max = tmax,
    interval = {iter = 10}, -- final simulation time
  }
}
-- the general projection table --
projection = {
  kind = 'l2p',
  factor = 1.0,
}

