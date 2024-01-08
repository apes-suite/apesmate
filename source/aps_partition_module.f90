! Copyright (c) 2014-2017 Kannan Masilamani <kannan.masilamani@dlr.de>
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

!******************************************************************************!
!> Contains routines to compute domain partitions on multiple processes
module aps_partition_module
  ! treelm modules
  use mpi
  use env_module,            only: rk, labelLen
  use tem_grow_array_module, only: grw_intarray_type, init, append, destroy,   &
    &                              truncate
  use tem_comm_env_module,   only: tem_comm_env_type
  use tem_logging_module,    only: logunit
  use tem_aux_module,        only: tem_abort

  use aps_logging_module,     only: aps_dbgUnit, aps_logUnit

  implicit none

  private

  public :: aps_compute_partitionWeights
  public :: aps_set_proc_domainIDs
  public :: aps_set_domain_ranks
  public :: aps_create_domain_comm

contains


  !****************************************************************************!
  !> Compute weight of domain partition on each process using nProc_frac
  !! defined for each domain.
  !!
  !! At first Weights for each domain is computed by normalizing nProc_frac and
  !! multiplying with total nProc. Then domain is distributed on each process
  !! based up their weights.
  subroutine aps_compute_partitionWeights(nDomains, glob_nProc, domWeights, &
    &                                     procWeight)
    !--------------------------------------------------------------------------!
    !> number of domains
    integer, intent(in) :: nDomains
    !> total number of process
    integer, intent(in) :: glob_nProc
    !> output: weight of domain partition on each process
    real(kind=rk), allocatable, intent(out) :: domWeights(:,:)
    !> process weights for each domain
    real(kind=rk), intent(in) :: procWeight(nDomains)
    !--------------------------------------------------------------------------!
    real(kind = rk), dimension(nDomains) :: remain_procWeight
    real(kind = rk) :: totWeight_proc
    integer :: iDomain, iProc
    !--------------------------------------------------------------------------!

    allocate(domWeights(glob_nProc,nDomains))
    domWeights = 0.0_rk

    remain_procWeight = procWeight

    ! distribute domain process weights to all process
    ! fill each process with weight fraction of domain to be
    ! computed on that process.
    procLoop: do iProc = 1, glob_nProc
      ! total weight on each process should not go beyond 1.0
      totWeight_proc = 0.0_rk
      domLoop: do iDomain = 1, nDomains
        ! proceed only when total weight on process is < 1 and
        ! remaining procWeight of current Domain is > 0
        if(totWeight_proc < 1.0_rk .and.              &
          & remain_procWeight(iDomain) > 0.0_rk) then
          domWeights(iProc, iDomain) = min(remain_procWeight(iDomain), &
            & 1.0_rk - totWeight_proc)
          ! compute remaining proc weight of this domain after
          ! assigning some weights on earlier processes
          if (remain_procWeight(iDomain) > 1.0_rk) then
            remain_procWeight(iDomain) = remain_procWeight(iDomain) &
              & - domWeights(iProc, iDomain)
          else
            remain_procWeight(iDomain) = 1.0_rk - remain_procWeight(iDomain)
          end if
          ! update total weight on iProc
          totWeight_proc = sum(domWeights(iProc,:))
        endif
      end do domLoop
      write(aps_dbgUnit(1),*) 'iProc ', iProc , 'weight ', domWeights(iProc, :)
    end do procLoop

  end subroutine aps_compute_partitionWeights
  !****************************************************************************!


  !****************************************************************************!
  !> This routine sets growing array of domainIDs in solver type using
  !! domain weights on each process
  subroutine aps_set_proc_domainIDs(domWeights, nDomains, glob_proc,           &
    &                               domainIDs_all, domainIDs)
    !--------------------------------------------------------------------------!
    !> weight of domain partition on each process
    real(kind=rk), intent(in) :: domWeights(:,:)
    !> total number of domains defined in config file
    integer, intent(in) :: nDomains
    !> global mpi communicator
    type(tem_comm_env_type), intent(in) :: glob_proc
    !> active domainIDs on each process
    type(grw_intArray_type), allocatable, intent(out) :: domainIDs_all(:)
    !> active domainIDs on local process
    integer, allocatable, intent(out) :: domainIDs(:)
    !--------------------------------------------------------------------------!
    integer :: iProc, iDomain
    !--------------------------------------------------------------------------!

    ! allocate domainIDs_all to size of total nProc
    allocate(domainIDs_all(glob_proc%comm_size))

    ! initialize growing array
    do iProc = 1, glob_proc%comm_size
      call init(domainIDs_all(iProc),0)
    end do

    ! if process has some domain weight then domain that domain is active
    ! on that process
    do iProc = 1, glob_proc%comm_size
      do iDomain = 1, nDomains
        if(domWeights(iProc, iDomain) > 0.0_rk)  &
          & call append(domainIDs_all(iProc), iDomain)
      end do
    end do

    ! truncate growing array
    do iProc = 1, glob_proc%comm_size
      call truncate(domainIDs_all(iProc))
    end do

    ! copy local process domainIDs
    allocate(domainIDs(domainIDs_all(glob_proc%rank+1)%nVals))
    domainIDs(:) = domainIDs_all(glob_proc%rank+1)%val(:)

    do iProc = 1, glob_proc%comm_size
      write(aps_dbgUnit(10),*) 'iProc ', iProc, 'domIDS ', domainIDs_all(iProc)%val
    end do

    !write(*,*) 'rank ', params%general%proc%rank, ' local domainIDs ', solver%domainIDs

  end subroutine aps_set_proc_domainIDs
  !****************************************************************************!


  !****************************************************************************!
  !> This routine sets growing array of domainIDs in solver type using
  !! domain weights on each process
  subroutine aps_set_domain_ranks(domWeights, iDomain, glob_nProc, domainRanks)
    !--------------------------------------------------------------------------!
    !> weight of domain partition on each process
    real(kind=rk), intent(in) :: domWeights(:,:)
    !> total number of domains defined in config file
    integer, intent(in) :: iDomain
    !> global number of process
    integer, intent(in) :: glob_nProc
    !> ranks of each domain
    type(grw_intArray_type), intent(out) :: domainRanks
    !--------------------------------------------------------------------------!
    integer :: iProc
    !--------------------------------------------------------------------------!

    ! initialize growing array of ranks
    call init(domainRanks,0)

    ! if process has some domain weight then that domain is active
    ! on that process
    do iProc = 1, glob_nProc
      if(domWeights(iProc, iDomain) > 0.0_rk) &
        & call append(domainRanks, iProc-1)
    end do

    ! truncate growing array
    call truncate(domainRanks)

    write(aps_dbgUnit(10),*) 'iDomain ', iDomain, 'ranks ', domainRanks%val
    flush(aps_dbgUnit(10))

  end subroutine aps_set_domain_ranks
  !****************************************************************************!


  !****************************************************************************!
  !> This routine create mpi communicator for each domain with mpi_comm_split
  subroutine aps_create_domain_comm(domWeights, nDomains, glob_proc, dom_comm)
    !--------------------------------------------------------------------------!
    !> weight of domain partition on each process
    real(kind=rk), intent(in) :: domWeights(:,:)
    !> total number of domains defined in config file
    integer, intent(in) :: nDomains
    !> global mpi environment
    type(tem_comm_env_type), intent(in) :: glob_proc
    !> mpi communicator for each domain
    integer, intent(out) :: dom_comm(:)
    !--------------------------------------------------------------------------!
    integer :: iDomain, color, iError
    !--------------------------------------------------------------------------!
    do iDomain = 1, nDomains
      if( domWeights(glob_proc%rank+1, iDomain) > 0.0_rk) then
        color = iDomain
      else
        ! not pariticipating
        color = MPI_UNDEFINED
      end if
      call mpi_comm_split(glob_proc%comm, color, glob_proc%rank,              &
        &                 dom_comm(iDomain), iError)
      if( iError .ne. mpi_success ) then
        write(aps_logUnit(1),*)' There was an error splitting the communicator'
        write(aps_logUnit(1),*)' for the tracking subset. Aborting...'
        call tem_abort()
      end if
    end do

  end subroutine aps_create_domain_comm
  !****************************************************************************!


end module aps_partition_module
!******************************************************************************!
