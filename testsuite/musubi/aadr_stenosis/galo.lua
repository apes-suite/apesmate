-- Time conversion factors
local min_to_s = 1/60
-- nM_to_molperm3 = 1e-6 -- Conversion factor for nM to mol/m^3
-- local nM_inv_to_m3permol = 1e6 -- Conversion factor for nM^-1 to m^3/mol
-- local mm2_to_m2 = 1e-6 -- Conversion factor for mm^2 to m^2

-- -- Non-SI units (min, mm, nM)
-- local min_to_s = 1 -- Conversion factor for minutes to seconds
nM_to_molperm3 = 1
local nM_inv_to_m3permol = 1
local mm2_to_m2 = 1

-- Parameters in SI units
k_11 = 0.000011 * min_to_s      -- s^-1
h_11 = 0.5 * min_to_s           -- s^-1

k_10 = 0.00033 * min_to_s       -- s^-1
k_10_bar = 500 * min_to_s           -- s^-1
h_10 = 1 * min_to_s       -- s^-1

k_9 = 20 * min_to_s             -- s^-1
h_9 = 0.2 * min_to_s            -- s^-1

-- Second-order rates: nM^-1 min^-1 → (m^3/mol)*s^-1
-- Conversion factor = (1/60)*1e6 = 16666.6667
local second_order_conversion = nM_inv_to_m3permol * min_to_s
k_89 = 100 * second_order_conversion
h_89 = 100 * min_to_s           -- s^-1

k_8 = 0.00001 * min_to_s        -- s^-1
h_8 = 0.31 * min_to_s           -- s^-1

k_5 = 0.17 * min_to_s           -- s^-1
h_5 = 0.31 * min_to_s           -- s^-1

k_510 = 100 * second_order_conversion
h_510 = 100 * min_to_s          -- s^-1

k_2 = 2.45 * min_to_s           -- s^-1
k_2_bar = 2500 * min_to_s       -- s^-1
h_2 = 2.3 * min_to_s            -- s^-1

K_2m = 58 * nM_to_molperm3      -- nM
K_2m_bar = 210 * nM_to_molperm3 -- nM

-- Diffusion: mm^2/min to m^2/s
D = 0.0037 * mm2_to_m2 * min_to_s -- mm^2/s

T_0 = 1400 * nM_to_molperm3     -- nM

-- -- Uncomment to print results for verification
-- print("k_11 (s^-1) =", k_11)
-- print("h_11 (s^-1) =", h_11)
-- print("k_10 (s^-1) =", k_10)
-- print("k_10_bar (s^-1) =", k_10_bar)
-- print("h_10 (s^-1) =", h_10)
-- print("k_9 (s^-1)  =", k_9)
-- print("h_9 (s^-1)  =", h_9)
-- print("k_89 (m^3/mol s) =", k_89)
-- print("h_89 (s^-1) =", h_89)
-- print("k_8 (s^-1)  =", k_8)
-- print("h_8 (s^-1)  =", h_8)
-- print("k_5 (s^-1)  =", k_5)
-- print("h_5 (s^-1)  =", h_5)
-- print("k_510 (m^3/mol s) =", k_510)
-- print("h_510 (s^-1) =", h_510)
-- print("k_2 (s^-1)  =", k_2)
-- print("k_2_bar (s^-1) =", k_2_bar)
-- print("h_2 (s^-1)  =", h_2)
-- print("K_2m (mol/m^3) =", K_2m)
-- print("K_2m_bar (mol/m^3) =", K_2m_bar)
-- print("D (m^2/s) =", D)
-- print("T_0 (mol/m^3) =", T_0)
