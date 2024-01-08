dt            = 0.0012685595291113
dx            = 0.0256
period        = 1.0 
period_iter   = math.ceil(period/dt)
tmax          = math.ceil(period_iter*2) 
tmax          = 1000
trstart       = math.ceil(period_iter*16 + period_iter/12.0)
instart       = math.ceil(period_iter*3)
pint          = math.ceil(period_iter/6.0)
int           = 40 
-------------------------------------------------------------------------------
--tracking = {}
-------------------------------------------------------------------------------
--for i=-14, 15, 1 do
--  tab3 = {
--    label = i,
--    variable = { 'velocity_phy' },
--    shape = {
--      kind  = 'canoND',
--      object  = {
--        origin = {i, 0.0, 0.0 },
--      }
--    },
--    folder       = 'inst/',
--    output = {format = 'ascii'}, 
--    time_control = { 
--      min      = { iter = instart }, 
--      max      = { iter = tmax    }, 
--      interval = { iter = int    } 
--    }
--  }
--  table.insert(tracking, tab3)
--end
----------------INITIAL TRANSIENTS ANALYSIS----------------------------------------
--for i=-14, 15, 1 do
--  tab4 = {
--    label = i,
--    variable = { 'velocity_phy', 'pressure_phy' },
--    shape = {
--      kind  = 'canoND',
--      object  = {
--        origin = {i, 0.0, 0.0 },
--      }
--    },
--    folder       = 'zero/',
--    output = {format = 'ascii'}, 
--    time_control = { 
--      min      = { iter = 0}, 
--      max      = { iter = instart }, 
--      interval = { iter = int    } 
--    }
--  }
--  table.insert(tracking, tab4)
--end
