! Copyright (c) 2013-2017 Kannan Masilamani <kannan.masilamani@dlr.de>
! Copyright (c) 2016-2017 Verena Krupp <verena.krupp@uni-siegen.de>
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
!> A P E S ( Adaptable Poly-Engineering Simulator )
!! Provides a coupling mechanism for APES solvers  to interact with each
!! other
!!
!! For a documentation, run ./waf gendoxy and find the documentation at
!! ./Documentation/html/index.html
!!
!! \author Kannan Masilamani
program apes
  use mpi

  ! include treelm modules
  use tem_general_module, only: tem_start, tem_finalize
  use tem_timer_module,   only: tem_startTimer, tem_stopTimer, &
    &                           tem_set_timerConfig

  ! include apes modules
  use aps_aux_module,             only: aps_banner
  use aps_param_module,           only: aps_param_type
  use aps_solver_module,          only: aps_solver_type,                   &
    &                                   aps_solverCount_type,              &
    &                                   aps_load_domainObjConfig,          &
    &                                   aps_create_domainPartition
  use aps_domainObj_module,       only: aps_domainObj_type
  use aps_stFun_coupling_module,  only: grw_aps_stFunCplArray_type
  use aps_program_module,         only: aps_initialize, aps_solve, aps_finalize
  use aps_config_module,          only: aps_load_config
  use aps_couplingRequest_module, only: aps_coupling_variables_type
  use aps_timer_module,           only: aps_addTimers, &
    &                                   aps_timerHandles

  implicit none
  ! ----------------------------------------------------------------------------
  !> apes mate global parameter
  type(aps_param_type) :: params
  !> contains list of domains and their corresponding solvers.
  type(aps_solver_type), target :: solver
  !> Count each solver type on local process
  type(aps_solverCount_type) :: solverCnt
  !> Contains all information about all domains
  type(aps_domainObj_type), allocatable :: domainObj(:)
  !> Contains all spacetime functions with predefined "apesmate"
  type(grw_aps_stFunCplArray_type) :: stFunCplList
  !> Contains all coupling variables requested by remote domain
  !! with point datas for all levels
  type(aps_coupling_variables_type) :: cplVars
  integer :: iError
  ! ----------------------------------------------------------------------------

  ! Initialize environment
  call tem_start( codeName   = 'Apes',                   &
    &             version    = params%version,           &
    &             general    = params%general,           &
    &             simControl = params%general%simControl )

  ! Initialize Apes screen
  if (params%general%proc%rank == 0) then
    call aps_banner(solver = params%general%solver)
  end if

  ! init the timer
  call aps_addTimers()

  call tem_startTimer( timerHandle = aps_timerHandles%loadConfig )
  ! load configuration file
  call aps_load_config( domainObj = domainObj, &
    &                   params    = params     )

  ! compute domain partition on each process and
  ! create mpi communicator group for each domain
  call aps_create_domainPartition( solver      = solver,             &
    &                              solverCnt   = solverCnt,          &
    &                              domainObj   = domainObj,          &
    &                              domWeights  = params%domWeights,  &
    &                              globProc    = params%general%proc )

  ! load each domain solver configuration files
  ! and Initialize apes time with max of solver time if solver uses restart file
  call aps_load_domainObjConfig( me        = solver,                        &
    &                            solverCnt = solverCnt,                     &
    &                            domainObj = domainObj,                     &
    &                            aps_now   = params%general%simControl%now, &
    &                            globProc  = params%general%proc            )
  call tem_stopTimer( timerHandle = aps_timerHandles%loadConfig )

  ! initialize each domain including coupling communication
  call tem_startTimer( timerHandle = aps_timerHandles%init )
  call aps_initialize( solver       = solver,       &
    &                  domainObj    = domainObj,    &
    &                  stFunCplList = stFunCplList, &
    &                  cplVars      = cplVars,      &
    &                  params       = params        )

  call MPI_Barrier(MPI_COMM_WORLD, iError)
  call tem_stopTimer( timerHandle = aps_timerHandles%init )

  ! solve each domain
  call aps_solve( solver       = solver,       &
    &             domainObj    = domainObj,    &
    &             stFunCplList = stFunCplList, &
    &             cplVars      = cplVars,      &
    &             params       = params        )

  ! finialize each domain
  call aps_finalize( solver    = solver,    &
    &                domainObj = domainObj, &
    &                params    = params     )

  ! Finalize environment
  ! set the correct timerconfig
  call tem_set_timerConfig(params%timerConfig)
  call tem_finalize(params%general)

end program apes
!******************************************************************************!
