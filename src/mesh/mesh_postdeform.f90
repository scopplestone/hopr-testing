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
! Copyright (C) 2017  Florian Hindenlang <hindenlang@gmail.com>
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
MODULE MOD_Mesh_PostDeform
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
INTERFACE PostDeform
  MODULE PROCEDURE PostDeform
END INTERFACE

PUBLIC::PostDeform
!===================================================================================================================================

CONTAINS

SUBROUTINE PostDeform()
!===================================================================================================================================
! input x,y,z node coordinates are transformed by a smooth (!) mapping to new x,y,z coordinates 
!===================================================================================================================================
!MODULE INPUT VARIABLES
USE MOD_Globals
USE MOD_Mesh_Vars   ,ONLY: tElem,Elems,MeshPostDeform,PostDeform_useGL
USE MOD_Mesh_Vars   ,ONLY: N,nMeshElems
USE MOD_Basis_Vars  ,ONLY: HexaMap
USE MOD_Basis1D     ,ONLY: LegGaussLobNodesAndWeights,BarycentricWeights,InitializeVandermonde
USE MOD_ChangeBasis ,ONLY: ChangeBasis3D
!MODULE OUTPUT VARIABLES
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
TYPE(tElem),POINTER          :: aElem   
INTEGER                      :: iNode   
INTEGER                      :: nTotal 
INTEGER                      :: i,iElem,ijk(3)
REAL,DIMENSION(0:N)          :: xi_EQ,xi_GL,wBary_EQ,wBary_GL
REAL,DIMENSION(0:N,0:N)      :: Vdm_EQtoGL, Vdm_GLtoEQ
REAL                         :: xElem(3,0:N,0:N,0:N,nMeshElems)
INTEGER                      :: HexaMapN1(8,3)
!===================================================================================================================================
IF(MeshPostDeform.EQ.0) RETURN
WRITE(UNIT_stdOut,'(132("~"))')
WRITE(UNIT_stdOut,'(A)')'POST DEFORM THE MESH...'
CALL Timer(.TRUE.)

IF(N.EQ.1)THEN
  HexaMapN1(:,1)=(/0,1,1,0,0,1,1,0/)
  HexaMapN1(:,2)=(/0,0,1,1,0,0,1,1/)
  HexaMapN1(:,3)=(/0,0,0,0,1,1,1,1/)
END IF !N=1

!prepare EQ to GL tranform
CALL LegGaussLobNodesAndWeights(N,xi_GL)
DO i=0,N
  xi_EQ(i)=REAL(i)
END DO
xi_EQ(:)=(2./REAL(N))*xi_EQ(:) -1.
CALL BarycentricWeights(N,xi_EQ,wBary_EQ)
CALL BarycentricWeights(N,xi_GL,wBary_GL)
CALL InitializeVandermonde(N,N,wBary_EQ,xi_EQ,xi_GL,Vdm_EQtoGL)
CALL InitializeVandermonde(N,N,wBary_GL,xi_GL,xi_EQ,Vdm_GLtoEQ)

xElem=0.
!Copy Equidist. element nodes
DO iElem=1,nMeshElems
  aElem=>Elems(iElem)%ep
  IF(N.EQ.1)THEN
    DO iNode=1,aElem%nNodes
      ijk(:)=HexaMapN1(iNode,:)
      xElem(1:3,ijk(1),ijk(2),ijk(3),aElem%ind)= aElem%Node(iNode)%np%x(:)
      aElem%Node(iNode)%np%tmp=-1
    END DO !iNode
  ELSE
    DO iNode=1,aElem%nCurvedNodes
      ijk(:)=HexaMap(iNode,:)
      xElem(1:3,ijk(1),ijk(2),ijk(3),aElem%ind)= aElem%CurvedNode(iNode)%np%x(:)
      aElem%CurvedNode(iNode)%np%tmp=-1
    END DO !iNode
  END IF !N=1
END DO ! iElem

!transform Equidist. to Gauss-Lobatto points
IF((PostDeform_useGL).AND.(N.GT.2))THEN
  CALL ChangeBasis3D(3,nMeshElems,N,N,Vdm_EQtoGL,xElem,xElem,.FALSE.)
END IF !PostDeform_useGL

!transform (all nodes are marked from -2 to -1)
nTotal=(N+1)**3*nMeshElems
CALL PostDeformFunc(nTotal,xElem,xElem)

IF((PostDeform_useGL).AND.(N.GT.2))THEN
  !transform back from GL to EQ
  CALL ChangeBasis3D(3,nMeshElems,N,N,Vdm_GLtoEQ,xElem,xElem,.FALSE.)
END IF
  
! copy back (all nodes are marked from -1 to 0)
DO iElem=1,nMeshElems
  aElem=>Elems(iElem)%ep
  IF(N.EQ.1)THEN
    DO iNode=1,aElem%nNodes
      IF(aElem%Node(iNode)%np%tmp.EQ.-1)THEN
        ijk(:)=HexaMapN1(iNode,:)
        aElem%Node(iNode)%np%x(:)= xElem(1:3,ijk(1),ijk(2),ijk(3),aElem%ind)
        aElem%Node(iNode)%np%tmp=0
      END IF
    END DO !iNode
  ELSE
    DO iNode=1,aElem%nCurvedNodes
      IF(aElem%CurvedNode(iNode)%np%tmp.EQ.-1)THEN
        ijk(:)=HexaMap(iNode,:)
        aElem%CurvedNode(iNode)%np%x(:)= xElem(1:3,ijk(1),ijk(2),ijk(3),aElem%ind)
        aElem%CurvedNode(iNode)%np%tmp=0
      END IF
    END DO !iNode
  END IF !N=1
END DO !iElem

CALL Timer(.FALSE.)
END SUBROUTINE PostDeform



SUBROUTINE PostDeformFunc(nTotal,X_in,X_out)
!===================================================================================================================================
! input x,y,z node coordinates are transformed by a smooth (!) mapping to new x,y,z coordinates 
!===================================================================================================================================
!MODULE INPUT VARIABLES
USE MOD_Globals
USE MOD_Mesh_Vars,ONLY:MeshPostDeform,PostDeform_R0,PostDeform_Rtorus 
USE MOD_Mesh_Vars,ONLY:PostDeform_sq,PostDeform_Lz
!MODULE OUTPUT VARIABLES
! MODULES
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT VARIABLES
INTEGER,INTENT(IN) :: nTotal         ! total number of points
REAL,INTENT(IN)    :: X_in(3,nTotal) ! contains original xyz coords
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
REAL,INTENT(OUT)   :: X_out(3,nTotal)    ! contains new XYZ position 
!-----------------------------------------------------------------------------------------------------------------------------------
! OUTPUT VARIABLES
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER            :: i
REAL               :: rr,x(3),dx(3),dx1(3),dx2(3),dx3(3)
REAL               :: xout(3)
REAL               :: alpha,HH, xi,eta
REAL               :: cosa,cosb,sina,sinb 
REAL               :: rotmat(2,2),arg
REAL               :: g,h,hMax,xLeft,normal,vec(2),length
REAL               :: vecRefBottom(2),xBlendBottom
REAL               :: vecRefTop(2),   xBlendTop
!===================================================================================================================================
dx=0.
SELECT CASE(MeshPostDeform)
CASE(1,11,12)
  DO i=1,nTotal
    x(:)=X_in(:,i)
    ! 2D box, x,y in [-1,1]^2, to cylinder with radius PostDeform_R0 (with PostDeform_Rtorus>0 to a torus, with zperiodic [0,1])
    ! all points outside [-1,1]^2 will be mapped directly to a circle (p.e. 2,2 => sqrt(0.5)*PostDeform_R0*(2,2) )
    ! inside [-1,1]^2 and outside [-0.5,0.5]^2 there will be a blending from a circle to a square
    ! the inner square [-0.5,0.5]^2 will be a linear blending of the bounding curves
    rr=MAX(ABS(x(1)),ABS(x(2)))
    IF(rr.LT.0.5)THEN !inside [-0.5,0.5]^2
      !right side at x=0.5
      dx1(1)=0.5*SQRT(2.)*COS(0.25*Pi*x(2)/0.5)-0.5
      dx1(2)=0.5*SQRT(2.)*SIN(0.25*Pi*x(2)/0.5)-x(2)
      !upper side at y=0.5
      dx2(1)=0.5*SQRT(2.)*SIN(0.25*Pi*x(1)/0.5)-x(1)
      dx2(2)=0.5*SQRT(2.)*COS(0.25*Pi*x(1)/0.5)-0.5
      alpha=0.35
      ! coons mapping of edges, dx=0 at the corners
      dx(1:2)=alpha*(dx1(1:2)*(/2*x(1),1./)+dx2(1:2)*(/1.,2*x(2)/))
    ELSE !outside [-0.5,0.5]^2
      IF(ABS(x(2)).LT.ABS(x(1)))THEN !left and right quarter
        dx(1)=x(1)*SQRT(2.)*COS(0.25*Pi*x(2)/x(1))-x(1) 
        dx(2)=x(1)*SQRT(2.)*SIN(0.25*Pi*x(2)/x(1))-x(2)
      ELSEIF(ABS(x(2)).GE.ABS(x(1)))THEN !upper and lower quarter
        dx(1)=x(2)*SQRT(2.)*SIN(0.25*Pi*x(1)/x(2))-x(1)
        dx(2)=x(2)*SQRT(2.)*COS(0.25*Pi*x(1)/x(2))-x(2)
      END IF
      alpha=MIN(1.,2.*rr-1.) !maps [0.5,1] --> [0,1] and alpha=1 outside [-1,1]^2
      alpha=SIN(0.5*Pi*alpha) !smooth transition at the outer boundary max(|x|,|y|)=1
      alpha=1.0*alpha+0.35*(1.-alpha) !alpha=1 at max(|x|,|y|)=1, and alpha=0.35 at max(|x|,|y|)=0.5 
      dx(1:2)=alpha*dx(1:2)
    END IF
    xout(1:2)=PostDeform_R0*SQRT(0.5)*(x(1:2)+dx(1:2))
    ! spiral rotation along z sq=0. no spiral, sq=1: 1 rotation along z [0,1]
    SELECT CASE(MeshPostDeform)
    CASE(1)
      arg=2.*pi*x(3)*PostDeform_sq
    CASE(11)
      arg=2.*pi*x(3)*PostDeform_sq*SUM(xout(1:2)**2)
    CASE(12)
      arg=2.*pi*x(3)*PostDeform_sq*SUM(xout(1:2)**2)*(1+0.5*xout(1))
    END SELECT
    rotmat(1,1)=COS(arg)
    rotmat(2,1)=SIN(arg)
    rotmat(1,2)=-rotmat(2,1)
    rotmat(2,2)=rotmat(1,1)
    xout(1:2)=MATMUL(rotmat,xout(1:2))
    IF(PostDeform_Rtorus.LT.0.)THEN
      xout(3)=x(3)*PostDeform_Lz !cylinder
    ELSE !torus, z_in must be [0,1] and periodic  !!, torus around z axis ,x =R*cos(phi), y=-R*sin(phi)!!!
      xout(3)=xout(2)
      !map R,Z to X,Y,Z
      xout(2)=-(xout(1)+PostDeform_Rtorus)*SIN(2*Pi*x(3))
      xout(1)= (xout(1)+PostDeform_Rtorus)*COS(2*Pi*x(3))
    END IF
    X_out(:,i)=xout(:)
  END DO !i=1,nTotal
CASE(66) 
  DO i=1,nTotal
    x(:)=X_in(:,i)
    ! 2D HEXAGON, x,y in [-1,1]^2, to cylinder with radius PostDeform_R0 (with PostDeform_Rtorus>0 to a torus, with zperiodic [0,1])
    ! all points outside [-1,1]^2 will be mapped directly to a circle (p.e. 2,2 => sqrt(0.5)*PostDeform_R0*(2,2) )
    !
    !              ^ y
    !              |
    !              |                             _
    !        0-----------0                        ^
    !       / \         / \                       |
    !      /   \       /   \               _      | 
    !     /     3-----2     \               ^     |1.0    
    !    /     / \     \     \              |0.5  |
    !   /     /   \     \     \             |     |
    !  0-----4     0-----1-----0 -----> x  _v    _v
    !   \     \   /     /     /
    !    \     \ /     /     /
    !     \     5-----6     /
    !      \   /       \   /
    !       \ /         \ /
    !        0-----------0
    !              |<>|           0.25
    !              |<--->|        0.5
    !              |<--------->|  1.
    !  y direction is not correctly scaled, will be scaled here by sqrt(3)/2 
    !
    ! inside [-1,1]^2 and outside [-0.5,0.5]^2 there will be a blending from a circle to a square
    ! the inner square [-0.5,0.5]^2 will be a linear blending of the bounding curves
    HH = 0.5*SQRT(3.)

    x(2)=HH*X_in(2,i) !scale with sqrt(3/4) y direction!

    IF(ABS(x(2)).LE.2.*HH*ABS(x(1)))THEN
      rr=ABS(x(1))+0.5/HH*ABS(x(2))
    ELSE !upper and lower
      rr=ABS(x(2))/HH
    END IF
    dx=0.
    IF(rr.GT.0.)THEN
      IF(rr.LT.0.5)THEN !inside hexagon 1-6
        !boundary curves are mapped with alpha from rr=0.5 below
        alpha=0.35
        !check if in left or right domain:
        IF(2.*HH*x(1).GT.-ABS(x(2))) THEN
          xi  = 2.*x(1)+ABS(x(2))/HH
          eta = 2.*ABS(x(2))/HH
          IF(x(2).GE.0.)THEN ! domain (0-1-2-3)
            dx1(1:2)=    (/0.5,0./)+eta*(/-0.25,0.5*HH/) !point at 1-2
            dx2(1:2)= xi*(/0.5,0./)+    (/-0.25,0.5*HH/) !point at 2-3
          ELSE  ! domain (0-5-6-1)
            dx1(1:2)=    (/0.5,0./)+eta*(/-0.25,-0.5*HH/) !point at 1-6
            dx2(1:2)= xi*(/0.5,0./)+    (/-0.25,-0.5*HH/) !point at 5-6
          END IF 
        ELSE ! domain (0-1-6-5), xi 0->3, eta 0->5
          eta= -x(2)/HH-2.*x(1)
          xi =  x(2)/HH-2.*x(1)
          dx1(1:2)=   (/-0.25,0.5*HH/)+eta*(/-0.25,-0.5*HH/) !point at 3-4
          dx2(1:2)=xi*(/-0.25,0.5*HH/)+    (/-0.25,-0.5*HH/) !point at 4-5
        END IF
        dx(1:2)= alpha*xi* (0.5/SQRT(SUM(dx1(1:2)**2))-1.)*dx1(1:2) &
                +alpha*eta*(0.5/SQRT(SUM(dx2(1:2)**2))-1.)*dx2(1:2)
      ELSE !outside hexagon 1-6, rr>=0.5 , for rr>1, alpha=1 
        alpha=MIN(1.,2.*rr-1.) !maps [0.5,1] --> [0,1] and alpha=1 outside [-1,1]^2
        alpha=SIN(0.5*Pi*alpha) !smooth transition at the outer boundary rr=1
        alpha=1.0*alpha+0.35*(1.-alpha) !alpha=1 at rr=1, and alpha=0.35 at rr=0.5 
        !r=SQRT(x(1)**2+x(2)**2) !r always > 0 here
        dx(1:2)=alpha*(rr/SQRT(SUM(x(1:2)**2))-1.)*x(1:2)
      END IF !inside/outside hexagon
    END IF !rr>0
    xout(1:2)=PostDeform_R0*(1.+0.35*(1.-alpha))*(x(1:2)+dx(1:2)) !scale inner part a little
    xout(3)=x(3)*PostDeform_Lz !cylinder
    X_out(:,i)=xout(:)
  END DO !i=1,nTotal
CASE(2) ! 3D box, x,y in [-1,1]^3, to Sphere with radius PostDeform_R0 
        ! all points outside [-1,1]^4 will be mapped directly to a sphere
  DO i=1,nTotal
    x(:)=x_in(:,i)
    rr=MAX(ABS(x(1)),ABS(x(2)),ABS(x(3)))
    IF(rr.LE.0.5)THEN !inside [-0.5,0.5]^3
      !right side at x=0.5
      cosa=COS(0.25*Pi*x(2)/0.5)
      sina=SIN(0.25*Pi*x(2)/0.5)
      cosb=COS(0.25*Pi*x(3)/0.5)
      sinb=SIN(0.25*Pi*x(3)/0.5)
      dx1(1)=cosa*cosb
      dx1(2)=sina*cosb
      dx1(3)=cosa*sinb
      dx1(:)=dx1(:)*0.5*SQRT(3./(cosb*cosb+(cosa*sinb)**2))-(/0.5,x(2),x(3)/)
      !upper side at y=0.5
      cosa=COS(0.25*Pi*x(3)/0.5)
      sina=SIN(0.25*Pi*x(3)/0.5)
      cosb=COS(0.25*Pi*x(1)/0.5)
      sinb=SIN(0.25*Pi*x(1)/0.5)
      dx2(1)=cosa*sinb
      dx2(2)=cosa*cosb
      dx2(3)=sina*cosb
      dx2(:)=dx2(:)*0.5*SQRT(3./(cosb*cosb+(cosa*sinb)**2))-(/x(1),0.5,x(3)/)
      ! side at z=0.5
      cosa=COS(0.25*Pi*x(1)/0.5)
      sina=SIN(0.25*Pi*x(1)/0.5)
      cosb=COS(0.25*Pi*x(2)/0.5)
      sinb=SIN(0.25*Pi*x(2)/0.5)
      dx3(1)=sina*cosb
      dx3(2)=cosa*sinb
      dx3(3)=cosa*cosb
      dx3(:)=dx3(:)*0.5*SQRT(3./(cosb*cosb+(cosa*sinb)**2))-(/x(1),x(2),0.5/)
      alpha=0.35
      !dx =0 at the corners, coons mapping for faces 
      dx(1:3)=alpha*( dx1(1:3)*(/   2*x(1),     1.,     1./) &
                     +dx2(1:3)*(/       1.,2*x(2) ,     1./) &
                     +dx3(1:3)*(/       1.,     1.,2*x(3) /))
      !-coons mapping for edges : x=0.5,y=0.5
      cosa=SQRT(0.5)
      sina=SQRT(0.5)
      cosb=COS(0.25*Pi*x(3)/0.5)
      sinb=SIN(0.25*Pi*x(3)/0.5)
      dx1(1)=cosa*cosb
      dx1(2)=sina*cosb
      dx1(3)=cosa*sinb
      dx1(:)=dx1(:)*0.5*SQRT(3./(cosb*cosb+(cosa*sinb)**2))-(/0.5,0.5,x(3)/)
      !-edges : y=0.5,z=0.5
      cosb=COS(0.25*Pi*x(1)/0.5)
      sinb=SIN(0.25*Pi*x(1)/0.5)
      dx2(1)=cosa*sinb
      dx2(2)=cosa*cosb
      dx2(3)=sina*cosb
      dx2(:)=dx2(:)*0.5*SQRT(3./(cosb*cosb+(cosa*sinb)**2))-(/x(1),0.5,0.5/)
      !-edges : x=0.5,z=0.5
      cosb=COS(0.25*Pi*x(2)/0.5)
      sinb=SIN(0.25*Pi*x(2)/0.5)
      dx3(1)=sina*cosb
      dx3(2)=cosa*sinb
      dx3(3)=cosa*cosb
      dx3(:)=dx3(:)*0.5*SQRT(3./(cosb*cosb+(cosa*sinb)**2))-(/0.5,x(2),0.5/)
      ! faces - edges (coons mapping, dx=0 at corners)
      dx(1:3)= dx(1:3)-  &
              alpha*2*( dx1(1:3)*(/ x(1) ,  x(2) ,  0.5*(ABS(x(1))+ABS(x(2))) /) &
                       +dx2(1:3)*(/ 0.5*(ABS(x(2))+ABS(x(3))),  x(2) , x(3) /) &
                       +dx3(1:3)*(/ x(1) ,0.5*(ABS(x(1))+ABS(x(3))), x(3) /))
      
    ELSE !outside [-0.5,0.5]^3
      IF((ABS(x(2)).LT.ABS(x(1))).AND.(ABS(x(3)).LT.ABS(x(1))))THEN !left and right (x dir)
        cosa=COS(0.25*Pi*x(2)/x(1))
        sina=SIN(0.25*Pi*x(2)/x(1))
        cosb=COS(0.25*Pi*x(3)/x(1))
        sinb=SIN(0.25*Pi*x(3)/x(1))
        dx(1)=cosa*cosb
        dx(2)=sina*cosb
        dx(3)=cosa*sinb
        dx(:)=x(1)*dx(:)*SQRT(3./(cosb*cosb+(cosa*sinb)**2))-x(:)
      ELSEIF((ABS(x(1)).LE.ABS(x(2))).AND.(ABS(x(3)).LT.ABS(x(2))))THEN !upper and lower (y dir)
        cosa=COS(0.25*Pi*x(3)/x(2))
        sina=SIN(0.25*Pi*x(3)/x(2))
        cosb=COS(0.25*Pi*x(1)/x(2))
        sinb=SIN(0.25*Pi*x(1)/x(2))
        dx(1)=cosa*sinb
        dx(2)=cosa*cosb
        dx(3)=sina*cosb
        dx(:)=x(2)*dx(:)*SQRT(3./(cosb*cosb+(cosa*sinb)**2))-x(:)
      ELSEIF((ABS(x(1)).LE.ABS(x(3))).AND.(ABS(x(2)).LE.ABS(x(3))))THEN !back and front (z dir)
        cosa=COS(0.25*Pi*x(1)/x(3))
        sina=SIN(0.25*Pi*x(1)/x(3))
        cosb=COS(0.25*Pi*x(2)/x(3))
        sinb=SIN(0.25*Pi*x(2)/x(3))
        dx(1)=sina*cosb
        dx(2)=cosa*sinb
        dx(3)=cosa*cosb
        dx(:)=x(3)*dx(:)*SQRT(3./(cosb*cosb+(cosa*sinb)**2))-x(:)
      END IF
      alpha=MIN(1.,2.*rr-1.) !maps [0.5,1] --> [0,1] and alpha=1 outside [-1,1]^2
      alpha=SIN(0.5*Pi*alpha) !smooth transition at the outer boundary max(|x|,|y|,|z|)=1
      alpha=1.0*alpha+0.35*(1.-alpha) !alpha=1 at max(|x|,|y|,|z|)=1, and alpha=0.35 at max(|x|,|y|,|z|)=0.5 
      dx(:)=alpha*dx(:)
    END IF
    xout(1:3)=PostDeform_R0/SQRT(3.)*(x(1:3)+dx(1:3))
    X_out(:,i)=xout(:)
  END DO !i=1,nTotal
CASE(3) ! 2D box, x,y in [-1,1]^2, to cylinder with radius PostDeform_R0 z  [0,1] is mapped to z*PostDeform_Lz)
        ! all points outside [-1,1]^3 and inside [-4,4]^3 are smoothly mapped back to a cube of 
        ! of size [-4,4]*PostDeform_R0/sqrt(2)
  DO i=1,nTotal
    x(:)=x_in(:,i)
    rr=MAX(ABS(x(1)),ABS(x(2)))
    IF(rr.LT.0.5)THEN !inside [-0.5,0.5]^2
      !right side at x=0.5
      dx1(1)=0.5*SQRT(2.)*COS(0.25*Pi*x(2)/0.5)-0.5
      dx1(2)=0.5*SQRT(2.)*SIN(0.25*Pi*x(2)/0.5)-x(2)
      !upper side at y=0.5
      dx2(1)=0.5*SQRT(2.)*SIN(0.25*Pi*x(1)/0.5)-x(1)
      dx2(2)=0.5*SQRT(2.)*COS(0.25*Pi*x(1)/0.5)-0.5
      alpha=0.35
      ! coons mapping of edges, dx=0 at the corners
      dx(1:2)=alpha*(dx1(1:2)*(/2*x(1),1./)+dx2(1:2)*(/1.,2*x(2)/))
    ELSEIF((rr.GE.0.5).AND.(rr.LE.4.))THEN !outside [-0.5,0.5]^2, inside [-4,4]^2
      IF(ABS(x(2)).LT.ABS(x(1)))THEN !left and right quarter
        dx(1)=x(1)*SQRT(2.)*COS(0.25*Pi*x(2)/x(1))-x(1)
        dx(2)=x(1)*SQRT(2.)*SIN(0.25*Pi*x(2)/x(1))-x(2)
      ELSEIF(ABS(x(2)).GE.ABS(x(1)))THEN !upper and lower quarter
        dx(1)=x(2)*SQRT(2.)*SIN(0.25*Pi*x(1)/x(2))-x(1)
        dx(2)=x(2)*SQRT(2.)*COS(0.25*Pi*x(1)/x(2))-x(2)
      END IF
      IF(rr.LE.1.)THEN
        alpha=2.*rr-1. !maps [0.5,1] --> [0,1] and alpha=1 outside [-1,1]^2
        alpha=SIN(0.5*Pi*alpha) !smooth transition at the outer boundary max(|x|,|y|,|z|)=1
        alpha=1.0*alpha+0.35*(1.-alpha) !alpha=1 at max(|x|,|y|,|z|)=1, and alpha=0.35 at max(|x|,|y|,|z|)=0.5 
        dx(1:2)=alpha*dx(1:2)
      ELSE
        !alpha=((4.-rr)/((4.-1.)*rr)) !between [-1,1] and [-4,4]
        alpha=(4.-rr)/(4.-1.) !maps [1,4] --> [1,0] and alpha=1 outside [-1,1]^2
        alpha=SIN(0.5*Pi*alpha) !smooth transition 
        dx(1:2)=alpha*(dx(1:2)/rr)
      END IF
    ELSE !outside [-4,4]^2
      dx=0.
    END IF
    xout(1:2)=PostDeform_R0*SQRT(0.5)*(x(1:2)+dx(1:2))
    xout(3)=x(3)*PostDeform_Lz 
    X_out(:,i)=xout(:)
  END DO !i=1,nTotal
CASE(300) ! planar Annulus: tensor-product mapping: input 2*pi*x=>theta must be  [-1,1] y => height in z ,z=> radius
  DO i=1,nTotal
    x(:)=x_in(:,i)
    xout(1)=PostDeform_R0*x(3)*COS(pi*x(1))
    xout(2)=PostDeform_R0*x(3)*SIN(pi*x(1))
    xout(3)=x(2)
    X_out(:,i)=xout(:)
  END DO !i=1,nTotal
CASE(310) ! spherical Annulus: tensor-product mapping: input pi*x=>theta must be  [-1,1] Pi*y => phi ,z=> radius
  DO i=1,nTotal
    x(:)=x_in(:,i)
    xout(1)=PostDeform_R0*x(3)*COS(pi*x(1))*COS(pi*x(2))
    xout(2)=PostDeform_R0*x(3)*SIN(pi*x(1))*COS(pi*x(2))
    xout(3)=PostDeform_R0*x(3)*SIN(pi*x(2))
    X_out(:,i)=xout(:)
  END DO !i=1,nTotal
CASE(4) ! 3D box, x,y in [-1,1]^3, to Sphere with radius PostDeform_R0 
        ! all points outside [-1,1]^3 and inside [-4,4]^3 are smoothly mapped back to a cube of 
        ! of size [-4,4]*PostDeform_R0/sqrt(3)
  DO i=1,nTotal
    x(:)=x_in(:,i)
    rr=MAX(ABS(x(1)),ABS(x(2)),ABS(x(3)))
    IF(rr.LE.0.5)THEN !inside [-0.5,0.5]^3
      !right side at x=0.5
      cosa=COS(0.25*Pi*x(2)/0.5)
      sina=SIN(0.25*Pi*x(2)/0.5)
      cosb=COS(0.25*Pi*x(3)/0.5)
      sinb=SIN(0.25*Pi*x(3)/0.5)
      dx1(1)=cosa*cosb
      dx1(2)=sina*cosb
      dx1(3)=cosa*sinb
      dx1(:)=dx1(:)*0.5*SQRT(3./(cosb*cosb+(cosa*sinb)**2))-(/0.5,x(2),x(3)/)
      !upper side at y=0.5
      cosa=COS(0.25*Pi*x(3)/0.5)
      sina=SIN(0.25*Pi*x(3)/0.5)
      cosb=COS(0.25*Pi*x(1)/0.5)
      sinb=SIN(0.25*Pi*x(1)/0.5)
      dx2(1)=cosa*sinb
      dx2(2)=cosa*cosb
      dx2(3)=sina*cosb
      dx2(:)=dx2(:)*0.5*SQRT(3./(cosb*cosb+(cosa*sinb)**2))-(/x(1),0.5,x(3)/)
      ! side at z=0.5
      cosa=COS(0.25*Pi*x(1)/0.5)
      sina=SIN(0.25*Pi*x(1)/0.5)
      cosb=COS(0.25*Pi*x(2)/0.5)
      sinb=SIN(0.25*Pi*x(2)/0.5)
      dx3(1)=sina*cosb
      dx3(2)=cosa*sinb
      dx3(3)=cosa*cosb
      dx3(:)=dx3(:)*0.5*SQRT(3./(cosb*cosb+(cosa*sinb)**2))-(/x(1),x(2),0.5/)
      alpha=0.35
      !dx =0 at the corners, coons mapping for faces 
      dx(1:3)=alpha*( dx1(1:3)*(/   2*x(1),     1.,     1./) &
                     +dx2(1:3)*(/       1.,2*x(2) ,     1./) &
                     +dx3(1:3)*(/       1.,     1.,2*x(3) /))
      !-coons mapping for edges : x=0.5,y=0.5
      cosa=SQRT(0.5)
      sina=SQRT(0.5)
      cosb=COS(0.25*Pi*x(3)/0.5)
      sinb=SIN(0.25*Pi*x(3)/0.5)
      dx1(1)=cosa*cosb
      dx1(2)=sina*cosb
      dx1(3)=cosa*sinb
      dx1(:)=dx1(:)*0.5*SQRT(3./(cosb*cosb+(cosa*sinb)**2))-(/0.5,0.5,x(3)/)
      !-edges : y=0.5,z=0.5
      cosb=COS(0.25*Pi*x(1)/0.5)
      sinb=SIN(0.25*Pi*x(1)/0.5)
      dx2(1)=cosa*sinb
      dx2(2)=cosa*cosb
      dx2(3)=sina*cosb
      dx2(:)=dx2(:)*0.5*SQRT(3./(cosb*cosb+(cosa*sinb)**2))-(/x(1),0.5,0.5/)
      !-edges : x=0.5,z=0.5
      cosb=COS(0.25*Pi*x(2)/0.5)
      sinb=SIN(0.25*Pi*x(2)/0.5)
      dx3(1)=sina*cosb
      dx3(2)=cosa*sinb
      dx3(3)=cosa*cosb
      dx3(:)=dx3(:)*0.5*SQRT(3./(cosb*cosb+(cosa*sinb)**2))-(/0.5,x(2),0.5/)
      ! faces - edges (coons mapping, dx=0 at corners)
      dx(1:3)= dx(1:3)-  &
              alpha*2*( dx1(1:3)*(/ x(1) ,  x(2) ,  0.5*(ABS(x(1))+ABS(x(2))) /) &
                       +dx2(1:3)*(/ 0.5*(ABS(x(2))+ABS(x(3))),  x(2) , x(3) /) &
                       +dx3(1:3)*(/ x(1) ,0.5*(ABS(x(1))+ABS(x(3))), x(3) /))
      
    ELSEIF((rr.GT.0.5).AND.(rr.LE.4.))THEN !outside [-0.5,0.5]^3 and inside [-4,4]^3
      IF((ABS(x(2)).LT.ABS(x(1))).AND.(ABS(x(3)).LT.ABS(x(1))))THEN !left and right (x dir)
        cosa=COS(0.25*Pi*x(2)/x(1))
        sina=SIN(0.25*Pi*x(2)/x(1))
        cosb=COS(0.25*Pi*x(3)/x(1))
        sinb=SIN(0.25*Pi*x(3)/x(1))
        dx(1)=cosa*cosb
        dx(2)=sina*cosb
        dx(3)=cosa*sinb
        dx(:)=x(1)*dx(:)*SQRT(3./(cosb*cosb+(cosa*sinb)**2))-x(:)
      ELSEIF((ABS(x(1)).LE.ABS(x(2))).AND.(ABS(x(3)).LT.ABS(x(2))))THEN !upper and lower (y dir)
        cosa=COS(0.25*Pi*x(3)/x(2))
        sina=SIN(0.25*Pi*x(3)/x(2))
        cosb=COS(0.25*Pi*x(1)/x(2))
        sinb=SIN(0.25*Pi*x(1)/x(2))
        dx(1)=cosa*sinb
        dx(2)=cosa*cosb
        dx(3)=sina*cosb
        dx(:)=x(2)*dx(:)*SQRT(3./(cosb*cosb+(cosa*sinb)**2))-x(:)
      ELSEIF((ABS(x(1)).LE.ABS(x(3))).AND.(ABS(x(2)).LE.ABS(x(3))))THEN !back and front (z dir)
        cosa=COS(0.25*Pi*x(1)/x(3))
        sina=SIN(0.25*Pi*x(1)/x(3))
        cosb=COS(0.25*Pi*x(2)/x(3))
        sinb=SIN(0.25*Pi*x(2)/x(3))
        dx(1)=sina*cosb
        dx(2)=cosa*sinb
        dx(3)=cosa*cosb
        dx(:)=x(3)*dx(:)*SQRT(3./(cosb*cosb+(cosa*sinb)**2))-x(:)
      END IF !lower/upper...
      IF(rr.LE.1.)THEN
        alpha=2.*rr-1. !maps [0.5,1] --> [0,1] and alpha=1 outside [-1,1]^2
        alpha=SIN(0.5*Pi*alpha) !smooth transition at the outer boundary max(|x|,|y|,|z|)=1
        alpha=1.0*alpha+0.35*(1.-alpha) !alpha=1 at max(|x|,|y|,|z|)=1, and alpha=0.35 at max(|x|,|y|,|z|)=0.5 
        dx(:)=alpha*dx(:)
      ELSE
        !alpha=((4.-rr)/((4.-1.)*rr)) !between [-1,1] and [-4,4]
        alpha=(4.-rr)/(4.-1.) !maps [1,4] --> [1,0] and alpha=1 outside [-1,1]^2
        alpha=SIN(0.5*Pi*alpha) !smooth transition 
        dx(:)=alpha*(dx(:)/rr)
      END IF
    ELSE   !outside [-4,4]^3 
      dx=0.
    END IF !rr
    xout(1:3)=PostDeform_R0/SQRT(3.)*(x(1:3)+dx(1:3))
    X_out(:,i)=xout(:)
  END DO !i=1,nTotal
CASE(5) ! 2D periodic hill geometry, see http://www.kbwiki.ercoftac.org/w/index.php/Abstr:2D_Periodic_Hill_Flow for description of
        ! test case. Starting point is a rectangular domain of size [0,9]x[0,3.035]x[0,4.5]. The deformation will be applied in the
        ! x-y-plane only.

  ! Domain height
  hMax = 3.035

  DO i=1,nTotal
    x(:)=x_in(:,i)
    xout = x

    ! height of the bottom wall at given x
    h = PHILL_H(x(1))

    ! polynomial for smooth mesh deformation across points in y direction
    g = 2./hMax**3*x(2)**3 - 3./hMax**2*x(2)**2 + 1. 

    ! First, simply move the geometry in y-direction regarding to the local hill size
    xout(2) = xout(2) + g*h

    ! Then, move the grid to create a mesh approximately normal to the wall, but only in the vicinity of the lower wall.
    ! This mesh deformation will again be smoothed out towards the top.
    xLeft = 4.5-ABS(x(1)-4.5) ! corresponding x in left half (hill is symmetric)
    IF ( (xLeft.GE.0.1) .AND. (x(2).LT.hMax) ) THEN
      ! Length of the vector from the hill to the current point, used for scaling
      length = xout(2) - h

      ! surface normal vector: 
      ! Near the horizontal walls on the top and bottom of the hill, 
      ! the slope will be lineary increased/decreased to infinity to smear out the sharp bends
      xBlendTop    = 0.8
      xBlendBottom = 1.6
      ! Linear blending between reference slope and (/0.,1./)
      IF (xLeft.LT.xBlendTop) THEN
        ! hill top
        vecRefTop = PHILL_NORMAL(xBlendTop)
        vec = (/0.,1./) + xLeft/xBlendTop*(vecRefTop-(/0.,1./))
      ELSE IF (xLeft.GE.xBlendBottom) THEN
        ! hill bottom
        vecRefBottom = PHILL_NORMAL(xBlendBottom)
        vec = vecRefBottom + (xLeft-xBlendBottom)/(4.5-xBlendBottom)*((/0.,1./)-vecRefBottom)
      ELSE 
        ! default case (at the hill slope): take the actual normal vector
        vec = PHILL_NORMAL(xLeft)
      END IF

      ! Mirror the second half of the hill geometry by inverting x component
      IF(x(1).GT.4.5) vec(1)=-vec(1)

      ! Smooth out the mesh deformation
      xout(1:2) = xout(1:2) + 0.9*g**3*length*(vec-(/0.,1./))
    END IF 

    X_out(:,i)=xout(:)
  END DO !i=1,nTotal

CASE(21)!Laval nozzle 
        ! 3D box, x,y in [-1,1]^2 and z in [0,nozzle_length], to cylindrical cross section with a r(z) profile
        ! r(z) profile here given by a fitted monomial polynomial over z.
        ! all points outside [-1,1]^2 will be mapped directly to a circle (p.e. 2,2 => sqrt(0.5)*PostDeform_R0*(2,2) )
        ! inside [-1,1]^2 and outside [-0.5,0.5]^2 there will be a blending from a circle to a square
        ! the inner square [-0.5,0.5]^2 will be a linear blending of the bounding curves
  DO i=1,nTotal
    x(:)=x_in(:,i)
    rr=MAX(ABS(x(1)),ABS(x(2)))
    IF(rr.LT.0.5)THEN !inside [-0.5,0.5]^2
      !right side at x=0.5
      dx1(1)=0.5*SQRT(2.)*COS(0.25*Pi*x(2)/0.5)-0.5
      dx1(2)=0.5*SQRT(2.)*SIN(0.25*Pi*x(2)/0.5)-x(2)
      !upper side at y=0.5
      dx2(1)=0.5*SQRT(2.)*SIN(0.25*Pi*x(1)/0.5)-x(1)
      dx2(2)=0.5*SQRT(2.)*COS(0.25*Pi*x(1)/0.5)-0.5
      alpha=0.35
      ! coons mapping of edges, dx=0 at the corners
      dx(1:2)=alpha*(dx1(1:2)*(/2*x(1),1./)+dx2(1:2)*(/1.,2*x(2)/))
    ELSE !outside [-0.5,0.5]^2
      IF(ABS(x(2)).LT.ABS(x(1)))THEN !left and right quarter
        dx(1)=x(1)*SQRT(2.)*COS(0.25*Pi*x(2)/x(1))-x(1)
        dx(2)=x(1)*SQRT(2.)*SIN(0.25*Pi*x(2)/x(1))-x(2)
      ELSEIF(ABS(x(2)).GE.ABS(x(1)))THEN !upper and lower quarter
        dx(1)=x(2)*SQRT(2.)*SIN(0.25*Pi*x(1)/x(2))-x(1)
        dx(2)=x(2)*SQRT(2.)*COS(0.25*Pi*x(1)/x(2))-x(2)
      END IF
      alpha=MIN(1.,2.*rr-1.) !maps [0.5,1] --> [0,1] and alpha=1 outside [-1,1]^2
      alpha=SIN(0.5*Pi*alpha) !smooth transition at the outer boundary max(|x|,|y|)=1
      alpha=1.0*alpha+0.35*(1.-alpha) !alpha=1 at max(|x|,|y|)=1, and alpha=0.35 at max(|x|,|y|)=0.5 
      dx(1:2)=alpha*dx(1:2)
    END IF
    xout(1:2)=PostDeform_R0*SQRT(0.5)*(x(1:2)+dx(1:2))  !r=[0;1]
    !scale with radius (polynomial given for z in [0;3.2]!!)
    xout(1:2)=xout(1:2)* ((((((( 5.650243547593181E-03)*x(3) -6.234872576213188E-02)*x(3) +2.717131733412690E-01)*x(3) & 
                                -5.898455159792279E-01)*x(3) +6.077001327643441E-01)*x(3) -3.529284589734004E-02)*x(3) &
                                +5.008061090611048E-01)
    xout(3)=x(3)
    X_out(:,i)=xout(:)
  END DO !i=1,nTotal
CASE(30) ! sin [-1;1]^3
  x_out(1,:) = x_in(1,:)+ 0.1*SIN(Pi*x_in(1,:))*SIN(Pi*x_in(2,:))
  x_out(2,:) = x_in(2,:)+ 0.1*SIN(Pi*x_in(1,:))*SIN(Pi*x_in(2,:))
  x_out(3,:) = x_in(3,:)+ 0.1*SIN(Pi*x_in(1,:))*SIN(Pi*x_in(2,:))
CASE(31) ! sin [-1;1]^3
  x_out(1,:) = x_in(1,:)+ 0.1*SIN(Pi*x_in(1,:))*SIN(Pi*x_in(2,:))*SIN(Pi*x_in(3,:))
  x_out(2,:) = x_in(2,:)+ 0.1*SIN(Pi*x_in(1,:))*SIN(Pi*x_in(2,:))*SIN(Pi*x_in(3,:))
  x_out(3,:) = x_in(3,:)+ 0.1*SIN(Pi*x_in(1,:))*SIN(Pi*x_in(2,:))*SIN(Pi*x_in(3,:))
CASE(32) ! sin [-1;1]^3
  x_out(1,:) = x_in(1,:)+ 0.1*SIN(Pi*x_in(1,:))
  x_out(2,:) = x_in(2,:)+ 0.1*SIN(Pi*x_in(1,:))
  x_out(3,:) = x_in(3,:)+ 0.1*SIN(Pi*x_in(1,:))
CASE(33) ! sin 2D [-1;1]^2
  x_out(1,:) = x_in(1,:)+ 0.1*SIN(Pi*x_in(1,:))*SIN(Pi*x_in(2,:))
  x_out(2,:) = x_in(2,:)+ 0.1*SIN(Pi*x_in(1,:))*SIN(Pi*x_in(2,:))
  x_out(3,:) = x_in(3,:)
CASE(34) ! cos3D (1.5Pi) [-1;1]^3
  x_out(1,:) = x_in(1,:)+ 0.1*COS(1.5*Pi*x_in(1,:))*COS(1.5*Pi*x_in(2,:))*COS(1.5*Pi*x_in(3,:))
  x_out(2,:) = x_in(2,:)+ 0.1*COS(1.5*Pi*x_in(1,:))*COS(1.5*Pi*x_in(2,:))*COS(1.5*Pi*x_in(3,:))
  x_out(3,:) = x_in(3,:)+ 0.1*COS(1.5*Pi*x_in(1,:))*COS(1.5*Pi*x_in(2,:))*COS(1.5*Pi*x_in(3,:))
CASE(40) ! cos with coupling  [-1;1]^3 (from https://arxiv.org/pdf/1809.01178.pdf, page 20) 
  x_out(2,:) = x_in(2,:)+ 0.15*COS(1.5*Pi*x_in( 1,:))*COS(0.5*Pi*x_in( 2,:))*COS(0.5*Pi*x_in(3,:))
  x_out(1,:) = x_in(1,:)+ 0.15*COS(0.5*Pi*x_in( 1,:))*SIN(2.0*Pi*x_out(2,:))*COS(0.5*Pi*x_in(3,:))
  x_out(3,:) = x_in(3,:)+ 0.15*COS(0.5*Pi*x_out(1,:))*COS(    Pi*x_out(2,:))*COS(0.5*Pi*x_in(3,:))
CASE(41) ! cos in xy with coupling  [-1;1]^2 (from https://arxiv.org/pdf/1809.01178.pdf, page 18) 
  x_out(1,:) = x_in(1,:)+ 0.15*COS(0.5*Pi*x_in( 1,:))*COS(1.5*Pi*x_in( 2,:))
  x_out(2,:) = x_in(2,:)+ 0.15*COS(2.0*Pi*x_out(1,:))*COS(0.5*Pi*x_in( 2,:))
  x_out(3,:) = x_in(3,:)
CASE(42) ! cos in xz with coupling  [-1;1]^2 (from https://arxiv.org/pdf/1809.01178.pdf, page 18) 
  x_out(1,:) = x_in(1,:)+ 0.15*COS(0.5*Pi*x_in( 1,:))*COS(1.5*Pi*x_in( 3,:))
  x_out(2,:) = x_in(2,:)
  x_out(3,:) = x_in(3,:)+ 0.15*COS(2.0*Pi*x_out(1,:))*COS(0.5*Pi*x_in( 3,:))
CASE(43) ! cos in yz with coupling  [-1;1]^2 (from https://arxiv.org/pdf/1809.01178.pdf, page 18) 
  x_out(1,:) = x_in(1,:)
  x_out(2,:) = x_in(2,:)+ 0.15*COS(0.5*Pi*x_in( 2,:))*COS(1.5*Pi*x_in( 3,:))
  x_out(3,:) = x_in(3,:)+ 0.15*COS(2.0*Pi*x_out(2,:))*COS(0.5*Pi*x_in( 3,:))
CASE(1000) !do nothing
  x_out(:,:)=x_in(:,:)

END SELECT

END SUBROUTINE PostDeformFunc

!===================================================================================================================================
! Height of the periodic hill (postdeform case 5) bottom wall as a function of x
!===================================================================================================================================
FUNCTION PHILL_H(X_in)
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
REAL,INTENT(IN) :: X_in    ! X coordinate
REAL            :: PHILL_H ! Height of periodic hill at given X
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
REAL           :: xloc
REAL,PARAMETER :: eps = 1.e-10
REAL,PARAMETER :: domain_size  =  9.
REAL,PARAMETER :: scale_factor = 28.
!-----------------------------------------------------------------------------------------------------------------------------------
! Hill geometry, the original geometry is given in a scaled system 28 times the size of the computational domain
xloc = X_in*scale_factor
IF(xloc.GT.(domain_size*scale_factor/2.)) xloc=scale_factor*domain_size-xloc ! The right side of the channel

! Between x=0. and x=9.
IF((xloc.GT.(-1.*eps)).AND.(xloc.LE.9.)) THEN
  PHILL_H = MIN(28.,&
             2.800000000000E+01          +0.000000000000E+00*xloc     &
            +6.775070969851E-03*xloc**2  -2.124527775800E-03*xloc**3)

! Between x=9. and x=14.
ELSEIF((xloc.GT.9.).AND.(xloc.LE.14.)) THEN
  PHILL_H =  2.507355893131E+01          +9.754803562315E-01*xloc     &
            -1.016116352781E-01*xloc**2  +1.889794677828E-03*xloc**3

! Between x=14. and x=20.
ELSEIF((xloc.GT.14.).AND.(xloc.LE.20.)) THEN
  PHILL_H =  2.579601052357E+01          +8.206693007457E-01*xloc     &
            -9.055370274339E-02*xloc**2  +1.626510569859E-03*xloc**3

! Between x=20. and x=30.
ELSEIF((xloc.GT.20.).AND.(xloc.LE.30.)) THEN
  PHILL_H =  4.046435022819E+01          -1.379581654948E+00*xloc     &
            +1.945884504128E-02*xloc**2  -2.070318932190E-04*xloc**3

! Between x=30. and x=40.
ELSEIF((xloc.GT.30.).AND.(xloc.LE.40.)) THEN
  PHILL_H =  1.792461334664E+01          +8.743920332081E-01*xloc     &
            -5.567361123058E-02*xloc**2  +6.277731764683E-04*xloc**3

! Between x=40. and x=54.
ELSEIF((xloc.GT.40.).AND.(xloc.LE.54.)) THEN
  PHILL_H = MAX(0.,&
              5.639011190988E+01          -2.010520359035E+00*xloc     &
             +1.644919857549E-02*xloc**2  +2.674976141766E-05*xloc**3)

! Between x=54. and middle of domain
ELSEIF(xloc.GT.54.) THEN
  PHILL_H = 0.
END IF

PHILL_H = PHILL_H/scale_factor ! Scale back to computational domain
END FUNCTION PHILL_H

!===================================================================================================================================
! Surface normal of the periodic hill (postdeform case 5) bottom wall as a function of x
!===================================================================================================================================
FUNCTION PHILL_NORMAL(X_in)
! IMPLICIT VARIABLE HANDLING
IMPLICIT NONE
!-----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
REAL,INTENT(IN) :: X_in            ! X coordinate
REAL            :: PHILL_NORMAL(2) ! 2D Normal vector at wall at given X
!-----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
REAL           :: xloc,hDeriv
REAL,PARAMETER :: eps = 1.e-10
REAL,PARAMETER :: domain_size  =  9.
REAL,PARAMETER :: scale_factor = 28.
!-----------------------------------------------------------------------------------------------------------------------------------
! Hill geometry, the original geometry is given in a scaled system 28 times the size of the computational domain
xloc = X_in*scale_factor
IF(xloc.GT.(domain_size*scale_factor/2.)) xloc=scale_factor*domain_size-xloc ! The right side of the channel

! Between x=0. and x=9.
IF((xloc.GT.(-1.*eps)).AND.(xloc.LE.9.)) THEN
  hDeriv =     0.000000000000E+00         &
           +2.*6.775070969851E-03*xloc    &
           -3.*2.124527775800E-03*xloc**2
! Between x=9. and x=14.
ELSEIF((xloc.GT.9.).AND.(xloc.LE.14.)) THEN
  hDeriv =     9.754803562315E-01         &
           -2.*1.016116352781E-01*xloc    &
           +3.*1.889794677828E-03*xloc**2

! Between x=14. and x=20.
ELSEIF((xloc.GT.14.).AND.(xloc.LE.20.)) THEN
  hDeriv =     8.206693007457E-01         &
           -2.*9.055370274339E-02*xloc    &
           +3.*1.626510569859E-03*xloc**2

! Between x=20. and x=30.
ELSEIF((xloc.GT.20.).AND.(xloc.LE.30.)) THEN
  hDeriv =    -1.379581654948E+00         &
           +2.*1.945884504128E-02*xloc    &
           -3.*2.070318932190E-04*xloc**2

! Between x=30. and x=40.
ELSEIF((xloc.GT.30.).AND.(xloc.LE.40.)) THEN
  hDeriv =     8.743920332081E-01         &
           -2.*5.567361123058E-02*xloc    &
           +3.*6.277731764683E-04*xloc**2

! Between x=40. and x=54.
ELSEIF((xloc.GT.40.).AND.(xloc.LE.54.)) THEN
  hDeriv =    -2.010520359035E+00         &
           +2.*1.644919857549E-02*xloc    &
           +3.*2.674976141766E-05*xloc**2

! Between x=54. and middle of domain
ELSEIF(xloc.GT.54.) THEN
  hDeriv = 0.
END IF

! Compute Normal Vector
IF(ABS(hDeriv).LT.eps) THEN
  PHILL_NORMAL=(/0.,1./)
ELSE
  ! This is the vector along the normal
  PHILL_NORMAL = (/ 1.,-1./hDeriv /)
  PHILL_NORMAL = PHILL_NORMAL/NORM2(PHILL_NORMAL)
END IF 
END FUNCTION PHILL_NORMAL

END MODULE MOD_Mesh_PostDeform
