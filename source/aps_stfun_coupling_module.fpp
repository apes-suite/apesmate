! Copyright (c) 2016 Kannan Masilamani <kannan.masilamani@dlr.de>
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

! *****************************************************************************!
!> This module contains data type for coupling with pointer to spacetime
!! function in different solvers.
!!
!! \author Kannan Masilamani, Verena Krupp
?? include 'arrayMacros.inc'
!!
module aps_stFun_coupling_module
  use env_module,               only: minlength, zerolength
  use tem_logging_module,       only: logUnit
  use tem_debug_module,         only: dbgUnit
  use tem_aux_module,           only: tem_abort
  use tem_spacetime_fun_module, only: tem_spacetime_fun_type,   &
    &                                 tem_st_fun_listElem_type, &
    &                                 tem_st_fun_linkedList_type
  use tem_comm_env_module,      only: tem_comm_env_type
  use tem_tools_module,         only: tem_PositionInSorted, &
    &                                 tem_horizontalSpacer
  use tem_grow_array_module,    only: grw_intArray_type

  use aps_solver_module,        only: aps_solver_type
  use aps_domainObj_module,     only: aps_domainObj_type,                 &
    &                                 aps_domainLabel_to_ID, musubi, ateles

  implicit none

  private

  public :: aps_stFun_coupling_type
  public :: grw_aps_stFunCplArray_type
  public :: aps_fill_stFunCoupling

  !> Data type contains pointer to spacetime function which has
  !! predefined = "apesmate" and pointer to spacetime function element list
  !! which contains point data for coupling on local process
  type aps_stFun_coupling_type
    !> Pointer to spacetime function element list
    type(tem_st_fun_listElem_type), pointer :: stFunElemPtr => NULL()

    !> Pointer to spacetime function with predefined "apesmate"
    type(tem_spacetime_fun_type), pointer :: stfunPtr => NULL()

    !> Level to communicate this coupling
    integer :: iLevel

    !> local domain ID
    integer :: loc_domID

    !> Target rank to send points to remote domain in round robin pattern.
    !! Later used as source rank to receive pntRanks from remote domain
    integer :: partner
  end type aps_stFun_coupling_type

?? copy :: GA_decltxt(aps_StFunCpl, type(aps_stFun_coupling_type))

contains

  ! ************************************************************************ !
  !> This routine fill growing array stFun_coupling_type for each coupling
  !! interface in space function in each domain
  subroutine aps_fill_stFunCoupling(stFunCplList, solver, domainObj, proc)
    ! -------------------------------------------------------------------- !
    !> Coupling descriptor to fill with space time function pointers
    type(grw_aps_stFunCplArray_type), intent(out) :: stFunCplList
    !> contains all solver definitions
    type(aps_solver_type), target, intent(in) ::solver
    !> Contains all information about all domains
    type(aps_domainObj_type), intent(in) :: domainObj(:)
    !> Global mpi environment
    type(tem_comm_env_type), intent(in) :: proc
    ! -------------------------------------------------------------------- !
    integer :: iDom, domID, sol_type, sol_pos
    integer :: iStElem, iStCpl
    type(tem_st_fun_linkedList_type), pointer :: stFunLinkList => NULL()
    type(tem_st_fun_listElem_type), pointer :: stFunElem_cur
    type(aps_stfun_coupling_type) :: stFunCpl_loc
    integer :: iLevel, minLevel, maxLevel
    integer :: rem_domID
    ! -------------------------------------------------------------------- !
    write(logUnit(1),*) 'Initializing fill stFun coupling in each domain: '
    write(dbgUnit(1),*) 'Fill apesmate stFun coupling:'

    call init(me = stFunCplList)

    do iDom = 1, solver%nDomains
      ! current domain ID
      domID = solver%domainIDs(iDom)
      ! solver type
      sol_type = domainObj(domID)%solver_type
      ! position of solver_type in respective solver array
      sol_pos = domainObj(domID)%solver_position

      select case (sol_type)
      case (musubi)
        stFunLinkList => solver%musubi(sol_pos)%scheme%st_funList
        minLevel = solver%musubi(sol_pos)%geometry%tree%global%minLevel
        maxLevel = solver%musubi(sol_pos)%geometry%tree%global%maxLevel
      case (ateles)
        stFunLinkList => solver%ateles(sol_pos)%equation%stFunList
        minLevel = solver%ateles(sol_pos)%tree%global%minLevel
        maxLevel = solver%ateles(sol_pos)%tree%global%maxLevel
      case default
        minLevel = -1
        maxLevel = -1
        write(logunit(1),*) 'ERROR: In Fill_stFunCoupling, Unknown solver'
        call tem_abort()
      end select

      stFunElem_cur => stFunLinkList%head
      do

        if (.not. associated(stFunElem_cur)) EXIT
        do iStElem = 1, stFunElem_cur%nVals

          if (trim(stFunElem_cur%val(iStElem)%fun_kind) == 'apesmate') then
             stFunCpl_loc%stFunElemPtr => stFunElem_cur
             stFunCpl_loc%stFunPtr => stFunElem_cur%val(iStElem)
             do iLevel = minLevel, maxLevel
               ! add spacetime function to coupling list only if there
               ! are some point on iLevel
               if (stFunElem_cur%pntData%pntLvl(iLevel)%nPnts > 0) then
                 stFunCpl_loc%iLevel = iLevel
                 stFunCpl_loc%loc_domID = domID
                 call append( me  = stFunCplList, &
                   &          val = stFunCpl_loc  )
               end if
             end do !iLevel
          end if

        end do !iStElem
        stFunElem_cur => stFunElem_cur%next
      end do

    end do !iDomain

    call truncate( me = stFunCplList )

    ! Now loop over stFun coupling objects and set remote domain ID from
    ! remote domain label specified in stfun table
    do iStCpl = 1, stFunCplList%nVals
      rem_domID = aps_domainLabel_to_ID(                             &
        &             domLabels = domainObj(:)%header%label,         &
        &             label     = stFunCplList%val(iStCpl)           &
        &                                     %stFunPtr%aps_coupling &
        &                                     %rem_domLabel          )
      stFunCplList%val(iStCpl)%stFunPtr%aps_coupling%rem_domID = rem_domID

      ! Store target rank to send points and to receive pntRanks
      domID = stFunCplList%val(iStCpl)%loc_domID
      stFunCplList%val(iStCpl)%partner                                        &
        & = get_target_roundRobin( loc_domRanks = domainObj(domID)%ranks,     &
        &                          rem_domRanks = domainObj(rem_domID)%ranks, &
        &                          myRank       = proc%rank                   )
    end do

    write(dbgUnit(1),*) 'nStFun coupling: ',stFunCplList%nVals
    write(logUnit(1),*) 'Done fill stFun coupling'
    call tem_horizontalSpacer( after = 1, fUnit = logUnit(1) )
  end subroutine aps_fill_stFunCoupling
  ! ************************************************************************ !


  ! ************************************************************************ !
  !> This function returns target rank to communicate in remote domain
  !! using round robin pattern
  function get_target_roundRobin(loc_domRanks, rem_domRanks, myRank ) &
    & result(target_rank)
    ! -------------------------------------------------------------------- !
    !> Local domain ranks
    type(grw_intArray_type), intent(in) :: loc_domRanks
    !> Remote domain ranks
    type(grw_intArray_type), intent(in) :: rem_domRanks
    !> global rank ID of local process
    integer, intent(in) :: myRank
    !> Target rank to send points and offset bit initially
    integer :: target_rank
    ! -------------------------------------------------------------------- !
    integer :: loc_nProcs, rem_nProcs, remote_rank_index, my_rank_index
    ! -------------------------------------------------------------------- !
    ! number of procs in local domain
    loc_nProcs = loc_domRanks%nVals

    ! number of procs in remote domain
    rem_nProcs = rem_domRanks%nVals

    ! getting the partner rank, since all ranks are distributed in the
    ! domainObj%rank list, we identify the ranks which should talk to each
    ! other via the index in the rank list
    my_rank_index = tem_PositionInSorted ( &
      &  me    = loc_domRanks%val,         &
      &  val   = myRank,                   &
      &  lower = 1,                        &
      &  upper = loc_nProcs                )
    ! -1, since it should start from 0 for mod
    my_rank_index = my_rank_index - 1
    ! get the remote rank based on indices
    remote_rank_index = mod( my_rank_index, rem_nProcs )
    ! + 1 since it is the index in the list
    remote_rank_index = remote_rank_index + 1
    ! finally we know to which proc send data
    target_rank = rem_domRanks%val(remote_rank_index)

  end function get_target_roundRobin
  ! ************************************************************************ !


?? copy :: GA_impltxt(aps_StFunCpl, type(aps_stFun_coupling_type))

end module aps_stFun_coupling_module
! *****************************************************************************!
