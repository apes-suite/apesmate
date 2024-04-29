#! /usr/bin/env python
# encoding: utf-8
# Harald Klimach 2011
import os
import glob

APPNAME = 'apesmate'
VERSION = '1'

top = '.'
out = 'build'

sol_pre = {"ateles": "atl", "musubi": "mus"}

def options(opt):
    import argparse
    preparse = argparse.ArgumentParser(add_help=False)
    preparse.add_argument('--no_ateles', action='store_true', help='Do not attempt to use Ateles.')
    preparse.add_argument('--no_musubi', action='store_true', help='Do not attempt to use Musubi.')
    preopts, remopts = preparse.parse_known_args()

    opt.recurse('bin')
    opt.recurse('aotus')
    opt.recurse('tem')

    solv_opt = opt.add_option_group('Apes packages to include')
    solv_opt.add_option('--no_ateles', action='store_true', help='Do not attempt to use Ateles.')
    solv_opt.add_option('--no_musubi', action='store_true', help='Do not attempt to use Musubi.')

    if not preopts.no_ateles:
        opt.recurse('atl')
    if not preopts.no_musubi:
        opt.recurse('mus')


def configure(conf):
    '''Project configuration'''
    from waflib import Logs
    conf.recurse('aotus', 'subconf')
    conf.recurse('bin', 'preconfigure')
    conf.load('coco')
    conf.env['COCOSET'] = 'default.coco'
    if not conf.options.coco_reports:
        # Make coco silent, if not explicitly asked for reports:
        if conf.env.COCOFLAGS:
            conf.env.COCOFLAGS.insert(0, '-s')
            conf.env.COCOFLAGS.append('-ad')
        else:
            conf.env.COCOFLAGS = ['-s', '-ad']
    conf.recurse('tem')

    if not conf.options.no_ateles:
        conf.recurse('polynomials')
        conf.recurse('atl')
        conf.env['with_ateles'] = True
    if not conf.options.no_musubi:
        conf.recurse('mus')
        conf.env['with_musubi'] = True

    conf.recurse('bin', 'postconfigure')

def build(bld):
    '''Build the apesmate project'''
    from revision_module import fill_revision_string
    bld.recurse('bin')
    if not (bld.cmd == 'docu' and bld.env.fordonline):
        bld.recurse('aotus')
    fill_revision_string(bld)
    bld(rule='cp ${SRC} ${TGT}', source=bld.env.COCOSET, target='coco.set')
    bld.recurse('tem')
    solv_use = []
    if bld.env.with_ateles:
        bld.recurse('polynomials')
        bld.recurse('atl')
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
    if bld.env.with_musubi:
        bld.recurse('mus')
        solv_use.append('mus_objs')
        if bld.env.with_ext_tdf:
          solv_use.append('ext_tdf')
          solv_use.append('STDCXX')
        mus_source = ['plugins/aps_musubi_module.f90']
    else:
        mus_source = ['plugins/aps_musubi_dummy.f90']

    aps_ppsources = bld.path.ant_glob('source/*.fpp')
    aps_sources = bld.path.ant_glob('source/*.f90',
                                    excl=['source/apes.f90'])
    aps_sources += aps_ppsources

    aps_sources += mus_source
    aps_sources += atl_source

    if not (bld.cmd == 'docu'):
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

#clean build directory and coco completely to create the build from scratch
def cleanall(ctx):
    from waflib import Options
    Options.commands = ['distclean'] + Options.commands
    ctx.exec_command('rm coco')
