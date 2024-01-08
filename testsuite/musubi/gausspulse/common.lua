height =  1.0
nHeight = 16--os.getenv("nHeight")
dx = height/nHeight
length = height
nLength = nHeight
nLength_bnd = 2*nLength+4
--dx = length_bnd/(2^level)
--dx_ini = length/nLength 
level = math.ceil(math.log(nLength_bnd)/math.log(2))
length_bnd = (2^level)*dx
--level = 9
--dx = length_bnd/2^level
--nLength = math.ceil((length)/dx)
--nHeight = math.ceil((height)/dx)
dx_half = dx*0.5
zpos = dx_half

--commpattern = os.getenv('cpat')
commpattern = 'isend_irecv'
originX =  -1.3
originY =  0.8
originZ =  0.1
halfwidth = 0.50
amplitude = 0.01
p0 = 0.0
function ic_1Dgauss_pulse(x, y, z)
  return p0+amplitude*math.exp(-0.5/(halfwidth^2)*( x - originX )^2)
end
