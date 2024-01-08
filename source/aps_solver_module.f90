! Copyright (c) 2014-2017 Kannan Masilamani <kannan.masilamani@dlr.de>
! Copyright (c) 2015-2017 Verena Krupp <verena.krupp@dlr.de>
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
!> This module contains solver data type and routines related to solvers
!!
!! \author Kannan Masilamani
module aps_solver_module
  use mpi
  ! treelm modules
  use env_module,            only: rk, labelLen, rk_mpi
  use tem_tools_module,      only: tem_horizontalSpacer
  use tem_aux_module,        only: tem_abort
  use tem_logging_module,    only: logunit
  use tem_grow_array_module, only: grw_intarray_type
  use tem_debug_module,      only: dbgUnit
  use tem_comm_env_module,   only: tem_comm_env_type
  use tem_time_module,       only: tem_time_type

  ! include aotus module
  use aotus_module,         only: aot_get_val, flu_State,                      &
    &                             aoterr_Fatal, aoterr_NonExistent,            &
    &                             aoterr_WrongType

  ! include apes module
  use aps_domainObj_module,     only: aps_domainObj_type, &
    &                                 musubi, ateles
  use aps_musubi_module,        only: aps_musubi_type, aps_load_musubi
  use aps_ateles_module,        only: aps_ateles_type, aps_load_ateles
  use aps_param_module,         only: aps_param_type
  use aps_partition_module,     only: aps_compute_partitionWeights,            &
    &                                 aps_set_proc_domainIDs,                  &
    &                                 aps_set_domain_ranks,                    &
    &                                 aps_create_domain_comm
  use aps_logging_module,       only: aps_dbgUnit, aps_logUnit

  implicit none

  private

  public :: aps_solver_type
  public :: aps_solverCount_type
  public :: aps_load_domainObjConfig
  public :: aps_create_domainPartition

  !> Counts number of different solver types in local process
  type aps_solverCount_type
    !> number of domain with musubi solver on local process
    integer :: nMusubi = 0

    !> number of domain with ateles solver on local process
    integer :: nAteles = 0
  end type aps_solverCount_type

  !> Contains list of solvers, domain headers and domain objects
  type aps_solver_type
    !> allocatable array of solver musubi
    type(aps_musubi_type), allocatable :: musubi(:)

    !> allocatable array of solver ateles
    type(aps_ateles_type), allocatable :: ateles(:)

    !> number of domain on local process
    integer :: nDomains

    !> number of domain on all process
    !! same as size of domainObj array
    integer :: nDomains_total

    !> array of domain ids on all process
    !! @todo KM: May not be required to store
    type(grw_intArray_type), allocatable :: domainIDs_all(:)

    !> array domain ids on local process
    integer, allocatable :: domainIDs(:)

  end type aps_solver_type

contains


  ! ***************************************************************************!
  !> This routine initialize number of solvers type
  subroutine aps_init_solverCount( me )
    ! -------------------------------------------------------------------------!
    type(aps_solverCount_type), intent(out) :: me
    ! -------------------------------------------------------------------------!
    me%nMusubi = 0
    me%nAteles = 0
  end subroutine aps_init_solverCount
  ! ***************************************************************************!


  ! ***************************************************************************!
  !> This routine computes domain partition weights on each process
  !! based on nproc_frac defined for each domain.
  !! using this weights append growing array of domainIds in solver type
  !! with domainIDs active on that process and append growing
  !! array of ranks in domainObj type with on which ranks that
  !! domain is distributed.
  !! Also create mpi communicator groups for each domain
  subroutine aps_create_domainPartition(solver, solverCnt, domainObj,    &
    &                                   domWeights, globProc )
    ! -------------------------------------------------------------------------!
    !> allocates apes solvers on this local process
    type(aps_solver_type), intent(out) :: solver
    !> Counts number of different solvers on local process
    type(aps_solverCount_type), intent(out) :: solverCnt
    !> Contains all information about all domains
    type(aps_domainObj_type), intent(inout) :: domainObj(:)
    !> domain weights on each process
    !! array size - (nProcs, nDomains)
    !! @todo KM: Check if its required for dynamic load balancing
    real(kind=rk), allocatable :: domWeights(:,:)
    !> apes global communication environment
    type(tem_comm_env_type), intent(in) :: globProc
    ! -------------------------------------------------------------------------!
    integer :: iDom, domID
    ! -------------------------------------------------------------------------!
    write(aps_logUnit(1),*) 'Computing domain partition...'

    ! total number of domains defined in lua file
    solver%nDomains_total = size(domainObj)

    ! compute weights of domain partition on each process
    ! and weights of process on each domain
    call aps_compute_partitionWeights(                   &
      & nDomains       = solver%nDomains_total,          &
      & glob_nProc     = globProc%comm_size,             &
      & domWeights     = domWeights,                     &
      & procWeight     = domainObj(:)%procWeight         )

    ! set domainIDs on all process and local process
    call aps_set_proc_domainIDs(domWeights    = domWeights,            &
      &                         nDomains      = solver%nDomains_total, &
      &                         glob_proc     = globProc,              &
      &                         domainIDs_all = solver%domainIDs_all,  &
      &                         domainIDs     = solver%domainIDs       )

    ! set ranks (process id) used by each domain
    do iDom = 1, solver%nDomains_total
      call aps_set_domain_ranks(domWeights  = domWeights,            &
        &                       iDomain     = iDom,                  &
        &                       glob_nProc  = globProc%comm_size,    &
        &                       domainRanks = domainObj(iDom)%ranks )
    end do

    ! create communicator for each domain
    call aps_create_domain_comm(domWeights = domWeights,            &
      &                         nDomains   = solver%nDomains_total, &
      &                         glob_proc  = globProc,              &
      &                         dom_comm   = domainObj(:)%comm      )

    ! number of domains on local processs
    solver%nDomains = size(solver%domainIDs)
    !write(*,*) 'nDomain on process ', params%general%proc%rank, &
    !  &        ' : ', solver%nDomains, ' domIDs ', solver%domainIDs

    call aps_init_solverCount( me = solverCnt )

    ! Count different solvers in local process and their position in
    ! corresponding solver type
    do iDom = 1, solver%nDomains
      domID = solver%domainIDs(iDom)
      select case(domainObj(domID)%solver_type)
      case(musubi)
        solverCnt%nMusubi = solverCnt%nMusubi + 1
        domainObj(domID)%solver_position = solverCnt%nMusubi
      case(ateles)
        solverCnt%nAteles = solverCnt%nAteles + 1
        domainObj(domID)%solver_position = solverCnt%nAteles
      end select
    end do

  end subroutine aps_create_domainPartition
  ! ***************************************************************************!


  ! ***************************************************************************!
  !> This routine load each domain solver configuration files
  subroutine aps_load_domainObjConfig( me, solverCnt, domainObj, aps_now, &
    &                                  globProc )
    ! -------------------------------------------------------------------------!
    !> contains all apes solvers on this process
    type(aps_solver_type), intent(inout) :: me
    !> number of different solvers on local process
    type(aps_solverCount_type), intent(in) :: solverCnt
    !> Contains all information about all domains
    type(aps_domainObj_type), intent(inout) :: domainObj(:)
    !> Starting time of apes
    type(tem_time_type), intent(inout) :: aps_now
    !> apes global communication environment
    type(tem_comm_env_type), intent(in) :: globProc
    ! -------------------------------------------------------------------------!
    integer :: iDomain, domID
    integer :: sol_type, sol_pos, iError
    real(kind=rk) :: simTime_loc
    ! -------------------------------------------------------------------------!
    call tem_horizontalSpacer( after = 1, fUnit = aps_logUnit(1) )
    write(aps_logUnit(1),*) 'Loading domainObj configuration files: '

    ! allocate solver array
    allocate(me%musubi(solverCnt%nMusubi))
    allocate(me%ateles(solverCnt%nAteles))

    ! loop over local process nDomains and load solver configuration file
    do iDomain = 1, me%nDomains
      domID = me%domainIDs(iDomain)
      sol_type = domainObj(domID)%solver_type
      sol_pos = domainObj(domID)%solver_position
      select case (sol_type)
      case (musubi)
        call aps_load_musubi(                                  &
          & me           = me%musubi(sol_pos),                 &
          & timerHandles = domainObj(domID)%mus_timerHandles,  &
          & status       = domainObj(domID)%status,            &
          & isRoot       = domainObj(domID)%isRoot,            &
          & comm         = domainObj(domID)%comm,              &
          & configFile   = domainObj(domID)%header%configFile, &
          & aps_now      = aps_now                             )

      case (ateles)
        call aps_load_ateles(                                 &
          & me           = me%ateles(sol_pos),                &
          & timerHandles = domainObj(domID)%atl_timerHandles, &
          & timerConfig  = domainObj(domID)%timerConfig,      &
          & status       = domainObj(domID)%status,           &
          & isRoot       = domainObj(domID)%isRoot,           &
          & comm         = domainObj(domID)%comm,             &
          & configFile   = domainObj(domID)%header%configFile,&
          & aps_now      = aps_now                            )

      end select
      ! Copy modular logUnit set by current domain
      domainObj(domID)%logUnit = logUnit
      domainObj(domID)%dbgUnit = dbgUnit
    end do
    ! reset logUnit and dbgUnit to apesmate units
    logUnit = aps_logUnit
    dbgUnit = aps_dbgUnit

    write(aps_logUnit(1),*) 'Done loading domain config'

    ! get maximum start time of all domains
    simTime_loc = aps_now%sim
    call mpi_allreduce(simTime_loc, aps_now%sim, 1, rk_mpi, mpi_max, &
      &                globProc%comm, iError)

    call tem_horizontalSpacer( after = 1, fUnit = aps_logUnit(1) )

  end subroutine aps_load_domainObjConfig
  ! ***************************************************************************!


end module aps_solver_module
!******************************************************************************!
