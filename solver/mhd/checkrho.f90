!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! This subroutine ensures that the density does not go below rho_atm
! and replace the grids with atmospheric density (tempearture and 
! chemical composition and so on) if found
! Written by Leung Shing Chi in 2016
! The subroutine do all the check automatically
! Notice that this subroutines also check the size of 
! the hydro array, and reduced the simulation grid-number
! to boost the calculation,
! i.e. (1:length_step_r_part, 1:length_step_z_part).
! For full array extension, switch the checkstep_flag = 0
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

SUBROUTINE CHECKRHO
USE DEFINITION
IMPLICIT NONE

! Dummy variables
INTEGER :: i, j, k, l

! Threshold for atmosphere density
REAL*8 :: rho_min1, rho_min2, factor, diff

! Temporal variables !
INTEGER :: x_grid1, y_grid1, z_grid1
INTEGER :: x_grid2, y_grid2, z_grid2

! Check timing with or without openmp
INTEGER :: time_start, time_end
INTEGER :: cr
REAL*8 :: rate
CALL system_clock(count_rate=cr)
rate = REAL(cr)

CALL system_clock(time_start)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Now do the normal matter

! Check the density of normal matter, assign floor for hydrodynamic variables !
IF(custom_floor) THEN

  ! custom variable floor !
  CALL CUSTOMFLOOR

ELSE

  !$OMP PARALLEL DO PRIVATE(diff, factor) COLLAPSE(3) SCHEDULE(STATIC)
  !$ACC PARALLEL LOOP GANG WORKER VECTOR COLLAPSE(3) DEFAULT(PRESENT) PRIVATE(diff, factor)
  DO l = nz_min_2, nz_part_2
    DO k = ny_min_2, ny_part_2
      DO j = nx_min_2, nx_part_2
        rho_min2 = 1.1D0 * prim2_a(irho2)
        diff = prim2(irho2,j,k,l) - rho_min2
        factor = MAX(SIGN(1.0D0, diff), 0.0D0)
        prim2(irho2:ivel2_z,j,k,l) = factor*prim2(irho2:ivel2_z,j,k,l) + (1.0D0 - factor)*prim2_a(irho2:ivel2_z)
        epsilon2(j,k,l) = factor*epsilon2(j,k,l) + (1.0D0 - factor)*eps2_a
      END DO
    END DO
  END DO
  !$ACC END PARALLEL
  !$OMP END PARALLEL DO
  
END IF

! Make sure the ghost cell knows the udpate
CALL BOUNDARY1D_NM (epsilon2, part, even, even, even, even, even, even)
CALL BOUNDARYP_NM  

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

CALL system_clock(time_end)
#ifdef DEBUG
WRITE(*,*) 'checkrho = ', REAL(time_end - time_start) / rate
#endif

END SUBROUTINE CHECKRHO