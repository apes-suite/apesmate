
require "common"

name = 'spacer'

--------------------------------------------------------------------------------
-- Load general configuration options from the treelm library.
--cube_length = 1.0 -- Has no relevance here, but needed for treelm/config
--require 'treelm/config'
--------------------------------------------------------------------------------


-- define the input
input = {
         read = 'restart/spacer_lastHeader.lua',
--          mesh = {folder = 'mesh/', solid = true}
        }

-- define the output
output = {  -- some general information 
            folder = 'harvest/',     -- Output location
            
--           { --first output subset
--
--	    solid = true, -- dump solid elements?
--	    format = 'VTU',
--            label = ''
--           },
		
	  { --second output subset
	    requestedData = { variable = { {'pressure_phy'}, {'velocity_phy'}}},
	    

	   label ='',

           format = 'VTU',   -- Output format
           shape= { kind = 'canoND', object={origin ={l_ch/2.0,dx,w_ch/2.0}} } , 

        --   dumpAll = true                 
         }             
       
        }
