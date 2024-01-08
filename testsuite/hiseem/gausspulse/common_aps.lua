-- all units are in physical units
-- length (m)
-- mesh info
-- length of the diffusion tube
scale = 1e-0
height =  0.4e-3*scale
l_h = 1
length = l_h*height

-- Mesh info
originX = -length*0.5
originY = -length*0.5
originZ = -length*0.5

-- simulation params
--https://en.wikipedia.org/wiki/Seawater
rho0_p = 1025 --kg/m^3
-- density
rho0_l = 1.0 
--dynamic viscosity
mu = 1.08e-3 --Pa s
--kinematic viscosity
nu_phy = mu / rho0_p  --m^2/s

-- Material info
permea_0 = 1.2566e-6 --N/A-2 permeability of vaccum
rel_permea_water = 0.99
permea = permea_0 * rel_permea_water
permit_0 = 8.854e-12 -- F/m or C/(Vm)Permittivity of vaccum
--http://chemistry.stackexchange.com/questions/16434/
--salt-concentration-and-electrical-permittivity-of-water
rel_permit_water = 45
permit = permit_0 * rel_permit_water
gam = 1.0
chi = 1.0

-- molecular weights
mH2O = 18.01528e-3 -- kg/mol
mNa = 22.98977e-3 -- kg/mol
mCl = 35.4527e-3  -- kg/mol
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
resi_latt = 2500.0

-- max velocity
u_mean_phy = 0.02 --m/3

Re = u_mean_phy*height/nu_phy

tmax_p = scale*0.1
t_ramp = 0.0--0.025*scale

-- pressure in vapor phase
pressure = 99.4e3 --Pa (N/m^2)
-- Temperature in vapor phase
temp = 328.5 --K

--concentration of sea water
--salinity of sea water = 35
--http://en.wikipedia.org/wiki/Seawater
--http://www.lenntech.com/composition-seawater.htm
--conc_Na = 10.556*1e-3/mNa  --mol/m^3
--conc_Cl = 18.980*1e-3/mCl  --mol/m^3
salinity = 34.5*0.1 -- kg/m^3
conc_Na = salinity/(mNa+mCl)  --mol/m^3
conc_Cl = salinity/(mNa+mCl)  --mol/m^3
conc_H2O = (rho0_p-salinity)/mH2O --mol/m^3
moleDens0 = conc_H2O+conc_Na+conc_Cl
--print(conc_H2O,conc_Na,conc_Cl,moleDens0)
---- mole fraction
moleFrac_H2O = conc_H2O/moleDens0
moleFrac_Na = conc_Na/moleDens0
moleFrac_Cl = conc_Cl/moleDens0
--print(moleFrac_H2O,moleFrac_Na,moleFrac_Cl)

--moleDens0 = 100  -- mol/m^3
--moleFrac_Na = 0.09
--moleFrac_Cl = 0.09
--moleFrac_H2O = 1.0 - (moleFrac_Na+moleFrac_Cl)
--print(moleFrac_H2O,moleFrac_Na,moleFrac_Cl)
---------------------------------------
-- Initial condition for gauss pulse
---------------------------------------
--smallness parameter
tau = 0.0001

originX_1 = length/8.0
originX_2 = 0.
originY_2 = .0
originZ_2 = .0
pulse_size = length/10.
halfwidth = pulse_size
amplitude = 0.0001
background = tau

function ic_1Dgauss_pulse(x, y, z, t)
  r = (x-originX_1)^2
  return background+amplitude*math.exp(-0.5/(halfwidth^2)*r)
end
function ic_2Dgauss_pulse(x, y, z, t)
  r = ( x - originX_2 )^2+( y - originY_2 )^2
  return background+amplitude*math.exp(-0.5/(halfwidth^2)*r)
end

function IC_velocity(x,y,z)
  return 0.0--u_mean_phy--4.0*u_max_phy*y*(height-y)/height^2.0
end

function BC_velocity(x,y,z)
  return {4.0*u_max_phy*y*(height-y)/height^2.0,0.0,0.0}
end

function IC_Na(x,y,z)
  r = ( x - originX_2 )^2+( y - originY_2 )^2
  --r = ( y - originY_2 )^2
  return tau+moleFrac_Na*math.exp(-0.5/(halfwidth^2)*r*math.log(2))
end

function IC_Cl(x,y,z)
  r = ( x - originX_2 )^2+( y - originY_2 )^2
  --r = ( y - originY_2 )^2
  return tau+moleFrac_Cl*math.exp(-0.5/(halfwidth^2)*r*math.log(2))
end

function IC_H2O(x,y,z)
  na = IC_Na(x,y,z)
  cl = IC_Cl(x,y,z)
  return 1.0 - na - cl
end

function IC_H2O_2Spc(x,y,z)
  na = IC_Na(x,y,z)
  return 1.0 - na
end

velocity = { predefined = 'combined',
             NOtemporal = {predefined='smooth', min_factor = 0.0, 
                          max_factor=1.0, from_time=0, to_time=t_ramp}, 
             spatial = BC_velocity
	    }

electric_field_external = 1e-5
function electric_force(x,y,z,t)
  if t>t_ramp then
    return {0.0,electric_field_external,0.0}
  else
    return {0.0,0.0,0.0}
  end
end

-- Source term definition, i.e. in Maxwell equations we are talking about 
-- space charges and Source term

-- current densities. In general they can depend on spatial coordinates and time.
function currentDensitySpaceTime(x, y, z, t)
  return {0.0, 0.0, 0.0}
end

function chargeDensitySpaceTime(x,y,z,t)
  r = ( x - originX_2 )^2+( y - originY_2 )^2
  return tau*math.exp(-0.5/(halfwidth^2)*r*math.log(2))
  --if r <= halfwidth^2.0 then
  --  return 0.001
  --else
  --  return 0.0
  --end
end


