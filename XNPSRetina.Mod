MODULE XNPSRetina;
IMPORT  XNPSBase, Objects;

TYPE Ray=XNPSBase.Ray;
TYPE PT=XNPSBase.PT;

TYPE Subtile*=OBJECT		(* 5x5 ray tile. Traces with edge detection/interpolation *)
VAR
	i,j: LONGINT;		(*position of tile in XNPSBase.rays*)
	afteredge: INTEGER;
	
PROCEDURE & init(a,b: LONGINT);
BEGIN
	i:=a; j:=b;	
END init;

PROCEDURE edge(a,b: Ray):BOOLEAN;
VAR
	re,ge,be: BOOLEAN;
BEGIN
	re:=ABS(a.r-b.r)>EDGE;
	ge:=ABS(a.g-b.g)>EDGE;
	be:=ABS(a.b-b.b)>EDGE;	
	IF re OR ge OR be THEN RETURN TRUE ELSE RETURN FALSE END
END edge;

PROCEDURE edge3(a,b: Ray):BOOLEAN;
VAR
	re,ge,be: BOOLEAN;
BEGIN
	re:=ABS(a.r-b.r)>EDGE3;
	ge:=ABS(a.g-b.g)>EDGE3;
	be:=ABS(a.b-b.b)>EDGE3;	
	IF re OR ge OR be THEN RETURN TRUE ELSE RETURN FALSE END
END edge3;

PROCEDURE interpcolor(VAR a,b,c: Ray);
BEGIN
	c.r:=(a.r+b.r)/2;
	c.g:=(a.g+b.g)/2;
	c.b:=(a.b+b.b)/2;
END interpcolor;

PROCEDURE interpray(VAR a,b,c: Ray);
BEGIN
	interpPT(a.oxyz,b.oxyz,c.dxyz); 
	XNPSBase.normalizePT(c.dxyz);
	c.oxyz:=c.dxyz;
	IF c.dxyz.x < 0 THEN c.di := FALSE  ELSE c.di := TRUE END; 
	IF c.dxyz.y < 0 THEN c.dj := FALSE  ELSE c.dj := TRUE END;
	IF c.dxyz.z < 0 THEN c.dk := FALSE  ELSE c.dk := TRUE END;		
	XNPSBase.world.Shade(c);
END interpray;

PROCEDURE interpPT(VAR a,b,c: PT);
BEGIN
	c.x:=(a.x+b.x)/2;
	c.y:=(a.y+b.y)/2;
	c.z:=(a.z+b.z)/2;
END interpPT;

PROCEDURE black(VAR c: Ray);
BEGIN
	c.b:=0; c.r:=0; c.g:=0;
END black;


PROCEDURE trace;   
(*There are four initialized rays:
		aooob
		ooooo
		oozoo
		ooooo
		coood		*)  
VAR
	ii: LONGINT;
	eab,eac,ecd,ebd,eaz, ebz, ecz,edz: BOOLEAN;
	
BEGIN
	DEC(afteredge);
	XNPSBase.world.Shade(XNPSBase.rays[i,j]);
	XNPSBase.world.Shade(XNPSBase.rays[i+4,j]);
	XNPSBase.world.Shade(XNPSBase.rays[i+4,j+4]);
	XNPSBase.world.Shade(XNPSBase.rays[i,j+4]);
	interpray(XNPSBase.rays[i,j],XNPSBase.rays[i+4,j+4],XNPSBase.rays[i+2,j+2]);	
	eab:=edge(XNPSBase.rays[i,j],XNPSBase.rays[i+4,j]);
	eac:=edge(XNPSBase.rays[i,j],XNPSBase.rays[i,j+4]);	
	ecd:=edge(XNPSBase.rays[i+4,j],XNPSBase.rays[i+4,j+4]);	
	ebd:=edge(XNPSBase.rays[i,j+4],XNPSBase.rays[i+4,j+4]);
	eaz:=edge(XNPSBase.rays[i,j],XNPSBase.rays[i+2,j+2]);
	ebz:=edge(XNPSBase.rays[i+4,j],XNPSBase.rays[i+2,j+2]);
	ecz:=edge(XNPSBase.rays[i,j+4],XNPSBase.rays[i+2,j+2]);
	edz:=edge(XNPSBase.rays[i+4,j+4],XNPSBase.rays[i+2,j+2]);	
	IF eab OR eac OR ecd OR ebd OR eaz OR ebz OR ecz OR edz THEN	
		afteredge:= AFTER;
	END;
	IF (afteredge>0) THEN 		
		interpray(XNPSBase.rays[i,j],XNPSBase.rays[i+4,j],XNPSBase.rays[i+2,j]);
		interpray(XNPSBase.rays[i,j+4],XNPSBase.rays[i+4,j+4],XNPSBase.rays[i+2,j+4]);		
		interpray(XNPSBase.rays[i,j],XNPSBase.rays[i,j+4],XNPSBase.rays[i,j+2]);		
		interpray(XNPSBase.rays[i+4,j],XNPSBase.rays[i+4,j+4],XNPSBase.rays[i+4,j+2]);	
		IF edge3(XNPSBase.rays[i,j],XNPSBase.rays[i+2,j]) THEN
			interpray(XNPSBase.rays[i,j],XNPSBase.rays[i+2,j],XNPSBase.rays[i+1,j]);	 
		ELSE
			interpcolor(XNPSBase.rays[i,j],XNPSBase.rays[i+2,j],XNPSBase.rays[i+1,j]);	
		END;
		IF edge3(XNPSBase.rays[i+2,j],XNPSBase.rays[i+2,j+2]) THEN
			interpray(XNPSBase.rays[i+2,j],XNPSBase.rays[i+2,j+2],XNPSBase.rays[i+2,j+1]);	 
		ELSE
			interpcolor(XNPSBase.rays[i+2,j],XNPSBase.rays[i+2,j+2],XNPSBase.rays[i+2,j+1]);	
		END;			
		IF edge3(XNPSBase.rays[i,j],XNPSBase.rays[i,j+2]) THEN
			interpray(XNPSBase.rays[i,j],XNPSBase.rays[i,j+2],XNPSBase.rays[i,j+1]);	 
		ELSE
			interpcolor(XNPSBase.rays[i,j],XNPSBase.rays[i,j+2],XNPSBase.rays[i,j+1]);	
		END;	
		IF edge3(XNPSBase.rays[i,j+2],XNPSBase.rays[i+2,j+2]) THEN
			interpray(XNPSBase.rays[i,j+2],XNPSBase.rays[i+2,j+2],XNPSBase.rays[i+1,j+2]);	 
		ELSE
			interpcolor(XNPSBase.rays[i,j+2],XNPSBase.rays[i+2,j+2],XNPSBase.rays[i+1,j+2]);	
		END;			

		IF edge3(XNPSBase.rays[i+2,j],XNPSBase.rays[i+4,j]) THEN
			interpray(XNPSBase.rays[i+2,j],XNPSBase.rays[i+4,j],XNPSBase.rays[i+3,j]);	 
		ELSE
			interpcolor(XNPSBase.rays[i+2,j],XNPSBase.rays[i+4,j],XNPSBase.rays[i+3,j]);	
		END;
		IF edge3(XNPSBase.rays[i+4,j],XNPSBase.rays[i+4,j+2]) THEN
			interpray(XNPSBase.rays[i+4,j],XNPSBase.rays[i+4,j+2],XNPSBase.rays[i+4,j+1]);	 
		ELSE
			interpcolor(XNPSBase.rays[i+4,j],XNPSBase.rays[i+4,j+2],XNPSBase.rays[i+4,j+1]);	
		END;			
		IF edge3(XNPSBase.rays[i+2,j+2],XNPSBase.rays[i+4,j+2]) THEN
			interpray(XNPSBase.rays[i+2,j+2],XNPSBase.rays[i+4,j+2],XNPSBase.rays[i+3,j+2]);	 
		ELSE
			interpcolor(XNPSBase.rays[i+2,j+2],XNPSBase.rays[i+2,j+4],XNPSBase.rays[i+3,j+2]);	
		END;	

		IF edge3(XNPSBase.rays[i+2,j+2],XNPSBase.rays[i+2,j+4]) THEN
			interpray(XNPSBase.rays[i+2,j+2],XNPSBase.rays[i+2,j+4],XNPSBase.rays[i+2,j+3]);	 
		ELSE
			interpcolor(XNPSBase.rays[i+2,j+2],XNPSBase.rays[i+2,j+4],XNPSBase.rays[i+2,j+3]);	
		END;			
		IF edge3(XNPSBase.rays[i+2,j+4],XNPSBase.rays[i+4,j+4]) THEN
			interpray(XNPSBase.rays[i+2,j+4],XNPSBase.rays[i+4,j+4],XNPSBase.rays[i+3,j+4]);	 
		ELSE
			interpcolor(XNPSBase.rays[i+2,j+4],XNPSBase.rays[i+4,j+4],XNPSBase.rays[i+3,j+4]);	
		END;	
		IF edge3(XNPSBase.rays[i+4,j+2],XNPSBase.rays[i+4,j+4]) THEN
			interpray(XNPSBase.rays[i+4,j+2],XNPSBase.rays[i+4,j+4],XNPSBase.rays[i+4,j+3]);	 
		ELSE
			interpcolor(XNPSBase.rays[i+4,j+2],XNPSBase.rays[i+4,j+4],XNPSBase.rays[i+4,j+3]);
		END;	
		
		IF edge3(XNPSBase.rays[i,j+2],XNPSBase.rays[i,j+4]) THEN
			interpray(XNPSBase.rays[i,j+2],XNPSBase.rays[i,j+4],XNPSBase.rays[i,j+3]);	 
		ELSE
			interpcolor(XNPSBase.rays[i,j+2],XNPSBase.rays[i,j+4],XNPSBase.rays[i,j+3]);	
		END;	
		IF edge3(XNPSBase.rays[i,j+4],XNPSBase.rays[i+2,j+4]) THEN
			interpray(XNPSBase.rays[i,j+4],XNPSBase.rays[i+2,j+4],XNPSBase.rays[i+1,j+4]);	 
		ELSE
			interpcolor(XNPSBase.rays[i,j+4],XNPSBase.rays[i+2,j+4],XNPSBase.rays[i+1,j+4]);		
		END;				
		interpcolor(XNPSBase.rays[i,j],XNPSBase.rays[i+2,j+2],XNPSBase.rays[i+1,j+1]);
		interpcolor(XNPSBase.rays[i+4,j],XNPSBase.rays[i+2,j+2],XNPSBase.rays[i+3,j+1]);
		interpcolor(XNPSBase.rays[i,j+4],XNPSBase.rays[i+2,j+2],XNPSBase.rays[i+1,j+3]);
		interpcolor(XNPSBase.rays[i+4,j+4],XNPSBase.rays[i+2,j+2],XNPSBase.rays[i+3,j+3]);	
		IF SHOW THEN black(XNPSBase.rays[i+2,j+2]) END 
	ELSE
		interpcolor(XNPSBase.rays[i,j],XNPSBase.rays[i+4,j],XNPSBase.rays[i+2,j]);
		interpcolor(XNPSBase.rays[i,j],XNPSBase.rays[i+2,j],XNPSBase.rays[i+1,j]);	 
	 	interpcolor(XNPSBase.rays[i+2,j],XNPSBase.rays[i+4,j],XNPSBase.rays[i+3,j]);
		interpcolor(XNPSBase.rays[i,j+4],XNPSBase.rays[i+4,j+4],XNPSBase.rays[i+2,j+4]);
		interpcolor(XNPSBase.rays[i,j+4],XNPSBase.rays[i+2,j+4],XNPSBase.rays[i+1,j+4]);	 
	 	interpcolor(XNPSBase.rays[i+2,j+4],XNPSBase.rays[i+4,j+4],XNPSBase.rays[i+3,j+4]);
	 	FOR ii:=i TO i+4 DO
			interpcolor(XNPSBase.rays[ii,j],XNPSBase.rays[ii,j+4],XNPSBase.rays[ii,j+2]);
			interpcolor(XNPSBase.rays[ii,j],XNPSBase.rays[ii,j+2],XNPSBase.rays[ii,j+1]);	 
	 		interpcolor(XNPSBase.rays[ii,j+2],XNPSBase.rays[ii,j+4],XNPSBase.rays[ii,j+3]);	 	
	 	END	 	
	 END
END trace;
	
END Subtile;

TYPE Tile=OBJECT
VAR
	tile: ARRAY 5,5 OF Subtile;
	GO,DONE: BOOLEAN;
	
PROCEDURE & init(a,b: INTEGER);
VAR
	i,j: INTEGER;
BEGIN
	FOR i := 0 TO 4 DO
		FOR j :=  0 TO 4 DO	
			NEW(tile[i,j],a+5*i,b+5*j)
		END
	END 
END init;

PROCEDURE go;
BEGIN{EXCLUSIVE}
     GO:=TRUE;
END go;

PROCEDURE trace;
VAR
	i,j: INTEGER;
BEGIN
	FOR i := 0 TO 4 DO
		FOR j :=  0 TO 4 DO	
			tile[i,j].trace
		END
	END 
END trace;

BEGIN{ACTIVE, PRIORITY(Objects.Normal)}
	REPEAT
		BEGIN{EXCLUSIVE}
			AWAIT(GO);
		END;
		trace;
		BEGIN{EXCLUSIVE}
			GO:=FALSE;
			DONE:=TRUE;
			incTD;
		END;		
		UNTIL ~XNPSBase.worldalive
END Tile;

VAR
	tile: ARRAY XNPSBase.W25, XNPSBase.H25 OF Tile;
	a,b,FAST: INTEGER;
	tilesdone:INTEGER;
	EDGE*,EDGE3*: REAL;
	AFTER*: INTEGER;
	SHOW*:BOOLEAN;

PROCEDURE incTD;
BEGIN{EXCLUSIVE}
	INC(tilesdone);
END incTD;

PROCEDURE zeroTD;
BEGIN{EXCLUSIVE}
	tilesdone:=0;
END zeroTD;
		
PROCEDURE gotilesgo;
VAR
	i,j: INTEGER;
BEGIN{EXCLUSIVE}
	FOR i:= 0 TO XNPSBase.W25-1  DO
		FOR j:= 0 TO XNPSBase.H25-1 DO
			tile[i,j].go
		END
	END
END gotilesgo;

PROCEDURE go*;
VAR
	i,j,t: INTEGER;
BEGIN
	zeroTD;
	gotilesgo; 
	BEGIN{EXCLUSIVE} 
		AWAIT(tilesdone=XNPSBase.W25*XNPSBase.H25) 
	END
END go;

PROCEDURE gosinglecore*;
VAR
	i,j: INTEGER;
BEGIN
	FOR i:= 0 TO XNPSBase.W25-1  DO
		FOR j:= 0 TO XNPSBase.H25-1 DO
			tile[i,j].trace
		END
	END
END gosinglecore;

BEGIN 
	FOR a:= 0 TO XNPSBase.W25-1  DO
		FOR b:= 0 TO XNPSBase.H25-1 DO
			NEW(tile[a,b],a*25,b*25);
		END
	END;
	EDGE:=0.05;
	EDGE3:=0.0051;
	AFTER:=1;
END XNPSRetina.