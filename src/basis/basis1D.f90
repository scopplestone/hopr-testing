!============================================================================================================ xX =================
!        _____     _____    _______________    _______________   _______________            .xXXXXXXXx.       X
!       /    /)   /    /)  /    _____     /)  /    _____     /) /    _____     /)        .XXXXXXXXXXXXXXx  .XXXXx
!      /    //   /    //  /    /)___/    //  /    /)___/    // /    /)___/    //       .XXXXXXXXXXXXXXXXXXXXXXXXXx
!     /    //___/    //  /    //   /    //  /    //___/    // /    //___/    //      .XXXXXXXXXXXXXXXXXXXXXXX`
!    /    _____     //  /    //   /    //  /    __________// /    __      __//      .XX``XXXXXXXXXXXXXXXXX`
!   /    /)___/    //  /    //   /    //  /    /)_________) /    /)_|    |__)      XX`   `XXXXX`     .X`
!  /    //   /    //  /    //___/    //  /    //           /    //  |    |_       XX      XXX`      .`
! /____//   /____//  /______________//  /____//           /____//   |_____/)    ,X`      XXX`
! )____)    )____)   )______________)   )____)            )____)    )_____)   ,xX`     .XX`
!                                                                           xxX`      XXx
! Copyright (C) 2017 Claus-Dieter Munz <munz@iag.uni-stuttgart.de>
! This file is part of HOPR, a software for the generation of high-order meshes.
!
! HOPR is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
! as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
!
! HOPR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
! of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License along with HOPR. If not, see <http://www.gnu.org/licenses/>.
!=================================================================================================================================
#include "hopr.h"
MODULE MOD_Basis1D
!===================================================================================================================================
! ?
!===================================================================================================================================
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
PRIVATE
!-----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES 
!-----------------------------------------------------------------------------------------------------------------------------------
! Private Part ---------------------------------------------------------------------------------------------------------------------
! Public Part ----------------------------------------------------------------------------------------------------------------------
INTERFACE Vandermonde1D
  MODULE PROCEDURE Vandermonde1D
END INTERFACE

INTERFACE GradVandermonde1D
  MODULE PROCEDURE GradVandermonde1D
END INTERFACE

INTERFACE BuildLegendreVdm
   MODULE PROCEDURE BuildLegendreVdm
END INTERFACE

INTERFACE JacobiP
  MODULE PROCEDURE JacobiP
END INTERFACE

INTERFACE GradJacobiP
  MODULE PROCEDURE GradJacobiP
END INTERFACE

INTERFACE LegendreGaussNodesAndWeights
   MODULE PROCEDURE LegendreGaussNodesAndWeights
END INTERFACE

INTERFACE LegGaussLobNodesAndWeights
   MODULE PROCEDURE LegGaussLobNodesAndWeights
END INTERFACE

INTERFACE ChebyshevGaussNodesAndWeights
   MODULE PROCEDURE ChebyshevGaussNodesAndWeights
END INTERFACE

INTERFACE ChebyGaussLobNodesAndWeights
   MODULE PROCEDURE ChebyGaussLobNodesAndWeights
END INTERFACE

INTERFACE PolynomialDerivativeMatrix
   MODULE PROCEDURE PolynomialDerivativeMatrix
END INTERFACE

INTERFACE BarycentricWeights 
   MODULE PROCEDURE BarycentricWeights 
END INTERFACE

INTERFACE InitializeVandermonde 
   MODULE PROCEDURE InitializeVandermonde
END INTERFACE

INTERFACE ALMOSTEQUAL
   MODULE PROCEDURE ALMOSTEQUAL
END INTERFACE

INTERFACE GetMortarVandermonde
   MODULE PROCEDURE GetMortarVandermonde
END INTERFACE



PUBLIC:: INV
PUBLIC:: BuildLegendreVdm
PUBLIC:: Vandermonde1D
PUBLIC:: GradVandermonde1D
PUBLIC:: JacobiP
PUBLIC:: GradJacobiP
PUBLIC:: LegendreGaussNodesAndWeights
PUBLIC:: LegGaussLobNodesAndWeights
PUBLIC:: ChebyshevGaussNodesAndWeights
PUBLIC:: ChebyGaussLobNodesAndWeights
PUBLIC:: PolynomialDerivativeMatrix
PUBLIC:: BarycentricWeights
PUBLIC:: InitializeVandermonde
PUBLIC:: GetMortarVandermonde
PUBLIC:: ALMOSTEQUAL
!===================================================================================================================================

CONTAINS
SUBROUTINE  JacobiP(nNodes,x,alpha,beta,Deg,P)
!===================================================================================================================================
! evaluates the Nth Jacobi-polynomial at position xi, Algorithm in book of hesthaven and found in his matlab code
! The Jacobi Polynomials P_i^{(alpha,beta)}(x) are orthonormal with respect to the weighting function in the interval [-1,1]
! w(x)=(1-x)^alpha(1+x)^beta
! \int_{-1}^{1} P_i^{(alpha,beta)}(x) P_j^{(alpha,beta)}(x) w(x) dx = \delta_{ij}
!===================================================================================================================================
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER, INTENT(IN):: nNodes  ! ?
REAL,INTENT(IN)    :: x(nNodes)  ! evaluation positions
INTEGER,INTENT(IN) :: alpha,beta ! coefficients of the weighting function w(x)=(1-x)^alpha(1+x)^beta
INTEGER,INTENT(IN) :: Deg          ! polynomial DEGREE of Jacobi Polynomial
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)   :: P(nNodes)      ! value of Jacobi polynomial N at all positions x
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
REAL,DIMENSION(nNodes) :: P_0,P_1  ! ?
REAL                   :: gamma0,gamma1,gammaf(1:alpha+beta+2)  ! ?
REAL                   :: aold,anew,bnew  ! ?
REAL                   :: ri,ralpha,rbeta       !temp
INTEGER                :: i,h1,h2  ! ?
!===================================================================================================================================
!fill gamma function, only for integer values, replace by real gamma function, if needed. Intrinsic gamma function only with GNU 
ralpha=REAL(alpha)
rbeta=REAL(beta)
gammaf(1:2)=1
DO i=3,alpha+beta+2
  gammaf(i)=(i-1)*gammaf(i-1)
END DO
gamma0=2.**(alpha+beta+1)/(ralpha+rbeta+1.)*gammaf(alpha+1)*gammaf(beta+1)/gammaf(alpha+beta+1)
P_0(:)=1./SQRT(gamma0)
IF(Deg.EQ.0) THEN
  P=P_0
  RETURN
END IF
gamma1=(ralpha+1.)*(rbeta+1.)/(ralpha+rbeta+3.)*gamma0
P_1(:)=0.5*((ralpha+rbeta+2.)*x(:) + (ralpha-rbeta))/SQRT(gamma1)
IF(Deg.EQ.1) THEN
  P(:)=P_1(:)
  RETURN
END IF
! a_i= 2/(2+aplha+beta)*sqrt( ( i*(i+alpha+beta)*(i+alpha)*(i+beta) ) / ( (2i+alpha+beta-1)(2i+alpha+beta+1) ) )
! b_i= (alpha**2-beta**2)/( (2i+alpha+beta)(2i+alpha+beta+2) )
! a_i for i=1
h1=alpha+beta
h2=beta*beta-alpha*alpha
aold= 2./REAL(2.+h1)*SQRT(REAL((1.+alpha)*(1+beta))/REAL(h1+3))
!start recurrence
DO i=2,Deg
  ri=REAL(i)
  h1= h1+2
  !a_i
  anew=2./REAL(h1+2)*SQRT(REAL(i*(i+alpha+beta)*(i+alpha)*(i+beta)) / REAL((h1+1)*(h1+3)) )
  !b_i
  bnew=REAL(h2)/REAL(h1*(h1+2))
  ! recurrence P(i)= ((x-b_i) P(i-1) - a_(i-1) P(i-2) )/a_i
  P(:)=((x(:)-bnew)*P_1(:)-aold*P_0(:))/anew
  P_0=P_1
  P_1=P
  aold=anew
END DO
END SUBROUTINE JacobiP


SUBROUTINE  GradJacobiP(nNodes,x,alpha,beta,Deg,GradP)
!===================================================================================================================================
! evaluates the first derivative of the Nth Jacobi-polynomial at position xi, 
! Algorithm in book of hesthaven and found in his matlab code
! The Jacobi Polynomials P_i^{(alpha,beta)}(x) are orthonormal with respect to the weighting function in the interval [-1,1]
! w(x)=(1-x)^alpha(1+x)^beta
! \int_{-1}^{1} P_i^{(alpha,beta)}(x) P_j^{(alpha,beta)}(x) w(x) dx = \delta_{ij}
!===================================================================================================================================
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER, INTENT(IN):: nNodes  ! ?
REAL,INTENT(IN)    :: x(nNodes)  ! evaluation positions
INTEGER,INTENT(IN) :: alpha,beta ! coefficients of the weighting function w(x)=(1-x)^alpha(1+x)^beta
INTEGER,INTENT(IN) :: Deg        ! polynomial DEGREE of Jacobi Polynomial
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)   :: GradP(nNodes)      ! value of the gradient of Jacobi polynomial N at all positions x
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
REAL,DIMENSION(nNodes) :: P  ! ?
!===================================================================================================================================
IF(Deg.EQ.0)THEN
  gradP=0.
  RETURN
END IF
CALL JacobiP(nNodes,x,alpha+1,beta+1, Deg-1,P)
gradP=SQRT(REAL(Deg*(Deg+alpha+beta+1)))*P
END SUBROUTINE GradJacobiP


SUBROUTINE  JacobiP_all(nNodes,x,alpha,beta,Deg,P)
!===================================================================================================================================
! evaluates the Nth Jacobi-polynomial at position xi, Algorithm in book of hesthaven and found in his matlab code
! The Jacobi Polynomials P_i^{(alpha,beta)}(x) are orthonormal with respect to the weighting function in the interval [-1,1]
! w(x)=(1-x)^alpha(1+x)^beta
! \int_{-1}^{1} P_i^{(alpha,beta)}(x) P_j^{(alpha,beta)}(x) w(x) dx = \delta_{ij}
!===================================================================================================================================
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER, INTENT(IN):: nNodes  ! ?
REAL,INTENT(IN)    :: x(nNodes)  ! evaluation positions
INTEGER,INTENT(IN) :: alpha,beta ! coefficients of the weighting function w(x)=(1-x)^alpha(1+x)^beta
INTEGER,INTENT(IN) :: Deg          ! polynomial DEGREE of Jacobi Polynomial
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)   :: P(nNodes,0:Deg)      ! value of Jacobi polynomial N at all positions x
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
REAL                   :: gamma0,gamma1,gammaf(1:alpha+beta+2)  ! ?
REAL                   :: aold,anew,bnew  ! ?
REAL                   :: ri,ralpha,rbeta       !temp
INTEGER                :: i,h1,h2  ! ?
!===================================================================================================================================
!fill gamma function, only for integer values, replace by real gamma function, if needed. Intrinsic gamma function only with GNU 
ralpha=REAL(alpha)
rbeta=REAL(beta)
gammaf(1:2)=1
DO i=3,alpha+beta+2
  gammaf(i)=(i-1)*gammaf(i-1)
END DO
gamma0=2.**(alpha+beta+1)/(ralpha+rbeta+1.)*gammaf(alpha+1)*gammaf(beta+1)/gammaf(alpha+beta+1)
P(:,0)=1./SQRT(gamma0)
IF(Deg.EQ.0) THEN
  RETURN
END IF
gamma1=(ralpha+1.)*(rbeta+1.)/(ralpha+rbeta+3.)*gamma0
P(:,1)=0.5*((ralpha+rbeta+2.)*x(:) + (ralpha-rbeta))/SQRT(gamma1)
IF(Deg.EQ.1) THEN
  RETURN
END IF
! a_i= 2/(2+aplha+beta)*sqrt( ( i*(i+alpha+beta)*(i+alpha)*(i+beta) ) / ( (2i+alpha+beta-1)(2i+alpha+beta+1) ) )
! b_i= (alpha**2-beta**2)/( (2i+alpha+beta)(2i+alpha+beta+2) )
! a_i for i=1
h1=alpha+beta
h2=beta*beta-alpha*alpha
aold= 2./REAL(2.+h1)*SQRT(REAL((1.+alpha)*(1+beta))/REAL(h1+3))
!start recurrence
DO i=2,Deg
  ri=REAL(i)
  h1= h1+2
  !a_i
  anew=2./REAL(h1+2)*SQRT(REAL(i*(i+alpha+beta)*(i+alpha)*(i+beta)) / REAL((h1+1)*(h1+3)) )
  !b_i
  bnew=REAL(h2)/REAL(h1*(h1+2))
  ! recurrence P(i)= ((x-b_i) P(i-1) - a_(i-1) P(i-2) )/a_i
  P(:,i)=((x(:)-bnew)*P(:,i-1)-aold*P(:,i-2))/anew
  aold=anew
END DO
END SUBROUTINE JacobiP_all


SUBROUTINE  GradJacobiP_all(nNodes,x,alpha,beta,Deg,GradP)
!===================================================================================================================================
! evaluates the first derivative of the Nth Jacobi-polynomial at position xi, 
! Algorithm in book of hesthaven and found in his matlab code
! The Jacobi Polynomials P_i^{(alpha,beta)}(x) are orthonormal with respect to the weighting function in the interval [-1,1]
! w(x)=(1-x)^alpha(1+x)^beta
! \int_{-1}^{1} P_i^{(alpha,beta)}(x) P_j^{(alpha,beta)}(x) w(x) dx = \delta_{ij}
!===================================================================================================================================
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER, INTENT(IN):: nNodes  ! ?
REAL,INTENT(IN)    :: x(nNodes)  ! evaluation positions
INTEGER,INTENT(IN) :: alpha,beta ! coefficients of the weighting function w(x)=(1-x)^alpha(1+x)^beta
INTEGER,INTENT(IN) :: Deg        ! polynomial DEGREE of Jacobi Polynomial
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)   :: GradP(nNodes,0:Deg)      ! value of the gradient of Jacobi polynomial N at all positions x
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
REAL,DIMENSION(nNodes,0:Deg) :: P  ! ?
INTEGER                      :: i  ! ?
!===================================================================================================================================
gradP=0.
IF(Deg.EQ.0)THEN
  RETURN
END IF
CALL JacobiP_all(nNodes,x,alpha+1,beta+1, Deg-1,P(:,1:Deg))
DO i=1,Deg
  gradP(:,i)=SQRT(REAL(i*(i+alpha+beta+1)))*P(:,i)
END DO
END SUBROUTINE GradJacobiP_all


SUBROUTINE Vandermonde1D(nNodes1D,Deg,r1D,VdM1D)
!===================================================================================================================================
! computes on a given set of nodes and a given polynomial degree
! the Vandermonde Matrix to 1D orthonormal Legendre polyonomials in reference space [-1,1]
!===================================================================================================================================
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER, INTENT(IN)          :: nNodes1D,Deg  ! ?
REAL,INTENT(IN)              :: r1D(nNodes1D)   ! node positions in reference space [-1,1]
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)             :: VdM1D(0:nNodes1D-1,0:Deg)   ! ?
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
!===================================================================================================================================
CALL JacobiP_all(nNodes1D,r1D, 0, 0, Deg,Vdm1D(:,:))
END SUBROUTINE Vandermonde1D


SUBROUTINE GradVandermonde1D(nNodes1D,Deg,r1D,gradVdM1D)
!===================================================================================================================================
! computes on a given set of nodes and a given polynomial degree
! the Gradient Vandermonde Matrix to 1D orthonormal Legendre polyonomials in reference space [-1,1]
!===================================================================================================================================
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER, INTENT(IN)          :: nNodes1D,Deg  ! ?
REAL,INTENT(IN)              :: r1D(nNodes1D)   ! node positions in reference space [-1,1]
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)             :: gradVdM1D(0:nNodes1D-1,0:Deg)   ! ?
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
!===================================================================================================================================
CALL GradJacobiP_all(nNodes1D,r1D, 0, 0,Deg,gradVdM1D(:,:))
END SUBROUTINE GradVandermonde1D


!==================================================================================================================================
!> Computes matrix inverse using lapack
!==================================================================================================================================
FUNCTION INV(A) RESULT(AINV)
! MODULES
USE MOD_Globals, ONLY: abort
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
REAL,INTENT(IN)  :: A(:,:)                      !< input matrix
REAL             :: AINV(SIZE(A,1),SIZE(A,2))   !< result: inverse of A
!----------------------------------------------------------------------------------------------------------------------------------
! External procedures defined in LAPACK
EXTERNAL DGETRF
EXTERNAL DGETRI
! LOCAL VARIABLES
REAL    :: work(SIZE(A,1))  ! work array for lapack
INTEGER :: ipiv(SIZE(A,1))  ! pivot indices
INTEGER :: n,info
!==================================================================================================================================
! Store A in Ainv to prevent it from being overwritten by LAPACK
Ainv = A
n = size(A,1)

! DGETRF computes an LU factorization of a general M-by-N matrix A
! using partial pivoting with row interchanges.
CALL DGETRF(n, n, Ainv, n, ipiv, info)

IF(info.NE.0)THEN
   CALL abort(__STAMP__,'INV(A): Matrix is numerically singular! INFO = ',IntInfoOpt=INFO)
END IF

! DGETRI computes the inverse of a matrix using the LU factorization
! computed by DGETRF.
CALL DGETRI(n, Ainv, n, ipiv, work, n, info)

IF(info.NE.0)THEN
   CALL abort(__STAMP__,'INV(A): ratrix inversion failed! INFO = ',IntInfoOpt=INFO)
END IF
END FUNCTION INV

!==================================================================================================================================
!> Build a 1D Vandermonde matrix from an orthonormal Legendre basis to a nodal basis and reverse
!==================================================================================================================================
SUBROUTINE buildLegendreVdm(N_In,xi_In,Vdm_Leg,sVdm_Leg)
! MODULES
USE MOD_Globals,ONLY:abort
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
INTEGER,INTENT(IN) :: N_In                    !< input polynomial degree
REAL,INTENT(IN)    :: xi_In(0:N_In)           !< nodal positions [-1,1]
REAL,INTENT(OUT)   ::  Vdm_Leg(0:N_In,0:N_In) !< Vandermonde from Lengedre to nodal basis
REAL,INTENT(OUT)   :: sVdm_Leg(0:N_In,0:N_In) !< Vandermonde from nodal basis to Legendre
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER            :: i,j
REAL               :: dummy
!REAL               :: wBary_Loc(0:N_In)
!REAL               :: xGauss(0:N_In),wGauss(0:N_In)
!==================================================================================================================================
! Alternative to matrix inversion: Compute inverse Vandermonde directly
! Direct inversion seems to be more accurate

!CALL BarycentricWeights(N_In,xi_in,wBary_loc)
!! Compute first the inverse (by projection)
!CALL LegendreGaussNodesAndWeights(N_In,xGauss,wGauss)
!!Vandermonde on xGauss
!DO i=0,N_In
!  DO j=0,N_In
!    CALL LegendrePolynomialAndDerivative(j,xGauss(i),Vdm_Leg(i,j),dummy)
!  END DO !i
!END DO !j
!Vdm_Leg=TRANSPOSE(Vdm_Leg)
!DO j=0,N_In
!  Vdm_Leg(:,j)=Vdm_Leg(:,j)*wGauss(j)
!END DO
!!evaluate nodal basis (depends on NodeType, for Gauss: unity matrix)
!CALL InitializeVandermonde(N_In,N_In,wBary_Loc,xi_In,xGauss,sVdm_Leg)
!sVdm_Leg=MATMUL(Vdm_Leg,sVdm_Leg)

!compute the Vandermonde on xGP (Depends on NodeType)
DO i=0,N_In; DO j=0,N_In
  CALL LegendrePolynomialAndDerivative(j,xi_In(i),Vdm_Leg(i,j),dummy)
END DO; END DO !j
sVdm_Leg=INV(Vdm_Leg)
!check (Vdm_Leg)^(-1)*Vdm_Leg := I
dummy=ABS(SUM(ABS(MATMUL(sVdm_Leg,Vdm_Leg)))/(N_In+1.)-1.)
IF(dummy.GT.10.*PP_RealTolerance) CALL abort(__STAMP__,&
                                         'problems in MODAL<->NODAL Vandermonde ',999,dummy)
END SUBROUTINE buildLegendreVdm



SUBROUTINE ChebyshevGaussNodesAndWeights(N_in,xGP,wGP)
!===================================================================================================================================
! algorithm 27, Kopriva
!===================================================================================================================================
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
!input parameters
INTEGER,INTENT(IN)        :: N_in       ! polynomial degree, (N_in+1) CLpoints 
!-----------------------------------------------------------------------------------------------------------------------------------
!output parameters
REAL,INTENT(OUT)          :: xGP(0:N_in)  ! Gausspoint positions for the reference interval [-1,1]
REAL,INTENT(OUT),OPTIONAL :: wGP(0:N_in)  ! Gausspoint weights
!-----------------------------------------------------------------------------------------------------------------------------------
!local variables
INTEGER                   :: iGP
!===================================================================================================================================
DO iGP=0,N_in
  xGP(iGP)=-cos((2*iGP+1)/(2*REAL(N_in)+2)*ACOS(-1.))
END DO
IF(PRESENT(wGP))THEN
  DO iGP=0,N_in
    wGP(iGP)=ACOS(-1.)/REAL(N_in+1)
  END DO
END IF
END SUBROUTINE ChebyshevGaussNodesAndWeights



SUBROUTINE ChebyGaussLobNodesAndWeights(N_in,xGP,wGP)
!===================================================================================================================================
! algorithm 27, Kopriva
!===================================================================================================================================
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN)        :: N_in       ! polynomial degree, (N_in+1) CLpoints 
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)          :: xGP(0:N_in)  ! Gausspoint positions for the reference interval [-1,1]
REAL,INTENT(OUT),OPTIONAL :: wGP(0:N_in)  ! Gausspoint weights
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
INTEGER            :: iGP  ! ?
!===================================================================================================================================
DO iGP=0,N_in
  xGP(iGP)=-COS(iGP/REAL(N_in)*ACOS(-1.))
END DO
IF(PRESENT(wGP))THEN
  DO iGP=0,N_in
    wGP(iGP)=ACOS(-1.)/REAL(N_in)
  END DO
  wGP(0)=wGP(0)*0.5
  wGP(N_in)=wGP(N_in)*0.5
END IF
END SUBROUTINE ChebyGaussLobNodesAndWeights



SUBROUTINE LegendreGaussNodesAndWeights(N_in,xGP,wGP)
!===================================================================================================================================
! algorithm 23, Kopriva
! starting with Chebychev point positions, a Newton method is used to find the roots 
! of the Legendre Polynomial L_(N_in+1), which are the positions of Gausspoints
! uses LegendrePolynomialAndDerivative subroutine
!===================================================================================================================================
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
!input parameters
INTEGER,INTENT(IN)        :: N_in              ! polynomial degree, (N_in+1) Gausspoints 
!-----------------------------------------------------------------------------------------------------------------------------------
!output parameters
REAL,INTENT(OUT)          :: xGP(0:N_in)       ! Gausspoint positions for the reference interval [-1,1]
REAL,INTENT(OUT),OPTIONAL :: wGP(0:N_in)       ! Gausspoint weights
!-----------------------------------------------------------------------------------------------------------------------------------
!local variables
INTEGER                   :: nIter = 10     ! max. number of newton iterations
REAL                      :: Tol   = 1.E-15 ! tolerance for Newton iteration
INTEGER                   :: iGP,iter
REAL                      :: L_Np1,Lder_Np1 ! L_{N_in+1},Lder_{N_in+1}
REAL                      :: dx             ! Newton step
REAL                      :: cheb_tmp       ! temporary variable for evaluation of chebychev node positions
!===================================================================================================================================
IF(N_in .EQ. 0) THEN
  xGP=0.
  IF(PRESENT(wGP))wGP=2.
  RETURN
ELSEIF(N_in.EQ.1)THEN
  xGP(0)=-sqrt(1./3.)
  xGP(N_in)=-xGP(0)
  IF(PRESENT(wGP))wGP=1.
  RETURN
ELSE ! N_in>1
  cheb_tmp=2.*atan(1.)/REAL(N_in+1) ! pi/(2N+2)
  DO iGP=0,(N_in+1)/2-1 !since points are symmetric, only left side is computed
    xGP(iGP)=-cos(cheb_tmp*REAL(2*iGP+1)) !initial guess
    ! Newton iteration
    DO iter=0,nIter
      CALL LegendrePolynomialAndDerivative(N_in+1,xGP(iGP),L_Np1,Lder_Np1)
      dx=-L_Np1/Lder_Np1
      xGP(iGP)=xGP(iGP)+dx
      IF(abs(dx).LT.Tol*abs(xGP(iGP))) EXIT
    END DO ! iter
    IF(iter.GT.nIter) THEN
      WRITE(*,*) 'maximum iteration steps >10 in Newton iteration for Legendre Gausspoint'
      xGP(iGP)=-cos(cheb_tmp*REAL(2*iGP+1)) !initial guess
      ! Newton iteration
      DO iter=0,nIter
        WRITE(*,*)iter,xGP(iGP)    !DEBUG  
        CALL LegendrePolynomialAndDerivative(N_in+1,xGP(iGP),L_Np1,Lder_Np1)
        dx=-L_Np1/Lder_Np1
        xGP(iGP)=xGP(iGP)+dx
        IF(abs(dx).LT.Tol*abs(xGP(iGP))) EXIT
      END DO !iter
      STOP 
    END IF ! (iter.GT.nIter)
    CALL LegendrePolynomialAndDerivative(N_in+1,xGP(iGP),L_Np1,Lder_Np1)
    xGP(N_in-iGP)=-xGP(iGP)
    IF(PRESENT(wGP))THEN
      !wGP(iGP)=2./((1.-xGP(iGP)*xGP(iGP))*Lder_Np1*Lder_Np1) !if Legendre not normalized
      wGP(iGP)=(2.*N_in+3)/((1.-xGP(iGP)*xGP(iGP))*Lder_Np1*Lder_Np1)
      wGP(N_in-iGP)=wGP(iGP)
    END IF
  END DO !iGP
END IF ! N_in
IF(mod(N_in,2) .EQ. 0) THEN
  xGP(N_in/2)=0.
  CALL LegendrePolynomialAndDerivative(N_in+1,xGP(N_in/2),L_Np1,Lder_Np1)
  !IF(PRESENT(wGP))wGP(N_in/2)=2./(Lder_Np1*Lder_Np1) !if Legendre not normalized
  IF(PRESENT(wGP))wGP(N_in/2)=(2.*N_in+3)/(Lder_Np1*Lder_Np1)
END IF ! (mod(N_in,2) .EQ. 0)
END SUBROUTINE LegendreGaussNodesAndWeights



SUBROUTINE qAndLEvaluation(N_in,x,q,qder,L)
!===================================================================================================================================
! algorithm 24, Kopriva
! evaluate the polynomial q=L_{N_in+1}-L_{N_in-1} and its derivative at position x[-1,1] 
! recursive algorithm using the N_in-1 N_in-2 Legendre polynomials
!===================================================================================================================================
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
!input parameters
INTEGER,INTENT(IN) :: N_in                               ! polynomial degree
REAL,INTENT(IN)    :: x                               ! coordinate value in the interval [-1,1]
!-----------------------------------------------------------------------------------------------------------------------------------
!output parameters
REAL,INTENT(OUT)   :: L,q,qder                        ! L_N(xi), d/dxi L_N(xi)
!-----------------------------------------------------------------------------------------------------------------------------------
!local variables
INTEGER            :: iLegendre
REAL               :: L_Nm1,L_Nm2                     ! L_{N_in-2},L_{N_in-1}
REAL               :: Lder,Lder_Nm1,Lder_Nm2          ! Lder_{N_in-2},Lder_{N_in-1}
!===================================================================================================================================
L_Nm2=1.
L_Nm1=x
Lder_Nm2=0.
Lder_Nm1=1.
DO iLegendre=2,N_in
  L=(REAL(2*iLegendre-1)*x*L_Nm1 - REAL(iLegendre-1)*L_Nm2)/REAL(iLegendre)
  Lder=Lder_Nm2 + REAL(2*iLegendre-1)*L_Nm1
  L_Nm2=L_Nm1
  L_Nm1=L
  Lder_Nm2=Lder_Nm1
  Lder_Nm1=Lder
END DO ! iLegendre
q=REAL(2*N_in+1)/REAL(N_in+1)*(x*L -L_Nm2) !L_{N_in+1}-L_{N_in-1} !L_Nm2 is L_Nm1, L_Nm1 was overwritten!
qder= REAL(2*N_in+1)*L             !Lder_{N_in+1}-Lder_{N_in-1} 
END SUBROUTINE qAndLEvaluation



SUBROUTINE LegGaussLobNodesAndWeights(N_in,xGP,wGP)
!===================================================================================================================================
! algorithm 25, Kopriva
! starting with initial guess by Parter Relation, a Newton method is used to find the roots 
! of the Legendre Polynomial Lder_(N_in), which are the positions of Gausspoints
! uses qAndLEvaluation subroutine
!===================================================================================================================================
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
!input parameters
INTEGER,INTENT(IN)        :: N_in                ! polynomial degree (N_in+1) Gausspoints 
!-----------------------------------------------------------------------------------------------------------------------------------
!output parameters
REAL,INTENT(OUT)          :: xGP(0:N_in)         ! Gausspoint positions for the reference interval [-1,1]
REAL,INTENT(OUT),OPTIONAL :: wGP(0:N_in)         ! Gausspoint weights
!-----------------------------------------------------------------------------------------------------------------------------------
!local variables
INTEGER                   :: nIter = 10       ! max. number of newton iterations
REAL                      :: Tol   = 1.E-15   !tolerance for Newton iteration
INTEGER                   :: iGP,iter
REAL                      :: q,qder,L         !q=L_{N_in+1}-L_{N_in-1},qder is derivative, L=L_{N_in}
REAL                      :: dx               !Newton step
REAL                      :: pi,cont1,cont2   !temporary variable for evaluation of parter nodes positions
!===================================================================================================================================
xGP(0)=-1.
xGP(N_in)= 1.
IF(PRESENT(wGP))THEN
  wGP(0)= 2./REAL(N_in*(N_in+1))
  wGP(N_in)=wGP(0)
END IF
IF(N_in.GT.1)THEN
  pi=4.*atan(1.)
  cont1=pi/REAL(N_in) ! pi/N_in
  cont2=3./(REAL(8*N_in)*pi) ! 3/(8*N_in*pi)
  DO iGP=1,(N_in+1)/2-1 !since points are symmetric, only left side is computed
    xGP(iGP)=-cos(cont1*(REAL(iGP)+0.25)-cont2/(REAL(iGP)+0.25)) !initial guess
    ! Newton iteration
    DO iter=0,nIter
      CALL qAndLEvaluation(N_in,xGP(iGP),q,qder,L)
      dx=-q/qder
      xGP(iGP)=xGP(iGP)+dx
      IF(abs(dx).LT.Tol*abs(xGP(iGP))) EXIT
    END DO ! iter
    IF(iter.GT.nIter) THEN
      WRITE(*,*) 'maximum iteration steps >10 in Newton iteration for LGL point:'
      xGP(iGP)=-cos(cont1*(REAL(iGP)+0.25)-cont2/(REAL(iGP)+0.25)) !initial guess
      ! Newton iteration
      DO iter=0,nIter
        WRITE(*,*)'iter,x^i',iter,xGP(iGP)     !DEBUG 
        CALL qAndLEvaluation(N_in,xGP(iGP),q,qder,L)
        dx=-q/qder
        xGP(iGP)=xGP(iGP)+dx
        IF(abs(dx).LT.Tol*abs(xGP(iGP))) EXIT
      END DO ! iter
      STOP 
    END IF ! (iter.GT.nIter)
    CALL qAndLEvaluation(N_in,xGP(iGP),q,qder,L)
    xGP(N_in-iGP)=-xGP(iGP)
    IF(PRESENT(wGP))THEN
      wGP(iGP)=wGP(0)/(L*L)
      wGP(N_in-iGP)=wGP(iGP)
    END IF
  END DO ! iGP
END IF !(N_in.GT.1)
IF(mod(N_in,2) .EQ. 0) THEN
  xGP(N_in/2)=0.
  CALL qAndLEvaluation(N_in,xGP(N_in/2),q,qder,L)
  IF(PRESENT(wGP))wGP(N_in/2)=wGP(0)/(L*L)
END IF ! (mod(N_in,2) .EQ. 0)
END SUBROUTINE LegGaussLobNodesAndWeights


SUBROUTINE BarycentricWeights(N_in,xGP,wBary)
!===================================================================================================================================
! algorithm 30, Kopriva
!===================================================================================================================================
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN) :: N_in               ! polynomial degree 
REAL,INTENT(IN)    :: xGP(0:N_in)        ! Gausspoint positions for the reference interval [-1,1]
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)   :: wBary(0:N_in)      ! barycentric weights
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
INTEGER            :: iGP,jGP  ! ?
!===================================================================================================================================
wBary(:)=1.
DO iGP=1,N_in
  DO jGP=0,iGP-1
    wBary(jGP)=wBary(jGP)*(xGP(jGP)-xGP(iGP))
    wBary(iGP)=wBary(iGP)*(xGP(iGP)-xGP(jGP))
  END DO ! jGP
END DO ! iGP
wBary(:)=1./wBary(:)
END SUBROUTINE BarycentricWeights


SUBROUTINE PolynomialDerivativeMatrix(N_in,xGP,D)
!===================================================================================================================================
! algorithm 37, Kopriva
!===================================================================================================================================
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN) :: N_in              ! polynomial degree
REAL,INTENT(IN)    :: xGP(0:N_in)       ! Gausspoint positions for the reference interval [-1,1]
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)   :: D(0:N_in,0:N_in)     ! differentiation Matrix
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
INTEGER            :: iGP,iLagrange  ! ?
REAL               :: wBary(0:N_in)   ! ?
!===================================================================================================================================
CALL BarycentricWeights(N_in,xGP,wBary)
D(:,:)=0.
DO iLagrange=0,N_in
  DO iGP=0,N_in
    IF(iLagrange.NE.iGP)THEN
      D(iGP,iLagrange)=wBary(iLagrange)/(wBary(iGP)*(xGP(iGP)-xGP(iLagrange)))
      D(iGP,iGP)=D(iGP,iGP)-D(iGP,iLagrange)
    END IF ! (iLagrange.NE.iGP)
  END DO ! iGP
END DO ! iLagrange
END SUBROUTINE PolynomialDerivativeMatrix


SUBROUTINE LagrangeInterpolationPolys(x,N_in,xGP,wBary,L)
!===================================================================================================================================
! Algorithm 34, Kopriva
! Computes all Lagrange functions evaluated at position x in [-1;1]
! Uses function ALMOSTEQUAL
!===================================================================================================================================
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
REAL, INTENT(IN)   :: x          ! Coordinate
INTEGER,INTENT(IN) :: N_in          ! polynomial degree
REAL,INTENT(IN)    :: xGP(0:N_in)   ! Gausspoint positions for the reference interval [-1,1]
REAL,INTENT(IN)    :: wBary(0:N_in) ! Barycentric weights
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)   :: L(0:N_in)     ! Lagrange basis functions evaluated at x
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
INTEGER                   :: iGP  ! ?
LOGICAL                   :: xEqualGP ! is x equal to a Gauss Point
REAL                      :: DummySum  ! ?
!===================================================================================================================================
xEqualGP=.FALSE.
DO iGP=0,N_in
  L(iGP)=0.
  IF(ALMOSTEQUAL(x,xGP(iGP))) THEN
    L(iGP)=1.
    xEqualGP=.TRUE.
  END IF ! (ALMOSTEQUAL(x,xGP(iGP)))
END DO ! iGP
! if x is equal to a Gauss point, L=(0,....,1,....0)
IF(xEqualGP) RETURN
DummySum=0.
DO iGP=0, N_in
  L(iGP)=wBary(iGP)/(x-xGP(iGP))
  DummySum=DummySum+L(iGP)
END DO

DO iGP=0,N_in
  L(iGP)=L(iGP)/DummySum
END DO

END SUBROUTINE LagrangeInterpolationPolys


SUBROUTINE InitializeVandermonde(N_In,N_Out,wBary_In,xi_In,xi_Out,Vdm)
!===================================================================================================================================
! build a 1D Vandermonde matrix using the lagrange basis functions of degree
! N_In, evaluated at the interpolation points xi_Out
!===================================================================================================================================
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN) :: N_In,N_Out  ! ?
REAL,INTENT(IN)    :: xi_In(0:N_In)  ! ?
REAL,INTENT(IN)    :: xi_Out(0:N_Out)  ! ?
REAL,INTENT(IN)    :: wBary_In(0:N_In)  ! ?
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
REAL,INTENT(OUT)   :: Vdm(0:N_Out,0:N_In)  ! ?
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES 
INTEGER            :: iXi  ! ?
!===================================================================================================================================
DO iXi=0,N_Out
  CALL LagrangeInterpolationPolys(xi_Out(iXi),N_In,xi_In,wBary_In,Vdm(iXi,:))
END DO
END SUBROUTINE InitializeVandermonde



SUBROUTINE LegendrePolynomialAndDerivative(N_in,x,L,Lder)
!===================================================================================================================================
! algorithm 22, Kopriva
! evaluate the Legendre polynomial L_N and its derivative at position x[-1,1] 
! recursive algorithm using the N_in-1 N_in-2 Legendre polynomials
!===================================================================================================================================
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
!input parameters
INTEGER,INTENT(IN)        :: N_in     ! polynomial degree, (N+1) CLpoints 
REAL,INTENT(IN)    :: x      ! coordinate value in the interval [-1,1]
!-----------------------------------------------------------------------------------------------------------------------------------
!output parameters
REAL,INTENT(OUT)    :: L,Lder  ! L_N(xi), d/dxi L_N(xi)
!-----------------------------------------------------------------------------------------------------------------------------------
!local variables
INTEGER :: iLegendre
REAL    :: L_Nm1,L_Nm2 ! L_{N_in-2},L_{N_in-1}
REAL    :: Lder_Nm1,Lder_Nm2 ! Lder_{N_in-2},Lder_{N_in-1}
!===================================================================================================================================
IF(N_in .EQ. 0)THEN
  L=1.
  Lder=0.
ELSEIF(N_in .EQ. 1) THEN
  L=x
  Lder=1.
ELSE ! N_in > 1
  L_Nm2=1.
  L_Nm1=x
  Lder_Nm2=0.
  Lder_Nm1=1.
  DO iLegendre=2,N_in
    L=(REAL(2*iLegendre-1)*x*L_Nm1 - REAL(iLegendre-1)*L_Nm2)/REAL(iLegendre)
    Lder=Lder_Nm2 + REAL(2*iLegendre-1)*L_Nm1
    L_Nm2=L_Nm1
    L_Nm1=L
    Lder_Nm2=Lder_Nm1
    Lder_Nm1=Lder
  END DO !iLegendre=2,N_in
END IF ! N_in
!normalize
L=L*SQRT(REAL(N_in)+0.5)
Lder=Lder*SQRT(REAL(N_in)+0.5)
END SUBROUTINE LegendrePolynomialAndDerivative



FUNCTION ALMOSTEQUAL(x,y)
!===================================================================================================================================
! Based on Algorithm 139, Kopriva
! Compares two real numbers
! Depends on PP_RealTolerance
! Takes into account that x,y is located in-between [-1;1]
!===================================================================================================================================
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
!input parameters
REAL,INTENT(IN) :: x,y         ! 2 scalar real numbers
!-----------------------------------------------------------------------------------------------------------------------------------
!output parameters
LOGICAL         :: AlmostEqual ! TRUE if |x-y| < 2*PP_RealTolerance
!-----------------------------------------------------------------------------------------------------------------------------------
!local variables
!===================================================================================================================================
AlmostEqual=.FALSE.
IF((x.EQ.0.).OR.(y.EQ.0.)) THEN
  IF(ABS(x-y).LE.2.*PP_RealTolerance) AlmostEqual=.TRUE.
ELSE ! x, y not zero
  IF((ABS(x-y).LE.PP_RealTolerance*ABS(x)).AND.((ABS(x-y).LE.PP_RealTolerance*ABS(y)))) AlmostEqual=.TRUE.
END IF ! x,y zero
END FUNCTION ALMOSTEQUAL

SUBROUTINE GetMortarVandermonde(Ngeo, M_0_1, M_0_2) 
!----------------------------------------------------------------------------------------------------------------------------------!
! description
!----------------------------------------------------------------------------------------------------------------------------------!
! MODULES                                                                                                                          !
!----------------------------------------------------------------------------------------------------------------------------------!
! insert modules here
!----------------------------------------------------------------------------------------------------------------------------------!
IMPLICIT NONE
! INPUT / OUTPUT VARIABLES 
INTEGER,INTENT(IN)      :: Ngeo
REAL,INTENT(OUT)        :: M_0_1(0:Ngeo,0:Ngeo), M_0_2(0:Ngeo,0:Ngeo)
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
! LOCAL VARIABLES
INTEGER                       :: i
REAL,DIMENSION(0:Ngeo)        :: x,wBary
!===================================================================================================================================
DO i=0,Ngeo
  x(i) = -1 + i*2./Ngeo  
END DO 
CALL BarycentricWeights(Ngeo,x,wBary)

!build interpolation operators M 0->1,M 0->2
CALL InitializeVandermonde(Ngeo,Ngeo,wBary,x,0.5*(x-1.),M_0_1)
CALL InitializeVandermonde(Ngeo,Ngeo,wBary,x,0.5*(x+1.),M_0_2)
END SUBROUTINE GetMortarVandermonde

END MODULE MOD_Basis1D
