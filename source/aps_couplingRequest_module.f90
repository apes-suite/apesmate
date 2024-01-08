! Copyright (c) 2016-2017 Kannan Masilamani <kannan.masilamani@dlr.de>
! Copyright (c) 2016-2017 Verena Krupp <verena.krupp@uni-siegen.de>
! Copyright (c) 2017 Harald Klimach <harald.klimach@dlr.de>
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
!> This module contains coupling request data type received from remote process
!!
!! \author Verena Krupp, Kannan Masilamani
module aps_couplingRequest_module
  use mpi
  use env_module,               only: rk, labelLen, eps, long_k
  use tem_comm_module,          only: tem_communication_type, tem_comm_init, &
    &                                 tem_comm_createBuffer
  use tem_dyn_array_module,     only: dyn_labelArray_type, append, destroy, &
    &                                 dyn_intArray_type, positionOfVal, init
  use tem_grow_array_module,    only: grw_intarray_type, append, init
  use tem_variable_module,      only: tem_variable_type
  use tem_varSys_module,        only: tem_varSys_type
  use tem_operation_var_module, only: tem_varSys_append_operVar
  use tem_tools_module,         only: tem_PositionInSorted, tem_horizontalSpacer
  use tem_aux_module,           only: tem_abort
  use tem_varMap_module,        only: tem_varMap_type, tem_create_varMap
  use treelmesh_module,         only: treelmesh_type
  use tem_topology_module,      only: tem_IDofCoord, tem_PathOf,               &
    &                                 tem_PathComparison, tem_path_type
  use tem_geometry_module,      only: tem_CoordOfReal
  use tem_construction_module,  only: tem_find_depProc
  use tem_comm_env_module,      only: tem_comm_env_type
  use tem_time_module,          only: tem_time_type
  use tem_timer_module,         only: tem_startTimer, tem_stopTimer
  use tem_logging_module,       only: logUnit
  use tem_debug_module,         only: dbgUnit

  ! apesmate modules
  use aps_domainObj_module,       only: aps_domainObj_type, musubi, ateles
  use aps_solver_module,          only: aps_solver_type
  use aps_logging_module,         only: aps_logUnit, aps_dbgUnit

  use aps_ateles_module,          only: atl_set_elemTimers, atl_get_elemTimers
  implicit none

  private

  public :: aps_couplingRequest_type
  public :: aps_coupling_variables_type
  public :: append, destroy
  public :: aps_create_cplVars_fromCplRequests
  public :: aps_cplReq_checkVars
  public :: aps_cplReq_identify_pntRanks
  public :: aps_cplVars_evaluate
  public :: get_numbercplranks

  !> Contains points, evalVal and communication buffer per level
  type requested_varData_level_type
    !> Communication buffer to send evaluated values to requested domain
    type(tem_communication_type) :: sendBuffer

    !> Evaluated point values
    !! size: nPnts*nScalars of requested variables
    real(kind=rk), allocatable :: evalVal(:)

!KM!    !> Space points to evaluate the variable
!KM!    !! size: nPnts, 3
!KM!    real(kind=rk), allocatable :: points(:, :)

    !> Indices for the  points to evaluate the variable
    !! size: nPnts
    integer, allocatable :: indices(:)

    !> Number of points to communicate to requested domains
    integer :: nPnts

    !> target global rank ID of remote domain
    !! to send values for each point.
    integer, allocatable :: tgtPntRanks(:)

  end type requested_varData_level_type


  !> Data type contains communication buffer to send evaluated values
  !! requested domain and space points to evaluate a variable.
  !! This is filled with datas stored in couplingRequest_type by grouping
  !! requests per unique coupling variable name
  type aps_requested_varData_type
    !> requested varData per level
    !! size: minLevel:maxLevel
    type(requested_varData_level_type), allocatable :: dataOnLvl(:)
  end type aps_requested_varData_type


  !> Data type gathers linked list coupling request per unique coupling
  !! variable name
  type aps_coupling_variables_type
    !> requested variable datas
    type(aps_requested_varData_type), allocatable :: requestedData(:)

    !> Position of unique coupling variable in local domain varSys
    type(grw_intArray_type) :: varPos

    !> nScalars of requested variables
    type(grw_intArray_type) :: nScalars

    !> Coupling ID received from remote domain
    type(grw_intArray_type) :: couplingID

    !> minimum level of dataOnLvl
    type(grw_intArray_type) :: minLevel

    !> maximum level of dataOnLvl
    type(grw_intArray_type) :: maxLevel

    !> local domainID
    type(grw_intArray_type) :: loc_domID

    !> remote domain ID
    type(grw_intArray_type) :: rem_domID

    !> coupling variable named created using coupling ID
    type(dyn_labelArray_type) :: varName
  end type aps_coupling_variables_type


  !> Data type contains actual information received for coupling domain process
  !! with points and variable names requested by remote domain
  type aps_couplingRequest_type
    !> requested global process ID
    integer :: partner

    !> local domainID
    integer :: loc_domID

    !> remote domain ID
    integer :: rem_domID

    !> remote coupling ID
    integer :: couplingID

    !> current level for that request
    integer :: iLevel

    !> Number of points requested
    integer :: nPnts = 0

    !> Space points requested by remote domain
    real(kind=rk), allocatable :: points(:,:)

    !> Offset bit encodes direction of boundary for surface coupling.
    character, allocatable :: offset_bit(:)

    !> Process ids for each requested point in global communicator
    !! Size: nPnts
    integer, allocatable :: pntRanks(:)

    !> Number of variables requested
    integer :: nVars = 0

    !> Variable names requested
    character(len=labelLen), allocatable :: varNames(:)

    !> nScalars of requested varNames
    integer :: nScalars = 0

    !> Logical decision of surface or volume coupling
    logical :: isSurface
  end type aps_couplingRequest_type

  interface init
    module procedure init_cplVars
  end interface init

contains


  ! ***************************************************************************!
  !> Intialize growing arrays in aps_coupling_variables_type
  subroutine init_cplVars(me)
    ! -------------------------------------------------------------------------!
    !> To be initialized
    type(aps_coupling_variables_type), intent(out) :: me
    ! -------------------------------------------------------------------------!
    call init(me%varName)
    call init(me%varPos)
    call init(me%nScalars)
    call init(me%couplingID)
    call init(me%minLevel)
    call init(me%maxLevel)
    call init(me%loc_domID)
    call init(me%rem_domID)
  end subroutine init_cplVars
  ! ***************************************************************************!


  ! ***************************************************************************!
  !> This routine evaluates coupling variables requested by remote domain
  !! for given simulation time
  subroutine aps_cplVars_evaluate( cplVars, solver, domainObj, time )
    ! -------------------------------------------------------------------------!
    !> To be filled with information in coupling request type by
    !! grouping request per coupling variable name.
    type(aps_coupling_variables_type), intent(inout) :: cplVars
    !> solver type, contains everything required to initialize
    !! data exchange between domains
    type(aps_solver_type), target, intent(in) :: solver
    !> Contains all information about all domains
    type(aps_domainObj_type), intent(inout) :: domainObj(:)
    !> Current simulation time
    type(tem_time_type), intent(in) :: time
    ! -------------------------------------------------------------------------!
    integer :: iVar, cplVarPos
    integer :: iLevel, minLevel, maxLevel
    integer :: nScalars
    type(tem_varSys_type), pointer :: varSys => NULL()
    type(treelmesh_type), pointer :: pTree => NULL()
    integer :: loc_domID, sol_pos, sol_type
!KM!    integer :: iPnt, iComp
    ! -------------------------------------------------------------------------!
    write(LogUnit(10),*) 'Start evaluation ...'

    do iVar = 1, cplVars%varName%nVals
      loc_domID = cplVars%loc_domID%val(iVar)
      call tem_startTimer( timerHandle = domainObj(loc_domID)%cplEval )
      sol_type = domainObj(loc_domID)%solver_type
      sol_pos = domainObj(loc_domID)%solver_position
      ! depends which solver is requested for the variables, we need to take
      ! the correct VarSys
      select case(sol_type)
      case(musubi)
        varSys => solver%musubi(sol_pos)%scheme%varSys
        pTree => solver%musubi(sol_pos)%geometry%tree
      case(ateles)
        call atl_set_elemTimers(domainObj(loc_domID)%atl_elemTimers)
        varSys => solver%ateles(sol_pos)%equation%varSys
        pTree => solver%ateles(sol_pos)%tree
      end select

      cplVarPos = cplVars%varPos%val(iVar)
!KM!      write(dbgUnit(1),*) 'varName: '//trim(varSys%varName%val(cplVarPos))
      minLevel = cplVars%minLevel%val(iVar)
      maxLevel = cplVars%maxLevel%val(iVar)
      nScalars = cplVars%nScalars%val(iVar)

      ! Update modular logUnit with domain logUnit
      logUnit = domainObj(loc_domID)%logUnit
      dbgUnit = domainObj(loc_domID)%dbgUnit

      ! derive coupling variable
      do iLevel = minLevel, maxLevel

        call varSys%method%val(cplVarPos)%get_valOfIndex(                    &
          & varSys  = varSys,                                                &
          & time    = time,                                                  &
          & iLevel  = iLevel,                                                &
          & idx     = cplVars%requestedData(iVar)%dataOnLvl(iLevel)%indices, &
          & nVals   = cplVars%requestedData(iVar)%dataOnLvl(iLevel)%nPnts,   &
          & res     = cplVars%requestedData(iVar)%dataOnLvl(iLevel)%evalVal  )

!KM!        call varSys%method%val(cplVarPos)%get_point(                       &
!KM!          & varSys = varSys,                                               &
!KM!          & point  = cplVars%requestedData(iVar)%dataOnLvl(iLevel)%points, &
!KM!          & time   = time,                                                 &
!KM!          & tree   = pTree,                                                &
!KM!          & nPnts  = cplVars%requestedData(iVar)%dataOnLvl(iLevel)%nPnts,  &
!KM!          & res    = cplVars%requestedData(iVar)%dataOnLvl(iLevel)%evalVal )

!KM!write(dbgUnit(1),*) 'nPnts ', cplVars%requestedData(iVar)%dataOnLvl(iLevel)%nPnts
!KM!do iPnt = 1, cplVars%requestedData(iVar)%dataOnLvl(iLevel)%nPnts
!KM!  write(dbgUnit(1),*) 'iPnt ', iPnt
!KM!  do iComp = 1, varSys%method%val(cplVarPos)%nComponents
!KM!    write(dbgUnit(1),*) cplVars%requestedData(iVar)&
!KM!    & %dataOnLvl(iLevel)%evalVal( &
!KM!    & (iPnt-1)*varSys%method%val(cplVarPos)%nComponents + iComp )
!KM!  end do
!KM!  write(dbgUnit(1),*)
!KM!end do
!KM!flush(dbgUnit(1))
      end do !iLevel
      call tem_stopTimer( timerHandle = domainObj(loc_domID)%cplEval )

      ! Reset domainObj(loc_domID)%atl_elemTimers to the atl_timers again!
      select case(sol_type)
      case(ateles)
        domainObj(loc_domID)%atl_elemTimers = atl_get_elemTimers()
      end select

    end do !iCplVars

    ! reset logUnit and dbgUnit to apesmate units
    logUnit = aps_logUnit
    dbgUnit = aps_dbgUnit

    write(LogUnit(10),*) '... end evaluation'

  end subroutine aps_cplVars_evaluate
  ! ***************************************************************************!


  ! ****************************************************************************
  !> Routine which check if the requested variables are in the local variable
  !! system
  subroutine aps_cplReq_checkVars(cplRequest, solver, domainObj)
    ! -------------------------------------------------------------------------!
    !> list of all request from the remote domain
    type(aps_couplingRequest_type), intent(inout) :: cplRequest(:)
    !> Contains all information about all domains
    type(aps_domainObj_type), intent(in) :: domainObj(:)
    !> solver type, contains the domain tree
    type(aps_solver_type), target, intent(in) :: solver
    ! -------------------------------------------------------------------------!
    integer :: sol_type, sol_pos
    integer :: iCplReq, nCplReqs, loc_domID
    type(tem_varMap_type) :: varMap
    type(tem_varSys_type), pointer :: varSys => NULL()
    integer :: iVar
    ! -------------------------------------------------------------------------!
    write(logUnit(1),*) 'Check exitence of requested variables'
    nCplReqs = size(cplRequest)

    !loop over the cplRequest
    do iCplReq = 1, nCplReqs

      loc_domID = cplRequest(iCplReq)%loc_domID
      sol_type = domainObj(loc_domID)%solver_type
      sol_pos = domainObj(loc_domID)%solver_position

      ! depends which solver is requested for the variables, we need to take
      ! the correct VarSys
      select case(sol_type)
      case(musubi)
        varSys => solver%musubi(sol_pos)%scheme%varSys
      case(ateles)
        varSys => solver%ateles(sol_pos)%equation%varSys
      end select

      ! check if the variable is in the varSYS
      call tem_create_varMap( varName = cplRequest(iCplReq)%varNames, &
        &                     varSys  = varSys,                       &
        &                     varMap  = varMap                        )

      ! if the mapping list less than the number of requested variables,
      ! than some is missing
      if (varMap%varPos%nVals /= cplRequest(iCplReq)%nVars) then
        call tem_abort('In aps_cplReq_checkVars: some requested variables ' &
          &         // 'not found')
      else
        ! Compute nScalars in given varNames and send it back to
        ! requested process to allocate evalVal array in st_fun coupling
        cplRequest(iCplReq)%nScalars = 0
        do iVar = 1, varMap%varPos%nVals
          cplRequest(iCplReq)%nScalars = cplRequest(iCplReq)%nScalars &
            & + varSys%method%val( varMap%varPos%val(iVar) )%nComponents
        end do
      end if
    end do !iCplReq

  end subroutine aps_cplReq_checkVars
  ! ****************************************************************************


  ! ****************************************************************************
  !> routine which identifies the rank which contains the points
  ! to identfy the correct treeID for boundary elements, we shift the points
  ! according to the offset_bit
  subroutine aps_cplReq_identify_pntRanks(cplRequest, solver, domainObj)
    ! -------------------------------------------------------------------------!
    !> list of all request from the remote domain,
    !! contains the arrays for the pntRanks
    type(aps_couplingRequest_type), intent(inout) :: cplRequest(:)
    !> solver type, contains the domain tree
    type(aps_solver_type), target, intent(in) :: solver
    !> Contains all information about all domains
    type(aps_domainObj_type), intent(in) :: domainObj(:)
    ! -------------------------------------------------------------------------!
    integer(kind=long_k) :: treeID
    integer :: iPoint
    real(kind=rk) :: pnt(3)
    type(tem_path_type), allocatable :: pathFirst(:), pathLast(:)
    type(tem_path_type) :: pathOfID
    integer :: loc_domID, sol_type, sol_pos, nProcs
    integer :: nDepProcs, depProc
    integer :: iCplReq, nCplReqs
    integer :: offsetX, offsetY, offsetZ
    type(treelmesh_type), pointer :: pTree => NULL()
    ! -------------------------------------------------------------------------!
    write(logUnit(1),*) 'Identify ranks for requested points'
    nCplReqs = size(cplRequest)

    do iCplReq = 1, nCplReqs

      ! identify the points now...

      ! Infos for the select case
      loc_domID = cplRequest(iCplReq)%loc_domID
      sol_type = domainObj(loc_domID)%solver_type
      sol_pos = domainObj(loc_domID)%solver_position
      select case(sol_type)
      case(musubi)
        pTree => solver%musubi(sol_pos)%geometry%tree
      case(ateles)
        pTree => solver%ateles(sol_pos)%tree
      end select

      ! Number of ranks on current loc_domID
      nProcs = domainObj(loc_domID)%ranks%nVals
      allocate(pathFirst( nProcs ))
      allocate(pathLast( nProcs ))

      ! Set pathFirst and pathLast depends on solver type
      ! Get path of first and last treeID of local process
      pathFirst = tem_PathOf(ptree%Part_First)
      pathLast = tem_PathOf(ptree%Part_Last)

      allocate(cplRequest(iCplReq)%pntRanks(cplRequest(iCplReq)%nPnts))

      do iPoint = 1, cplRequest(iCplReq)%nPnts

        ! transform the offset bit back
        if (cplRequest(iCplReq)%isSurface) then
          offsetX = mod(ichar(cplRequest(iCplReq)%offset_bit(iPoint)),4) - 1
          offsetY = mod(ichar(cplRequest(iCplReq)%offset_bit(iPoint)),16)/4 - 1
          offsetZ = ichar(cplRequest(iCplReq)%offset_bit(iPoint))/16 - 1

          ! shift the points according to the offset bit * eps scaled by position
          pnt(1) = cplRequest(iCplReq)%points(iPoint,1) &
            & + offsetX*spacing(pTree%global%BoundingCubeLength)
          pnt(2) = cplRequest(iCplReq)%points(iPoint,2) &
            & + offsetY*spacing(pTree%global%BoundingCubeLength)
          pnt(3) = cplRequest(iCplReq)%points(iPoint,3) &
            & + offsetZ*spacing(pTree%global%BoundingCubeLength)
        else
          pnt(:) = cplRequest(iCplReq)%points(iPoint,:)
        end if

        ! get the TreeID for that point
        ! by converting point to coordinate on finest level
        treeID = tem_IdOfCoord(                     &
          &          tem_CoordOfReal(mesh  = ptree, &
          &                          point = pnt)   )

        ! path of treeID
        pathOfID = tem_PathOf(treeID)

        ! find the process of pathOfID using last and first entry
        ! depProc - returns process id + 1 in remote domain sub-communicator
        call tem_find_depProc( depProc   = depProc,   &
          &                    nDepProcs = nDepProcs, &
          &                    tree      = pTree,     &
          &                    elemPath  = pathOfID,  &
          &                    PathFirst = PathFirst, &
          &                    PathLast  = PathLast   )

        if (depProc > 0) then
          ! Send global rank ID to communicate
          cplRequest(iCplReq)%pntRanks(iPoint) = domainObj(loc_domID)%ranks &
            &                                                   %val(depProc)
        else
          write(logUnit(1),*) 'Requested point not found in domain: '&
            &                //trim(domainObj(loc_domID)%header%label)
          write(logUnit(1),*) 'Point: ', pnt
          call tem_abort()
        end if
      end do


      ! deallocate pathFirst and pathLast for next coupling request since
      ! next coupling request might depend on another domain
      deallocate(pathFirst)
      deallocate(pathLast)
    end do !iCplReq

  end subroutine aps_cplReq_identify_pntRanks
  !****************************************************************************!


  ! ***************************************************************************!
  !> This routine creates coupling variables list from cplRequets received
  !! from remote domain and prepares sendBuffer to send evaluated values
  !! at every time step.
  !! CplRequest received might have requests for same coulpling variable
  !! from different process ids so gather them together under one coupling
  !! variable to evaluate point values together and sent it back.
  subroutine aps_create_cplVars_fromCplRequests( cplVars, cplRequest, solver, &
    &                                            domainObj )
    ! -------------------------------------------------------------------------!
    !> To be filled with information in coupling request type by
    !! grouping request per coupling variable name.
    type(aps_coupling_variables_type), intent(out) :: cplVars
    !> list of all requests from the remote domain,
    !! conatins the arrays for the pntRanks
    type(aps_couplingRequest_type), intent(in) :: cplRequest(:)
    !> Contains all information about all domains
    type(aps_domainObj_type), intent(in) :: domainObj(:)
    !> solver type, contains the domain tree
    type(aps_solver_type), target, intent(in) :: solver
    ! -------------------------------------------------------------------------!
    integer :: nCplVars, nPnts
    integer :: iVar, iLevel, minLevel, maxLevel, nScalars, rem_domID
    ! -------------------------------------------------------------------------!
    write(logUnit(1),*) 'Create coulping variables from coupling requests'

    ! Step 1: Create unique variable list and append coupling variable to
    ! local domain varSys amd store its position in growing array in cplVars.
    ! Also, compute nScalars, couplingID, minLevel and maxLevel per coupling
    ! variable.
    call append_couplingVariables( cplVars    = cplVars,    &
      &                            cplRequest = cplRequest, &
      &                            domainObj  = domainObj,  &
      &                            solver     = solver      )

    nCplVars = cplVars%varName%nVals

    if (nCplVars > 0) then
      ! Step 2: Initialize requestedData
      call init_requestedData(                              &
        & me            = cplVars%requestedData,            &
        & nCplVars      = nCplVars,                         &
        & dyn_varName   = cplVars%varName,                  &
        & minLvlArray   = cplVars%minLevel%val(1:nCplVars), &
        & maxLvlArray   = cplVars%maxLevel%val(1:nCplVars), &
        & nScalarsArray = cplVars%nScalars%val(1:nCplVars), &
        & cplRequest    = cplRequest                        )

      ! Step 3: Copy point sets and source rank from linked list of
      ! coupling request to requestedData
      call copy_pointAndRank_fromCplReqToReqData(           &
        & requestedData = cplVars%requestedData,            &
        & nCplVars      = nCplVars,                         &
        & cplRequest    = cplRequest,                       &
        & dyn_varName   = cplVars%varName,                  &
        & minLvlArray   = cplVars%minLevel%val(1:nCplVars), &
        & maxLvlArray   = cplVars%maxLevel%val(1:nCplVars), &
        & domainObj     = domainObj,                        &
        & solver        = solver                            )

      ! Step 4: initialize sendBuffer to send evalVal to requested domain

      do iVar = 1, nCplVars
        minLevel = cplVars%minLevel%val(iVar)
        maxLevel = cplVars%maxLevel%val(iVar)
        nScalars = cplVars%nScalars%val(iVar)
        rem_domID = cplVars%rem_domID%val(iVar)
        do iLevel = minLevel, maxLevel
          nPnts = cplVars%requestedData(iVar)%dataOnLvl(iLevel)%nPnts
          call tem_comm_createBuffer(                                       &
            & commBuffer    = cplVars%requestedData(iVar)%dataOnLvl(iLevel) &
            &                                            %sendBuffer,       &
            & nScalars      = nScalars,                                     &
            & nElems        = nPnts,                                        &
            & elemRanks     = cplVars%requestedData(iVar)%dataOnLvl(iLevel) &
            &                                            %tgtPntRanks       )

          ! not required anymore
          deallocate(cplVars%requestedData(iVar)%dataOnLvl(iLevel)%tgtPntRanks)
        end do !level
      end do !iVar
    else
      allocate(cplVars%requestedData(0))
    end if ! nCplVars > 0

  end subroutine aps_create_cplVars_fromCplRequests
  ! ***************************************************************************!


  ! ***************************************************************************!
  !> This routine append coupling variable and stores its position in growing
  !! array of varPos. Also store nScalars, couplingID, minLevel and maxLevel
  !! per coupling variable
  subroutine append_couplingVariables( cplVars, cplRequest, solver, domainObj )
    ! -------------------------------------------------------------------------!
    !> To be filled with information in coupling request type by
    !! grouping request per coupling variable name.
    type(aps_coupling_variables_type), intent(out) :: cplVars
    !> list of all requests from the remote domain
    type(aps_couplingRequest_type), intent(in) :: cplRequest(:)
    !> Contains all information about all domains
    type(aps_domainObj_type), intent(in) :: domainObj(:)
    !> solver type, contains the domain tree
    type(aps_solver_type), target, intent(in) :: solver
    ! -------------------------------------------------------------------------!
    character(len=labelLen) :: varName
    integer :: pos, addedPos, nCplVars
    integer :: loc_domID, sol_pos, sol_type
    logical :: wasAdded
    type(tem_variable_type) :: temVar
    type(tem_varSys_type), pointer :: varSys => NULL()
    integer :: iCplReq, nCplReqs
    ! -------------------------------------------------------------------------!
    write(logUnit(1),*) 'Append coupling variables...'
    nCplReqs = size(cplRequest)
    write(dbgUnit(1),*) 'Append coupling variables...', nCplReqs

    ! KM: Fix for intel compiler, Initialize growing arrays for no request
    ! just to allocate arrays with size 0.
    ! Initializiting growing arrays for nCplReqs>0 has problems in append
    ! with intel compiler
    if (nCplReqs == 0) call init(me = cplVars)

    do iCplReq = 1, nCplReqs
      ! Create a variable with coupling ID and level to gather points
      ! and evalVal levelWise
      write(varName,'(a,i6.6)') 'couplingID', cplRequest(iCplReq)%couplingID
      write(dbgUnit(1),*) 'iCplReq ', iCplReq, trim(varname)
      flush(dbgUnit(1))
      call append( me       = cplVars%varName, &
        &          val      = trim(varName),   &
        &          pos      = pos,             &
        &          wasAdded = wasAdded         )

      if (wasAdded) then
        loc_domID = cplRequest(iCplReq)%loc_domID
        sol_type = domainObj(loc_domID)%solver_type
        sol_pos = domainObj(loc_domID)%solver_position

        ! depends which solver is requested for the variables, we need to take
        ! the correct VarSys
        select case(sol_type)
        case(musubi)
          varSys => solver%musubi(sol_pos)%scheme%varSys
        case(ateles)
          varSys => solver%ateles(sol_pos)%equation%varSys
        end select

        ! append a variable of operation kind combine with requested
        ! varNames to solver varSys
        temVar%label = trim(varName)
        ! set nComps in append_operVar from nScalars of input_varNames
        temVar%nComponents = -1
        temVar%operType = 'combine'
        ! get input varnames from cplRequest
        allocate(temVar%input_varname(cplRequest(iCplReq)%nVars))
        temVar%input_varName = cplRequest(iCplReq)%varNames

        write(dbgUnit(1),*) 'varName ', temVar%label
        write(dbgUnit(1),*) 'input_varname ', temVar%input_varName
        call tem_varSys_append_operVar( operVar = temVar,  &
          &                             varSys  = varSys,  &
          &                             pos     = addedPos )
        deallocate(temVar%input_varName)

        ! store in temporary growing array and copy to requestedData_type
        call append( me = cplVars%varPos , val = addedPos )

        ! store nScalars in requested variables
        call append( me  = cplVars%nScalars,                       &
          &          val = varSys%method%val(addedPos)%nComponents )

        ! initialize minLevel and maxLevel when variable is added
        call append( me  = cplVars%minLevel,          &
          &          val = cplRequest(iCplReq)%iLevel )
        call append( me  = cplVars%maxLevel,          &
          &          val = cplRequest(iCplReq)%iLevel )

        call append( me  = cplVars%loc_domID, &
          &          val = loc_domID          )
        call append( me  = cplVars%rem_domID,            &
          &          val = cplRequest(iCplReq)%rem_domID )

        call append( me  = cplVars%couplingID,            &
          &          val = cplRequest(iCplReq)%couplingID )
      end if

      ! compute minLevel and maxLevel
      cplVars%minLevel%val(pos) = min( cplVars%minLevel%val(pos), &
        &                              cplRequest(iCplReq)%iLevel )
      cplVars%maxLevel%val(pos) = max( cplVars%maxLevel%val(pos), &
        &                              cplRequest(iCplReq)%iLevel )

    end do

    nCplVars = cplVars%varName%nVals

  end subroutine append_couplingVariables
  ! ***************************************************************************!


  ! ***************************************************************************!
  !> This routine initialize requested data.
  !! Count total number of points to evaluate per variable.
  !! Allocates requestedData and its dataOnLvl for all variables.
  subroutine init_requestedData( me, nCplVars, dyn_varName, minLvlArray, &
    &                            maxLvlArray, nScalarsArray, cplRequest )
    ! -------------------------------------------------------------------------!
    !> Requested data to initialize per coupling variable
    type(aps_requested_varData_type), allocatable, intent(out) :: me(:)
    !> Number of coupling variables
    integer, intent(in) :: nCplVars
    !> Array of coupling variable names added to local domain varSys
    type(dyn_labelArray_type), intent(in) :: dyn_varName
    !> minlevel in each coupling variable
    integer, intent(in) :: minLvlArray(nCplVars)
    !> maxlevel in each coupling variable
    integer, intent(in) :: maxLvlArray(nCplVars)
    !> Number of scalars in each coupling variable
    integer, intent(in) :: nScalarsArray(nCplVars)
    !> list of all requests from the remote domain
    type(aps_couplingRequest_type), intent(in) :: cplRequest(:)
    ! -------------------------------------------------------------------------!
    integer :: minLevel, maxLevel, nScalars, glob_minLvl, glob_maxLvl
    character(len=labelLen) :: varName
    integer :: iVar, iLevel, nPnts
    integer :: iCplReq, nCplReqs
    ! -------------------------------------------------------------------------!
    write(logUnit(1),*) 'Initialize requested data for all cpl variables'
    nCplReqs = size(cplRequest)

    ! Step 2.1 Allocate requested data and dataOnLvl
    allocate( me(nCplVars) )
    do iVar = 1, nCplVars
      minLevel = minLvlArray(iVar)
      maxLevel = maxLvlArray(iVar)

      ! allocating dataOnLvl in requestedData
      allocate( me(iVar)%dataOnLvl(minLevel:maxLevel) )
      me(iVar)%dataOnLvl(:)%nPnts = 0
    end do

    glob_minLvl = minval(minLvlArray(:))
    glob_maxLvl = maxval(maxLvlArray(:))

    ! Step 2.2: Count number of points per coupling request to allocate
    ! points, tgtPntRanks and evalVal array
    do iCplReq = 1, nCplReqs
      write(varName,'(a,i6.6)') 'couplingID', cplRequest(iCplReq)%couplingID
      iVar = positionOfVal( me  = dyn_varName,  &
        &                   val = trim(varName) )

      iLevel = cplRequest(iCplReq)%iLevel

      me(iVar)%dataOnLvl(iLevel)%nPnts = me(iVar)%dataOnLvl(iLevel)%nPnts &
        &                              + cplRequest(iCplReq)%nPnts

    end do

    ! Step 2.3: allocate points, tgtPntRanks and evalVal
    do iVar = 1, nCplVars
      minLevel = minLvlArray(iVar)
      maxLevel = maxLvlArray(iVar)
      nScalars = nScalarsArray(iVar)
      do iLevel = minLevel, maxLevel
        nPnts = me(iVar)%dataOnLvl(iLevel)%nPnts

!KM!        allocate( me(iVar)%dataOnLvl(iLevel)%points( nPnts, 3 ) )
!KM!        me(iVar)%dataOnLvl(iLevel)%points = -1.0_rk

        allocate( me(iVar)%dataOnLvl(iLevel)%indices( nPnts ) )
        me(iVar)%dataOnLvl(iLevel)%indices = -1

        allocate( me(iVar)%dataOnLvl(iLevel)%tgtPntRanks( nPnts ) )
        me(iVar)%dataOnLvl(iLevel)%tgtPntRanks = -1

        allocate( me(iVar)%dataOnLvl(iLevel)%evalVal( nPnts*nScalars ) )
        me(iVar)%dataOnLvl(iLevel)%evalVal = -1.0_rk
      end do
    end do

  end subroutine init_requestedData
  ! ***************************************************************************!


  ! ***************************************************************************!
  !> Routine copies points and rank information from linked list of
  !! couplingRequest to allocatable array aps_requested_varData_type
  subroutine copy_pointAndRank_fromCplReqToReqData( requestedData, cplRequest, &
    &                                               dyn_varName, nCplVars,     &
    &                                               minLvlArray, maxLvlArray,  &
    &                                               domainObj, solver )
    ! -------------------------------------------------------------------------!
    !> Number of coupling variables
    integer, intent(in) :: nCplVars
    !> Requested data to initialize per coupling variable
    type(aps_requested_varData_type), intent(inout) :: requestedData(nCplVars)
    !> Array of coupling variable names added to local domain varSys
    type(dyn_labelArray_type), intent(in) :: dyn_varName
    !> list of all requests from the remote domain
    type(aps_couplingRequest_type), intent(in) :: cplRequest(:)
    !> minlevel in each coupling variable
    integer, intent(in) :: minLvlArray(nCplVars)
    !> maxlevel in each coupling variable
    integer, intent(in) :: maxLvlArray(nCplVars)
    !> Contains all information about all domains
    type(aps_domainObj_type), intent(in) :: domainObj(:)
    !> solver type, contains everything required to initialize
    !! data exchange between domains
    type(aps_solver_type), target, intent(in) :: solver
    ! -------------------------------------------------------------------------!
    integer, allocatable :: nPnts_var_lvl(:,:)
    integer :: iLevel, iVar, buf_start, buf_end
    integer :: glob_minLvl, glob_maxLvl
    character(len=labelLen) :: varName
    integer :: offsetX, offsetY, offsetZ, iPnt
!KM!    real(kind=rk) :: pnt(3)
    integer :: iCplReq, nCplReqs
    integer :: loc_domID, sol_type, sol_pos
    type(treelmesh_type), pointer :: pTree => NULL()
    type(tem_varSys_type), pointer :: varSys => NULL()
    real(kind=rk), allocatable :: pnts(:,:)
    integer, allocatable :: idx(:)
    integer :: solver_varPos
    ! -------------------------------------------------------------------------!
    nCplReqs = size(cplRequest)

    glob_minLvl = minval(minLvlArray(:))
    glob_maxLvl = maxval(maxLvlArray(:))

    allocate(nPnts_var_lvl(nCplVars, glob_minLvl:glob_maxLvl))
    nPnts_var_lvl = 0
    do iCplReq = 1, nCplReqs
      allocate( pnts(cplRequest(iCplReq)%nPnts,3))
      allocate( idx(cplRequest(iCplReq)%nPnts))
      pnts = 0.0
      idx = 0

      ! Infos for the select case
      loc_domID = cplRequest(iCplReq)%loc_domID
      sol_type = domainObj(loc_domID)%solver_type
      sol_pos = domainObj(loc_domID)%solver_position
      select case(sol_type)
      case(musubi)
        pTree => solver%musubi(sol_pos)%geometry%tree
        varSys => solver%musubi(sol_pos)%scheme%varSys
      case(ateles)
        pTree => solver%ateles(sol_pos)%tree
        varSys => solver%ateles(sol_pos)%equation%varSys
      end select

      write(varName,'(a,i6.6)') 'couplingID', cplRequest(iCplReq)%couplingID
      iVar = positionOfVal( me  = dyn_varName,  &
        &                   val = trim(varName) )

      iLevel = cplRequest(iCplReq)%iLevel

      ! Copy Points
      do iPnt = 1, cplRequest(iCplReq)%nPnts
        ! transform the offset bit back
        if (cplRequest(iCplReq)%isSurface) then
          offsetX = mod(ichar(cplRequest(iCplReq)%offset_bit(iPnt)),4) - 1
          offsetY = mod(ichar(cplRequest(iCplReq)%offset_bit(iPnt)),16)/4 - 1
          offsetZ = ichar(cplRequest(iCplReq)%offset_bit(iPnt))/16 - 1

          ! shift the points according to the offset bit * eps* elementsize
          pnts(iPnt,1) = cplRequest(iCplReq)%points(iPnt,1) &
            & + offsetX*spacing(pTree%global%BoundingCubeLength)
          pnts(iPnt,2) = cplRequest(iCplReq)%points(iPnt,2) &
            & + offsetY*spacing(pTree%global%BoundingCubeLength)
          pnts(iPnt,3) = cplRequest(iCplReq)%points(iPnt,3) &
            & + offsetZ*spacing(pTree%global%BoundingCubeLength)
!KM!          pnt(1) = cplRequest(iCplReq)%points(iPnt,1) &
!KM!            & + offsetX*spacing(pTree%global%BoundingCubeLength)
!KM!          pnt(2) = cplRequest(iCplReq)%points(iPnt,2) &
!KM!            & + offsetY*spacing(pTree%global%BoundingCubeLength)
!KM!          pnt(3) = cplRequest(iCplReq)%points(iPnt,3) &
!KM!            & + offsetZ*spacing(pTree%global%BoundingCubeLength)
        else
          pnts(iPnt,:) = cplRequest(iCplReq)%points(iPnt,:)
!KM!          pnt(:) = cplRequest(iCplReq)%points(iPnt,:)
        end if

!KM!        requestedData(iVar)%dataOnLvl(iLevel)                  &
!KM!          & %points(nPnts_var_lvl(iVar, iLevel)+iPnt, 1:3) = pnt

      end do !iPnt

      ! Update modular logUnit with domain logUnit
      logUnit = domainObj(loc_domID)%logUnit
      dbgUnit = domainObj(loc_domID)%dbgUnit

      ! call the correspoding setup indices routine for the coupling variables
      ! and the store the points in the solver and the indices in apesmate
      ! get pos in varSys
      solver_varPos = PositionOfVal( me  = varSys%varName, &
         &                           val = trim(varName)   )
      call varSys%method%val(solver_varPos)%setup_indices( &
        &  varSys     = varSys,                            &
        &  point      = pnts,                              &
        &  offset_bit = cplRequest(iCplReq)%offset_bit,    &
        &  iLevel     = iLevel,                            &
        &  tree       = ptree,                             &
        &  nPnts      = cplRequest(iCplReq)%nPnts,         &
        &  idx        = idx                                )


      buf_start = nPnts_var_lvl(iVar, iLevel) + 1
      buf_end   = nPnts_var_lvl(iVar, iLevel) + cplRequest(iCplReq)%nPnts
!!      requestedData(iVar)%dataOnLvl(iLevel)%indices(:) = idx(:)
      requestedData(iVar)%dataOnLvl(iLevel)%indices(buf_start: buf_end) = idx(:)

      requestedData(iVar)%dataOnLvl(iLevel)                            &
        & %tgtPntRanks(buf_start: buf_end) = cplRequest(iCplReq)%partner

      nPnts_var_lvl(iVar, iLevel) = nPnts_var_lvl(iVar, iLevel) &
        &                         + cplRequest(iCplReq)%nPnts
      deallocate( pnts )
      deallocate( idx )

    end do !iCplReq
    ! reset logUnit and dbgUnit to apesmate units
    logUnit = aps_logUnit
    dbgUnit = aps_dbgUnit

    deallocate(nPnts_var_lvl)
  end subroutine copy_pointAndRank_fromCplReqToReqData
  ! ***************************************************************************!

!!  ! ***************************************************************************!
!!  function get_numberCplRanks(cplVars)
!!    ! -------------------------------------------------------------------------!
!!    !> type with all important info about cplVars includinge the targetranks
!!    ! per point
!!    type(aps_coupling_variables_type), intent(out) :: cplVars
!!    type(tem_general_type), intent(inout) :: general
!!    integer, intent(in) :: nprocs_total
!!    ! -------------------------------------------------------------------------!
!!    ! flag for each proc if this is part of coupling or not
!!    logical, allocatable :: isCoupling(nprocs_total)
!!    integer :: iLevel, iRank
!!    integer :: iError
!!    ! -------------------------------------------------------------------------!
!!
!!    do iLevel= minLevel, maxLevel
!!      ! do I need this loop? since the variabes will lay on the proc anyway
!!      do iVar = 1, nScalars
!!        target_ranks =
!!        do iRank = 1, size(target_ranks)
!!          isCoupling(cplVars%requestedData(iVar)%dataOnLvl(iLevel) &
!!                            %tgtPntRanks(iRank)) = .true.
!!        end do
!!      end do
!!    end do
!!
!!    ! reduce the list of ranks over all processes, use mpi_lor
!!    !MPI_REDUCE(SENDBUF, RECVBUF, COUNT, DATATYPE, OP, ROOT, COMM, IERROR)
!!    call MPI_reduce( isCoupling, isCoupling_red, nprocs_total , logical, MPI_LOR, 0,  general%proc%comm,iError )
!!
!!    nCoupling_proc = count(isCoupling)
!!    write(logUnit(1),*) " Number of ranks included for coupling is", &
!!      &  nCoupling_proc
!!
!!  end function get_numberCplRanks

  ! ***************************************************************************!
  subroutine get_numberCplRanks(cplVars, ndom_global, comm)
    ! -------------------------------------------------------------------------!
    !> type with all important info about cplVars includinge the targetranks
    ! per point
    type(aps_coupling_variables_type), intent(in) :: cplVars
    integer, intent(in) :: ndom_global
    integer, intent(in) :: comm
    ! -------------------------------------------------------------------------!
    ! flag for each proc if this is part of coupling or not
    integer, allocatable :: coupling_in_dom(:)
    integer, allocatable :: nCplRanks(:)
    integer :: iLvl, iVar
    integer :: iError
    ! -------------------------------------------------------------------------!
!!    write(*,*) 'ndom_global', ndom_global
    allocate( coupling_in_dom(ndom_global) )
    allocate( nCplRanks(ndom_global) )
    coupling_in_dom = 0

    do iVar = 1, cplVars%nScalars%nVals
!!      write(*,*) 'minLevel', cplVars%minLevel%val(iVar)
!!      write(*,*) 'maxLevel', cplVars%maxLevel%val(iVar)
      do iLvl = cplVars%minLevel%val(iVar),  cplVars%maxLevel%val(iVar)
        if (cplVars%requestedData(iVar)%dataOnLvl(iLvl)%nPnts > 0) then
!!          write(*,*) 'cplVars%loc_domID%val(iVar))', cplVars%loc_domID%val(iVar)
          coupling_in_dom(cplVars%loc_domID%val(iVar)) = 1
        end if
      end do
    end do

!!    write(*,*) 'coupling_in_dom', coupling_in_dom

    ! reduce the list of ranks over all processes, use mpi_lor
    !MPI_REDUCE(SENDBUF, RECVBUF, COUNT, DATATYPE, OP, ROOT, COMM, IERROR)
    call MPI_Allreduce( coupling_in_dom, nCplRanks, ndom_global, MPI_INT, MPI_Sum, comm, iError )

    write(logUnit(1),*) " Number of ranks involved in coupling per domain is", nCplRanks
    deallocate( coupling_in_dom )

  end subroutine get_numberCplRanks
! *****************************************************************************!

end module aps_couplingRequest_module
! *****************************************************************************!
