! Copyright (c) 2015-2017 Kannan Masilamani <kannan.masilamani@dlr.de>
! Copyright (c) 2016-2017 Verena Krupp <verena.krupp@uni-siegen.de>
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
!> This module contain domain describtion in in Apes
!!
!! domain object is used to build up list of solvers perform simulation on the
!! domain specified in the solver configuration file
!!
!! \author Kannan Masilamani
module aps_domainObj_module
  ! treelm modules
  use env_module,            only: rk, labelLen, pathLen
  use tem_aux_module,        only: tem_abort
  use tem_logging_module,    only: logUnit, tem_last_lu
  use tem_debug_module,      only: dbgUnit
  use tem_grow_array_module, only: grw_intArray_type
  use tem_tools_module,      only: upper_to_lower, tem_horizontalSpacer
  use tem_status_module,     only: tem_status_type
  use tem_timer_module,      only: tem_addTimer, tem_timer_type, &
    &                              tem_timerconfig_type

  ! aotus modules
  use aotus_module,     only: flu_State, aot_get_val, aoterr_Fatal, &
    &                         aoterr_NonExistent, aoterr_WrongType
  use aot_table_module, only: aot_table_open, aot_table_close,     &
    &                         aot_table_length

  use aps_musubi_module, only: mus_timer_handle_type
  use aps_ateles_module, only: atl_timer_handle_type

  use aps_logging_module, only: aps_logUnit, aps_dbgUnit

  implicit none

  private

  public :: aps_domainObj_type
  public :: aps_load_domainObj
  public :: aps_domainlabel_to_ID

  ! Identifiers for supported apes applications
  integer, parameter, public :: seeder = 1
  integer, parameter, public :: musubi = 2
  integer, parameter, public :: ateles = 3
  integer, parameter, public :: harvester = 4

  !> Contains domain header information loaded from apes configuration file
  type aps_domain_header_type
    !> label to identify this domain
    character(len=labelLen) :: label

    !> solver description
    !type( tem_solveHead_type ) :: solver
    !> name of solver
    character(len=labelLen) :: solName

    !> solver configuration file
    character(len=pathLen) :: configFile

    !> fraction of number of process from total nProc to use for this domain
    real(kind=rk) :: nProcs_frac

    !> Exact number of process per domain.
    !! Sum of nProc per domain must be equal to total nProcs
    integer :: nProcs
  end type aps_domain_header_type


  !> Contains type and position of apes solver in the solver array and
  !! position of domain header for solver specific info
  type aps_domainObj_type
    !> Contains domain object table loaded from config file
    type(aps_domain_header_type) :: header

    !> type of apes solver
    !! Supported are:
    !! 1. musubi = 2
    !! 2. ateles = 3
    integer :: solver_type

    !> position in the list of corresponding apes solver
    integer :: solver_position = -1

    !> process weights on this domain
    !! Used to compute number of process needed for this domain
    !! from total number of available process.
    !! domain Weight distribution on each process is stored
    !! in params%domWeight.
    real(kind=rk) :: procWeight

    !> id of ranks which works on this domain
    type(grw_intArray_type) :: ranks

    !> MPI communicator of the processes, the domain is distrubuted on
    integer :: comm

    !> A logUnit of this domain
    integer :: logUnit(0:tem_last_lu)

    !> A debugUnit of this domain
    integer :: dbgUnit(0:tem_last_lu)

    !> timer config required for detailed timer information
    type(tem_timerconfig_type) :: timerConfig

    !> Musubi timer handles, store it here after mus_initialize to
    !! set mus_timerHandles in mus_timer_module at every timeStep.
    !! Similar to logUnit and dbgUnit
    type(mus_timer_handle_type) :: mus_timerHandles

    !> Ateles timer handles, store it here after atl_initialize_program to
    !! set atl_timerHandles in mus_timer_module at every timeStep.
    type(atl_timer_handle_type) :: atl_timerHandles

    !> Ateles elemtwise timer , store it here after atl_initialize_program to
    !! set them every timestep and enable runig multiple domain per process
    type(tem_timer_type) :: atl_elemTimers

    !> Whether this process is the root of this domain
    logical :: isRoot

    !> Pointer to status bit of this domain
    type(tem_status_type), pointer :: status => NULL()

    !> Time spent on solving the single domain
    integer :: singleDom

    !> Time spent on evaluting polynomials for each domain
    integer :: cplEval

    !> Time spent on waiting of the other domains for each domain
    integer :: cplWait
  end type aps_domainObj_type

contains

  ! ***************************************************************************!
  !> This routine load domain table from config file.
  !!
  !! Usage:
  !! \verbatim
  !! domain = {
  !!           solver = 'musubi', -- name of the solver
  !!           configFile = 'musubi.lua', -- solver configuration file
  !!           nProc_frac = 1.0/3.0, -- fraction of process to use for this domain
  !!                                 -- from total nProcs
  !!           label = 'mus' -- identification label for this domain
  !! }
  !! \endverbatim
  subroutine aps_load_domainObj( me, conf, nProcIsFrac, share_dom, glob_nProc )
    !--------------------------------------------------------------------------!
    !> contains all domain objects defined in the config file
    type( aps_domainObj_type ), allocatable, intent(out) :: me(:)
    !> lua state
    type(flu_State), intent(inout) :: conf
    !> is nProcs per domain should be loaded as fraction or exact count
    logical, intent(in) :: nProcIsFrac
    !> Decide whether to distribute all domains on all process
    logical, intent(in) :: share_dom
    !> total number of process
    integer, intent(in) :: glob_nProc
    !-------------------------------------------------------------------------!
    integer :: dom_handle, dom_subhandle
    integer :: nDomains, iDomObj
    real(kind = rk), allocatable :: norm_nProcs_frac(:)
    !--------------------------------------------------------------------------!
    call tem_horizontalSpacer(funit=aps_logUnit(1))
    write(aps_logUnit(1),*) 'Loading apes domain object '
    nDomains = 0

    ! load domain objects
    call aot_table_open(L = conf, thandle = dom_handle, key = 'domain_object')

    ! Load domain sub handle to check between single table or multiple table
    call aot_table_open(L       = conf,          &
      &                 parent  = dom_handle,    &
      &                 thandle = dom_subhandle, &
      &                 pos     = 1              )

    if (dom_handle > 0) then
      ! domain table definition exists in the configuration.

      if (dom_subHandle == 0 ) then
        ! There is no second table within the opened domain table at the
        ! first position. Interpret the parent table as a single domain object.
        nDomains = 1
        allocate(me(nDomains))
        allocate(norm_nProcs_frac(nDomains))
        call aot_table_close( L = conf, thandle = dom_subHandle )
        write(aps_logUnit(1),*) 'Loading domain header: ', nDomains
        call aps_load_domainHeader_single( me          = me(1)%header,      &
          &                                conf        = conf,              &
          &                                thandle     = dom_handle,        &
          &                                solver_type = me(1)%solver_type, &
          &                                nProcIsFrac = nProcIsFrac        )
      else
        ! The first entry in the domain table is a table in itself, try
        ! to interpret all entries as object definitions and read multiple
        ! objects from the domain object table.
        call aot_table_close(L = conf, thandle = dom_subHandle)
        nDomains = aot_table_length(L = conf, thandle = dom_handle)
        allocate(me(nDomains))
        allocate(norm_nProcs_frac(nDomains))
        do iDomObj = 1, nDomains
          write(aps_logUnit(1),*) 'Loading domain header: ', iDomObj
          call aot_table_open(L       = conf,          &
            &                 parent  = dom_handle,    &
            &                 thandle = dom_subhandle, &
            &                 pos     = iDomObj        )
          call aps_load_domainHeader_single(         &
            & me          = me(iDomObj)%header,      &
            & conf        = conf,                    &
            & thandle     = dom_subhandle,           &
            & solver_type = me(iDomObj)%solver_type, &
            & nProcIsFrac = nProcIsFrac              )
          call aot_table_close(L = conf, thandle = dom_subHandle)
        end do
      endif
    else
      write(aps_logUnit(1),*) 'WARNING: No domain objects are defined!'
    end if

    call aot_table_close(L = conf, thandle = dom_handle)

    write(aps_logUnit(1),*) 'Total number of domains defined: ', nDomains
    call tem_horizontalSpacer(funit=aps_logUnit(1))

    ! Compute procWeight.
    if (share_dom) then
      me(:)%procWeight = 1.0_rk/nDomains
    else
      if (nProcIsFrac) then
        ! normalize number of process fraction on each domain
        norm_nProcs_frac(:) = me(:)%header%nProcs_frac &
          &                 / sum(me(:)%header%nProcs_frac)

        ! process weights on each process
        do iDomObj = 1, nDomains
          me(iDomObj)%procWeight = norm_nProcs_frac(iDomObj)*glob_nProc
        end do
      else
        if (sum(me(:)%header%nProcs) /= glob_nProc) then
          call tem_abort('Sum of nProcs per domain /= total nProcs')
        end if

        do iDomObj = 1, nDomains
          me(iDomObj)%procWeight = real(me(iDomObj)%header%nProcs, kind=rk)
        end do
      end if
    end if


    do iDomObj = 1, nDomains
      write(aps_dbgUnit(1),*) 'iDom ', iDomObj,                    &
        &                     ' procWeight ', me(iDomObj)%procWeight
      call tem_addTimer(timerName   = trim(me(iDomObj)%header%label)//'Single',&
        &               timerHandle = me(iDomObj)%singleDom                    )
      call tem_addTimer(timerName   = trim(me(iDomObj)%header%label)//'Eval', &
        &               timerHandle = me(iDomObj)%cplEval                     )
      call tem_addTimer(timerName   = trim(me(iDomObj)%header%label)//'Wait', &
        &               timerHandle = me(iDomObj)%cplWait                     )
    end do

  end subroutine aps_load_domainObj
  ! ***************************************************************************!


  ! ***************************************************************************!
  !> Load single domain object from config file
  subroutine aps_load_domainHeader_single(me, conf, thandle, solver_type, &
    &                                     nProcIsFrac )
    ! -------------------------------------------------------------------------!
    !> domain header info
    type(aps_domain_header_type), intent(out) :: me
    !> lua state
    type(flu_State), intent(inout) :: conf
    !> handle for domain Object
    integer, intent(in) :: thandle
    !> current domain solver type
    integer, intent(out) :: solver_type
    !> is nProcs per domain should be loaded as fraction or exact count
    logical, intent(in) :: nProcIsFrac
    ! -------------------------------------------------------------------------!
    integer :: iError
    ! -------------------------------------------------------------------------!
    call tem_horizontalSpacer(funit=aps_logUnit(1))

    call aot_get_val(L       = conf,      &
        &            thandle = thandle,   &
        &            val     = me%label,  &
        &            key     = 'label',   &
        &            default = 'default', &
        &            ErrCode = iError     )

    ! load name of the solver
    call aot_get_val(L       = conf,       &
        &            thandle = thandle,    &
        &            val     = me%solName, &
        &            key     = 'solver',   &
        &            ErrCode = iError      )

    if (btest(iError, aoterr_Fatal)) then
      write(aps_logUnit(1),*)"FATAL Error occured, while retrieving 'solver' :"
      if (btest(iError, aoterr_WrongType)) &
        & write(aps_logUnit(1),*)'Variable has wrong type!'

      if (btest(iError, aoterr_NonExistent)) &
        & write(aps_logUnit(1),*)'Variable does not exist!'
      call tem_abort()
    end if

    select case(upper_to_lower(trim(me%solName)))
    case('musubi')
      solver_type = musubi
    case('ateles')
      solver_type = ateles
    case default
      write(aps_logUnit(1),*) 'ERROR: Unknown solver: '//trim(me%solName)
      call tem_abort()
    end select

    ! load solver configuration file
    call aot_get_val(L       = conf,          &
        &            thandle = thandle,       &
        &            val     = me%configFile, &
        &            key     = 'filename',    &
        &            ErrCode = iError         )

    if (btest(iError, aoterr_Fatal)) then
      write(aps_logUnit(1),*)"FATAL Error occured, while retrieving solver"&
        & //" config 'filename' :"
      if (btest(iError, aoterr_WrongType)) &
        & write(aps_logUnit(1),*)'Variable has wrong type!'

      if (btest(iError, aoterr_NonExistent)) &
        & write(aps_logUnit(1),*)'Variable does not exist!'
      call tem_abort()
    end if

    if (nProcIsFrac) then
      ! load number of fraction of process to use for this domain
      ! from total nProcs of apesmate
      call aot_get_val(L       = conf,          &
          &            thandle = thandle,       &
          &            val     = me%nProcs_frac, &
          &            key     = 'nProc_frac',  &
          &            ErrCode = iError         )

      if (btest(iError, aoterr_Fatal)) then
        write(aps_logUnit(1),*)"FATAL Error occured, " &
          &                 // "while retrieving nProc_frac:"
        if (btest(iError, aoterr_WrongType)) then
          write(aps_logUnit(1),*)'Variable has wrong type!'
          call tem_abort()
        endif
        if (btest(iError, aoterr_NonExistent)) then
          write(aps_logUnit(1),*)'Variable not defined!'
          call tem_abort()
        end if
      end if
    else
      call aot_get_val(L       = conf,      &
          &            thandle = thandle,   &
          &            val     = me%nProcs, &
          &            key     = 'nProc',   &
          &            ErrCode = iError     )

      if (btest(iError, aoterr_Fatal)) then
        write(aps_logUnit(1),*)"FATAL Error occured, while retrieving nProc:"
        if (btest(iError, aoterr_WrongType)) then
          write(aps_logUnit(1),*)'Variable has wrong type!'
          call tem_abort()
        endif
        if (btest(iError, aoterr_NonExistent)) then
          write(aps_logUnit(1),*)'Variable is not defined!'
          call tem_abort()
        end if
      end if
    end if

    write(aps_logUnit(1),*) 'label       : ', trim(me%label)
    write(aps_logUnit(1),*) 'Solver      : ', trim(me%solName)
    write(aps_logUnit(1),*) 'Config file : ', trim(me%configFile)
    if (nProcIsFrac) then
      write(aps_logUnit(1),*) 'nProcs_frac  : ', me%nProcs_frac
    else
      write(aps_logUnit(1),*) 'nProcs  : ', me%nProcs
    end if

  end subroutine aps_load_domainHeader_single
  ! ***************************************************************************!


  ! ***************************************************************************!
  ! function to convert domain label to ID
  function aps_domainlabel_to_ID(domLabels, label) result (ID)
    ! -------------------------------------------------------------------------!
    ! list of domain
    character(len=*), intent(in) :: domLabels(:)
    ! label for which the ID is required
    character(len=*), intent(in) :: label
    ! ID for that domain, equal to position in the domain list
    integer :: ID
    ! -------------------------------------------------------------------------!
    integer :: pos
    logical :: found
    ! -------------------------------------------------------------------------!

    found = .false.
    ! loop over the list and check if the domain label is the label
    ! I am looking for
    id = -1
    do pos = 1, size(domLabels)
      if (trim(domLabels(pos)) == trim(label)) then
        ! if it is the label, set the ID
        ID = pos
        ! and finish the loop
        found = .true.
        exit
      end if
    end do

    if (.not. found) then
      write(aps_logUnit(1),*) 'Error: Domain label is not found'
      call tem_abort()
    end if

  end function aps_domainlabel_to_ID
  ! ***************************************************************************!


end module aps_domainObj_module
! *****************************************************************************!
