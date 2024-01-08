! Copyright (c) 2014, 2016-2017 Kannan Masilamani <kannan.masilamani@dlr.de>
! Copyright (c) 2017 Verena Krupp <verena.krupp@uni-siegen.de>
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

!******************************************************************************!
!> Contain apes global parameter definitions and routines related to that
module aps_param_module

  ! include treelm modules
  use env_module,           only: rk, labelLen
  use tem_general_module,   only: tem_general_type
  use tem_timer_module,     only: tem_addTimer, tem_get_timerConfig, &
    &                             tem_timer_type, tem_timerConfig_type
  use tem_general_module,   only: tem_load_general

  ! include apes modules
  use aps_logging_module,   only: aps_load_logging

  ! aotus modules
  use aotus_module,     only: aot_get_val

  implicit none

  private

  public :: aps_param_type
  public :: aps_load_params

  !> contains global information
  type aps_param_type
    !> Treelm param parameter type
    type( tem_general_type ) :: general

    !> weight of domain partition on each process
    !! array size - (nProcs, nDomains)
    !!
    !! This is used to build nProc per domain and nDomain per proc.
    !! This weights will be used for dynamic load balancing
    !! between domains
    real(kind=rk), allocatable :: domWeights(:,:)

    !> Maximum dt of all domains is used as apes physical time
    !! step to do synchorize between domains
    !! max dt of all domain in local process
    real(kind=rk) :: dt

    !> max dt amoung all domain from all process
    real(kind=rk) :: dt_max

    !> need to set solver version in  general%solver%version
    character(len=labelLen) :: version = 'v0.1'

    !> is nProc per domain defined as exact with integer or fraction with real
    logical :: nProcIsFrac = .true.

    !> share all domains on each process equally.
    !! Requires for volume coupling
    logical :: share_dom

    !> timerConfig for apesmate, to differentiate with domain specific timer configs
    type(tem_timerconfig_type) :: timerConfig

  end type aps_param_type

contains

  !*****************************************************************************
  !> Load global parameters from config file
  subroutine aps_load_params(me)
    !--------------------------------------------------------------------------!
    !> contains basic information above apes
    type( aps_param_type ), intent(inout) :: me
    !--------------------------------------------------------------------------!
    integer :: iError
    !--------------------------------------------------------------------------!
    ! load logging and debug table from config file
    call aps_load_logging(conf = me%general%solver%conf(1), &
      &                   rank = me%general%proc%rank       )

    ! load general information
    call tem_load_general( me   = me%general,               &
      &                    conf = me%general%solver%conf(1) )
    ! get the timer config for apes
    me%timerConfig = tem_get_timerConfig()

    ! share all domains on each process equally.
    ! Requires for volume coupling
    call aot_get_val(L       = me%general%solver%conf(1), &
        &            val     = me%share_dom,              &
        &            key     = 'share_domain',            &
        &            default = .false.,                   &
        &            ErrCode = iError                     )

    ! is nProcs per domain defined as fraction or integer
    call aot_get_val(L       = me%general%solver%conf(1), &
        &            val     = me%nProcIsFrac,            &
        &            key     = 'nproc_is_frac',           &
        &            default = .true.,                    &
        &            ErrCode = iError                     )

  end subroutine aps_load_params
  !*****************************************************************************

end module aps_param_module
!******************************************************************************!
