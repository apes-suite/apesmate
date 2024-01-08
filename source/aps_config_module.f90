! Copyright (c) 2014, 2016-2017 Kannan Masilamani <kannan.masilamani@dlr.de>
! Copyright (c) 2016 Verena Krupp <verena.krupp@uni-siegen.de>
!
! Redistribution and use in source and binary forms, with or without
! modification, are permitted provided that the following conditions are met:
!
! 1. Redistributions of source code must retain the above copyright notice, this
! list of conditions and the following disclaimer.
!
! 2. Redistributions in binary form must reproduce the above copyright notice,
! this list of conditions and the following disclaimer in the documentation
! and/or other materials provided with the distribution.
!
! THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
! AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
! IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
! DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
! FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
! DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
! SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
! CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
! OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
! OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

!*******************************************************************************
!> This module contain routine to load apes configuration file
module aps_config_module

  ! include aotus modules
  use aotus_module,         only: aot_get_val, open_config_file, close_config, &
    &                             flu_State,                                   &
    &                             aoterr_Fatal, aoterr_NonExistent,            &
    &                             aoterr_WrongType

  ! include treelm modules
  use env_module,           only: pathLen
  use tem_tools_module,     only: tem_horizontalSpacer
  use tem_logging_module,   only: logUnit
  use tem_debug_module,     only: tem_debug_type, tem_load_debug

  ! include apes modules
  use aps_param_module,     only: aps_param_type, aps_load_params
  use aps_domainObj_module, only: aps_domainObj_type, &
    &                             aps_load_domainObj

  implicit none

  private

  public :: aps_load_config

contains

  !*****************************************************************************
  !> Load the configuration from the Lua script provided on the command line
  !! or from apes.lua by default, if no file name is given as program
  !! argument.
  !!
  !! The configuration needs to describe solve and config file for that solver
  !! through the domain table
  subroutine aps_load_config( domainObj, params )
    !--------------------------------------------------------------------------!
    !> contains all domain objects defined in the config file
    type( aps_domainObj_type ), allocatable, intent(out) :: domainObj(:)
    !> contains basic information above apes
    type( aps_param_type ), intent(inout) :: params
    !--------------------------------------------------------------------------!
    ! local variables
    character(len=pathLen) :: filename
    ! maximum number of openMP threads
    integer :: nMaxThreads
    !--------------------------------------------------------------------------!

    filename = ''
    ! Get filename from command argument
    call get_command_argument(1,filename)
    if ( trim(filename) == '')  then
      ! Default to apes.lua, if no filename is provided on the command line.
      filename = 'apes.lua'
    endif

    params%general%solver%configFile = filename
    if (params%general%proc%rank==0) then
      write(logUnit(1),*) "Loading configuration file: "//trim( filename )
      call tem_horizontalSpacer(fUnit = logUnit(1))
    end if

    ! set the number to be one for now since no openMP is currently implemented
    nMaxThreads = 1
    ! allocate the array of lua states
    allocate( params%general%solver%conf( nMaxThreads ))

    ! Attempt to open the given file as a Lua script. Store a handle to that
    ! script in conf.
    call open_config_file(L        = params%general%solver%conf(1), &
      &                   filename = trim(filename)                 )

    ! Load global parameters like logging and general info from config file
    call aps_load_params( me = params )

    ! load domain_object table from config file
    call aps_load_domainObj( me          = domainObj,                     &
      &                      conf        = params%general%solver%conf(1), &
      &                      nProcIsFrac = params%nProcIsFrac,            &
      &                      share_dom   = params%share_dom,              &
      &                      glob_nProc  = params%general%proc%comm_size  )

    ! Close the configuration script again.
    call close_config(params%general%solver%conf(1))

  end subroutine aps_load_config
  !*****************************************************************************

end module aps_config_module
!*******************************************************************************
