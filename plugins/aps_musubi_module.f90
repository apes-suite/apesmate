! *****************************************************************************!
!> This module contains musubi data type and growing array of musubi types
!! Also include routines needed to couple musubi.
!! \author Kannan Masilamani
module aps_musubi_module
  ! include treelm modules
  use env_module,                   only: rk
  use tem_general_module,           only: tem_start
  use tem_adaptation_config_module, only: tem_adapt_type
  use tem_time_module,              only: tem_time_type, tem_time_advance, &
    &                                     tem_time_never, tem_time_reset,  &
    &                                     tem_time_dump
  use tem_comm_env_module,          only: tem_comm_env_fin
  use tem_status_module,            only: tem_status_type,       &
    &                                     tem_stat_steady_state, &
    &                                     tem_status_clear
  use tem_logging_module,           only: logUnit
  use tem_aux_module,               only: tem_abort
  use tem_simControl_module,        only: tem_simControl_steadyState_reset

  ! include musubi modules
  ! RESPECT THE ORDER !!!!!!!!
  use mus_scheme_type_module, only: mus_scheme_type
  use mus_param_module,       only: mus_param_type
  use mus_timer_module,       only: mus_init_mainTimer,    &
    &                               mus_timer_handle_type, &
    &                               mus_init_levelTimer,   &
    &                               mus_init_bcTimer,      &
    &                               mus_get_timerHandles,  &
    &                               mus_set_timerHandles
  use mus_geom_module,        only: mus_geom_type 
  use mus_control_module,     only: mus_control_type
  use mus_aux_module,         only: mus_banner
  use mus_config_module,      only: mus_load_config
  use mus_varSys_module,      only: mus_varSys_solverData_type
  use mus_program_module,     only: mus_initialize, mus_solve, mus_finalize
 
  implicit none

  private

  public :: aps_musubi_type
  public :: aps_load_musubi
  public :: aps_init_musubi
  public :: aps_solve_musubi
  public :: aps_finalize_musubi
  public :: mus_timer_handle_type

  !> This type contains all data types needed to work with Musubi
  type aps_musubi_type
    !> scheme contains mainly state values and 
    !! boundary infos which describe different flow physics like lbm, 
    !! lbm_incomp and multi-species_liquid
    type(mus_scheme_type) :: scheme

    !> Musubi geometry type contains treelmesh, boundary info and
    !! weights for load balancing
    type(mus_geom_type) :: geometry
    !> contains all global information related to simulation

    type(mus_param_type) :: params  
    !> contains main control routine function pointer
    type(mus_control_type) :: control

    !> Mesh adaptation
    type(tem_adapt_type) :: adapt

    !> musubi solver container for varSys method data
    type(mus_varSys_solverData_type) :: solverData
  end type aps_musubi_type


contains


  !****************************************************************************!
  !> This routine start musubi solver by loading its configuration file
  subroutine aps_load_musubi( me, timerHandles, status, isRoot, comm, &
    &                         configFile, aps_now )
    !--------------------------------------------------------------------------!
    !> musubi type
    type(aps_musubi_type), target, intent(out) :: me
    !> Timer handles
    type(mus_timer_handle_type), intent(out) :: timerHandles
    !> status bits
    type(tem_status_type), pointer, intent(out) :: status
    !> True for root process
    logical, intent(out) :: isRoot
    !> sub-communicator
    integer, intent(in) :: comm
    !> Configuration file
    character(len=*), intent(in) :: configFile
    !> Starting time of apes
    type(tem_time_type), intent(inout) :: aps_now
    !--------------------------------------------------------------------------!

    ! Initialize musubi environment
    call tem_start(codeName   = 'Musubi',                    &
      &            version    = me%params%version,           &
      &            general    = me%params%general,           &
      &            comm       = comm,                        &
      &            simControl = me%params%general%simControl )

    ! set musubi configuration file after tem_start since tem_start
    ! initialize solverhead type
    me%params%general%solver%configFile = configFile

    if (me%params%general%proc%rank == 0) then
      call mus_banner(solver = me%params%general%solver)
    end if  

    ! initialize global timers 
    call mus_init_mainTimer()

    ! load configuration file 
    call mus_load_config( scheme     = me%scheme,     &
      &                   solverData = me%solverData, &
      &                   geometry   = me%geometry,   &
      &                   params     = me%params,     &
      &                   adapt      = me%adapt       )

    call mus_init_levelTimer( me%geometry%tree%global%minLevel, &
      &                       me%geometry%tree%global%maxLevel )
    call mus_init_bcTimer( me%geometry%boundary%nBCtypes )

    ! return musubi timer handles in domain Obj
    timerHandles = mus_get_timerHandles()

    ! return if current process is root of musubi domain
    isRoot = me%params%general%proc%isRoot

    ! return pointer to musubi status
    status => me%params%general%simControl%status

    ! set apes time max of solvers time if solvers uses restart file to restart
    ! simulation
    aps_now%sim = max(aps_now%sim, me%params%general%simControl%now%sim)
  end subroutine aps_load_musubi
  !****************************************************************************!

  !****************************************************************************!
  !> Initialize musubi domain
  subroutine aps_init_musubi( me, mus_dt, mus_now, aps_maxTime )
    !---------------------------------------------------------------------------
    !> musubi type
    type(aps_musubi_type), intent(inout) :: me
    !> musubi time step
    real(kind=rk), intent(out) :: mus_dt
    !> Musubi current time
    type(tem_time_type), intent(out) :: mus_now
    !> overwrite solver time_control%max with apesmate time_control%max
    type(tem_time_type), intent(in) :: aps_maxTime
    !---------------------------------------------------------------------------
    call mus_initialize(scheme     = me%scheme,     &
      &                 solverData = me%solverData, &
      &                 geometry   = me%geometry,   &
      &                 params     = me%params,     &
      &                 control    = me%control     )
    
    ! set solver simulation timeControl max with apesmate timeControl max 
    ! to set solver wall time same as in apesmate while sim time is 
    ! defined by apesmate for each solver at every timestep
    me%params%general%simControl%timeControl%max = tem_time_never()
    me%params%general%simControl%timeControl%max%clock = aps_maxTime%clock
    
    ! time step of current musubi
    mus_dt = me%params%physics%dt

    ! current time of musubi
    if (me%params%general%simControl%abortCriteria%steady_state) then
      call tem_time_reset(mus_now) 
    else
      mus_now = me%params%general%simControl%now
    end if  

  end subroutine aps_init_musubi
  !****************************************************************************!

  !****************************************************************************!
  !> Solve musubi domain
  subroutine aps_solve_musubi( me, timerHandles, next_syncTime, mus_dt, &
    &                          aps_now )
    !---------------------------------------------------------------------------
    !> musubi type
    type(aps_musubi_type), intent(inout) :: me
    !> Timer handles
    type(mus_timer_handle_type), intent(inout) :: timerHandles
    !> next synchorous time for solver to run to reach
    real(kind=rk), intent(in) :: next_syncTime
    !> musubi time step
    real(kind=rk), intent(out) :: mus_dt
    !> Current simulation time
    type(tem_time_type), intent(in) :: aps_now
    !---------------------------------------------------------------------------
    ! Update modular timer handle
    call mus_set_timerHandles(timerHandles)

    if (me%params%general%simControl%abortCriteria%steady_state) then
      ! Reset solver time, status bit, convergence and simControl trigger 
      ! for steady state domain
      call tem_simControl_steadyState_reset(me%params%general%simControl)
    else  
      ! Update solver time with current apesmate time
      me%params%general%simControl%now = aps_now
      ! update solvers simulation timeControl max with next sync time
      ! only if is not a steady state problem
      me%params%general%simControl%timeControl%max%sim = next_syncTime 
    end if 

    ! musubi time step
    mus_dt = me%params%physics%dt

    call mus_solve(scheme     = me%scheme,     &
      &            solverData = me%solverData, &
      &            geometry   = me%geometry,   &
      &            params     = me%params,     &
      &            control    = me%control,    &
      &            adapt      = me%adapt       )

    timerHandles = mus_get_timerHandles()
 
  end subroutine aps_solve_musubi
  !****************************************************************************!

  !****************************************************************************!
  !> Finalize musubi domain
  subroutine aps_finalize_musubi( me, timerHandles )
    !---------------------------------------------------------------------------
    !> musubi type
    type(aps_musubi_type), intent(inout) :: me
    !> Timer handles
    type(mus_timer_handle_type), intent(in) :: timerHandles
    !---------------------------------------------------------------------------
    ! Update modular timer handle
    call mus_set_timerHandles(timerHandles)

    call mus_finalize(scheme       = me%scheme,                     &
      &               tree         = me%geometry%tree,              &
      &               params       = me%params,                     &
      &               nBCs         = me%geometry%boundary%nBCtypes, &
      &               levelPointer = me%geometry%levelPointer,      &
      &               globIBM      = me%geometry%globIBM            )


    ! free musubi sub-communicator
    call tem_comm_env_fin(me%params%general%proc)
  end subroutine aps_finalize_musubi
  ! ***************************************************************************!


end module aps_musubi_module
! *****************************************************************************!
