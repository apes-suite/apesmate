! Copyright (c) 2016 Verena Krupp <verena.krupp@uni-siegen.de>
! Copyright (c) 2016 Kannan Masilamani <kannan.masilamani@dlr.de>
! Copyright (c) 2016 Tobias Girresser <tobias.girresser@student.uni-siegen.de>
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
!> This module contains logging ande debug type for apesmate
module aps_logging_module

  use tem_logging_module, only: logUnit, tem_logging_load_primary, &
    &                           tem_last_lu
  use tem_debug_module,   only: dbgUnit, tem_debug_load_main

  use aot_table_module, only: aot_table_open, aot_table_close
  use aotus_module,     only: flu_state

  implicit none

  public :: aps_load_logging

  integer, public :: aps_dbgUnit(0:tem_last_lu)
  integer, public :: aps_logUnit(0:tem_last_lu)

contains

  ! ***************************************************************************!
  !> This routine load logging table and debug table from apes config file
  subroutine aps_load_logging(conf, rank)
    !--------------------------------------------------------------------------!
    !> lua state
    type(flu_State), intent(inout) :: conf
    !> local rank
    integer, intent(in) :: rank
    !--------------------------------------------------------------------------!
    ! load and initialize logUnit
    call tem_logging_load_primary(conf = conf, &
      &                           rank = rank  )
    aps_logUnit = logUnit

    ! load and initialize debug unit
    call tem_debug_load_main(conf = conf, &
      &                      rank = rank  )
    aps_dbgUnit = dbgUnit

  end subroutine aps_load_logging
  ! ***************************************************************************!

end module aps_logging_module
! *****************************************************************************!
