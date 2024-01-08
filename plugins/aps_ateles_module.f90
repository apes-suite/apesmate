!******************************************************************************!
!> This module contains ateles data type and growing array of ateles types
!! Also include routines needed to couple ateles.
!! \author Verena Krupp

module aps_ateles_module
  ! include treelm modules
  use env_module,             only: rk, pathLen
  use tem_general_module,     only: tem_start
  use tem_time_module,        only: tem_time_type, tem_time_advance, &
    &                               tem_time_never, tem_time_reset
  use tem_comm_env_module,    only: tem_comm_env_fin
  use tem_status_module,      only: tem_status_type, tem_stat_steady_state
  use tem_convergence_module, only: tem_convergence_reset
  use treelmesh_module,       only: treelmesh_type
  use tem_timer_module,       only: tem_timer_type,       &
    &                               tem_timerConfig_type, &
    &                               tem_set_timerConfig,  & 
    &                               tem_get_timerConfig,  &
    &                               tem_timer_dump_glob
  use tem_logging_module,     only: logUnit
  use tem_simControl_module,  only: tem_simControl_steadyState_reset

  ! include ateles modules
  use atl_solver_param_module, only: atl_solver_param_type
  use atl_container_module,    only: atl_element_container_type
  use atl_equation_module,     only: atl_equations_type
  use atl_varSys_module,       only: atl_varSys_solverData_type
  use atl_program_module,      only: atl_load_config,        &
    &                                atl_initialize_program, &
    &                                atl_solve_program,      &
    &                                atl_finalize_program
  use atl_aux_module,          only: atl_banner
  use atl_timer_module,        only: atl_addTimers, atl_timer_handle_type, &
    &                                atl_set_timerHandles, atl_set_elemTimers, &
    &                                atl_get_timerHandles, atl_get_elemTimers
  
  use ply_poly_project_module, only: ply_poly_project_type

  implicit none

  private

  public :: aps_ateles_type
  public :: aps_load_ateles
  public :: aps_init_ateles
  public :: aps_solve_ateles
  public :: aps_finalize_ateles
  public :: atl_timer_handle_type
  public :: atl_set_elemTimers, atl_get_elemTimers

  !> This type contains all data types needed to work with Ateles
  type aps_ateles_type
    !> The structure that holds the solver parameter
    type(atl_solver_param_type)                   :: params
    !> Description of the equation system to solve
    type(atl_equations_type)                      :: equation
    !> The treelmesh data structure
    type(treelmesh_type)                      :: tree
    !> Data Infomation of the variable System
    type(atl_varSys_solverData_type)          :: varSys_data
    !> Number of cells on each levels
    integer, allocatable                      :: nCellsNoBnd(:)
    !> Main data structure of Ateles describing the mesh elements
    type(atl_element_container_type)              :: element_container
    !> Desribe the projetion methods for the polynomials
    type(ply_poly_project_type), allocatable  :: poly_proj_list(:)
  end type aps_ateles_type

contains


  ! ***************************************************************************!
  !> This routine start ateles solver by loading its configuration file
  subroutine aps_load_ateles( me, timerHandles, timerConfig, status, isRoot, &
    &                         comm, configFile, aps_now )
    !--------------------------------------------------------------------------!
    !> ateles type
    type(aps_ateles_type), target, intent(out) :: me
    !> Timer handles
    type(atl_timer_handle_type), intent(out) :: timerHandles
    !> Timer config 
    type(tem_timerConfig_type), intent(out) :: timerConfig
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
    
    ! Initialize atekes  environment
    call tem_start( codeName   = 'ATELES',                    &
      &             version    = 'v0.4',                      &
      &             general    = me%params%general,           &
      &             comm       = comm,                        &
      &             simcontrol = me%params%general%simControl )
 
    ! set atekes configuration file after tem_start since tem_start
    ! initialize solverhead type
    me%params%general%solver%configFile = configFile
 
    if (me%params%general%proc%rank == 0) then
      call atl_banner(trim(me%params%general%solver%version))
    end if  
 
    ! init the timer
    call atl_addTimers()
    
    ! set the timer config
    call tem_set_timerConfig(timerConfig)
 
    ! load the config file
    call atl_load_config(params = me%params, &
      &                  tree   = me%tree    )

    ! return ateles timer handles to domain Obj
    timerHandles = atl_get_timerHandles()

    ! return the timer config
    timerConfig = tem_get_timerConfig()

    ! return if current process is root of ateles domain
    isRoot = me%params%general%proc%isRoot

    ! return pointer to ateles status
    status => me%params%general%simControl%status

    ! set apes time max of solvers time if solvers uses restart file to restart
    ! simulation
    aps_now%sim = max(aps_now%sim, me%params%general%simControl%now%sim)

  end subroutine aps_load_ateles
  ! ***************************************************************************!

  !****************************************************************************!
  !> Initialize ateles domain
  subroutine aps_init_ateles( me, elemTimers, atl_dt, atl_now, aps_maxTime )
    !---------------------------------------------------------------------------
    !> ateles type
    type(aps_ateles_type), intent(inout) :: me
    !> Elementwise Timers
    type(tem_timer_type), intent(inout) :: elemTimers
    !> ateles time step
    real(kind=rk), intent(out) :: atl_dt
    !> Ateles current time
    type(tem_time_type), intent(out) :: atl_now
    !> overwrite solver time_control%max with apesmate time_control%max
    type(tem_time_type), intent(in) :: aps_maxTime
    !---------------------------------------------------------------------------
    call atl_initialize_program( params            = me%params,            &
      &                          equation          = me%equation,          &
      &                          tree              = me%tree,              &
      &                          varSys_data       = me%varSys_data,       &
      &                          nCellsNoBnd       = me%nCellsNoBnd,       &
      &                          element_container = me%element_container, &
      &                          poly_proj_list    = me%poly_proj_list     )
    ! return ateles element wise timer to domain Obj which were init
    ! in atl_initialize_program
    elemTimers = atl_get_elemTimers()
    
    ! set solver simulation timeControl max with apesmate timeControl max 
    ! to set solver wall time same as in apesmate while sim time is 
    ! defined by apesmate for each solver at every timestep
    me%params%general%simControl%timeControl%max = tem_time_never()
    me%params%general%simControl%timeControl%max%clock = aps_maxTime%clock

    
    ! time step of current ateles, taking the one from minlevel since currently
    ! all levels have the same timestep
    atl_dt = me%element_container%cubes%scheme_list(me%tree%global%minLevel) &
      &                                %time%dt

    ! current time of ateles
    if (me%params%general%simControl%abortCriteria%steady_state) then
      call tem_time_reset(atl_now) 
    else
      atl_now = me%params%general%simControl%now
    end if  

  end subroutine aps_init_ateles  
  ! ***************************************************************************!
 
  !****************************************************************************!
  !> Solve ateles domain
  subroutine aps_solve_ateles( me, timerHandles, elemTimers, next_syncTime, &
    &                          atl_dt, aps_now )
    !---------------------------------------------------------------------------
    !> ateles type
    type(aps_ateles_type), intent(inout) :: me
    !> Timer handles
    type(atl_timer_handle_type), intent(inout) :: timerHandles
    !> Elementwise timers
    type(tem_timer_type), intent(inout) :: elemTimers 
    !> next synchorous time for solver to run to reach
    real(kind=rk), intent(in) :: next_syncTime
    !> ateles time step
    real(kind=rk), intent(out) :: atl_dt
    !> Current simulation time
    type(tem_time_type), intent(in) :: aps_now
    !---------------------------------------------------------------------------
    ! Update modular timer handle
    call atl_set_timerHandles(timerHandles)
    ! and element timers
    call atl_set_elemTimers(elemTimers)

    ! reset convergence to check for new steady state
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

    
    ! solve ateles
    call atl_solve_program( params            = me%params,            &
      &                     equation          = me%equation,          &
      &                     tree              = me%tree,              &
      &                     nCellsNoBnd       = me%nCellsNoBnd,       &
      &                     element_container = me%element_container, &
      &                     poly_proj_list    = me%poly_proj_list     )

    elemTimers = atl_get_elemTimers()
    timerHandles = atl_get_timerHandles()
    
    ! time step of current ateles
    ! taking the one from minlevel since currently
    ! all levels have the same timestep
    atl_dt  = me%element_container%cubes%scheme_list(me%tree%global%minLevel) &
      &                                 %time%dt

  end subroutine aps_solve_ateles  
  ! ***************************************************************************!
 
  !****************************************************************************!
  !> Finalize ateles domain
  subroutine aps_finalize_ateles( me, timerHandles, elemTimers, timerConfig )
    !---------------------------------------------------------------------------
    !> ateles type
    type(aps_ateles_type), intent(inout) :: me
    !> Timer handles
    type(atl_timer_handle_type), intent(in) :: timerHandles
    !> Element timer
    type( tem_timer_type), intent(in) :: elemTimers
    !> timer config required for detailed timer information
    type(tem_timerconfig_type), intent(in) :: timerConfig
    !---------------------------------------------------------------------------
    ! Update modular timer handle
    call atl_set_timerHandles(timerHandles)
    ! and element timers
    call atl_set_elemTimers(elemTimers)

    call atl_finalize_program(params            = me%params,           &
      &                       equation          = me%equation,         &
      &                       tree              = me%tree,             &
      &                       nCellsNoBnd       = me%nCellsNoBnd,      &
      &                       element_container = me%element_container )

    ! dump the detailed timer info
    ! 1. set the correct timer config 
    call tem_set_timerConfig( timerConfig )
    ! 2. call the timer dump routine
    call tem_timer_dump_glob( comm   = me%params%general%proc%comm,     &
      &                       myrank = me%params%general%proc%rank,     &
      &                       nProcs = me%params%general%proc%comm_size )

    ! free ateles solver communicator
    ! to this for every solver
    call tem_comm_env_fin(me%params%general%proc)

  end subroutine aps_finalize_ateles   
  ! ***************************************************************************!


end module aps_ateles_module
!******************************************************************************!
