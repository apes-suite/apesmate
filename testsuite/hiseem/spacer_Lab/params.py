prod_dir = 'prod'
######################################################################################
seeder_template = 'seeder.template'                                     
run_preproc_exec = True				
path_to_preproc_exec = '../../../../seeder/build/seeder'
seeder_params = [			     
              [ "nHeight",128],
              [ "lm_hsp", 2.5],
              [ "nFilament",8,9]
              ]
run_command_preproc = path_to_preproc_exec               			     
										    
										   
										  
																				
######################################################################################
									
lua_template = 'musubi.template'				
#lua_file = 'musubi.lua'
run_solver_exec = False
path_to_solver_exec = '../../../build/musubi'
lua_params = [
              [ "u_mean",0.1]
             ]

run_command_solver = '$MPIEXEC -np 4'
							
######################################################################################
						
jobscript_template = 'rwth.template'
submit_job = False
sub_command = 'bsub < '
job_params = [
              [ "nNode", 1024 ]
             ]
######################################################################################

# runs with the run_command_solver which is specified above
#harvester_template = 'harvester.template'					     #
#path_to_harvester_exec = '../../../../harvester/build/harvester'

#run_command_solver = '$MPIEXEC -np 16'
							

#################################################################################
#
