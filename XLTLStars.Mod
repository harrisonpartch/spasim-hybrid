MODULE XLTLStars; (** AUTHOR "fnecati"; PURPOSE "Adjusted for commandline run"; *)

IMPORT
	Objects, Modules, XLTLGL, GL:=OpenGL, GLC := OpenGLConst, 
	Out:=KernelLog;


TYPE
	Stars = OBJECT
	VAR
		alive:BOOLEAN;	
	BEGIN {ACTIVE, SAFE,PRIORITY(Objects.Low)}
		alive:=TRUE;
		REPEAT
			Objects.Sleep(1000);  
			drawstars
		UNTIL   alive=FALSE;
		Out.Char('#');
	END Stars;

VAR
	stars:Stars;		

PROCEDURE drawstars*;
VAR
	i,j,k: LONGINT;
BEGIN
	GL.SetFCR(); 
	GL.glClear(GLC.GL_COLOR_BUFFER_BIT + GLC.GL_DEPTH_BUFFER_BIT); 
	GL.glBegin(GLC.GL_POINTS);
	FOR i:=-20 TO 20 DO FOR j:=-20 TO 20 DO FOR k:=-20 TO 20 DO
		GL.glVertex3f(i/10,j/10,k/10);
	END END END;
	GL.glEnd;
	GL.DelFCR();	
	GL.glXSwapBuffers(XLTLGL.display, XLTLGL.win); 
	Out.Char('*');
	Out.Ln;
END drawstars;


PROCEDURE Open*;
BEGIN
	
END Open;

PROCEDURE Close*;
BEGIN

END Close;

BEGIN	
	GL.InitOpenGL;
	Modules.InstallTermHandler(Close);
	NEW(stars);	
END XLTLStars.

XLTLStars.drawstars ~

XLTLStars.Close ~

SystemTools.FreeDownTo  XLTLGL ~ 