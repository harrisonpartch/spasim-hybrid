MODULE XLTLBloom;

CONST 
	P=99397; (* P MUST BE THE LARGEST OF {P,Q,R,S} *)
	Q=85447;
	R=78049;
	S=67651

TYPE Filter*=OBJECT
VAR
	f: ARRAY P OF BOOLEAN;

PROCEDURE hash*(a,b,c,d: LONGINT);
VAR
	i: LONGINT;
BEGIN
	i:=a+1234567;
	i:=b+(i*512) + (i DIV 8388608)+7654321;
	
	i:=c+(i*512) + (i DIV 8388608)+1234567;
	i:=d+(i*512) + (i DIV 8388608)+7654321;
	i:=d+(i*512) + (i DIV 8388608);
	f[i MOD P]:=TRUE;
	f[i MOD Q]:=TRUE;	
(*	f[i MOD R]:=TRUE;
	f[i MOD S]:=TRUE	*)
END hash;

PROCEDURE flush*;
VAR
	i:LONGINT;
BEGIN
	FOR i:=0 TO P-1 DO
		f[i]:=FALSE
	END;
END flush;


PROCEDURE probe*(a,b,c,d:LONGINT):BOOLEAN;
VAR
	i: LONGINT;
BEGIN
	i:=a+1234567;
	i:=b+(i*512) + (i DIV 8388608)+7654321;
	i:=c+(i*512) + (i DIV 8388608)+1234567;
	i:=d+(i*512) + (i DIV 8388608)+7654321;
	i:=d+(i*512) + (i DIV 8388608);
	RETURN f[i MOD P]&f[i MOD Q](*&f[i MOD R]&f[i MOD S]*)
END probe;

END Filter;

END XLTLBloom.

