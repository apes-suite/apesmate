! *****************************************************************************!
!> This module contains musubi data type and growing array of musubi types
!! Also include routines needed to couple musubi.
!! \author Kannan Masilamani
module aps_musubi_module

  ! include treelm modules
  use env_module,               only: rk
  use tem_status_module,        only: tem_status_type
  use tem_aux_module,           only: tem_abort
  use tem_spacetime_fun_module, only: tem_st_fun_linkedList_type
  use tem_varSys_module,        only: tem_varSys_type, tem_varSys_init
  use treelmesh_module,         only: treelmesh_type
  use tem_time_module,          only: tem_time_type

  implicit none

  private

  public :: aps_musubi_type
  public :: aps_load_musubi
  public :: aps_init_musubi
  public :: aps_solve_musubi
  public :: aps_finalize_musubi
  public :: mus_timer_handle_type

  !> Dummy scheme type
  type scheme_type
    !> global variable system definition
    type(tem_varSys_type) :: varSys
    
    !> contains spacetime functions defined for lua variables
    type(tem_st_fun_linkedList_type) :: st_funList
  end type scheme_type

  !> Dummy geometry type
  type geom_type
    !> tree data type
    type( treelmesh_type )  :: tree
  end type geom_type

  !> This type contains all data types needed to work with Musubi
  type aps_musubi_type
    type(scheme_type) :: scheme
    type(geom_type) :: geometry
  end type aps_musubi_type

  !> Dummy timer handle
  type mus_timer_handle_type
    integer :: dummy
  end type

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
    call tem_varSys_init( me         = me%scheme%varSys, &
      &                   systemName = 'dummy',          &
      &                   length     = 0                 )
    me%scheme%st_funList%head => NULL()
    timerHandles%dummy = 0
    status => NULL()
    isRoot = .false.

    call tem_abort('ERROR: DUMMY load musubi routine')

  end subroutine aps_load_musubi
  !****************************************************************************!

  !****************************************************************************!
  !> Initialize musubi domain
  subroutine aps_init_musubi( me, mus_dt, mus_now, aps_maxTime )
    !---------------------------------------------------------------------------
    !> musubi type
    type(aps_musubi_type), intent(inout) :: me
    !> Musubi current time
    type(tem_time_type), intent(out) :: mus_now
    !> musubi time step
    real(kind=rk), intent(out) :: mus_dt
    !> overwrite solver time_control%max with apesmate time_control%max
    type(tem_time_type), intent(in) :: aps_maxTime
    !---------------------------------------------------------------------------
    call tem_abort('ERROR: DUMMY init musubi routine')

  end subroutine aps_init_musubi
  !****************************************************************************!

  !****************************************************************************!
  !> Solve musubi domain
  subroutine aps_solve_musubi( me, timerHandles, next_syncTime, mus_dt, aps_now )
    !---------------------------------------------------------------------------
    !> musubi type
    type(aps_musubi_type), intent(inout) :: me
    !> Timer handles
    type(mus_timer_handle_type), intent(in) :: timerHandles
    !> next synchorous time for solver to run to reach
    real(kind=rk), intent(in) :: next_syncTime
    !> musubi time step
    real(kind=rk), intent(out) :: mus_dt
    !> Current simulation time
    type(tem_time_type), intent(in) :: aps_now
    !---------------------------------------------------------------------------
    call tem_abort('ERROR: DUMMY solve musubi routine')
 
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
    call tem_abort('ERROR: DUMMY finalize musubi routine')

  end subroutine aps_finalize_musubi
  ! ***************************************************************************!

end module aps_musubi_module
! *****************************************************************************!
