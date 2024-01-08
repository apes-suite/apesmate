######################################################################
# ref_path and output have to be provided as a string
#
# Execute shepherd like this: ./shepherd.py ateles_params.py
#
#####################################################################
import os
import sys
import datetime
import shutil

from clone_and_build_function import *

# Set this switch to true to abort the recheck when the first job fails.
abort = False

templateFolder = './templates/'
machineFolder = './machines/'
apesFolder = os.getenv('HOME')+'/apes/'

date = datetime.datetime.now().strftime("%Y-%m-%d__%X")
weekday = datetime.datetime.now().strftime("%A")

# Production directory, keep the past week as history.
prod_dir = 'apesmate-runs_' + weekday

run_label = 'APESmate'

# Cleanup production directory before using it:
shutil.rmtree(prod_dir, ignore_errors=True)
loglevel = 'INFO'

git_clone_source = 'https://github.com/apes-suite/'

# mail adress
from recheck import notify_list, mail_server
mail_address = notify_list
smtp_server = mail_server

# name of the shepherd log file
shepherd_out = 'shepherd.log'

# output files
clone_build_out = 'clone_build.log'
clone_build_err = 'clone_build_error.log'

# Set this to true to have the current revision marked as working when all tests
# succeed.
create_tag_on = True
# Set this to true to have shepherd store the performance results in the loris
# repository.
grep_performance = True

loris_clone_url = apesFolder + 'loris/'

# path to the testsuite dir to shorten the string in the job_dict
apmdir = apesFolder + 'apesmate/testsuite/ateles'
acousticdir  = apmdir + '/densityPulse/'
movingGeodir = apmdir + '/moving_cylinder_2d/'
ee_ledir     = apmdir + '/ee_le/'
threefielddir     = apmdir + '/3-field_coupling/'

loris_clone_url = apesFolder + 'loris/'

shepherd_jobs = []

seeder_exe = clone_build( solver          = 'seeder',
                          revision        = 'default',
                          hg_clone_source = git_clone_source+'seeder.git',
                          solver_dir      = 'seeder',
                          clone_build_out = clone_build_out,
                          clone_build_err = clone_build_err           )

apesmate_exe = clone_build( solver          = 'apes',
                            hg_clone_source = git_clone_source+'apesmate.git',
                            solver_dir      = 'apesmate',
                            clone_build_out = clone_build_out,
                            clone_build_err = clone_build_err         )

## APESMATE JOB 1 ##
shepherd_jobs.append(
    dict(
        executable = None,
        mail = False,
        template = acousticdir + 'common.lua',
        extension = 'lua',
        run_exec = False,
        abort_failure = abort,
        prefix = 'densityPulse_2d_Euler',
        label = 'common_config',
    )
)
shepherd_jobs.append(
    dict(
        executable = seeder_exe,
        mail = False,
        template = acousticdir + 'seeder_left.lua',
        extension = 'lua',
        run_exec = True,
        abort_failure = abort,
        create_subdir = ['mesh_left'],
        depend = 'common_config',
        label = 'densityPulse_2d_Euler_seeder_left',
    )
)
shepherd_jobs.append(
    dict(
        executable = seeder_exe,
        mail = False,
        template = acousticdir + 'seeder_right.lua',
        extension = 'lua',
        run_exec = True,
        abort_failure = abort,
        create_subdir = ['mesh_right'],
        depend = 'common_config',
        label = 'densityPulse_2d_Euler_seeder_right',
    )
)

shepherd_jobs.append(
    dict(
        executable = None,
        mail = False,
        template = acousticdir + 'ateles_right.lua',
        extension = 'lua',
        run_exec = False,
        abort_failure = abort,
        depend = 'densityPulse_2d_Euler_seeder_right',
        label = 'ateles_right_config',
    )
)
shepherd_jobs.append(
    dict(
        executable = None,
        mail = False,
        template = acousticdir + 'ateles_left.lua',
        extension = 'lua',
        run_exec = False,
        abort_failure = abort,
        depend = 'densityPulse_2d_Euler_seeder_left',
        label = 'ateles_left_config',
    )
)
shepherd_jobs.append(
    dict(
        executable = apesmate_exe,
        solver_name = 'apes',
        template = acousticdir + 'apes.lua',
        extension = 'lua',
        run_exec = True,
        abort_failure = abort,
        additional_params = dict(testsuite_path=apmdir),
        depend = ['ateles_left_config', 'ateles_right_config'],
        label = 'coupled_Simulation_densityPulse_2d_Euler',
        attachment = True,
        validation = True,
        val_method = 'difference',
        val_ref_path = acousticdir + 'ateles_Ref_right_lineX_p00000_t20.000E-03.res',
        val_output_filename = 'ateles_right_lineX_p00000_t20.000E-03.res',
    )
)
######## END JOB 2 ##########

## APESMATE JOB 2##

shepherd_jobs.append(
    dict(
        executable = None,
        mail = False,
        template = movingGeodir + 'common.lua',
        extension = 'lua',
        run_exec = False,
        abort_failure = abort,
        prefix = 'movingGeo_2d_Euler',
        label = 'common_config',
    )
)
shepherd_jobs.append(
    dict(
        executable = seeder_exe,
        mail = False,
        template = movingGeodir + 'seeder_left.lua',
        extension = 'lua',
        run_exec = True,
        abort_failure = abort,
        create_subdir = ['mesh_left'],
        depend = 'common_config',
        label = 'movingGeo_2d_Euler_seeder_left',
    )
)
shepherd_jobs.append(
    dict(
        executable = seeder_exe,
        mail = False,
        template = movingGeodir + 'seeder_right.lua',
        extension = 'lua',
        run_exec = True,
        abort_failure = abort,
        create_subdir = ['mesh_right'],
        depend = 'common_config',
        label = 'movingGeo_2d_Euler_seeder_right',
    )
)

shepherd_jobs.append(
    dict(
        executable = None,
        mail = False,
        template = movingGeodir + 'ateles_right.lua',
        extension = 'lua',
        run_exec = False,
        abort_failure = abort,
        depend = 'movingGeo_2d_Euler_seeder_right',
        label = 'ateles_right_config',
    )
)
shepherd_jobs.append(
    dict(
        executable = None,
        mail = False,
        template = movingGeodir + 'ateles_left.lua',
        extension = 'lua',
        run_exec = False,
        abort_failure = abort,
        depend = 'movingGeo_2d_Euler_seeder_left',
        label = 'ateles_left_config',
    )
)
shepherd_jobs.append(
    dict(
        executable = apesmate_exe,
        solver_name = 'apes',
        template = movingGeodir + 'apes.lua',
        extension = 'lua',
        run_exec = True,
        abort_failure = abort,
        additional_params = dict(testsuite_path=movingGeodir),
        depend = ['ateles_left_config', 'ateles_right_config'],
        label = 'coupled_Simulation_movingGeo_2d_Euler',
        attachment = True,
        validation = True,
        val_method = 'difference',
        val_ref_path = movingGeodir + 'ateles_Ref_right_lineX_p00000_t40.000E-03.res',
        val_output_filename = 'ateles_right_lineX_p00000_t40.000E-03.res',
    )
)
###### END JOB2 ########

## APESMATE JOB 3##

shepherd_jobs.append(
    dict(
        executable = seeder_exe,
        mail = False,
        prefix = 'ee_le',
        template = ee_ledir + 'seeder_euler.lua',
        extension = 'lua',
        run_exec = True,
        abort_failure = abort,
        create_subdir = ['mesh_euler'],
        label = 'pressurePulse_seeder_euler',
    )
)
shepherd_jobs.append(
    dict(
        executable = seeder_exe,
        mail = False,
        template = ee_ledir + 'seeder_lineuler.lua',
        extension = 'lua',
        run_exec = True,
        abort_failure = abort,
        create_subdir = ['mesh_lineuler'],
        depend = 'pressurePulse_seeder_euler',
        label = 'pressurePulse_seeder_lineuler',
    )
)

shepherd_jobs.append(
    dict(
        executable = None,
        mail = False,
        template = ee_ledir + 'ateles_euler.lua',
        extension = 'lua',
        run_exec = False,
        abort_failure = abort,
        depend = 'pressurePulse_seeder_euler',
        label = 'ateles_euler_config',
    )
)
shepherd_jobs.append(
    dict(
        executable = None,
        mail = False,
        template = ee_ledir + 'ateles_lineuler.lua',
        extension = 'lua',
        run_exec = False,
        abort_failure = abort,
        depend = 'pressurePulse_seeder_lineuler',
        label = 'ateles_lineuler_config',
    )
)
shepherd_jobs.append(
    dict(
        executable = apesmate_exe,
        solver_name = 'apes',
        template = ee_ledir + 'apes.lua',
        extension = 'lua',
        run_exec = True,
        abort_failure = abort,
        additional_params = dict(testsuite_path=ee_ledir),
        depend = ['ateles_euler_config', 'ateles_lineuler_config'],
        label = 'coupled_Simulation_PressurePulse_ee_le_2D',
        attachment = True,
        validation = True,
        val_method = 'difference',
        val_ref_path = ee_ledir + 'ateles_lineuler_Ref_point_p00000.res',
        val_output_filename = 'ateles_lineuler_point_p00000.res',
    )
)
###### END JOB3 ########

## APESMATE JOB 4 ##
shepherd_jobs.append(
    dict(
        executable = None,
        mail = False,
        prefix = '3field_coupling',
        template = threefielddir + 'common.lua',
        extension = 'lua',
        run_exec = False,
        abort_failure = abort,
        label = 'common_config',
    )
)
shepherd_jobs.append(
    dict(
        executable = seeder_exe,
        mail = False,
        template = threefielddir + 'seeder_navier.lua',
        extension = 'lua',
        run_exec = True,
        abort_failure = abort,
        create_subdir = ['mesh_navier'],
        depend = 'common_config',
        label = '3field_seeder_navier',
    )
)
shepherd_jobs.append(
    dict(
        executable = seeder_exe,
        mail = False,
        template = threefielddir + 'seeder_euler.lua',
        extension = 'lua',
        run_exec = True,
        abort_failure = abort,
        create_subdir = ['mesh_euler'],
        depend = 'common_config',
        label = '3field_seeder_euler',
    )
)
shepherd_jobs.append(
    dict(
        executable = seeder_exe,
        mail = False,
        template = threefielddir + 'seeder_lineuler.lua',
        extension = 'lua',
        run_exec = True,
        abort_failure = abort,
        create_subdir = ['mesh_lineuler'],
        depend = 'common_config',
        label = '3field_seeder_lineuler',
    )
)

shepherd_jobs.append(
    dict(
        executable = None,
        mail = False,
        template = threefielddir + 'ateles_navier.lua',
        extension = 'lua',
        run_exec = False,
        abort_failure = abort,
        depend = '3field_seeder_navier',
        label = 'ateles_navier_config',
    )
)

shepherd_jobs.append(
    dict(
        executable = None,
        mail = False,
        template = threefielddir + 'ateles_euler.lua',
        extension = 'lua',
        run_exec = False,
        abort_failure = abort,
        depend = '3field_seeder_euler',
        label = 'ateles_euler_config',
    )
)
shepherd_jobs.append(
    dict(
        executable = None,
        mail = False,
        template = threefielddir + 'ateles_lineuler.lua',
        extension = 'lua',
        run_exec = False,
        abort_failure = abort,
        depend = '3field_seeder_lineuler',
        label = 'ateles_lineuler_config',
    )
)
shepherd_jobs.append(
    dict(
        executable = apesmate_exe,
        solver_name = 'apes',
        template = threefielddir + 'apes.lua',
        extension = 'lua',
        run_exec = True,
        abort_failure = abort,
        additional_params = dict(testsuite_path=threefielddir),
        depend = ['ateles_navier_config', 'ateles_euler_config', 'ateles_lineuler_config'],
        label = 'coupled_Simulation_3field',
        attachment = True,
        validation = True,
        val_method = 'difference',
        val_ref_path = threefielddir + 'ateles_Ref_lineuler_lineuler_p00000.res',
        val_output_filename = 'ateles_lineuler_lineuler_p00000.res',
    )
)
######## END JOB4 ########

