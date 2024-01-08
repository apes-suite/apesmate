!******************************************************************************!
!> This module contains ateles data type and growing array of ateles types
!! Also include routines needed to couple ateles.
!! \author Verena Krupp

module aps_ateles_module
  ! include treelm modules
  use env_module,               only: rk
  use tem_status_module,        only: tem_status_type
  use tem_aux_module,           only: tem_abort
  use tem_spacetime_fun_module, only: tem_st_fun_linkedList_type
  use tem_varSys_module,        only: tem_varSys_type, tem_varSys_init
  use treelmesh_module,         only: treelmesh_type
  use tem_timer_module,         only: tem_timer_type,       &
    &                                 tem_timerConfig_type
  use tem_time_module,          only: tem_time_type


  implicit none

  private

  public :: aps_ateles_type
  public :: aps_load_ateles
  public :: aps_init_ateles
  public :: aps_solve_ateles
  public :: aps_finalize_ateles
  public :: atl_timer_handle_type
  public :: atl_set_elemTimers, atl_get_elemTimers

  !> Dummy equation type
  type equation_type
    !> Dummy varSys
    type(tem_varSys_type) :: varSys
    !> contains spacetime functions defined for lua variables
    type(tem_st_fun_linkedList_type) :: stFunList
  end type equation_type

  !> This type contains all data types needed to work with Musubi
  type aps_ateles_type
    type(equation_type) :: equation
    type(treelmesh_type) :: tree
  end type aps_ateles_type

  !> Dummy timer handle
  type atl_timer_handle_type
    integer :: dummy
  end type

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
    call tem_varSys_init( me         = me%equation%varSys, &
      &                   systemName = 'dummy',           &
      &                   length     = 0                  )
    me%equation%stFunList%head => NULL()
    timerHandles%dummy = 0
    status => NULL()
    isRoot = .false.

    call tem_abort('ERROR: DUMMY load ateles routine')

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
    !> Ateles current time
    type(tem_time_type), intent(out) :: atl_now
    !> ateles time step
    real(kind=rk), intent(out) :: atl_dt
    !> overwrite solver time_control%max with apesmate time_control%max
    type(tem_time_type), intent(in) :: aps_maxTime
    !---------------------------------------------------------------------------
    call tem_abort('ERROR: DUMMY init ateles routine')

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
    type(atl_timer_handle_type), intent(in) :: timerHandles
    !> Elementwise timers
    type(tem_timer_type), intent(in) :: elemTimers 
    !> next synchorous time for solver to run to reach
    real(kind=rk), intent(in) :: next_syncTime
    !> ateles time step
    real(kind=rk), intent(out) :: atl_dt
    !> Current simulation time
    type(tem_time_type), intent(in) :: aps_now
    !---------------------------------------------------------------------------
    call tem_abort('ERROR: DUMMY solve ateles routine')

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
    call tem_abort('ERROR: DUMMY finalize ateles routine')

  end subroutine aps_finalize_ateles   
  ! ***************************************************************************!

  !> This routine sets elementTimers passed by apesmate
  subroutine atl_set_elemTimers(elemTimers)
    !---------------------------------------------------------------------------
    type(tem_timer_type), intent(in) :: elemTimers
    !---------------------------------------------------------------------------
    call tem_abort('ERROR: DUMMY finalize ateles routine')
  end subroutine atl_set_elemTimers
  ! ***************************************************************************!

  ! ***************************************************************************!
  !> This function returns local modular variable atl_elemTimers to apesmate
  function atl_get_elemTimers() result(elemTimers)
    !---------------------------------------------------------------------------
    type(tem_timer_type) :: elemTimers
    !---------------------------------------------------------------------------
    call tem_abort('ERROR: DUMMY finalize ateles routine')
  end function atl_get_elemTimers
  !****************************************************************************!


end module aps_ateles_module
!******************************************************************************!
