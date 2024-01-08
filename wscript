#! /usr/bin/env python
# encoding: utf-8
# Harald Klimach 2011
import os
import glob

APPNAME = 'apesmate'
VERSION = '1'

top = '.'
out = 'build'

def options(opt):
    import argparse
    preparse = argparse.ArgumentParser(add_help=False)
    preparse.add_argument('--no_ateles', action='store_true', help='Do not attempt to use Ateles.')
    preparse.add_argument('--no_musubi', action='store_true', help='Do not attempt to use Musubi.')
    preparse.add_argument('--ateles_path', action='store', help='Path to Ateles.')
    preparse.add_argument('--musubi_path', action='store', help='Path to Musubi.')
    preopts, remopts = preparse.parse_known_args()

    opt.recurse('treelm')

    solv_opt = opt.add_option_group('Apes packages to include')
    solv_opt.add_option('--no_ateles', action='store_true', help='Do not attempt to use Ateles.')
    solv_opt.add_option('--no_musubi', action='store_true', help='Do not attempt to use Musubi.')
    #solv_opt.add_option('--no_seeder', action='store_true', help='Do not attempt to use Seeder.')
    #solv_opt.add_option('--no_harvester', action='store_true', help='Do not attempt to use Harvester.')
    solv_opt.add_option('--ateles_path', action='store', help='Path to Ateles.')
    solv_opt.add_option('--musubi_path', action='store', help='Path to Musubi.')
    #solv_opt.add_option('--seeder_path', action='store', help='Path to Seeder.')
    #solv_opt.add_option('--harvester_path', action='store', help='Path to Harvester.')

    if not preopts.no_ateles:
      opt.recurse(path_for_apesPackage(preopts.ateles_path,'ateles'))
    if not preopts.no_musubi:
      opt.recurse(path_for_apesPackage(preopts.musubi_path,'musubi'))
    

def path_for_apesPackage(solv_path, solv_name):
    """
       Little helper routine to check for required solver support and running
       the according configurations.
    """
    from waflib import Logs

    solver = solv_name.lower()
    if solv_path:
        Logs.warn(solv_name + ' to be used from: ' + solv_path)
        conf_path = 'plugins/conf_'+solver
        if os.path.exists(solv_path + '/wscript'):
            if os.path.exists(conf_path):
                if os.path.islink(conf_path):
                    os.unlink(conf_path)
                else:
                    if os.path.isdir(conf_path):
                        os.removedir(conf_path)
                    else:
                        os.remove(conf_path)
            path_to_solv = os.path.relpath(os.path.abspath(solv_path),
                                           os.path.abspath('plugins'))
            os.symlink(path_to_solv, conf_path)
            slvpath = conf_path
        else:
            Logs.error('No wscript found for ' + solv_name + ' at '
                       + solv_path + '/wscript')
    else:
        solv_path = 'plugins/APES_'+solver
        if os.path.exists(solv_path + '/wscript'):
            Logs.warn(solv_name + ' used from default APES location!')
            slvpath = solv_path
    return slvpath

def conf_for_apesPackage(conf, solv_path, solv_name):
    """
       Little helper routine to check for required solver support and running
       the according configurations.
    """
    from waflib import Logs

    solver = solv_name.lower()
    if solv_path:
        Logs.warn(solv_name + ' to be used from: ' + solv_path)
        conf_path = 'plugins/conf_'+solver
        if os.path.exists(solv_path + '/wscript'):
            if os.path.exists(conf_path):
                if os.path.islink(conf_path):
                    os.unlink(conf_path)
                else:
                    if os.path.isdir(conf_path):
                        os.removedir(conf_path)
                    else:
                        os.remove(conf_path)
            path_to_solv = os.path.relpath(os.path.abspath(solv_path),
                                           os.path.abspath('plugins'))
            os.symlink(path_to_solv, conf_path)
#            conf.recurse(conf_path, 'subconf')
            conf.env["with_"+solver] = True
            conf.env.solv_path[solver] = conf_path
        else:
            Logs.error('No wscript found for ' + solv_name + ' at '
                       + solv_path + '/wscript')
    else:
        solv_path = 'plugins/APES_'+solver
        if os.path.exists(solv_path + '/wscript'):
            Logs.warn(solv_name + ' used from default APES location!')
#            conf.recurse(solv_path, 'subconf')
            conf.env["with_"+solver] = True
            conf.env.solv_path[solver] = solv_path


def configure(conf):
    from waflib import Logs
    conf.env.solv_path = {}
    conf.recurse('treelm')
    conf.setenv('')

    Logs.warn('Apes package specific configuration:')
    conf.env["with_ateles"] = False
    conf.env["with_musubi"] = False
    #conf.env["with_Seeder"] = False
    #conf.env["with_Harvester"] = False
    if not conf.options.no_ateles:
        #if conf.options.ateles_path:
        #  conf.recurse(conf.options.ateles_path['ateles']+'/polynomials')
        #else:
        #  conf.recurse('plugins/APES_ateles/polynomials')
          
        conf_for_apesPackage(conf, conf.options.ateles_path, 'Ateles')
        conf.recurse(conf.env.solv_path['ateles']+'/polynomials')
    if not conf.options.no_musubi:
        conf_for_apesPackage(conf, conf.options.musubi_path, 'Musubi')
        conf.recurse(conf.env.solv_path['musubi'], "subconf")

    #if not conf.options.no_seeder:
    #    conf_for_apesPackage(conf, conf.options.seeder_path, 'Seeder')
    #if not conf.options.no_harvester:
    #    conf_for_apesPackage(conf, conf.options.harvester_path, 'Harvester')

    # Add support for FORD documentation generation
    conf.setenv('')
    conf.setenv('ford', conf.env)
    conf.env.ford_mainpage = 'mainpage.md'

def build(bld):
    
    bld(rule='cp ${SRC} ${TGT}', source=bld.env.COCOSET, target='coco.set')

    bld.add_group()

    # Don't create treelm when building the documentation is requested
    if bld.cmd != 'gendoxy':
        bld.recurse('treelm')
    else:
        bld(rule='cp ${SRC} ${TGT}',
            source = bld.path.find_node(['treelm', 'source', 'arrayMacros.inc']),
            target = bld.path.find_or_declare('arrayMacros.inc'))

    # Adapters for the solvers to support.
    solv_use = []
    # Ateles:
    if bld.env.with_ateles:
        bld.recurse(bld.env.solv_path['ateles']+'/polynomials')
        bld.recurse(bld.env.solv_path['ateles'], 'build_atl_objs')
        solv_use.append('ply_objs')
        solv_use.append('atl_objs')
        solv_use.append('fftw_mod_obj')
        solv_use.append('fftw_wrap_obj')
        solv_use.append('fxtp_obj')
        solv_use.append('fxtp_wrapper')
        solv_use.append('fxtp_wrap_obj')
        atl_source = ['plugins/aps_ateles_module.f90']
    else:
        atl_source = ['plugins/aps_ateles_dummy.f90']

    # Musubi:
    if bld.env.with_musubi:
        bld.recurse(bld.env.solv_path['musubi'], 'build_mus_objs')
        solv_use.append('mus_objs')
        if bld.env.with_ext_tdf:
          solv_use.append('ext_tdf')
          solv_use.append('STDCXX')
        mus_source = ['plugins/aps_musubi_module.f90']
    else:
        mus_source = ['plugins/aps_musubi_dummy.f90']

    # Seeder:
    ## todo: KM: Implement "build_sdr_objs" in seeder/wscript
    #if bld.env.with_seeder:
    #    bld.recurse(bld.env.solv_path['seeder'], 'build_sdr_objs')
    #    solv_use.append('sdr_objs')

    ## Harvester:
    ### todo: KM: Implement "build_hvs_objs" in harvester/wscript
    #if bld.env.with_harvester:
    #    bld.recurse(bld.env.solv_path['harvester'], 'build_hvs_objs')
    #    solv_use.append('hvs_objs')

    aps_ppsources = bld.path.ant_glob('source/*.fpp')
    aps_sources = bld.path.ant_glob('source/*.f90', 
                                    excl=['source/apes.f90'])
    aps_sources += aps_ppsources

    aps_sources += mus_source
    aps_sources += atl_source

    if bld.cmd != 'gendoxy':
        bld(
            features = 'coco fc',
            source   = aps_sources,
            use      = solv_use + ['tem_objs', 'aotus', bld.env.mpi_mem_c_obj],
            target   = 'objs')

        bld(
            features = 'fc fcprogram',
            source   = 'source/apes.f90',
            use      = 'objs',
            target   = 'apes')

    else:
        bld.recurse('treelm', 'post_doxy')
        bld(
            features = 'coco',
            source   = aps_ppsources)

#clean build directory and coco completely to create the build from scratch
def cleanall(ctx):
    from waflib import Options
    Options.commands = ['distclean'] + Options.commands
    ctx.exec_command('rm coco')
    
