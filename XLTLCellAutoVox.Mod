MODULE XLTLCellAutoVox;
IMPORT XLTLBase, XLTLVoxel, Objects;

TYPE 	PT=XLTLBase.PT;
		Ray = XLTLBase.Ray;
		Voxel = XLTLBase.Voxel;
		Name = XLTLBase.Name;
		
CONST
	GREEN='g';
	BLUE='b';
	RED='r';
	N=1000;

TYPE CAVox*=OBJECT(XLTLVoxel.TVox)
VAR
	center*: PT;		(* in world coordinates! *)
	delta*: REAL;

PROCEDURE step;	
END step;
END CAVox;

TYPE FuseVox*=OBJECT(CAVox)
VAR
	greenf,burning1*, burning2*, burnt*: BOOLEAN;
	color:CHAR;

PROCEDURE set*(p:PT; size: LONGINT); 
BEGIN
	color:=GREEN;
	greenf:=TRUE;
	center.x:=(ENTIER(p.x*size))/size + 1/(2*size);
	center.y:=(ENTIER(p.y*size))/size + 1/(2*size);	
	center.z:=(ENTIER(p.z*size))/size + 1/(2*size);		
	delta:=0.55/size;
END set;

PROCEDURE probe*(x,y,z: REAL):Voxel;
BEGIN
	IF greenf THEN
		greenf:=FALSE;
		burning1:=TRUE;
		Engine.push(SELF)
	END;
	RETURN(SELF)
END probe;

PROCEDURE passprobe*(x,y,z: REAL):BOOLEAN;
BEGIN
	IF greenf THEN
		greenf:=FALSE;
		burning1:=TRUE;
		Engine.push(SELF);
	END;
	RETURN(passable);
END passprobe;

PROCEDURE step*;	
VAR
	v: Voxel
BEGIN
	IF burning1 THEN
		v:=XLTLBase.world.probe(center.x+delta,center.y,center.z);
		v:=XLTLBase.world.probe(center.x-delta,center.y,center.z);
		v:=XLTLBase.world.probe(center.x,center.y+delta,center.z);
		v:=XLTLBase.world.probe(center.x,center.y-delta,center.z);
		v:=XLTLBase.world.probe(center.x,center.y,center.z+delta);
		v:=XLTLBase.world.probe(center.x,center.y,center.z-delta);
		burning1:=FALSE;
		burning2:=TRUE;	
		color:=RED;
		anonyhook;
		Engine.push(SELF);	
	ELSIF burning2 THEN
		burning2:=FALSE;
		color:=GREEN;
		greenf:=TRUE
	END;	
END step;


PROCEDURE Shade*(VAR ray: Ray);
BEGIN
	CASE color OF
			GREEN:	green.Shade(ray)
		| 	RED:	red.Shade(ray)
		|	BLUE: 	blue.Shade(ray)
	END
END Shade;

PROCEDURE anonyhook;
BEGIN
	
END anonyhook;

END FuseVox;

TYPE GroVox*=OBJECT(FuseVox)
PROCEDURE anonyhook;	
VAR
	v: Voxel;
	g:GroVox;
BEGIN
	v:=XLTLBase.world.probe(center.x,center.y,center.z-delta);
	IF (v=NIL) OR v.passable THEN
		NEW(g);
		center.z:=center.z-delta;
		g.set(center,XLTLBase.avatarsize);
		g.burning2:=TRUE;
		XLTLBase.world.stroke(center,XLTLBase.avatarsize, g);
	END
END anonyhook;
END GroVox;


TYPE GateFuseVox*=OBJECT(FuseVox)
PROCEDURE step;	
VAR
	v: Voxel
BEGIN
	IF burning1 THEN
		v:=XLTLBase.world.probe(center.x+delta,center.y,center.z);
		burning1:=FALSE;
		burning2:=TRUE;	
		CASE color OF
				GREEN:	color:=RED
			| 	RED:	color:=BLUE
			|	BLUE: 	color:=GREEN
		END;
		Engine.push(SELF)	
	ELSIF burning2 THEN
		burning2:=FALSE;
		greenf:=TRUE
	END
END step;
PROCEDURE Shade (VAR ray: Ray);
BEGIN
	CASE color OF
			RED:	green.Shade(ray)
		| 	BLUE:	red.Shade(ray)
		|	GREEN: 	blue.Shade(ray)
	END
END Shade;

END GateFuseVox;

TYPE CAEngine=OBJECT
VAR
	Front, F2: ARRAY N OF CAVox;
	fn,i: LONGINT;
	
PROCEDURE push(v: CAVox);
BEGIN
	IF fn<N-1 THEN F2[fn]:=v; INC(fn) END
END push;

PROCEDURE tick*;
VAR i,n: LONGINT;
BEGIN
	FOR i:=0 TO fn-1 DO
		Front[i]:=F2[i]
	END;
	n:=fn;
	fn:=0;
	FOR i:=0 TO n-1 DO	
		Front[i].step;
	END;
END tick
	 
END CAEngine;

VAR
	Engine*: CAEngine;
	green*,blue*,red*: XLTLVoxel.fleetingTVox;
BEGIN
	NEW(Engine)
END XLTLCellAutoVox.
