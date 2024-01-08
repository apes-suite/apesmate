useObstacle = true 
height =  0.5e-6  
nHeight = 100
l_h = 1
nLength = nHeight*l_h 
dx = height/nHeight
length = nLength*dx
nLength_bnd = 2*nLength+4
level = math.ceil(math.log(nLength_bnd)/math.log(2))
length_bnd = (2^level)*dx
dx_half = dx*0.5
zpos = dx_half

-- Simulation parameters
nu_phy = 1e-6 --m^2/s
rho0_p = 1000.0

ref_pot = -25e-3
permit = 6.95e-10
moleDens0 = 1e-4*1e3 -- Molarity * 1e3
valence_sqr = 1
charge = 1.60217657e-19
k_b = 1.3805e-23
temp = 273
N_A = 6.02e23 

-- Parameter for analytical solution
k = math.sqrt(2*moleDens0*N_A*valence_sqr*charge^2/(permit*k_b*temp))*length
--print(k)
function analy_pot(x,y,z,t)  
  -- reciprocal of debye length
  ek = math.exp(k)
  eminusk = math.exp(-k)
  term_1 = (ek - 1)/(ek-eminusk)*math.exp(-k*x/length)  
  term_2 = (1-eminusk)/(ek-eminusk)*math.exp(k*x/length)
  return (term_1+term_2)*ref_pot 
end


