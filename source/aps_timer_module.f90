! Copyright (c) 2016-2017 Verena Krupp <verena.krupp@uni-siegen.de>
! Copyright (c) 2016, 2018 Kannan Masilamani <kannan.masilamani@dlr.de>
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

! *************************************************************************** !
!> This module provides a convenient way to setup timers in the code.
!!
!! To define a new one, declare an integer module variable here, and
!! add a tem_timer_module::TEM_addTimer statement for it in the APS_addTimers
!! routine with a label for identification. Then use this module in the relevant
!! code part and call tem_timer_module::TEM_startTimer and
!! tem_timer_module::TEM_stopTimer by passing in this integer.
!!
!! Upon finishing execution, Ateles will then print the measured time, for
!! this code block into timing.res.
module aps_timer_module
  use env_module,              only: rk, long_k, newunit, pathlen, labellen, &
    &                                my_status_int

  use tem_logging_module,      only: logunit
  use tem_general_module,      only: tem_general_type
  use tem_timer_module,        only: tem_addTimer, tem_getTimerVal,        &
    &                                tem_getMaxTimerVal, tem_getTimerName
  use tem_simControl_module,   only: tem_simControl_type
  use tem_comm_env_module,     only: tem_comm_env_type
  use tem_revision_module,     only: tem_solver_revision
  use tem_solveHead_module,    only: tem_solveHead_type
  use tem_comm_env_module,     only: tem_comm_env_type

  use aps_domainObj_module,    only: aps_domainObj_type

  implicit none

  private

  public :: aps_timerHandles
  public :: aps_addTimers
  public :: aps_dumpTimers

  !> Handles for timer objects to measure the time for some code parts.
  !! Overall solver time handle is in tem_solverHead_type.
  type aps_timer_handle_type
    !> Load config files
    integer :: loadConfig
    !> Initialization time including initialization of all domains and coupling
    integer :: init
    !> Explicit initialization time of all domains
    integer :: initSolver
    !> Explicit initialization time of coupling
    integer :: initCoupling
    !> Finialize time including finialize of all domains and coupling
    integer :: finalize
    !> Finialize time including finialize of all solver
    integer :: finalSolver
    !> Simulationloop time
    integer :: simLoop
    !> Synchronization time at every time step
    integer :: syncDom
    !> Time spent on evaluation of point values
    integer :: evalVal
    !> Time spend in waiting in the Synchronization step
    integer :: commWait
    integer :: init_cplComm
    integer :: fillStFun
    integer :: roundRobin
    integer :: checkVars
    integer :: identRanks
    integer :: exchRanks
    integer :: exchCplData
    integer :: createCplVars
    !> First handle position in treelm timer object to access contigous timers
    integer :: first = 0
    !> Last handle position in treelm timer object
    integer :: last = -1
  end type aps_timer_handle_type

  type(aps_timer_handle_type), save :: aps_timerHandles

contains


  ! ************************************************************************
  !> Setup timers to assess the runtime of various parts of Ateles.
  subroutine aps_addTimers()
    ! ---------------------------------------------------------------------------

    ! Create some timer objects
    call tem_addTimer(timerName   = 'loadConfig',              &
      &               timerHandle = aps_timerHandles%loadConfig)
    ! time spend in intial
    call tem_addTimer(timerName   = 'init',              &
      &               timerHandle = aps_timerHandles%init)

    ! time spend to initialize solver
    call tem_addTimer(timerName   = 'initSolver',              &
      &               timerHandle = aps_timerHandles%initSolver)

    ! time spend to initialize coupling including communication
    call tem_addTimer(timerName   = 'initCpl',                 &
      &               timerHandle = aps_timerHandles%initCoupling)
    ! time spend to initialize coupling for filling stFun of Coupling
    call tem_addTimer(timerName    = 'fillStFun',              &
      &                timerHandle = aps_timerHandles%fillStFun)

     !time spend in init coupling communication
     call tem_addTimer(timerName   = 'init_cplComm',               &
       &               timerHandle = aps_timerHandles%init_cplComm )
     call tem_addTimer(timerName   = 'roundRobin',               &
       &               timerHandle = aps_timerHandles%roundRobin )
     call tem_addTimer(timerName   = 'checkVars',               &
       &               timerHandle = aps_timerHandles%checkVars )
     call tem_addTimer(timerName   = 'identRanks',               &
       &               timerHandle = aps_timerHandles%identRanks )
     call tem_addTimer(timerName   = 'exchRanks',               &
       &               timerHandle = aps_timerHandles%exchRanks )
     call tem_addTimer(timerName   = 'exchCplData',               &
       &               timerHandle = aps_timerHandles%exchCplData )
     call tem_addTimer(timerName   = 'createCplVars',              &
       &               timerHandle = aps_timerHandles%createCplVars)

    ! time spend in finialize
    call tem_addTimer(timerName   = 'finalize',              &
      &               timerHandle = aps_timerHandles%finalize)
    ! time spend in finialize the solver
    call tem_addTimer(timerName   = 'finalSolver',             &
      &               timerHandle = aps_timerHandles%finalSolver)


    ! time spend to simLoop
    call tem_addTimer(timerName   = 'aps_simLoop',          &
      &               timerHandle = aps_timerHandles%simLoop)

    ! time spend in synchronize domains done in time loop
    call tem_addTimer(timerName   = 'syncDoms',             &
      &               timerHandle = aps_timerHandles%syncDom)
    ! time in synchronize domain which is spend in waiting after
    ! exchange of the cpl values
    call tem_addTimer(timerName   = 'commWait',              &
      &               timerHandle = aps_timerHandles%commWait)
    ! time in synchronize domain which is spend in evaluation the coupling
    ! variable
    call tem_addTimer(timerName   = 'evalVal',              &
      &               timerHandle = aps_timerHandles%evalVal)

    ! First and last handles which are contigous in treelm timer object
    aps_timerHandles%first = aps_timerHandles%loadConfig
    aps_timerHandles%last = aps_timerHandles%evalVal

  end subroutine aps_addTimers
  ! ******************************************************************************


  ! ******************************************************************************
  !> Performance results are written to a file for statistical review
  !! The file-format is simple can be evaluated with gnuplot
  subroutine aps_dumpTimers(general, domainObj)
    ! ---------------------------------------------------------------------------
    type(tem_general_type), intent(inout) :: general
    !> Contains all information about all domains
    type(aps_domainObj_type), intent(in) :: domainObj(:)
    ! ---------------------------------------------------------------------------
    !< Memory usage (resident set size, high water mark)
    integer :: memRss, memHwm
    logical              :: file_exists
    character(len=pathLen)        :: filename
    integer              :: fileunit, iTimer, counter, iDom
    real(kind=rk),allocatable        :: timerVal(:)
    character(len=40)                :: timerLabel
    character(len=PathLen)    :: header
    character(len=PathLen)    :: output
    integer              :: iterations
    integer :: nTimers
    real(kind=rk) :: tApes
    ! ---------------------------------------------------------------------------
    nTimers = aps_timerHandles%last - aps_timerHandles%first + 1 &
      &     + 3*size(domainObj)
    allocate( timerVal( nTimers ) )
    ! first and last handle convers all apesmate handles which are added
    ! contigously
    counter = 0
    ! Get MaxTimer outside if isRoot since tem_getMaxTimerVal uses
    ! mpi_allreduce
    do iTimer = aps_timerHandles%first, aps_timerHandles%last
      counter = counter+1
      timerVal(counter)   = tem_getMaxTimerVal(timerHandle = iTimer,           &
        &                                      comm        = general%proc%comm )
    end do
    ! Add timer measure for individual domains
    do iDom = 1, size(domainObj)
      ! for waiting
      counter = counter+1
      iTimer = domainObj(iDom)%cplWait
      timerVal(counter)   = tem_getMaxTimerVal(timerHandle = iTimer,           &
        &                                      comm        = general%proc%comm )
      ! for solving single domains
      counter = counter+1
      iTimer = domainObj(iDom)%singleDom
      timerVal(counter)   = tem_getMaxTimerVal(timerHandle = iTimer,           &
        &                                      comm        = general%proc%comm )

      ! for evaluating
      counter = counter+1
      iTimer = domainObj(iDom)%cplEval
      timerVal(counter)   = tem_getMaxTimerVal(timerHandle = iTimer,           &
        &                                      comm        = general%proc%comm )
    end do

    if ( general%proc%isRoot ) then
      !>@todo HK: Make mem-stuff configurable.
      !!          Maybe reduce values from all processes
      !!          to find global maximum.
      memRss = my_status_int('VmRSS:')
      memHwm = my_status_int('VmHWM:')

      write(header,'(a1,1x,a12,1x,a20,1x,a8,1x,a8,2(1x,a12))')&
        & '#', 'Revision', &
        & 'Casename', &
        & 'nProcs',&     ! The number of proc (i.e. MPI ranks)
        & 'threads', &   ! The number of OMP threads per proc
        & 'maxIter', &
        & 'timeApes'

      ! first and last handle convers all ateles handles which are added
      ! contigously
      counter = 0
      do iTimer = aps_timerHandles%first, aps_timerHandles%last
        timerLabel = trim(tem_getTimerName(timerHandle = iTimer))
        write(header,'(a,a12,a1)') trim(header), trim(timerLabel), '|'
      enddo

      ! Add timer measure of coupling wait
      do iDom = 1, size(domainObj)
        iTimer = domainObj(iDom)%cplWait
        timerLabel = trim(tem_getTimerName(timerHandle = iTimer))
        write(header,'(a,a12,a1)') trim(header), trim(timerLabel), '|'
        iTimer = domainObj(iDom)%singleDom
        timerLabel = trim(tem_getTimerName(timerHandle = iTimer))
        write(header,'(a,a12,a1)') trim(header), trim(timerLabel), '|'
        iTimer = domainObj(iDom)%cplEval
        timerLabel = trim(tem_getTimerName(timerHandle = iTimer))
        write(header,'(a,a12,a1)') trim(header), trim(timerLabel), '|'
      enddo


      write(header,'(a,2(1x,a12))') trim(header), &
        & 'MemRSS', &    ! memory usage in sim loop
        & 'MemHWM'       ! memory usage max

      !>@todo HK: ensure, that timing is actually now, and it is valid to use
      !!          the iter component of it as the overall number of iterations
      !!          (might be different after restart?)
      iterations = general%simControl%now%iter &
        &        - general%simControl%timeControl%min%iter
      ! total time taken for Apes
      tApes = tem_getTimerVal( timerHandle = general%solver%timerHandle )
      write(output, '(1x,a13,1x,a20,i8,1x,i8,1x,i12,1x,en12.3)' ) &
        &   trim(tem_solver_revision), &
        &   trim(general%solver%simName), &
        &   general%proc%comm_size, &
        &   general%proc%nThreads,  &
        &   iterations,             &
        &   tApes ! Time spend on Apesmate

      do iTimer = 1, nTimers
        write(output,'(a,1x,en12.3)') trim(output), timerVal( iTimer )
      enddo

      write(output,'(a,i12,i12)') trim(output), memRss, memHwm

      filename = trim(general%timingFile)
      write(logunit(2),*) 'Writing timing information to ', trim(filename)
      inquire(file=filename, exist=file_exists)
      fileunit = newunit()
      open(unit=fileunit, file=trim(filename), position='append')

      if (.not. file_exists ) then
         write(fileunit,'(a)') trim(header)
      end if
      write(fileunit,'(a)') trim(output)
      close(fileunit)
    end if

  end subroutine aps_dumpTimers
  ! ******************************************************************************

end module aps_timer_module
