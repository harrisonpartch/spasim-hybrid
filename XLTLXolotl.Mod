MODULE XLTLXolotl; (** AUTHOR "fnecati"; PURPOSE ""; *)
 (* axolotl-felix GL implemetation in Oberon
 	http://code.google.com/p/axolotl-felix/
 	 *)
 	 
IMPORT
	XLTLBase, XLTLMarsh, XLTLRenderer, Objects, Random, Out:=KernelLog;

CONST
	NCUBES=10;
VAR 
	cubes: ARRAY NCUBES OF cube;
	cubesdone:INTEGER;
	i: LONGINT;
	rand: Random.Generator;
	frameisalive, worldisalive:BOOLEAN;

TYPE cube=OBJECT
VAR
	x,y,z:REAL;
	GO, DONE: BOOLEAN;

PROCEDURE & new;
BEGIN
	x:=rand.Dice(6)-3;
	y:=rand.Dice(8)-4;
	z:=-rand.Dice(40)-10;
	Out.Char('^');
END new;

PROCEDURE go;
BEGIN
	Out.String("cube ");
	Out.Ln;
(*	XLTLRenderer.Cube(0,0,0,30+rand.Uniform()*10); *)
END go;

END cube;	

PROCEDURE gocubes;
VAR	
	i:LONGINT;
BEGIN
	Out.String("2.5... ");
	Out.Ln;
	FOR i:=0 TO 1 DO
		cubes[i].go
	END;
END gocubes;

PROCEDURE P*;
BEGIN
	
END P;

PROCEDURE close*;
BEGIN
	XLTLRenderer.Close
END close;
	
BEGIN
	NEW(rand);
	XLTLRenderer.Open; 
	XLTLMarsh.loadmarsh
END XLTLXolotl.

SystemTools.FreeDownTo  XLTLBase~

XLTLXolotl.P ~
XLTLXolotl.close ~
