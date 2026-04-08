require "galo"
require "params"

-- Convert all parameters to lattice units
local converter_time = dt -- s, reference with dt
local converter_concentration = 1 / T_0 -- nM^-1, reference with T_0

k_11_L = k_11 * converter_time 
h_11_L = h_11 * converter_time

k_10_L = k_10 * converter_time
k_10_bar_L = k_10_bar * converter_time
h_10_L = h_10 * converter_time

k_9_L = k_9 * converter_time
h_9_L = h_9 * converter_time

local second_order_conversion = converter_time / converter_concentration -- nM * s
k_89_L = k_89 * second_order_conversion
h_89_L = h_89 * converter_time

k_8_L = k_8 * converter_time
h_8_L = h_8 * converter_time

k_5_L = k_5 * converter_time
h_5_L = h_5 * converter_time

k_510_L = k_510 * second_order_conversion
h_510_L = h_510 * converter_time

k_2_L = k_2 * converter_time
k_2_bar_L = k_2_bar * converter_time
h_2_L = h_2 * converter_time

K_2m_L = K_2m * converter_concentration
K_2m_bar_L = K_2m_bar * converter_concentration

if if_print then
  print("k_11_L =", k_11_L)
  print("h_11_L =", h_11_L)
  print("k_10_L =", k_10_L)
  print("k_10_bar_L =", k_10_bar_L)
  print("h_10_L =", h_10_L)
  print("k_9_L  =", k_9_L)
  print("h_9_L  =", h_9_L)
  print("k_89_L =", k_89_L)
  print("h_89_L =", h_89_L)
  print("k_8_L  =", k_8_L)
  print("h_8_L  =", h_8_L)
  print("k_5_L  =", k_5_L)
  print("h_5_L  =", h_5_L)
  print("k_510_L =", k_510_L)
  print("h_510_L =", h_510_L)
  print("k_2_L  =", k_2_L)
  print("k_2_bar_L =", k_2_bar_L)
  print("h_2_L  =", h_2_L)
  print("K_2m_L =", K_2m_L)
  print("K_2m_bar_L =", K_2m_bar_L)
end


---------- Lattice parameters with diffusive scaling -----------
tau_D = 0.8
D_L = (tau_D - 0.5) / 3.0
D = D_L * dx^2 / dt
if if_print then
  print("D = "..D)
  print("tau_D = "..tau_D)
  print("Sc = "..nu_phy / D)
end
----------- Lattice parameters with diffusive scaling -----------
---
---
----------- Concentration "pressures" -----------
con_ref = 1.        -- reference with T_0
c_init = 1e-2
con_press_ref = con_ref*(dx^2)/(3.*dt^2)
con_press_init = c_init*(dx^2)/(3.*dt^2)
----------- Concentration "pressures" -----------