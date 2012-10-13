MODULE XLTLRetina;
IMPORT  XLTLBase, Objects, Out:=KernelLog;

TYPE Ray=XLTLBase.Ray;
TYPE PT=XLTLBase.PT;

TYPE Subtile*=OBJECT		(* 5x5 ray tile. *)
VAR
	I,J: LONGINT;		(*position of tile in XLTLBase.rays*)	
	
PROCEDURE & init(a,b: LONGINT);
BEGIN
	I:=a; J:=b;	
END init;

PROCEDURE trace;   

VAR
	i,j: LONGINT;	
BEGIN
	FOR i := 0 TO 4 DO
		FOR j :=  0 TO 4 DO	
			XLTLBase.world.Shade(XLTLBase.rays[I+i,J+j]); 
		END
	END 
END trace;
	
END Subtile;

TYPE Tile=OBJECT
VAR
	subtile: ARRAY 5,5 OF Subtile;
	GO: BOOLEAN;
	
PROCEDURE & init(a,b: INTEGER);
VAR
	i,j: INTEGER;
BEGIN
	FOR i := 0 TO 4 DO
		FOR j :=  0 TO 4 DO	
			NEW(subtile[i,j],a+5*i,b+5*j)
		END
	END 
END init;

PROCEDURE trace;
VAR
	i,j: INTEGER;
BEGIN
	FOR i := 0 TO 4 DO
		FOR j :=  0 TO 4 DO	
			subtile[i,j].trace
		END
	END 
END trace;

PROCEDURE go;
BEGIN
	BEGIN{EXCLUSIVE}
    		 GO:=TRUE
    	END
END go;

BEGIN{ACTIVE, PRIORITY(Objects.Normal)}
	REPEAT
		BEGIN{EXCLUSIVE}
			AWAIT(GO);
		END;
		trace;
		BEGIN{EXCLUSIVE}
			GO:=FALSE
		END;
		incTD				
	UNTIL FALSE & ~XLTLBase.worldalive
END Tile;


VAR
	tile: ARRAY XLTLBase.W25, XLTLBase.H25 OF Tile;
	a,b: INTEGER;
	tilesdone:INTEGER;

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
BEGIN
	FOR i:= 0 TO XLTLBase.W25-1  DO
		FOR j:= 0 TO XLTLBase.H25-1 DO
			BEGIN
				tile[i,j].go
			END
		END	
	END;
END gotilesgo;

PROCEDURE go*;
VAR
	i,j: INTEGER;
BEGIN
	zeroTD;
	gotilesgo;
	BEGIN{EXCLUSIVE} 
		AWAIT(tilesdone=XLTLBase.W25*XLTLBase.H25);
	END;	
END go;

BEGIN 
	FOR a:= 0 TO XLTLBase.W25-1  DO
		FOR b:= 0 TO XLTLBase.H25-1 DO
			NEW(tile[a,b],a*25,b*25);
		END
	END
END XLTLRetina.