! Copyright (c) 2015-2017 Verena Krupp <verena.krupp@uni-siegen.de>
! Copyright (c) 2015-2016 Kannan Masilamani <kannan.masilamani@dlr.de>
! Copyright (c) 2016 Harald Klimach <harald.klimach@dlr.de>
! Copyright (c) 2016 Tobias Girresser <tobias.girresser@student.uni-siegen.de>

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
!> This module contains everything needed for the communication between to
!domains
!!
!! \author Verena Krupp, Kannan Masilamani
module aps_comm_module
  ! treelm modules
  use mpi
  use env_module,              only: rk, labelLen, long_k
  use tem_aux_module,          only: tem_abort
  use tem_comm_env_module,     only: tem_comm_env_type
  use tem_comm_module,         only: tem_communication_type, &
    &                                tem_comm_init,          &
    &                                tem_comm_createBuffer,  &
    &                                tem_comm_alltoall_int
  use tem_tools_module,        only: tem_PositionInSorted, &
    &                                tem_horizontalSpacer
  use tem_logging_module,      only: logUnit
  use tem_dyn_array_module,    only: dyn_intArray_type, init, append, destroy, &
    &                                PositionOfVal
  use tem_grow_array_module,   only: grw_intArray_type, append
  use tem_pointData_module,    only: tem_pointData_type
  use tem_coupling_module,     only: tem_aps_coupling_type
  use treelmesh_module,        only: treelmesh_type
  use tem_varSys_module,       only: tem_varSys_type
  use tem_time_module,         only: tem_time_type
  use tem_timer_module,        only: tem_startTimer, tem_stopTimer

  ! apesmate modules
  use aps_domainObj_module,       only: aps_domainObj_type, musubi, ateles
  use aps_solver_module,          only: aps_solver_type
  use aps_stFun_coupling_module,  only: grw_aps_stFunCplArray_type, &
    &                                   aps_stFun_coupling_type
  use aps_logging_module,         only: aps_dbgUnit, aps_logUnit
  use aps_couplingRequest_module, only: aps_couplingRequest_type,           &
    &                                   aps_coupling_variables_type,        &
    &                                   append, destroy,                    &
    &                                   aps_create_cplVars_fromCplRequests, &
    &                                   aps_cplReq_checkVars,               &
    &                                   aps_cplReq_identify_pntRanks,       &
    &                                   aps_cplVars_evaluate
  use aps_timer_module,           only: aps_timerHandles

  implicit none

  private

  public :: aps_init_cplComm
  public :: aps_sync_domains

  ! init all message flags
  integer, parameter :: info_msg_flag = 1
  integer, parameter :: pnt_msg_flag = 2
  integer, parameter :: var_msg_flag = 3
  integer, parameter :: off_msg_flag = 4

  !> Maximum number of coupling per domain
  integer, parameter :: maxCplPerDom = 1000

  !> Number of integers in baseInfo buffer
  integer, parameter :: baseInfo_nInts = 7

  !> Process-wise buffer for 2D array of points
  !! This datatype is used to describe the exchange with a specific process, in
  !! case of explicit buffers it provides the memory for them.
  type pointData_buffer_type
    !> nPoints to communicate to this process
    integer :: nPnts

    !> 2D array of points to communicate
    real(kind=rk), allocatable :: points(:,:)

    !> is true for surface coupling else it is volume coupling
    logical :: isSurface

    !> offset bit
    character, allocatable :: offset_bit(:)

    !> Mapping to stFunCplList to access varNames
    integer :: map2StFunCpl
  end type pointData_buffer_type

  !> Data type contains basic info communicated between process
  type baseInfo_type
    !! Contains: remote domainID ( the one to talk to), domID, couplingID,
    !! iLevel, nPoints, nVars, surface
    integer :: buffer(7)
  end type baseInfo_type

contains


  ! ***************************************************************************!
  !> This routine does synchorization between domains by evaluating points
  !! of requested domains and communicate.
  !! Get point evaluation handles interpolation.
  !! and quadratic interpolation
  subroutine aps_sync_domains( stFunCplList, cplVars, solver, domainObj, time, &
    &                          proc )
    ! -------------------------------------------------------------------------!
    !> Coupling descriptor to fill with space time function pointers
    type(grw_aps_stFunCplArray_type), intent(inout) :: stFunCplList
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
    !> Global mpi environment
    type(tem_comm_env_type), intent(in) :: proc
    ! -------------------------------------------------------------------------!
    ! -------------------------------------------------------------------------!
    call tem_startTimer( timerHandle = aps_timerHandles%syncDom )
    write(aps_dbgUnit(1),*) 'Synchronize between domains '
    write(logUnit(10),*) 'Start Synchronizing between domains ...'

    call tem_startTimer( timerHandle = aps_timerHandles%evalVal )
    call aps_cplVars_evaluate( cplVars   = cplVars,   &
      &                        solver    = solver,    &
      &                        domainObj = domainObj, &
      &                        time      = time       )
    call tem_stopTimer( timerHandle = aps_timerHandles%evalVal )

    ! exchange values
    call exchange_evalVal( stFunCplList = stFunCplList, &
      &                    cplVars      = cplVars,      &
      &                    proc         = proc          )
    call tem_stopTimer( timerHandle = aps_timerHandles%syncDom )

    write(logUnit(10),*) '... ebd Synchronizing.'

  end subroutine aps_sync_domains
  ! ***************************************************************************!


  !****************************************************************************!
  !> Routine which initializing the first communictaion between the domain.
  !! task is 1) send the points in round robin fashion to remote domain
  !! 2) to identify the points requested by the remote domain via TreeID,
  !! find the corresponding rank for each point
  !! 3) send back rank to the requested domain
  subroutine aps_init_cplComm( stFunCplList, cplVars, solver, &
    &                          domainObj, proc )
    ! -------------------------------------------------------------------------!
    !> Coupling descriptor to fill with space time function pointers
    type(grw_aps_stFunCplArray_type), intent(inout) :: stFunCplList
    !> To be filled with information in coupling request type by
    !! grouping request per coupling variable name.
    type(aps_coupling_variables_type), intent(out) :: cplVars
    !> solver type, contains everything required to initialize
    !! data exchange between domains
    type(aps_solver_type), intent(in) :: solver
    !> Contains all information about all domains
    type(aps_domainObj_type), intent(in) :: domainObj(:)
    !> Global mpi environment
    type(tem_comm_env_type), intent(in) :: proc
    ! -------------------------------------------------------------------------!
    !> list of this type used in round robin communication and final
    !! communication
    type(aps_couplingRequest_type), allocatable :: cplRequest(:)
    ! -------------------------------------------------------------------------!
    call tem_startTimer( timerHandle = aps_timerHandles%init_cplComm )
    write(logUnit(1),*) 'Initializing communication between domains '

    ! exchange coupling data and fill up the coupling Request
    ! with round robin communication
    call tem_startTimer( timerHandle = aps_timerHandles%roundRobin )
    call exchangeCplData_roundRobin( cplRequest   = cplRequest,   &
      &                              stFunCplList = stFunCplList, &
      &                              proc         = proc          )
    call tem_stopTimer( timerHandle = aps_timerHandles%roundRobin )

    ! check if the requested variable is in requested domain,
    ! if not abort inside
    call tem_startTimer( timerHandle = aps_timerHandles%checkVars )
    call aps_cplReq_checkVars( cplRequest = cplRequest, &
      &                        solver     = solver,     &
      &                        domainObj  = domainObj   )
    call tem_stopTimer( timerHandle = aps_timerHandles%checkVars )

    ! Now each domain need to identify where are the requested points
    ! are located
    call tem_startTimer( timerHandle = aps_timerHandles%identRanks)
    call aps_cplReq_identify_pntRanks( cplRequest = cplRequest, &
      &                                solver     = solver,     &
      &                                domainObj  = domainObj   )
    call tem_stopTimer( timerHandle = aps_timerHandles%identRanks)

    ! Exchange the rank of requested points and nScalars of requested
    ! variables to the requested domain process
    call tem_startTimer( timerHandle = aps_timerHandles%exchRanks)
    call exchange_pntRanksAndnScalars( cplRequest   = cplRequest,   &
      &                                stFunCplList = stFunCplList, &
      &                                proc         = proc          )
    call tem_stopTimer( timerHandle = aps_timerHandles%exchRanks)

    ! deallocate cplRequest received from round robin and refill
    ! with request sent to correct point ranks
    deallocate(cplRequest)

    ! Exchange coupling data and fill up coupling request with points
    ! to evaluate in this domain by sending data to correct process
    call tem_startTimer( timerHandle = aps_timerHandles%exchCplData)
    call exchangeCplData_toCorrectProc( cplRequest   = cplRequest,   &
      &                                 stFunCplList = stFunCplList, &
      &                                 proc         = proc          )
    call tem_stopTimer( timerHandle = aps_timerHandles%exchCplData)

    ! Create coupling variables from linked list of coupling requests
    call tem_startTimer( timerHandle = aps_timerHandles%createCplVars)
    call aps_create_cplVars_fromCplRequests( cplVars    = cplVars,    &
      &                                      cplRequest = cplRequest, &
      &                                      solver     = solver,     &
      &                                      domainObj  = domainObj   )
    call tem_stopTimer( timerHandle = aps_timerHandles%createCplVars)

    ! destroy cplRequest after datas are copied to cplVars
    deallocate(cplRequest)

    write(logUnit(1),*) 'Done initializing communication'
    call tem_horizontalSpacer( after = 1, fUnit = logUnit(1) )

    call tem_stopTimer( timerHandle = aps_timerHandles%init_cplComm )
  end subroutine aps_init_cplComm
  ! ***************************************************************************!


  ! ***************************************************************************!
  !> Routine to fill up the coupling request with points to evaluate in this
  !! domain. Send data to correct process using pntRanks received from
  !! remote domain.
  subroutine exchangeCplData_toCorrectProc( cplRequest, stFunCplList, proc )
    ! -------------------------------------------------------------------------!
    !> coupling requests filled by the information from remote domain
    type(aps_couplingRequest_type), allocatable, intent(out) :: cplRequest(:)
    !> Coupling descriptor to fill with space time function pointers
    type(grw_aps_stFunCplArray_type), intent(inout) :: stFunCplList
    !> Global mpi environment
    type(tem_comm_env_type), intent(in) :: proc
    ! -------------------------------------------------------------------------!
    integer :: iStCpl, iPartner, iLevel, iProc, iCplSend, nCplSends, nPnts
    logical :: isSurface
    integer, allocatable :: nCplSends_proc(:)
    type(dyn_intArray_type) :: targets
    type(baseInfo_type), allocatable :: baseSend(:)
    type(tem_aps_coupling_type), pointer :: temCpl => NULL()
    type(pointData_buffer_type), allocatable :: pntDataBuf(:)
    integer, allocatable :: map2SendData(:,:)
    ! -------------------------------------------------------------------------!

    !init targets since there could be a process without spacetimefunction
    call init(me=targets)

    ! Create recvBuffer using pntRanks received from remote domain and
    ! count total sends
    nCplSends = 0
    do iStCpl = 1, stFunCplList%nVals
      ! iLevel
      iLevel = stFunCplList%val(iStCpl)%iLevel

      ! pointer to stfun coupling in treelm
      temCpl => stFunCplList%val(iStCpl)%stFunPtr%aps_coupling

      ! check if nScalars received are same as nComps in stFun
      ! @todo KM: This check is not needed since nScalars received
      ! from remote domain is used to allocate evalVal
      if (temCpl%nScalars /= stFunCplList%val(iStCpl)%stFunPtr%nComps) then
        call tem_abort('Error: nScalars from remote domain /= nComps in stFun')
      end if

      ! total number of points to communicate to remote domain for this
      ! coupling
      nPnts = stFunCplList%val(iStCpl)%stFunElemPtr%pntData%pntLvl(iLevel)%nPnts

      temCpl%valOnLvl(iLevel)%nPnts = nPnts
      ! allocate couping evalVal
      allocate( temCpl%valOnLvl(iLevel)%evalVal( nPnts*temCpl%nScalars ) )

      ! Prepare receive buffer for evalVal to receive evaluate values
      ! from remote process
      call tem_comm_createBuffer(                             &
        & commBuffer    = temCpl%valOnLvl(iLevel)%recvBuffer, &
        & nScalars      = temCpl%nScalars,                    &
        & nElems        = nPnts,                              &
        & elemRanks     = temCpl%valOnLvl(iLevel)%pntRanks    )

      ! deallocate pntRanks, its not needed any more
      deallocate(temCpl%valOnLvl(iLevel)%pntRanks)

      do iProc = 1, temCpl%valOnLvl(iLevel)%recvBuffer%nProcs
        ! create unique list of targets to talk to
        call append( me  = targets,                                       &
          &          val = temCpl%valOnLvl(iLevel)%recvBuffer%proc(iProc) )
      end do

      nCplSends = nCplSends + temCpl%valOnLvl(iLevel)%recvBuffer%nProcs
    end do !iStCpl

    ! count number of st fun coupling to send per partner
    allocate(baseSend(nCplSends))
    allocate(pntDataBuf(nCplSends))
    allocate(nCplSends_proc(targets%nVals))
    allocate(map2SendData(targets%nVals, stFunCplList%nVals))
    nCplSends_proc = 0
    iCplSend = 0
    do iStCpl = 1, stFunCplList%nVals

      iLevel = stFunCplList%val(iStCpl)%iLevel
      temCpl => stFunCplList%val(iStCpl)%stFunPtr%aps_coupling
      isSurface = ( temCPl%isSurface == 0 )

      do iProc = 1, temCpl%valOnLvl(iLevel)%recvBuffer%nProcs
        iPartner = PositionOfVal( me  = targets,                &
          &                       val = temCpl%valOnLvl(iLevel) &
          &                             %recvBuffer%proc(iProc) )
        nCplSends_proc(iPartner) = nCplSends_proc(iPartner) + 1

        iCplSend = iCplSend + 1
        map2SendData(iPartner, nCplSends_proc(iPartner)) = iCplSend
        ! Fill pointData buffer
        call fill_pointDataBuffer(                             &
          & pntDataBuf = pntDataBuf(iCplSend),                 &
          & temPntData = stFunCplList%val(iStCpl)%stFunElemPtr &
          &                          %pntData%pntLvl(iLevel),  &
          & elemPos    = temCpl%valOnLvl(iLevel)%recvBuffer    &
          &                    %elemPos(iProc),                &
          & isSurface  = isSurface,                            &
          & iStCpl     = iStCpl                                )

        ! Fill base info to send
        call fill_baseSendFromStFunCpl( baseSend = baseSend(iCplSend),       &
          &                             stFunCpl = stFunCplList%val(iStCpl), &
          &                             iStCpl   = iStCpl                    )

        ! save number of points we want to send
        baseSend(iCplSend)%buffer(5) = pntDataBuf(iCplSend)%nPnts
      end do !iProc
    end do !iStCpl

    ! Fill coupling request
    call fill_cplRequest( cplRequest     = cplRequest,                   &
      &                   pntDataBuf     = pntDataBuf,                   &
      &                   stFunCplList   = stFunCplList,                 &
      &                   baseSend       = baseSend,                     &
      &                   targets        = targets%val(1:targets%nVals), &
      &                   nCplSends_proc = nCplSends_proc,               &
      &                   map2SendData   = map2SendData,                 &
      &                   proc           = proc                          )

  end subroutine exchangeCplData_toCorrectProc
  ! ***************************************************************************!


  ! ***************************************************************************!
  !> Routine to fill up the coupling request from remote domain.
  !! Communictaion is done in a round robin fashion, which means every rank
  !! send request info to the same rank in the remote domain
  subroutine exchangeCplData_roundRobin( cplRequest, stFunCplList, proc )
    ! -------------------------------------------------------------------------!
    !> coupling requests filled by the information from remote domain
    type(aps_couplingRequest_type), allocatable, intent(out) :: cplRequest(:)
    !> Coupling descriptor to fill with space time function pointers
    type(grw_aps_stFunCplArray_type), intent(inout) :: stFunCplList
    !> Global mpi environment
    type(tem_comm_env_type), intent(in) :: proc
    ! -------------------------------------------------------------------------!
    integer :: iStCpl, iPartner, iLevel
    logical :: isSurface
    integer, allocatable :: nCplSends_proc(:)
    type(dyn_intArray_type) :: targets
    type(baseInfo_type), allocatable :: baseSend(:)
    type(pointData_buffer_type), allocatable :: pntDataBuf(:)
    integer, allocatable :: map2SendData(:,:)
    ! -------------------------------------------------------------------------!
    write(logUnit(1),*) 'Exchange point data via round robin fashin'
    ! Get process ids to talk to
    ! For round robin communication, sum(nCplSends_proc) = stFunCplList%nVals
    call init(me=targets)
    do iStCpl = 1, stFunCplList%nVals
      call append( me  = targets,                         &
        &          val = stFunCplList%val(iStCpl)%partner )
    end do !iStCpl

    ! Fill point data buffer i.e points and offset bit.
    ! Fill baseSend info.
    ! count number of st fun coupling to send per partner
    allocate(pntDataBuf(stFunCplList%nVals))
    allocate(baseSend(stFunCplList%nVals))
    allocate(nCplSends_proc(targets%nVals))
    allocate(map2SendData(targets%nVals, stFunCplList%nVals))
    nCplSends_proc = 0
    do iStCpl = 1, stFunCplList%nVals
      iPartner = PositionOfVal( me  = targets,                         &
        &                       val = stFunCplList%val(iStCpl)%partner )
      nCplSends_proc(iPartner) = nCplSends_proc(iPartner) + 1

      map2SendData(iPartner, nCplSends_proc(iPartner)) = iStCpl

      call fill_baseSendFromStFunCpl( baseSend = baseSend(iStCpl),         &
        &                             stFunCpl = stFunCplList%val(iStCpl), &
        &                             iStCpl   = iStCpl                    )

      iLevel = stFunCplList%val(iStCpl)%iLevel
      isSurface = ( stFunCplList%val(iStCpl)%stFunPtr       &
        &                      %aps_coupling%isSurface == 0 )
      call fill_pointDataBuffer(                             &
        & pntDataBuf = pntDataBuf(iStCpl),                   &
        & temPntData = stFunCplList%val(iStCpl)%stFunElemPtr &
        &                          %pntData%pntLvl(iLevel),  &
        & isSurface  = isSurface,                            &
        & iStCpl     = iStCpl                                )
    end do !iStCpl

    ! Fill coupling request
    call fill_cplRequest( cplRequest     = cplRequest,                   &
      &                   pntDataBuf     = pntDataBuf,                   &
      &                   stFunCplList   = stFunCplList,                 &
      &                   baseSend       = baseSend,                     &
      &                   targets        = targets%val(1:targets%nVals), &
      &                   nCplSends_proc = nCplSends_proc,               &
      &                   map2SendData   = map2SendData,                 &
      &                   proc           = proc                          )

  end subroutine exchangeCplData_roundRobin
  ! ***************************************************************************!


  ! ***************************************************************************!
  !> This routine fills up coupling requests received from remote domain
  subroutine fill_cplRequest( cplRequest, pntDataBuf, stFunCplList, baseSend, &
    &                         targets, nCplSends_proc, map2SendData, proc )
    ! -------------------------------------------------------------------------!
    !> coupling requests filled by the information from remote domain
    type(aps_couplingRequest_type), allocatable, intent(out) :: cplRequest(:)
    !> Point data buffer to be filled to send to remote domain
    type(pointData_buffer_type), intent(in) :: pntDataBuf(:)
    !> Coupling descriptor to fill with space time function pointers
    type(grw_aps_stFunCplArray_type), intent(in) :: stFunCplList
    !> Coupling base information to send to remote domain
    type(baseInfo_type), intent(in) :: baseSend(:)
    !> List of target ranks to send coupling info
    integer, intent(in) :: targets(:)
    !> Number of coupling to send per target rank
    integer, intent(in) :: nCplSends_proc(:)
    !> Map to baseSend and pntDataBuf from target loop
    integer, intent(in) :: map2SendData(:,:)
    !> Global mpi environment
    type(tem_comm_env_type), intent(in) :: proc
    ! -------------------------------------------------------------------------!
    type(baseInfo_type), allocatable :: baseRecv(:)
    integer, allocatable :: sources(:)
    integer, allocatable :: nCplRecvs_proc(:)
    ! -------------------------------------------------------------------------!

    ! Send nCplSends_proc to targets and receive nCplRecv_proc from sources
    call tem_comm_alltoall_int( targets     = targets,        &
      &                         send_buffer = nCplSends_proc, &
      &                         sources     = sources,        &
      &                         recv_buffer = nCplRecvs_proc, &
      &                         comm        = proc%comm       )

    ! Exchange base information between domains
    call exchange_baseInfo( baseSend       = baseSend,       &
      &                     baseRecv       = baseRecv,       &
      &                     targets        = targets,        &
      &                     nCplSends_proc = nCplSends_proc, &
      &                     map2SendData   = map2SendData,   &
      &                     sources        = sources,        &
      &                     nCplRecvs_proc = nCplRecvs_proc, &
      &                     proc           = proc            )

    ! Allocate cplRequest and fill with information received in
    ! baseRecv
    call init_cplRequestFromBaseInfo( cplRequest     = cplRequest,    &
      &                               baseRecv       = baseRecv,      &
      &                               sources        = sources,       &
      &                               nCplRecvs_proc = nCplRecvs_proc )

    ! Exchange points, offset_bit and varNames
    call exchange_pointData( cplRequest     = cplRequest,     &
      &                      pntDataBuf     = pntDataBuf,     &
      &                      stFunCplList   = stFunCplList,   &
      &                      targets        = targets,        &
      &                      nCplSends_proc = nCplSends_proc, &
      &                      map2SendData   = map2SendData,   &
      &                      sources        = sources,        &
      &                      nCplRecvs_proc = nCplRecvs_proc, &
      &                      proc           = proc            )

  end subroutine fill_cplRequest
  ! ***************************************************************************!


  ! ***************************************************************************!
  !> This routine exchange points, offset_bit and varNames between domains.
  !! Datas from remote domain are stored in array of cplRequest
  subroutine exchange_pointData( cplRequest, pntDataBuf, stFunCplList,  &
    &                            targets, nCplSends_proc, map2SendData, &
    &                            sources, nCplRecvs_proc, proc          )
    ! -------------------------------------------------------------------------!
    !> coupling requests filled by the information from remote domain
    type(aps_couplingRequest_type), intent(inout) :: cplRequest(:)
    !> Point data buffer to be filled to send to remote domain
    type(pointData_buffer_type), intent(in) :: pntDataBuf(:)
    !> Coupling descriptor to fill with space time function pointers
    type(grw_aps_stFunCplArray_type), intent(in) :: stFunCplList
    !> List of target ranks to send coupling info
    integer, intent(in) :: targets(:)
    !> Number of coupling to send per target rank
    integer, intent(in) :: nCplSends_proc(:)
    !> Map to baseSend and pntDataBuf from target loop
    integer, intent(in) :: map2SendData(:,:)
    !> List of source ranks to receive coupling info from
    integer, intent(in) :: sources(:)
    !> Number of coupling to receive per source rank
    integer, intent(in) :: nCplRecvs_proc(:)
    !> Global mpi environment
    type(tem_comm_env_type), intent(in) :: proc
    ! -------------------------------------------------------------------------!
    integer :: iProc, iCplSend, iCplRecv, iError, iStCpl
    integer :: nCplSends, nCplRecvs, nTargets, nSources
    integer :: iCplSend_proc, iCplRecv_proc
    integer :: iComm, nComms, couplingID
    integer, allocatable :: rq_handle(:)
    integer, allocatable :: status(:,:)
    ! -------------------------------------------------------------------------!

    ! Number of target process
    nTargets = size(targets)
    ! Number of source process
    nSources = size(sources)

    ! Number of coupling data to send to remote domain
    nCplSends = sum(nCplSends_proc)
    ! Number of coupling data to receive from remote domain
    nCplRecvs = sum(nCplRecvs_proc)

    ! Total number of communication
    ! 3 communication per coupling for if it surface coupling else nComm is 2
    nComms = 0
    do iCplRecv = 1, nCplRecvs
      if (cplRequest(iCplRecv)%isSurface) then
        nComms = nComms + 3
      else
        nComms = nComms + 2
      end if
    end do

    do iCplSend = 1, nCplSends
      if (pntDataBuf(iCplSend)%isSurface) then
        nComms = nComms + 3
      else
        nComms = nComms + 2
      end if
    end do

    allocate( status( mpi_status_size, nComms ) )
    allocate(rq_handle(nComms))
    rq_handle(:) = MPI_REQUEST_NULL

    iComm = 0
    ! Receive data
    iCplRecv = 0
    do iProc = 1, nSources
      do iCplRecv_proc = 1, nCplRecvs_proc(iProc)
        iCplRecv = iCplRecv + 1
        iComm = iComm + 1
        couplingID = cplRequest(iCplRecv)%couplingID
        ! --> receive points
        call mpi_irecv( cplRequest(iCplRecv)%points,  & ! buffer
          &             cplRequest(iCplRecv)%nPnts*3, & ! counter
          &             MPI_DOUBLE_PRECISION,         & ! datatype
          &             sources(iProc),               & ! source
          &             pnt_msg_flag + couplingID,    & ! tag
          &             proc%comm,                    & ! comm
          &             rq_handle(iComm),             & ! handle
          &             iError                        ) !error status

        ! --> receive offset bit for surface coupling
        if (cplRequest(iCplRecv)%isSurface) then
          iComm = iComm + 1
          call mpi_irecv( cplRequest(iCplRecv)%offset_bit, & ! buffer
            &             cplRequest(iCplRecv)%nPnts,      & ! counter
            &             MPI_CHARACTER,                   & ! datatype
            &             sources(iProc),                  & ! source
            &             off_msg_flag+couplingID,         & ! tag
            &             proc%comm,                       & ! comm
            &             rq_handle(iComm),                & ! handle
            &             iError                           ) !error status
        end if

        ! --> receive variables
        iComm = iComm + 1
        call mpi_irecv( cplRequest(iCplRecv)%varNames,       & ! buffer
          &             cplRequest(iCplRecv)%nVars*labelLen, & ! counter
          &             MPI_CHARACTER,                       & ! datatype
          &             sources(iProc),                      & ! source
          &             var_msg_flag + couplingID,           & ! tag
          &             proc%comm,                           & ! comm
          &             rq_handle(iComm),                    & ! handle
          &             iError                               ) !error status
      end do !iCplRecv_proc
    end do !iProc

    ! send data
    iCplSend = 0
    do iProc = 1, nTargets
      do iCplSend_proc = 1, nCplSends_proc(iproc)
        iCplSend = map2SendData(iProc, iCplSend_proc)
        iStCpl = pntDataBuf(iCplSend)%map2StFunCpl
        couplingID = (stFunCplList%val(iStCpl)%loc_domID-1)*maxCplPerDom &
          &        + iStCpl
        ! --> send points
        iComm = iComm + 1
        call mpi_isend( pntDataBuf(iCplSend)%points,   & ! buffer
          &             pntDataBuf(iCplSend)%nPnts*3,  & ! count
          &             MPI_DOUBLE_PRECISION,          & ! data type
          &             targets(iProc),                & ! target
          &             pnt_msg_flag + couplingID,     & ! tag
          &             proc%comm,                     & ! communicator
          &             rq_handle(iComm),              & ! handle
          &             iError                         ) ! error status


        ! --> send offset bit for surface coupling
        ! isSurface = 0 for surface coupling and 1 for volume coupling
        if (pntDataBuf(iCplSend)%isSurface) then
          iComm = iComm + 1
          call mpi_isend( pntDataBuf(iCplSend)%offset_bit, & ! buffer
            &             pntDataBuf(iCplSend)%nPnts,      & ! count
            &             MPI_CHARACTER,                   & ! data type
            &             targets(iProc),                  & ! target
            &             off_msg_flag + couplingID,       & ! tag
            &             proc%comm,                       & ! communicator
            &             rq_handle(iComm),                & ! handle
            &             iError                           ) ! error status
        end if

        ! --> send the varNames
        iComm = iComm + 1
        call mpi_isend( stFunCplList%val(iStCpl)%stFunPtr%aps_coupling &
          &                                          %varNames,        & ! buffer
          &             stFunCplList%val(iStCpl)%stFunPtr%aps_coupling &
          &                                          %nVars*labelLen,  & ! count
          &             MPI_CHARACTER,                                 & ! data type
          &             targets(iProc),                                & ! target
          &             var_msg_flag + couplingID,                     & ! tag
          &             proc%comm,                                     & ! communicator
          &             rq_handle(iComm),                              & !handle
          &             iError                                         ) ! error status
      end do !iCplSend_proc
    end do !iProc

    call mpi_waitall( nComms, rq_handle, status, iError)

  end subroutine exchange_pointData
  ! ***************************************************************************!


  ! ***************************************************************************!
  !> This routine fills pointData buffer with points and offset bit
  !! from points stored in tem_coupling_type.
  !! If elemPos is present used it to access points and offset bit.
  !! Also store iStCpl to in pntDataBuf%map2StFunCpl to access varNames
  subroutine fill_pointDataBuffer( pntDataBuf, temPntData, iStCpl, &
    &                              isSurface, elemPos )
    ! -------------------------------------------------------------------------!
    !> Point data buffer to be filled to send to remote domain
    type(pointData_buffer_type), intent(out) :: pntDataBuf
    !> Point data stored in treelm spacetime function element type by
    !! setup_indices
    type(tem_pointData_type), intent(in) :: temPntData
    !> map to current stFunCpl in stFunCplList
    integer, intent(in) :: iStCpl
    !> Store offset_bit only if isSurface is true
    logical, intent(in) :: isSurface
    !> Position in temPntData%points array to store in pntDataBuf.
    !! Created by tem_comm_createBuffer.
    type(grw_intArray_type), optional, intent(in) :: elemPos
    ! -------------------------------------------------------------------------!
    integer :: iPnt, pntPos
    ! -------------------------------------------------------------------------!
    pntDataBuf%map2StFunCpl = iStCpl
    pntDataBuf%isSurface = isSurface

    if (present(elemPos)) then
      pntDataBuf%nPnts = elemPos%nVals
      ! points
      allocate(pntDataBuf%points(elemPos%nVals, 3))
      do iPnt = 1, elemPos%nVals
        pntPos = elemPos%val(iPnt)
        pntDataBuf%points(iPnt, 1) = temPntData%grwPnt%coordX%val(pntPos)
        pntDataBuf%points(iPnt, 2) = temPntData%grwPnt%coordY%val(pntPos)
        pntDataBuf%points(iPnt, 3) = temPntData%grwPnt%coordZ%val(pntPos)
      end do

      ! offset bit
      if (isSurface) then
        allocate(pntDataBuf%offset_bit(elemPos%nVals))
        do iPnt = 1, elemPos%nVals
          pntDataBuf%offset_bit(iPnt) = temPntData%offset_bit             &
            &                                     %val( elemPos%val(iPnt) )
        end do
      end if

    else
      pntDataBuf%nPnts = temPntData%nPnts
      allocate(pntDataBuf%points(temPntData%nPnts,3))
      do iPnt = 1, temPntData%nPnts
        ! points
        pntDataBuf%points(iPnt, 1) = temPntData%grwPnt%coordX%val(iPnt)
        pntDataBuf%points(iPnt, 2) = temPntData%grwPnt%coordY%val(iPnt)
        pntDataBuf%points(iPnt, 3) = temPntData%grwPnt%coordZ%val(iPnt)
      end do

      ! offset bit
      if (isSurface) then
        allocate(pntDataBuf%offset_bit(temPntData%nPnts))
        pntDataBuf%offset_bit(:) = temPntData%offset_bit%val(1:pntDataBuf%nPnts)
      end if

    end if !elemPos

  end subroutine fill_pointDataBuffer
  ! ***************************************************************************!


  ! ***************************************************************************!
  !> This routine exchange base information between domains with non-blocking
  !! point-point communication with nCoupling to send and receive from proceses
  !! gathered using sparse alltoall
  subroutine exchange_baseInfo( baseSend, baseRecv, targets, nCplSends_proc, &
    &                           map2SendData, sources, nCplRecvs_proc, proc  )
    ! -------------------------------------------------------------------------!
    !> Coupling base information to send to remote domain
    type(baseInfo_type), intent(in) :: baseSend(:)
    !> Coupling base information received from remote domain
    type(baseInfo_type), allocatable, intent(out) :: baseRecv(:)
    !> List of target ranks to send coupling info
    integer, intent(in) :: targets(:)
    !> Number of coupling to send per target rank
    integer, intent(in) :: nCplSends_proc(:)
    !> Map to baseSend and pntDataBuf from target loop
    integer, intent(in) :: map2SendData(:,:)
    !> List of source ranks to receive coupling info from
    integer, intent(in) :: sources(:)
    !> Number of coupling to receive per source rank
    integer, intent(in) :: nCplRecvs_proc(:)
    !> Global mpi environment
    type(tem_comm_env_type), intent(in) :: proc
    ! -------------------------------------------------------------------------!
    integer :: iProc, iCplSend, iCplRecv, iError
    integer :: nCplSends, nCplRecvs, nTargets, nSources
    integer :: iCplSend_proc, iCplRecv_proc
    integer :: nComms
    integer, allocatable :: rq_handle(:)
    integer, allocatable :: status(:,:)
    ! -------------------------------------------------------------------------!

    ! Number of target process
    nTargets = size(targets)
    ! Number of source process
    nSources = size(sources)

    ! Number of coupling data to send to remote domain
    nCplSends = sum(nCplSends_proc)
    ! Number of coupling data to receive from remote domain
    nCplRecvs = sum(nCplRecvs_proc)
    allocate(baseRecv(nCplRecvs))

    ! Total number of communication
    nComms = nCplRecvs + nCplSends
    allocate( status( mpi_status_size, nComms ) )
    allocate(rq_handle(nComms))
    rq_handle(:) = MPI_REQUEST_NULL

    iCplRecv = 0
    do iProc = 1, nSources
      do iCplRecv_proc = 1, nCplRecvs_proc(iProc)
        iCplRecv = iCplRecv + 1
        call mpi_irecv( baseRecv(iCplRecv)%buffer, & ! buffer
          &             baseInfo_nInts,            & ! counter
          &             MPI_INTEGER,               & ! datatype
          &             sources(iProc),            & ! source
          &             iCplRecv_proc,             & ! tag
          &             proc%comm,                 & ! comm
          &             rq_handle(iCplRecv),       & ! handle
          &             iError                     ) !error status
      end do
    end do

    iCplSend = 0
    do iProc = 1, nTargets
      do iCplSend_proc = 1, nCplSends_proc(iProc)
        iCplSend = map2SendData(iProc, iCplSend_proc)
        call mpi_isend( baseSend(iCplSend)%buffer,     & ! buffer
          &             baseInfo_nInts,                & ! count
          &             MPI_INTEGER,                   & ! data type
          &             targets(iProc),                & ! target
          &             iCplSend_proc,                 & ! tag
          &             proc%comm,                     & ! communicator
          &             rq_handle(nCplRecvs+iCplSend), & ! handle
          &             iError                         ) !error status
      end do
    end do

    call mpi_waitall( nComms, rq_handle, status, iError)

  end subroutine exchange_baseInfo
  ! ***************************************************************************!


  ! ***************************************************************************!
  !> This routine exchange evalVal using non-blocking communication
  subroutine exchange_evalVal( stFunCplList, cplVars, proc )
    ! -------------------------------------------------------------------------!
    !> Coupling descriptor to fill with space time function pointers
    type(grw_aps_stFunCplArray_type), target, intent(inout) :: stFunCplList
    !> To be filled with information in coupling request type by
    !! grouping request per coupling variable name.
    type(aps_coupling_variables_type), target, intent(inout) :: cplVars
    !> Global mpi environment
    type(tem_comm_env_type), intent(in) :: proc
    ! -------------------------------------------------------------------------!
    integer :: nCpl_send, nCpl_recv, iCpl_send, iCpl_recv, nCommunications
    integer :: iError
    integer :: iLevel, iStCpl, iVar, iVal
    integer :: iProc, var_flag, couplingID, domID
    integer :: nSendVals, nRecvVals
    integer, allocatable :: rq_handle(:), status(:,:)
    type(tem_communication_type), pointer :: send => NULL()
    type(tem_communication_type), pointer :: recv => NULL()
    ! -------------------------------------------------------------------------!
    write(LogUnit(10),*) 'Start exchange evaluated cplVars ...'
    ! count number of receives
    nCpl_recv = 0
    do iStCpl = 1, stFunCplList%nVals
      iLevel = stFunCplList%val(iStCpl)%iLevel
      nCpl_recv = stFunCplList%val(iStCpl)%stFunPtr%aps_coupling  &
        &                     %valOnLvl(iLevel)%recvBuffer%nProcs &
        &       + nCpl_recv
    end do !iStCpl

    ! Fill sendBuffer and count number of sends
    nCpl_send = 0
    do iVar = 1, cplVars%varName%nVals
      do iLevel = cplVars%minLevel%val(iVar), cplVars%maxLevel%val(iVar)
        ! Fill send buffer with evalVal
        send => cplVars%requestedData(iVar)%dataOnLvl(iLevel)%sendBuffer
        nCpl_send = send%nProcs + nCpl_send
        do iProc = 1, send%nProcs
          nSendVals = send%buf_real(iProc)%nVals
          do iVal = 1, nSendVals
            send%buf_real(iProc)%val(iVal)                        &
              & = cplVars%requestedData(iVar)%dataOnLvl(iLevel)   &
              &          %evalVal( send%buf_real(iProc)%pos(iVal) )
          end do !iVal
        end do !iProc
      end do !iLevel
    end do !iVar

    nCommunications = nCpl_send + nCpl_recv

    allocate( status( mpi_status_size, nCommunications ) )
    allocate(rq_handle(nCommunications))
    rq_handle(:) = MPI_REQUEST_NULL

    ! receive values from remote domains
    iCpl_recv = 0
    do iStCpl = 1, stFunCplList%nVals
      ! the current domain
      domID = stFunCplList%val(iStCpl)%loc_domID
      ! unique coupling ID
      couplingID = (domID-1)*maxCplPerDom + iStCpl

      iLevel = stFunCplList%val(iStCpl)%iLevel
      recv => stFunCplList%val(iStCpl)%stFunPtr%aps_coupling &
        &                 %valOnLvl(iLevel)%recvBuffer

      var_flag = couplingID + var_msg_flag
      do iProc = 1, recv%nProcs
        iCpl_recv = iCpl_Recv + 1
        call mpi_irecv( recv%buf_real(iProc)%val,   & ! buffer
          &             recv%buf_real(iProc)%nVals, & ! counter
          &             MPI_DOUBLE_PRECISION,       & ! datatype
          &             recv%proc(iProc),           & ! source
          &             var_flag,                   & ! tag
          &             proc%comm,                  & ! comm
          &             rq_handle(iCpl_recv),       & ! handle
          &             iError                      ) !error status
      end do !iProc
    end do !iStCpl

    ! send requested variable values
    iCpl_send = 0
    do iVar = 1, cplVars%varName%nVals
      var_flag = cplVars%couplingID%val(iVar) + var_msg_flag

      do iLevel = cplVars%minLevel%val(iVar), cplVars%maxLevel%val(iVar)

        send => cplVars%requestedData(iVar)%dataOnLvl(iLevel)%sendBuffer
        do iProc = 1, send%nProcs
          iCpl_send = iCpl_send + 1
          call mpi_isend( send%buf_real(iProc)%val,         & ! buffer
            &             send%buf_real(iProc)%nVals,       & ! counter
            &             MPI_DOUBLE_PRECISION,             & ! datatype
            &             send%proc(iProc),                 & ! target
            &             var_flag,                         & ! tag
            &             proc%comm,                        & ! comm
            &             rq_handle(iCpl_send + nCpl_recv), & ! handle
            &             iError                            ) !error status
        end do !iProc
      end do !iLevel
    end do !iVar


    call tem_startTimer( timerHandle = aps_timerHandles%commWait )
    ! Wait for above communications to complete
    call mpi_waitall(nCommunications,   & ! count
      &              rq_handle,         & ! request handles
      &              status,            & ! mpi status
      &              iError )             ! error status
    call tem_stopTimer( timerHandle = aps_timerHandles%commWait )

    ! Copy received values from remote domain to stFun coupling
    do iStCpl = 1, stFunCplList%nVals
      iLevel = stFunCplList%val(iStCpl)%iLevel
      recv => stFunCplList%val(iStCpl)%stFunPtr%aps_coupling &
        &                 %valOnLvl(iLevel)%recvBuffer

      ! Fill the recv buffer val
      do iProc = 1, recv%nProcs
        nRecvVals = recv%buf_real(iProc)%nVals
        do iVal = 1, nRecvVals
          stFunCplList%val(iStCpl)%stFunPtr%aps_coupling%valOnLvl(iLevel) &
            &         %evalVal( recv%buf_real(iProc)%pos(iVal) )          &
            & = recv%buf_real(iProc)%val(iVal)
        end do
      end do

    end do !iStCpl

    write(LogUnit(10),*)  '... end exchange evaluated cplVars.'

  end subroutine exchange_evalVal
  ! ***************************************************************************!


  ! ***************************************************************************!
  !> This routine exchange the ranks for each requested point back to
  !! the requested rank.
  !! Sources and targets are used for recv and send
  subroutine exchange_pntRanksAndnScalars( cplRequest, stFunCplList, proc )
    ! -------------------------------------------------------------------------!
    !> list of all requests from the remote domain
    type(aps_couplingRequest_type), intent(in) :: cplRequest(:)
    !> Coupling descriptor to fill with space time function pointers
    type(grw_aps_stFunCplArray_type), intent(inout) :: stFunCplList
    !> Global mpi environment
    type(tem_comm_env_type), intent(in) :: proc
    ! -------------------------------------------------------------------------!
    integer, allocatable :: rq_handle(:)
    integer, allocatable :: status(:,:)
    integer :: iStCpl, iCplReq, nCplReqs, nCplStFuns, iError, iLevel
    integer :: couplingID
    integer :: nComms, nPnts
    ! -------------------------------------------------------------------------!

    nCplStFuns = stFunCplList%nVals
    nCplReqs = size(cplRequest)
    ! two communications: rank of points and varPos
    nComms = 2*(nCplStFuns + nCplReqs)
    allocate( status( mpi_status_size, nComms ) )
    allocate(rq_handle(nComms))
    rq_handle(:) = MPI_REQUEST_NULL

    ! Receive ranks from the process to which we sent points to
    do iStCpl = 1, nCplStFuns
      iLevel = stFunCplList%val(iStCpl)%iLevel
      nPnts = stFunCplList%val(iStCpl)%stFunElemPtr   &
        &                 %pntData%pntLvl(iLevel)%nPnts
      ! @todo KM: deallocate pntRanks after its used
      allocate( stFunCplList%val(iStCpl)%stFunPtr%aps_coupling &
        &                    %valOnLvl(iLevel)%pntRanks(nPnts) )
      couplingID = (stFunCplList%val(iStCpl)%loc_domID-1)*maxCplPerDom &
        &        + iStCpl

      ! receive rank of points
      call mpi_irecv( stFunCplList%val(iStCpl)%stFunPtr%aps_coupling &
        &                         %valOnLvl(iLevel)%pntRanks,        & ! buffer
        &             nPnts,                                         & ! counter
        &             MPI_INTEGER,                                   & ! datatype
        &             stFunCplList%val(iStCpl)%partner,              & ! source
        &             pnt_msg_flag + couplingID,                     & ! tag
        &             proc%comm,                                     & ! comm
        &             rq_handle(iStCpl),                             & ! handle
        &             iError                                         ) !error status

      ! receive nScalars
      call mpi_irecv( stFunCplList%val(iStCpl)%stFunPtr%aps_coupling  &
        &                                              %nScalars,     & ! buffer
        &             1,                                              & ! counter
        &             MPI_INTEGER,                                    & ! datatype
        &             stFunCplList%val(iStCpl)%partner,               & ! source
        &             var_msg_flag + couplingID,                      & ! tag
        &             proc%comm,                                      & ! comm
        &             rq_handle(iStCpl + nComms/2),                   & ! handle
        &             iError                                          ) !error status
    end do !iStCpl

    ! Send point ranks and nScalars to requested domain
    do iCplReq = 1, nCplReqs
      couplingID = cplRequest(iCplReq)%couplingID
      ! send rank of all points
      call mpi_isend( cplRequest(iCplReq)%pntRanks,    & ! buffer
        &             cplRequest(iCplReq)%nPnts,       & ! counter
        &             MPI_INTEGER,                     & ! datatype
        &             cplRequest(iCplReq)%partner,     & ! target
        &             pnt_msg_flag + couplingID,       & ! tag
        &             proc%comm,                       & ! comm
        &             rq_handle(iCplReq + nCplStFuns), & ! handle
        &             iError                           ) !error status

      ! send nScalars
      call mpi_isend( cplRequest(iCplReq)%nScalars,   & ! buffer
        &             1,                              & ! counter
        &             MPI_INTEGER,                    & ! datatype
        &             cplRequest(iCplReq)%partner,    & ! target
        &             var_msg_flag + couplingID,      & ! tag
        &             proc%comm,                      & ! comm
        &             rq_handle(iCplReq + nCplStFuns  &
        &                               + nComms/2),  & ! handle
        &             iError                          ) !error status
    end do !iCplReq

    call mpi_waitall( nComms, rq_handle, status, iError)

  end subroutine exchange_pntRanksAndnScalars
  ! ***************************************************************************!


  ! ***************************************************************************!
  !> Routine to fill coupling request from baseInfo received from remote domain
  subroutine init_cplRequestFromBaseInfo( cplRequest, baseRecv, sources, &
    &                                     nCplRecvs_proc )
    ! -------------------------------------------------------------------------!
    !> Coupling request to be filled with base information
    type(aps_couplingRequest_type), allocatable, intent(out) :: cplRequest(:)
    !> Base infos received from remote domain
    type(baseInfo_type), intent(in) :: baseRecv(:)
    !> List of source ranks to receive coupling info from
    integer, intent(in) :: sources(:)
    !> Number of coupling to receive per source rank
    integer, intent(in) :: nCplRecvs_proc(:)
    ! -------------------------------------------------------------------------!
    integer :: iProc, iCplRecv_proc, iCplRecv
    ! -------------------------------------------------------------------------!
    allocate( cplRequest( size(baseRecv) ) )

    iCplRecv = 0
    do iProc = 1, size(sources)
      do iCplRecv_proc = 1, nCplRecvs_proc(iProc)
        iCplRecv = iCplRecv + 1
        cplRequest(iCplRecv)%partner  = sources(iProc)

        cplRequest(iCplRecv)%loc_domID  = baseRecv(iCplRecv)%buffer(1)
        cplRequest(iCplRecv)%rem_domID  = baseRecv(iCplRecv)%buffer(2)
        cplRequest(iCplRecv)%couplingID = baseRecv(iCplRecv)%buffer(3)
        cplRequest(iCplRecv)%iLevel     = baseRecv(iCplRecv)%buffer(4)
        cplRequest(iCplRecv)%nPnts      = baseRecv(iCplRecv)%buffer(5)
        cplRequest(iCplRecv)%nVars      = baseRecv(iCplRecv)%buffer(6)
        cplRequest(iCplRecv)%isSurface  = (baseRecv(iCplRecv)%buffer(7) == 0)

        allocate(cplRequest(iCplRecv)%points(cplRequest(iCplRecv)%nPnts,3))
        allocate(cplRequest(iCplRecv)%varNames(cplRequest(iCplRecv)%nVars))
        if (cplRequest(iCplRecv)%isSurface) then
          allocate(cplRequest(iCplRecv)%offset_bit(cplRequest(iCplRecv)%nPnts))
        end if !isSurdace

      end do !iCplRecv_proc
    end do !iProc
  end subroutine init_cplRequestFromBaseInfo
  ! ***************************************************************************!


  ! ***************************************************************************!
  !> Routine to fill baseInfo to send from aps_stFun_coupling_type
  subroutine fill_baseSendFromStFunCpl( baseSend, stFunCpl, iStCpl )
    ! -------------------------------------------------------------------------!
    !> Base info to send to remote domain
    type(baseInfo_type), intent(out) :: baseSend
    !> aps coupling type to fill baseSend
    type(aps_stFun_coupling_type), intent(in) :: stFunCpl
    !> To create unique id for current coupling
    integer, intent(in) :: iStCpl
    ! -------------------------------------------------------------------------!
    ! remote domain ID to send baseSend
    baseSend%buffer(1) = stFunCpl%stFunPtr%aps_coupling%rem_domID
    ! local domain ID
    baseSend%buffer(2) = stFunCpl%loc_domID
    ! unique coupling ID
    baseSend%buffer(3) = (stFunCpl%loc_domID-1)*maxCplPerDom + iStCpl
    ! level
    baseSend%buffer(4) = stFunCpl%iLevel
    ! nPoints to send to remote domain
    ! Is overwritten in comm_couplingRequest_finalize
    baseSend%buffer(5) = stFunCpl%stFunElemPtr%pntData          &
      &                          %pntLvl( stFunCpl%iLevel )%nPnts
    ! save number of variables we want to send
    baseSend%buffer(6) = stFunCpl%stFunPtr%aps_coupling%nVars
    ! is surface
    baseSend%buffer(7) = stFunCpl%stFunPtr%aps_coupling%isSurface

  end subroutine fill_baseSendFromStFunCpl
  ! ***************************************************************************!

end module aps_comm_module
! *****************************************************************************!
