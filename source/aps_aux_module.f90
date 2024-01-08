! Copyright (c) 2013-2014 Kannan Masilamani <kannan.masilamani@dlr.de>
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
!> Some auxilary functionalities.
module aps_aux_module
  ! include treelm modules
  use env_module,             only: rk
  use tem_aux_module,         only: tem_print_execInfo, utc_date_string
  use tem_logging_module,     only: logUnit
  use tem_solveHead_module,   only: tem_solveHead_type

  implicit none

  private

  public :: aps_banner


contains


  !****************************************************************************!
  !> Prominently let the user now, what he actually is running right now.
  !!
  subroutine aps_banner( solver )
    !> solver definition
    type(tem_solveHead_type), intent(in) :: solver
    !---------------------------------------------------------------------------
    character(len=26) :: dat_string
    !---------------------------------------------------------------------------

    write(logUnit(1),*)"                               "
    write(logUnit(1),*)"     _    ____  _____ ____     "
    write(logUnit(1),*)"    / \  |  _ \| ____/ ___|    "
    write(logUnit(1),*)"   / _ \ | |_) |  _| \___ \    "
    write(logUnit(1),*)"  / ___ \|  __/| |___ ___) |   "
    write(logUnit(1),*)" /_/   \_\_|   |_____|____"    &
      &              //trim(solver%version)
    write(logUnit(1),*)"                               "
    write(logUnit(1),*)" (C) 2013 University of Siegen "
    write(logUnit(1),*)"                               "
    ! Write the information about the executable, gathered at build time to
    ! the screen.
    call tem_print_execInfo()
    write(logUnit(1),*)"                               "
    dat_string = utc_date_string()
    write(logUnit(1),*)"Run at: "//dat_string
    write(logUnit(1),*)"                               "
    write(logUnit(1),*)"                               "

  end subroutine aps_banner
  !****************************************************************************!



end module aps_aux_module
!******************************************************************************!
