MODULE XLTLlife;	(* Soren Renner *)

IMPORT  Random, Kernel, Math, XLTLBase, XLTLE;

CONST
	N = 32;
	M = 32;
	V= 10;
	A = 80;
	B = 20;
	C = 0.03;

VAR
	random:Random.Generator;
	STOP: BOOLEAN;

TYPE PT=XLTLBase.PT;
TYPE Voxel = XLTLBase.Voxel;	

TYPE RDCellVox= OBJECT(Voxel);
PROCEDURE Shade (VAR ray: XLTLBase.Ray);
VAR
	l, x, y, z: REAL;
BEGIN

END Shade;
END RDCellVox; 

TYPE LifeVox*= OBJECT(Voxel);
VAR
	m : ARRAY M,N OF BOOLEAN;
	n: ARRAY M,N OF INTEGER;
	gen: INTEGER;
	i:LONGINT;
			
PROCEDURE &init*;
BEGIN
	seed;
	register;
END init;
			
PROCEDURE seed*;
VAR
	i,j:LONGINT;
BEGIN								
	FOR i := 1 TO M - 2 DO
		FOR j := 1 TO N - 2 DO
			IF random.Dice(5) = 0 THEN m[i, j] := TRUE ELSE m[i, j] := FALSE END;
		END
	END;
END seed;
			
PROCEDURE tick;
VAR
	i, j: LONGINT;
BEGIN	
	IF random.Dice(100) = 0 THEN seed END;	
	FOR i := 1 TO M - 2 DO
		FOR j := 1 TO N - 2 DO
			n[i,j] := 0;
			IF m[i-1,j-1] THEN INC(n[i,j]) END;
			IF m[i-1,j] THEN INC(n[i,j]) END;
			IF m[i-1,j+1] THEN INC(n[i,j]) END;
			IF m[i,j-1] THEN INC(n[i,j]) END;
			IF m[i,j+1] THEN INC(n[i,j]) END;
			IF m[i+1,j-1] THEN INC(n[i,j]) END;
			IF m[i+1,j] THEN INC(n[i,j]) END;
			IF m[i+1,j+1] THEN INC(n[i,j]) END;
		END
	END;
	FOR i := 1 TO M - 2 DO
		FOR j := 1 TO N - 2 DO
			IF m[i,j] THEN IF (n[i,j]=2) OR (n[i,j]=3) THEN ELSE m[i,j] := FALSE END;
			ELSIF n[i,j]=3 THEN m[i,j] := TRUE END;
		END
	END					 
END tick;

PROCEDURE Shade (VAR ray: XLTLBase.Ray);
VAR
	x,y: LONGINT;
	lx, ly, d: REAL;
	nx, ny, nz: INTEGER;
	dot: REAL;
	inside: BOOLEAN;
BEGIN
	CASE ray.face OF
		0: inside := TRUE
		|1: nx := -1
		|2: ny := -1
		|3: nz := -1
		|4: nx := 1
		|5: ny := 1
		|6: nz := 1
	ELSE
	END;
	CASE ray.face OF
		1: lx := ray.lxyz.y; ly :=  ray.lxyz.z;
		| 2:  lx := ray.lxyz.x; ly := ray.lxyz.z;
		| 3: lx := ray.lxyz.x; ly := ray.lxyz.y;
		| 4: lx := ray.lxyz.y; ly := ray.lxyz.z;
		| 5: lx := ray.lxyz.x; ly := ray.lxyz.z;
		| 6: lx := ray.lxyz.x; ly := ray.lxyz.y;
	ELSE
	END; 
	lx := lx*M; ly := ly*N;
	x :=  ENTIER(lx); y :=  ENTIER(ly);  
	IF x > (M-1) THEN x := M-1 END;
	IF y > (N-1) THEN y := N-1 END;
	IF inside THEN dot := 1 ELSE dot := ABS(nx*ray.dxyz.x + ny*ray.dxyz.y+ nz*ray.dxyz.z) END;
	IF m[x,y] THEN
		lx :=  (x+1/2)-lx; 
		lx := lx*lx;
		ly :=(y+1/2)-ly;
		ly := ly*ly;
	IF (lx+ly)< 0.70 THEN 
			CASE ray.face OF
				|1: nx := -1
				|2: ny := -1
				|3: nz := -1
				|4: nx := 1
				|5: ny := 1
				|6: nz := 1
			ELSE
			END;
			CASE ray.face OF
				1: 	 ray.dxyz.x:= -ray.dxyz.x; 
				|2:	ray.dxyz.y:= -ray.dxyz.y;
				|3:	ray.dxyz.z:= -ray.dxyz.z;
				|4: 	ray.dxyz.x:= -ray.dxyz.x; 
				|5:	ray.dxyz.y:= -ray.dxyz.y;
				|6:	ray.dxyz.z:= -ray.dxyz.z;
			ELSE
			END;
	
		ELSE
			
			ray.terminate:=TRUE;
		END 
	ELSE 

		ray.terminate:=TRUE;
	END;
END Shade;
END LifeVox;

TYPE RDVox*= OBJECT(Voxel);
VAR
		m1,m2,n1,n2 : ARRAY M,N OF REAL;
		gen: INTEGER;
		i:LONGINT;
		color: XLTLBase.COLOR;

PROCEDURE &init*;
BEGIN
	passable:=FALSE;
END init;	

PROCEDURE setcolor* (red, green, blue : REAL);
BEGIN
	color.red :=red ;
	color.green:= green;
	color.blue := blue;
END setcolor;	

PROCEDURE Shade (VAR ray: XLTLBase.Ray);
VAR

	lx, ly: REAL;
	
	nx, ny, nz: INTEGER;
	dot: REAL;
	inside: BOOLEAN;
BEGIN
	CASE ray.face OF
		1: lx := ray.lxyz.y; ly :=  ray.lxyz.z;
		| 2:  lx := ray.lxyz.x; ly := ray.lxyz.z;
		| 3: lx := ray.lxyz.x; ly := ray.lxyz.y;
		| 4: lx := ray.lxyz.y; ly := ray.lxyz.z;
		| 5: lx := ray.lxyz.x; ly := ray.lxyz.z;
		| 6: lx := ray.lxyz.x; ly := ray.lxyz.y;
	ELSE
	END; 
	CASE ray.face OF
		0: inside := TRUE
		|1: nx := -1
		|2: ny := -1
		|3: nz := -1
		|4: nx := 1
		|5: ny := 1
		|6: nz := 1
	ELSE
	END; 
	IF inside THEN dot := 1 ELSE dot := ABS(nx*ray.dxyz.x + ny*ray.dxyz.y+ nz*ray.dxyz.z) END; 


	ray.terminate:=TRUE;
END Shade;
END RDVox;

TYPE RDVolVox*=OBJECT(Voxel);
VAR
	m1*,m2,n1,n2: ARRAY V,V,V OF REAL;
	gen: INTEGER;
	i:LONGINT;
	tock*: INTEGER;
	BLUE: Voxel;
	RED: Voxel;
	YELLOW: Voxel;
	timer: Kernel.Timer;
	frame: LONGINT;

PROCEDURE &init*(red,blue,yellow: Voxel);
BEGIN
	RED := red;
	BLUE := blue;
	YELLOW:= yellow;
	IF RED=NIL THEN NEW(RED) END;
	IF BLUE=NIL THEN NEW(BLUE) END;	
	IF YELLOW=NIL THEN NEW(YELLOW) END;
		clere;
	seed;
	register;
	tock := 1;
END init;
			
PROCEDURE clere*;
VAR
	i,j,k:LONGINT;
BEGIN								
	FOR i := 0 TO V - 1 DO
		FOR j := 0 TO V - 1 DO
			FOR k := 0 TO V - 1 DO
				m1[i, j,k] := 0;
				m2[i, j,k] := 0;
				n1[i, j,k] := 0;
				n2[i, j,k] := 0
			END
		END
	END;
	gen := 0;
END clere;

PROCEDURE seed*;
VAR
	i,j,k:LONGINT;
BEGIN								
	FOR i := 0 TO V - 1 DO
		FOR j := 0 TO V - 1 DO
			FOR k := 0 TO V - 1 DO
				(* IF random.Dice(4) = 0 THEN m1[i, j,k] := 0.3  END *)
				IF ODD(i+j+k) THEN m1[i, j,k] := 0.3 END;
			END
		END
	END;
END seed;

PROCEDURE bounds (i, j, k: LONGINT; VAR out: BOOLEAN);
BEGIN
	IF (i < 0) OR (i > V-1) OR (j < 0) OR (j > V-1) OR (k < 0) OR (k > V-1) THEN
		out := TRUE
	ELSE
		out := FALSE
	END
END bounds;

PROCEDURE tick;
VAR
		i, j,k: LONGINT;
		nx1, nx2: REAL;
		A1, B1, C1, D1: REAL;
BEGIN
	INC(frame);
	IF TRUE OR (frame MOD tock = 0) THEN 
	FOR i := 1 TO V - 2 DO
		FOR j := 1 TO V - 2 DO
			FOR k := 1 TO V - 2 DO
				n1[i, j,k] := (* m1[i - 1, j, k] + *) m1[i + 1, j, k] + m1[i, j - 1, k] + m1[i, j + 1, k]
				 + m1[i,j, k-1] +  m1[i, j, k+1];
			END
		END
	END;
	C1 := C;
	D1 := 1;
	IF D1 < 0 THEN D1 := 0 END;
	A1 := A;
	B1 := B;
	FOR i := 1 TO V - 2 DO
(*		A1 := A + i/10;
		B1 := B; *)
		FOR j := 1 TO V - 2 DO
			B1 := B1 + 0.08;
			FOR k := 1 TO V-1 DO
				(*  HERE ARE THE DIFFERENCE RULES! *)
				m1[i, j, k] := m1[i, j, k] + (n1[i, j, k] /A1 - m2[i, j, k])*D1;  
				m2[i, j, k] := m2[i, j, k] +  (m1[i, j, k] /B1 - C1);
				IF m1[i, j, k] < 0 THEN m1[i, j, k] := 0 END;
				IF m2[i, j, k] < 0 THEN m2[i, j, k] := 0 END;
				IF m1[i, j, k] > 1 THEN m1[i, j, k] := 1 END;
				IF m2[i, j, k] > 1 THEN m2[i, j, k] := 1 END;
			END
		END;
	END;
	END;
 END tick;

PROCEDURE probe(x,y,z: REAL):Voxel;
VAR
	X,Y,Z: REAL;
	i,j,k: LONGINT;
	color: LONGINT;
BEGIN
	XLTLBase.clamp3(x,y,z);
	X := x*V; Y := y*V; Z := z*V;
	i := ENTIER(X); 
	j := ENTIER(Y);
	k := ENTIER(Z);
	color := ENTIER(10*m1[i,j,k]);	
	IF color < 3 THEN 
		RETURN(NIL)
	ELSE
		RETURN(YELLOW) 
	END
END probe;

PROCEDURE Shade (VAR ray: XLTLBase.Ray);
VAR
	oldxyz: XLTLBase.PT;
	drx, dry, drz: REAL;
	iter, di, dj, dk: INTEGER;
	out: BOOLEAN;
	v: Voxel;
	ijk: XLTLBase.IPT;
	lx, ly, lz, distance: REAL;
	color: LONGINT;
BEGIN
		oldxyz := ray.xyz;
		ray.xyz.x := ray.lxyz.x * V- ray.dxyz.x / 1000000;
		ray.xyz.y := ray.lxyz.y * V- ray.dxyz.y / 1000000;		
		ray.xyz.z := ray.lxyz.z * V- ray.dxyz.z / 1000000; 
		XLTLE.E(ray.xyz,ijk);
		bounds(ijk.i,ijk.j,ijk.k, out);
		IF ~out THEN
			ray.lxyz.x := ABS(ray.xyz.x - ijk.i);
			ray.lxyz.y := ABS(ray.xyz.y - ijk.j);
			ray.lxyz.z := ABS(ray.xyz.z - ijk.k);
			color := ENTIER(10*m1[ijk.i,ijk.j,ijk.k]);
			CASE color OF
				0: RED.Shade(ray)
				|1: RED.Shade(ray)
				|2: RED.Shade(ray)
				|3: YELLOW.Shade(ray)
				|4: BLUE.Shade(ray)
				|5: YELLOW.Shade(ray)
				|6: BLUE.Shade(ray)
				|7: YELLOW.Shade(ray)
				|8: BLUE.Shade(ray)
				|9: YELLOW.Shade(ray)
			ELSE
				RED.Shade(ray)
			END;
		END;
		IF ~ray.changed THEN
			REPEAT
				ray.changed := FALSE;
				IF ray.dxyz.x < 0 THEN di := - 1  ELSE di := 1 END;
				IF ray.dxyz.y < 0 THEN dj := - 1  ELSE dj := 1 END;
				IF ray.dxyz.z< 0 THEN dk := - 1  ELSE dk := 1 END;
				REPEAT
					IF di > 0 THEN
						drx := ( (ijk.i + 1) - ray.xyz.x) / ray.dxyz.x
					ELSE
						drx :=  (ijk.i -  ray.xyz.x) / ray.dxyz.x
					END;
					IF dj > 0 THEN
						dry := ( (ijk.j + 1) - ray.xyz.y) / ray.dxyz.y
					ELSE
						dry :=  (ijk.j - ray.xyz.y) / ray.dxyz.y
					END;
					IF dk > 0 THEN
						drz := ( (ijk.k + 1) - ray.xyz.z) / ray.dxyz.z
					ELSE
						drz :=  (ijk.k - ray.xyz.z) / ray.dxyz.z
					END;
					IF (drx < dry) THEN
						IF (drx < drz ) THEN
							INC(ijk.i, di);
							IF di > 0 THEN ray.face := 1 ELSE ray.face := 4 END;
							ray.xyz.x := ray.xyz.x + drx * ray.dxyz.x; ray.xyz.y := ray.xyz.y + drx * ray.dxyz.y; ray.xyz.z  := ray.xyz.z + drx * ray.dxyz.z
						ELSE
							INC(ijk.k, dk);
							IF dk > 0 THEN ray.face := 3 ELSE ray.face := 6 END;
							ray.xyz.x := ray.xyz.x + drz * ray.dxyz.x; ray.xyz.y := ray.xyz.y + drz * ray.dxyz.y; ray.xyz.z  := ray.xyz.z + drz * ray.dxyz.z
						END
					ELSIF (dry < drz) THEN
						INC(ijk.j, dj);
						IF dj > 0 THEN ray.face := 2 ELSE ray.face := 5 END;
						ray.xyz.x := ray.xyz.x + dry * ray.dxyz.x; ray.xyz.y := ray.xyz.y + dry * ray.dxyz.y; ray.xyz.z  := ray.xyz.z+ dry * ray.dxyz.z
					ELSE
						INC(ijk.k, dk);
						IF dk > 0 THEN ray.face := 3 ELSE ray.face := 6 END;
						ray.xyz.x := ray.xyz.x + drz * ray.dxyz.x; ray.xyz.y := ray.xyz.y + drz * ray.dxyz.y; ray.xyz.z  := ray.xyz.z + drz * ray.dxyz.z
					END;
					bounds(ijk.i,ijk.j,ijk.k, out);
					IF ~out THEN
						ray.lxyz.x := ABS(ray.xyz.x - ijk.i);
						ray.lxyz.y := ABS(ray.xyz.y - ijk.j);
						ray.lxyz.z := ABS(ray.xyz.z - ijk.k);			
						color := ENTIER(10*m1[ijk.i,ijk.j,ijk.k]);
						CASE color OF
							0: RED.Shade(ray)
							|1: RED.Shade(ray)
							|2: RED.Shade(ray)
							|3: YELLOW.Shade(ray)
							|4: BLUE.Shade(ray)
							|5: YELLOW.Shade(ray)
							|6: BLUE.Shade(ray)
							|7: YELLOW.Shade(ray)
							|8: BLUE.Shade(ray)
							|9: YELLOW.Shade(ray)
						ELSE
						END;

					END;
				UNTIL   ray.terminate OR out OR ray.changed;
			UNTIL   ray.terminate OR out;
		END;
		ray.xyz := oldxyz;
END Shade;

END RDVolVox;

TYPE RDCloud*=OBJECT(RDVolVox);

PROCEDURE tick;
VAR
		i, j,k: LONGINT;
		nx1, nx2: REAL;
		A1, B1, C1, D1: REAL;
BEGIN
	FOR i := 1 TO V - 2 DO
		FOR j := 1 TO V - 2 DO
			FOR k := 1 TO V - 2 DO
				n1[i, j,k] := m1[i - 1, j, k] + m1[i + 1, j, k] + m1[i, j - 1, k] + m1[i, j + 1, k]
				 + m1[i,j, k-1] +  m1[i, j, k+1];
			END
		END
	END;
	C1 := C;
	D1 := 1;
	IF D1 < 0 THEN D1 := 0 END;
	FOR i := 1 TO V - 2 DO
		A1 := A + i/10;
		B1 := B;
		FOR j := 1 TO V - 2 DO
			B1 := B1 + 0.08;
			FOR k := 1 TO V-1 DO
				(*  HERE ARE THE DIFFERENCE RULES! *)
				m1[i, j, k] := m1[i, j, k] + (n1[i, j, k] /A1 - m2[i, j, k])*D1;  
				m2[i, j, k] := m2[i, j, k] +  (m1[i, j, k] /B1 - C1);
				IF m1[i, j, k] < 0 THEN m1[i, j, k] := 0 END;
				IF m2[i, j, k] < 0 THEN m2[i, j, k] := 0 END;
				IF m1[i, j, k] > 1 THEN m1[i, j, k] := 1 END;
				IF m2[i, j, k] > 1 THEN m2[i, j, k] := 1 END;
			END
		END;
	END;
END tick;

END RDCloud;
		
PROCEDURE STOPGO*;
BEGIN
	STOP:= ~STOP;
END STOPGO;

PROCEDURE normalize(VAR x,y,z: REAL);
VAR d: REAL;
BEGIN
	d := Math.sqrt(x*x+y*y+z*z);  (* Norma! Liza! Ray! Front and center, oh dark thirty!*)
	x := x/d; y := y/d; z:=z/d;
END normalize;

PROCEDURE reflect(VAR x,y,z: REAL; nx,ny,nz:REAL);
VAR 
	dot: REAL;
BEGIN
	dot := x*nx+y*ny+z*nz;
	nx := 2*nx*dot; ny := 2*ny*dot; nz := 2*nz*dot;
	x := x-nx; y := y-ny; z := z-nz; 
END reflect;


BEGIN
	NEW(random);	
END XLTLlife.

