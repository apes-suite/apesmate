! Copyright (c) 2014-2018 Kannan Masilamani <kannan.masilamani@dlr.de>
! Copyright (c) 2015-2017 Verena Krupp <verena.krupp@uni-siegen.de>
! Copyright (c) 2019 Neda Ebrahimi Pour <neda.ebrahimipour@dlr.de>
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
!> This module contains routines to intialize, solve and finialize each domain
!! solver
!!
!! \author Kannan Masilamani
module aps_program_module
  ! treelm modules
  use mpi
  use env_module,             only: rk, labelLen, rk_mpi
  use tem_time_module,        only: tem_time_type, tem_time_dump
  use tem_timer_module,       only: tem_startTimer, tem_stopTimer
  use tem_timeControl_module, only: tem_timeControl_update,      &
    &                               tem_timeControl_dump,        &
    &                               tem_timeControl_start_at_sim
  use tem_simControl_module,  only: tem_simControl_syncUpdate, &
    &                               tem_simControl_clearStat
  use tem_status_module,      only: tem_status_run_end, tem_status_dump, &
    &                               tem_status_run_terminate,            &
    &                               tem_stat_interval,                   &
    &                               tem_stat_run_terminate,              &
    &                               tem_stat_nonPhysical,                &
    &                               tem_stat_steady_state,               &
    &                               tem_status_type
  use tem_aux_module,         only: tem_abort
  use tem_logging_module,     only: logunit
  use tem_debug_module,       only: dbgUnit
  use tem_tools_module,       only: tem_horizontalSpacer

  ! include apes module
  use aps_domainObj_module,       only: aps_domainObj_type, musubi, ateles
  use aps_solver_module,          only: aps_solver_type
  use aps_musubi_module,          only: aps_init_musubi, aps_solve_musubi, &
    &                                   aps_finalize_musubi
  use aps_ateles_module,          only: aps_init_ateles, aps_solve_ateles, &
    &                                   aps_finalize_ateles
  use aps_param_module,           only: aps_param_type
  use aps_comm_module,            only: aps_init_cplComm, aps_sync_domains
  use aps_stFun_coupling_module,  only: grw_aps_stFunCplArray_type, &
    &                                   aps_fill_stFunCoupling
  use aps_logging_module,         only: aps_logUnit, aps_dbgUnit
  use aps_couplingRequest_module, only: aps_coupling_variables_type, &
    &                                   get_numberCplRanks
  use aps_timer_module,           only: aps_dumpTimers, &
    &                                   aps_timerHandles

  private

  public :: aps_initialize
  public :: aps_solve
  public :: aps_finalize

contains


  !****************************************************************************!
  !> This routine initialize domains active on local process
  subroutine aps_initialize(solver, domainObj, stFunCplList, cplVars, params)
    !--------------------------------------------------------------------------!
    !> contains all apes solvers on this process
    type(aps_solver_type), intent(inout) :: solver
    !> Contains all information about all domains
    type(aps_domainObj_type), intent(inout) :: domainObj(:)
    !> Contains all spacetime functions with predefined "apesmate"
    type(grw_aps_stFunCplArray_type), intent(out) :: stFunCplList
    !> To be filled with information in coupling request type by
    !! grouping request per coupling variable name.
    type(aps_coupling_variables_type), intent(out) :: cplVars
    !> apes global params
    type(aps_param_type), intent(inout) :: params
    !--------------------------------------------------------------------------!
    integer :: iDomain, iError, domID
    integer :: sol_type, sol_pos
    real(kind=rk) :: sol_dt
    type(tem_time_type) :: sol_now
    real(kind=rk) :: sol_nowSim, sol_nowSim_max
    integer :: sol_nowIter, sol_nowIter_max
    !--------------------------------------------------------------------------!
    call tem_horizontalSpacer( after = 1, fUnit = aps_logUnit(1) )
    write(aps_logUnit(1),*) 'Initializing each domain with its solver: '

    ! maximum of all domain dt is will be used as global apes params dt
    params%dt = 0.0_rk
    sol_nowSim = 0.0_rk
    sol_nowIter = 0

    call tem_startTimer( timerHandle = aps_timerHandles%initSolver )
    ! loop over local process nDomains
    do iDomain = 1, solver%nDomains
      domID = solver%domainIDs(iDomain)

      ! Update modular logUnit with domain logUnit
      logUnit = domainObj(domID)%logUnit
      dbgUnit = domainObj(domID)%dbgUnit

      sol_type = domainObj(domID)%solver_type
      sol_pos = domainObj(domID)%solver_position
      write(aps_logUnit(1),*) 'Initialize dom:', iDomain, '- solver: ' &
        &                     // trim(domainObj(domID)%header%solName)
      select case (sol_type)
      case (musubi)
        ! initialize musubi
        call aps_init_musubi( me          = solver%musubi(sol_pos),   &
          &                   mus_dt      = sol_dt,                   &
          &                   mus_now     = sol_now,                  &
          &                   aps_maxTime = params%general%simControl &
          &                                       %timeControl%max    )

      case (ateles)
        ! initialize ateles
        call aps_init_ateles( me          = solver%ateles(sol_pos),          &
          &                   elemTimers  = domainObj(domID)%atl_elemTimers, &
          &                   atl_dt      = sol_dt,                          &
          &                   atl_now     = sol_now,                         &
          &                   aps_maxTime = params%general%simControl        &
          &                                       %timeControl%max           )

      end select

      ! time step to synchronize domains
      params%dt = max(sol_dt, params%dt)

      ! solver current time, if a solver uses restart file to
      sol_nowSim = max(sol_nowSim, sol_now%sim)
      sol_nowIter = max(sol_nowIter, sol_now%iter)

    end do  ! iDomain

    write(aps_logUnit(1),*) 'Done initializing domains'
    call tem_horizontalSpacer( after = 1, fUnit = aps_logUnit(1) )
    call tem_stopTimer( timerHandle = aps_timerHandles%initSolver )
    ! reset logUnit and dbgUnit to apesmate units
    logUnit = aps_logUnit
    dbgUnit = aps_dbgUnit

    call tem_startTimer( timerHandle = aps_timerHandles%initCoupling )
    ! Fill stFunCoupling list for each coupling interface in each domain
    call tem_startTimer( timerHandle = aps_timerHandles%fillStFun )
    call aps_fill_stFunCoupling( stFunCplList = stFunCplList,       &
      &                          solver       = solver,             &
      &                          domainObj    = domainObj,          &
      &                          proc         = params%general%proc )
    call tem_stopTimer( timerHandle = aps_timerHandles%fillStFun )

    ! Initialize communication between domains
    call aps_init_cplComm( stFunCplList = stFunCplList,       &
      &                    cplVars      = cplVars,            &
      &                    solver       = solver,             &
      &                    domainObj    = domainObj,          &
      &                    proc         = params%general%proc )

    call tem_stopTimer( timerHandle = aps_timerHandles%initCoupling )

    ! get the number of ranks involved in coupling
    call get_numberCplRanks(cplVars     = cplVars,                &
      &                     ndom_global = solver%nDomains_total,  &
      &                     comm        = params%general%proc%comm)

    ! do synchorization between domains
    ! interpolation, boundary condition, exchange information between
    ! domains etc.
    call aps_sync_domains( stFunCplList = stFunCplList,                  &
      &                    cplVars      = cplVars,                       &
      &                    solver       = solver,                        &
      &                    domainObj    = domainObj,                     &
      &                    time         = params%general%simControl%now, &
      &                    proc         = params%general%proc            )

    ! get maximum dt of all domains
    call mpi_allreduce(params%dt, params%dt_max, 1, rk_mpi, mpi_max, &
      &                params%general%proc%comm, iError)

    ! get maximum dt of all domains
    call mpi_allreduce(sol_nowSim, sol_nowSim_max, 1, rk_mpi, mpi_max, &
      &                params%general%proc%comm, iError)
    call mpi_allreduce(sol_nowIter, sol_nowIter_max, 1, mpi_integer, mpi_max, &
      &                params%general%proc%comm, iError)

    params%general%simControl%now%sim = sol_nowSim_max
    params%general%simControl%now%iter = sol_nowIter_max

    call tem_timeControl_start_at_sim(                           &
      &             me = params%general%simControl%timeControl,  &
      &             now = params%general%simControl%now )

    if ( params%general%proc%isRoot ) then
      write(logUnit(1),*)"Starting Apesmate MAIN loop with time control:"
      call tem_timeControl_dump(params%general%simControl%timeControl, &
        &                       logUnit(1))
    end if

    call tem_horizontalSpacer( after = 1, fUnit = logUnit(1) )

  end subroutine aps_initialize
  !****************************************************************************!


  !****************************************************************************!
  !> This routine solve domains active on local process
  !>
  subroutine aps_solve(solver, domainObj, stFunCplList, cplVars, params)
    !--------------------------------------------------------------------------!
    !> contains all apes solvers defined in the config file
    type(aps_solver_type), intent(inout) :: solver
    !> Contains all information about all domains
    type(aps_domainObj_type), intent(inout) :: domainObj(:)
    !> Contains all spacetime functions with predefined "apesmate"
    type(grw_aps_stFunCplArray_type), intent(inout) :: stFunCplList
    !> To be filled with information in coupling request type by
    !! grouping request per coupling variable name.
    type(aps_coupling_variables_type), intent(inout) :: cplVars
    !> apes global params
    type(aps_param_type), intent(inout) :: params
    !--------------------------------------------------------------------------!
    integer :: iDomain, iError, domID
    !--------------------------------------------------------------------------!
    ! Main time loop
    !
    call tem_startTimer( timerHandle = aps_timerHandles%simLoop )
    mainloop: do
      ! clear status flags
      call tem_simControl_clearStat(params%general%simControl)

      write(logUnit(6),*) 'Step size (dt_max): ', params%dt_max

      ! loop over local process nDomains
      do iDomain = 1, solver%nDomains
        domID = solver%domainIDs(iDomain)
        call tem_startTimer( timerHandle = domainObj(domID)%singleDom )
        call aps_solve_singleDomain( solver    = solver,          &
          &                          params    = params,          &
          &                          domainObj = domainObj(domID) )
        call tem_stopTimer( timerHandle = domainObj(domID)%singleDom )
      end do

      ! reset logUnit and dbgUnit to apesmate units
      logUnit = aps_logUnit
      dbgUnit = aps_dbgUnit

      ! do synchorization between domains
      ! interpolation, boundary condition, exchange information between
      ! domains etc.
      call aps_sync_domains( stFunCplList = stFunCplList,                  &
        &                    cplVars      = cplVars,                       &
        &                    solver       = solver,                        &
        &                    domainObj    = domainObj,                     &
        &                    time         = params%general%simControl%now, &
        &                    proc         = params%general%proc            )

      do iDomain = 1, solver%nDomains
        domID = solver%domainIDs(iDomain)
        call tem_startTimer( timerHandle = domainObj(domID)%cplWait )
      end do

      call mpi_allreduce(params%dt, params%dt_max, 1, rk_mpi, mpi_max, &
        &                params%general%proc%comm, iError)

      call tem_simControl_syncUpdate(me      = params%general%simControl, &
        &                            proc    = params%general%proc,       &
        &                            dt      = params%dt_max)

      do iDomain = 1, solver%nDomains
        domID = solver%domainIDs(iDomain)
        call tem_stopTimer( timerHandle = domainObj(domID)%cplWait )
      end do

      if (params%general%simControl%status%bits(tem_stat_interval) .and. &
        & params%general%proc%isRoot) then
        call tem_time_dump(params%general%simControl%now, logUnit(1))
        call tem_horizontalSpacer( after = 1, before = 1, fUnit = logUnit(1) )
      endif

      if( tem_status_run_end(params%general%simControl%status) .or.    &
        & tem_status_run_terminate(params%general%simControl%status) ) &
        & exit mainLoop

    enddo mainloop
    call tem_stopTimer( timerHandle = aps_timerHandles%simLoop )
    !
    ! Finish main loop
    !-----------------------------------------------------------------------------

  end subroutine aps_solve
  !****************************************************************************!


  !****************************************************************************!
  !> This routine solve single domain defined in the domainObj
  subroutine aps_solve_singleDomain( solver, params, domainObj )
    !--------------------------------------------------------------------------!
    !> contains all apes solvers defined in the config file
    type(aps_solver_type), target, intent(inout) :: solver
    !> apes global params
    type(aps_param_type), intent(inout) :: params
    !> current domain object
    type(aps_domainObj_type), intent(inout) :: domainObj
    !--------------------------------------------------------------------------!
    integer :: sol_type, sol_pos, iStatus
    logical :: stat_interval
    real(kind=rk) :: sol_dt, next_syncTime
    !--------------------------------------------------------------------------!
    ! next synchorous time for solver to run to reach
    next_syncTime = params%general%simControl%now%sim + params%dt_max

    write(logUnit(6),*) 'Next syncTime: ', next_syncTime

    stat_interval = .false.

    ! Update modular logUnit with domain logUnit
    logUnit = domainObj%logUnit
    dbgUnit = domainObj%dbgUnit

    sol_type = domainObj%solver_type
    sol_pos = domainObj%solver_position

    sol_dt = 0.0_rk
    select case (sol_type)
    case (musubi)
      ! solve musubi
      call aps_solve_musubi( me            = solver%musubi(sol_pos),       &
        &                    timerHandles  = domainObj%mus_timerHandles,   &
        &                    next_syncTime = next_syncTime,                &
        &                    mus_dt        = sol_dt,                       &
        &                    aps_now       = params%general%simControl%now )

    case (ateles)
      call aps_solve_ateles( me            = solver%ateles(sol_pos),       &
        &                    timerHandles  = domainObj%atl_timerHandles,   &
        &                    elemTimers    = domainObj%atl_Elemtimers,     &
        &                    next_syncTime = next_syncTime,                &
        &                    atl_dt        = sol_dt,                       &
        &                    aps_now       = params%general%simControl%now )

    end select

    ! Apesmate time step to synchronize domains
    params%dt = max(sol_dt, params%dt )

    stat_interval = domainObj%status%bits(tem_stat_interval)

    ! Copy domain status bits. Use .or. if process contains two domains
    do iStatus = tem_stat_run_terminate, tem_stat_nonPhysical
      params%general%simControl%status%bits(iStatus)       &
        & = params%general%simControl%status%bits(iStatus) &
        & .or. domainObj%status%bits(iStatus)
    end do

    if (domainObj%isRoot) then
      if (domainObj%status%bits(tem_stat_steady_state)) then
        call tem_horizontalSpacer( before = 1, fUnit = logUnit(6) )
        write(logUnit(3),*) 'Reached steady state for domain: ', &
          & trim(domainObj%header%label)
        call tem_horizontalSpacer( after = 1, fUnit = logUnit(6) )
      end if

      if(stat_interval ) then
        write(logUnit(10),*) 'aps_dt ', params%dt
        write(logUnit(10),*) 'aps_dt_max ', params%dt_max
        write(logUnit(10),*) 'sol_dt ', sol_dt
        write(logUnit(2),*) 'Solved domain name: ', &
          & trim(domainObj%header%label)
        call tem_horizontalSpacer( after = 1, fUnit = logUnit(1) )
      end if
    endif

  end subroutine aps_solve_singleDomain
  !****************************************************************************!


  !****************************************************************************!
  !> This routine finalize domains active on local process
  subroutine aps_finalize(solver, domainObj, params)
    !--------------------------------------------------------------------------!
    !> contains all apes solvers defined in the config file
    type(aps_solver_type), target, intent(inout) :: solver
    !> Contains all information about all domains
    type(aps_domainObj_type), intent(in) :: domainObj(:)
    !> apes global params
    type(aps_param_type), intent(inout) :: params
    !--------------------------------------------------------------------------!
    integer :: iDomain, domID
    integer :: sol_type, sol_pos
    !--------------------------------------------------------------------------!
    call tem_startTimer( timerHandle = aps_timerHandles%finalize )
    call tem_time_dump(params%general%simControl%now, logUnit(1))
    ! dump status information on how simulation was terminated
    call tem_status_dump(params%general%simControl%status, aps_logUnit(1))

    ! loop over local process nDomains
    do iDomain = 1, solver%nDomains
      domID = solver%domainIDs(iDomain)

      ! Update modular logUnit with domain logUnit
      logUnit = domainObj(domID)%logUnit
      dbgUnit = domainObj(domID)%dbgUnit

      sol_type = domainObj(domID)%solver_type
      sol_pos = domainObj(domID)%solver_position
      call tem_startTimer( timerHandle = aps_timerHandles%finalSolver )
      select case (sol_type)
      case (musubi)
        ! finalize musubi
        call aps_finalize_musubi( me           = solver%musubi(sol_pos), &
          &                       timerHandles = domainObj(domID)        &
          &                                      %mus_timerHandles       )

      case (ateles)
        ! finalize ateles
        call aps_finalize_ateles( me           = solver%ateles(sol_pos), &
          &                       timerHandles = domainObj(domID)        &
          &                                      %atl_timerHandles,      &
          &                       elemTimers   = domainObj(domID)        &
          &                                      %atl_elemTimers,        &
          &                       timerConfig  = domainObj(domID)        &
          &                                      %timerConfig            )

      end select
      call tem_stopTimer( timerHandle = aps_timerHandles%finalSolver )

      if (domainObj(domID)%isRoot) then
        write(logUnit(1),*) 'Finalized domain name: ', &
          & trim(domainObj(domID)%header%label)
        call tem_horizontalSpacer( after = 1, fUnit = logUnit(1) )

        if ( tem_status_run_terminate(domainObj(domID)%status) ) then
          write(logUnit(1),*) '+--------------------------------------------+'
          write(logUnit(1),*) 'Abnormal termination of domain: ' &
            &         // trim(domainObj(domID)%header%label)
          write(logUnit(1),*) '+--------------------------------------------+'
          write(logUnit(1),*)
        end if
      end if

    end do
    call tem_stopTimer( timerHandle = aps_timerHandles%finalize )

    ! reset logUnit and dbgUnit to apesmate units
    logUnit = aps_logUnit
    dbgUnit = aps_dbgUnit

    ! write out timers for performance analysis only for successful runs
    if ( .not. tem_status_run_terminate(params%general%simControl%status) ) then
      call aps_dumpTimers(general   = params%general, &
        &                 domainObj = domainObj )
    end if

  end subroutine aps_finalize
  !****************************************************************************!

end module aps_program_module
!******************************************************************************!
