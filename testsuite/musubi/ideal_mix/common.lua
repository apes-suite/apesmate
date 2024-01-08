useObstacle = true 
height =  50.0e-9
nHeight = 256
l_h = 1
nLength = 1--nHeight*l_h 
offset = height/2.0
dx = height/nHeight
length = nLength*dx
nLength_bnd = math.max(nHeight,nLength)+2
level = math.ceil(math.log(nLength_bnd)/math.log(2))
length_bnd = (2^level)*dx
dx_half = dx*0.5
zpos = dx_half

-- Simulation parameters
--rho0_p = 1e3 --kg/m^3
---- density
--rho0_l = 1.0 
----kinematic viscosity
--nu_phy = 1e-6 --m^2/s
----dynamic viscosity
--mu = nu_phy*rho0_p --Pa s
-- Properties of sea water at 20C and 35g/kg salinity
rho0_p = 1025 --kg/m^3
mu = 1.08e-3 --Pa s
nu_phy = mu / rho0_p  --m^2/s

-- molecular weights
mH2O = 18.01528e-3 -- H20
mNa = 22.98977e-3 -- Na
mCl = 35.4527e-3  -- Cl
--avg_m = (mNa+mCl)/2.0
--mNa = avg_m
--mCl = avg_m
m_max = math.max(mH2O,mNa,mCl)
m_min = math.min(mH2O,mNa,mCl)
-- specific charge
charge_nr_H2O = 0.0
charge_nr_Na = 1.0
charge_nr_Cl = -1.0

conc_NaCl = 100 -- Molarity * 1e3
-- diffusivities
-- diagonals are not important
-- largest diffusivities
fac = 1e0
diff_diag = 1.0e-9*fac
diff_H2O_Na = 1e-9*fac--1.31570699e-9*fac
diff_H2O_Cl = 1e-9*fac--2.097388e-9*fac
diff_Na_Cl = 1e-11*fac--2.95407e-11*fac
diff_H2O_Na = 1.31570699e-9*fac
--diff_H2O_Cl = diff_H2O_Na--2.097388e-9*fac
diff_H2O_Cl = 2.097388e-9*fac
diff_Na_Cl = 2.95407e-11*fac

function diff_coeff(conc, p1, p2, p3, p4, p5)
  return p1 + p2 * conc + p3 * conc^1.5 + p4 * conc^2 + p5 * conc^0.5
end
diff_H2O_Na = diff_coeff(conc_NaCl, 1.34e-9, -3.06e-14, -3.91e-15, 3.77e-17, -1.77e-12)
diff_H2O_Cl = diff_coeff(conc_NaCl, 2.04e-9, -2.24e-13, -3.79e-15, 3.78e-17, 8.32e-12)
diff_Na_Cl = diff_coeff(conc_NaCl, 0, 8.02e-14, -2.09e-16, -7.03e-18, 2.18e-12)
--print('Diff_coef:', diff_H2O_Na, diff_H2O_Cl, diff_Na_Cl)


resi_diag = 1.0/diff_diag
resi_H2O_Na = 1.0/diff_H2O_Na
resi_Na_Cl = 1.0/diff_Na_Cl
resi_ref = resi_H2O_Na
resi_ref = resi_diag
resi_ref = resi_Na_Cl
-- lattice resistivity
resi_latt = 20.0
-- time step size 
dt = (resi_ref/resi_latt)*dx*dx

--omega
omega_diff = 2.0
nu_L = nu_phy * dt / dx^2
omega_kine = 1.0/(3.0*nu_L)

tmax_p = 5e-6
tmax = math.ceil(tmax_p/dt)
t_ramp = 0--1e-5--tmax_p/10

-- pressure in vapor phase
pressure = 99.4e3 --Pa (N/m^2)
-- Temperature in vapor phase
--temp = 328.5 --K

ref_pot = -50e-3
pot_north = ref_pot
pot_south = -ref_pot 
charge_north = 2e-5
charge_south = -2e-5
permit = 8.854e-12*80
valence_sqr = 1
charge = 1.60217657e-19
k_b = 1.3805e-23
temp = 293
N_A = 6.02e23 
gasConst = 8.3144621
faraday = 96485.3365

-- Parameter for analytical solution
k = math.sqrt(2*conc_NaCl*valence_sqr*faraday^2/(permit*gasConst*temp))*height
k_H = k/height
--print('k ', k, k_H)
--print(2e-5*math.cosh(k_H*height)/(permit*k_H*math.sinh(k_H*height)))
--print(2.0*permit*gasConst*temp/faraday*k_H*math.sinh(faraday*0/(2.0*gasConst*temp)))
function analy_pot_exp(x,y,z,t)  
  -- reciprocal of debye length
  ek = math.exp(k)
  eminusk = math.exp(-k)
  term_1 = (ek - 1)/(ek-eminusk)*math.exp(-k*y/height)  
  term_2 = (1-eminusk)/(ek-eminusk)*math.exp(k*y/height)
  if y>0 then
    return (term_1+term_2)*ref_pot 
  else
    return 0
  end  
end

local M = {}

local exp = math.exp

function M.cosh (x)
  if x == 0.0 then return 1.0 end
  if x < 0.0 then x = -x end
  x = exp(x)
  x = x / 2.0 + 0.5 / x
  return x
end

function M.sinh (x)
  if x == 0 then return 0.0 end
  local neg = false
  if x < 0 then x = -x; neg = true end
  if x < 1.0 then
    local y = x * x
    x = x + x * y *
        (((-0.78966127417357099479e0  * y +
           -0.16375798202630751372e3) * y +
           -0.11563521196851768270e5) * y +
           -0.35181283430177117881e6) /
        ((( 0.10000000000000000000e1  * y +
           -0.27773523119650701667e3) * y +
            0.36162723109421836460e5) * y +
           -0.21108770058106271242e7)
  else
    x =  exp(x)
    x = x / 2.0 - 0.5 / x
  end
  if neg then x = -x end
  return x
end



function analy_pot(x,y,z,t)
k = math.sqrt(2*conc_NaCl*valence_sqr*faraday^2/(permit*gasConst*temp))*(height)
  if y>0 then
    return M.cosh(k*(y/(height)))/M.cosh(k/2)*ref_pot
  else
    return 0
  end
end


function analy_pot_surfcharge(x,y,z,t)
  return charge_north/(permit*k_H)*M.cosh(k_H*y)/M.cosh(k/2.0)
end
function analy_electric_field_exp(x,y,z,t)
  ek = math.exp(k)
  eminusk = math.exp(-k)
  term_1 = (ek - 1)/(ek-eminusk)*(-k)*math.exp(-k*y/height)  
  term_2 = (1-eminusk)/(ek-eminusk)*k*math.exp(k*y/height)
  return {0.0,-(term_1+term_2)*ref_pot/height,0.0}
end

function analy_electric_field(x,y,z,t)
 k = math.sqrt(2*conc_NaCl*valence_sqr*faraday^2/(permit*gasConst*temp))*(height)
  if y>0 then
    return {0.0,k*M.sinh(k*(y/(height)))/(height*M.cosh(k/2))*ref_pot,0.0}
  else
    return {0.0,-k*M.sinh(k*(y/(height)))/(height*M.cosh(k/2))*ref_pot,0.0}
  end
end
--function analy_pot_2(x,y,z,t)
--  return charge_north*math.cosh(k_H*y)/(permit*k_H*math.sinh(k))
--end

--concentration of sea water
--salinity of sea water = 35
--http://en.wikipedia.org/wiki/Seawater
conc_Na = conc_NaCl --mol/m^3
conc_Cl = conc_NaCl --mol/m^3
rho_H2O = rho0_p - conc_NaCl*(mNa+mCl)
conc_H2O = rho_H2O/mH2O --mol/m^3
moleDens0 = conc_H2O+conc_Na+conc_Cl
---- mole fraction
moleFrac_H2O = conc_H2O/moleDens0
moleFrac_Na = conc_Na/moleDens0
moleFrac_Cl = conc_Cl/moleDens0
--print('dt =', dt)
--print('dx =', dx)
--print(conc_H2O,conc_Na,conc_Cl,moleDens0)
--print(moleFrac_H2O,moleFrac_Na,moleFrac_Cl)
--print('conc wall ', charge_nr_Na*conc_Na*math.exp(faraday*charge_nr_Na/(gasConst*temp)*ref_pot))

function analy_charge_density(x,y,z,t)
  pot = analy_pot(x,y,z,0)
  na = charge_nr_Na*conc_Na*math.exp(-faraday*charge_nr_Na/(gasConst*temp)*pot)
  cl = charge_nr_Cl*conc_Cl*math.exp(-faraday*charge_nr_Cl/(gasConst*temp)*pot)
  return (na+cl)*faraday
end
--print('charge_dens ', analy_charge_density(0,height/2.0,0,0), analy_pot(0,height/2.0,0))

function IC_Na(x,y,z)
  pot = analy_pot(x,y,z,0)
  return moleFrac_Na--*math.exp(-faraday*charge_nr_Na/(gasConst*temp)*pot)
end

function BC_Na_north(x,y,z,t)
  return moleFrac_Na*math.exp(-(charge_nr_Na*faraday/(gasConst*temp))*pot_north)
end

function BC_Na_south(x,y,z,t)
  return moleFrac_Na*math.exp(-(charge_nr_Na*faraday/(gasConst*temp))*pot_south)
end

function IC_Cl(x,y,z)
  pot = analy_pot(x,y,z,0)
  return moleFrac_Cl--*math.exp(-faraday*charge_nr_Cl/(gasConst*temp)*pot)
end

function BC_Cl_north(x,y,z,t)
  return moleFrac_Cl*math.exp(-(charge_nr_Cl*faraday/(gasConst*temp))*pot_north)
end

function BC_Cl_south(x,y,z,t)
  return moleFrac_Cl*math.exp(-(charge_nr_Cl*faraday/(gasConst*temp))*pot_south)
end
print(BC_Na_north(0,0,0)*moleDens0,BC_Na_south(0,0,0)*moleDens0)
print(BC_Cl_north(0,0,0)*moleDens0,BC_Cl_south(0,0,0)*moleDens0)

function IC_H2O(x,y,z)
  return 1.0 - IC_Na(x,y,z) - IC_Cl(x,y,z)
end

function BC_H2O(x,y,z,t)
  return 1.0 - BC_Na(x,y,z) - BC_Cl(x,y,z)
end
