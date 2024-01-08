-- all units are in physical units
-- length (m)
-- mesh info
-- length of the diffusion tube
scale = 1e-0
height =  0.4e-3*scale
l_h = 5
length = l_h*height

-- Mesh info
nHeight = math.ceil(64)
nLength = nHeight*l_h 
dx = height/nHeight
nLength_bnd = nLength+2
level = math.ceil(math.log(nLength_bnd)/math.log(2))
length_bnd = (2^level)*dx
dx_half = dx*0.5
zpos = dx_half

-- simulation params
rho0_p = 1025 --kg/m^3
-- density
rho0_l = 1.0 
--dynamic viscosity
mu = 1.08e-3 --Pa s
--kinematic viscosity
nu_phy = mu / rho0_p  --m^2/s

-- molecular weights
mH2O = 18.01528e-3 -- H20
mNa = 22.98977e-3 -- Na
mCl = 35.4527e-3  -- Cl
m_min = math.min(mH2O,mNa,mCl)
-- specific charge
charge_nr_H2O = 0.0
charge_nr_Na = 1.0
charge_nr_Cl = -1.0

-- diffusivities
-- diagonals are not important
-- largest diffusivities
fac = 1e0
diff_diag = 1.0e-9
diff_H2O_Na = 1.31570699e-9*fac
diff_H2O_Cl = 2.097388e-9*fac
diff_Na_Cl = 2.95407e-11*fac

resi_diag = 1.0/diff_diag
resi_H2O_Na = 1.0/diff_H2O_Na
resi_Na_Cl = 1.0/diff_Na_Cl
resi_ref = resi_Na_Cl
resi_ref = resi_H2O_Na
-- lattice resistivity
resi_latt = 5.0

-- max velocity
u_max_phy = 0.1 --m/3
u_mean_phy = u_max_phy*2.0/3.0 --m/s
deltaP = u_max_phy*length*rho0_p*nu_phy / (height*height)

Re = u_mean_phy*height/nu_phy

-- time step size 
dt = (resi_ref/resi_latt)*dx*dx
--omega
omega_diff = 2.0
--omega_kine = 2.0
--nu_L = (1.0/(3.0*omega_kine))
--dt = nu_L*dx^2./nu_phy
nu_L = nu_phy * dt / dx^2
omega_kine = 1.0/(3.0*nu_L)
u_max_L = u_max_phy*dt/dx
u_mean_L = 2.0*u_max_L/3.0
Re_l = u_mean_L*nHeight/nu_L
print('dt =', dt)
print('u_max_L ',u_max_L)

tmax_p = 0.2*scale
t_ramp = 0.0--0.025*scale

-- pressure in vapor phase
pressure = 99.4e3 --Pa (N/m^2)
-- Temperature in vapor phase
temp = 328.5 --K

--concentration of sea water
--salinity of sea water = 35
--http://en.wikipedia.org/wiki/Seawater
conc_H2O = 53.6*rho0_p --mol/m^3
conc_Na = 0.5*rho0_p --0.469*rho0_p --mol/m^3
conc_Cl = 0.5*rho0_p --0.546*rho0_p --mol/m^3
moleDens0 = conc_H2O+conc_Na+conc_Cl
--print(conc_H2O,conc_Na,conc_Cl,moleDens0)
---- mole fraction
moleFrac_H2O = conc_H2O/moleDens0
moleFrac_Na = conc_Na/moleDens0
moleFrac_Cl = conc_Cl/moleDens0
--print(moleFrac_H2O,moleFrac_Na,moleFrac_Cl)

--moleDens0 = 100  -- mol/m^3
--moleFrac_Na = 0.009
--moleFrac_Cl = 0.009
----moleFrac_Na = 1/3.
----moleFrac_Cl = 1/3.
--moleFrac_H2O = 1.0 - (moleFrac_Na+moleFrac_Cl)
--print(moleFrac_H2O,moleFrac_Na,moleFrac_Cl)
---------------------------------------
-- Initial condition for taylor dispersion
---------------------------------------
--smallness parameter
tau = 0.0001

function IC_pressure(x,y,z)
  return rho0_p*(-deltaP*x/length + deltaP)
end

function IC_velocity(x,y,z)
  return 4.0*u_max_phy*y*(height-y)/height^2.0
end

function BC_velocity(x,y,z)
  return {4.0*u_max_phy*y*(height-y)/height^2.0,0.0,0.0}
end

function IC_Na(x,y,z)
  return moleFrac_Na--tau
end

function BC_Na(x,y,z,t)
  if t>t_ramp then
    return moleFrac_Na
  else
    return tau 
  end  
end

function IC_Cl(x,y,z)
  return moleFrac_Cl--tau
end

function BC_Cl(x,y,z,t)
  if t>t_ramp then
    return moleFrac_Cl
  else
    return tau  
  end  
end


function IC_H2O(x,y,z)
  na = IC_Na(x,y,z)
  cl = IC_Cl(x,y,z)
  return 1.0 - na - cl
end

function BC_H2O(x,y,z,t)
  na = BC_Na(x,y,z,t)
  cl = BC_Cl(x,y,z,t)
  return 1.0 - na - cl
end

velocity = { predefined = 'combined',
             NOtemporal = {predefined='smooth', min_factor = 0.0, 
                          max_factor=1.0, from_time=0, to_time=t_ramp}, 
             spatial = BC_velocity
	    }

electric_field_external = 0.0--1e-4
function electric_force(x,y,z,t)
  if t>t_ramp then
    return {0.0,electric_field_external,0.0}
  else
    return {0.0,0.0,0.0}
  end
end
