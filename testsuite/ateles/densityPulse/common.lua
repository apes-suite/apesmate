
---- testcase setup------------------------------------------------------------
gamma = 1.4
density = 1.0
velocityX = 4.0
velocityY = 0.0
pressure = 10.0

-- reference solution and initial condition
function gauss (x,y,z,t)
x0 = velocityX * t - 0.125 -- shifted by 1 to the left
y0 = -0.125
d = (x-x0)*(x-x0)+ (y-y0)*(y-y0) 
return( density + 1.0* math.exp(-d/0.00625*math.log(2)) )
end 

function ic_gauss (x,y,z)
return( gauss(x,y,z,0.0) )
end 
