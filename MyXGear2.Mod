MODULE MyXGear2; (** AUTHOR "fnecati"; PURPOSE "Adjusted for commandline run"; *)

(* Test: FULLSCREEN,  Press F1, F11 F12,  window close events*)
(* inspired from: htp://gpwiki.org/index.php/OpenGL:Tutorials:Setting_up_OpenGL_on_X11   *)

(*!   fullscreen messages  *)
IMPORT
	X11, Api := X11Api, GL:=OpenGL, GLC := OpenGLConst, Kernel, Inputs, KS := X11KeySymDef,
	
	Trace,  Math , Raster, WMGraphics,  SYSTEM, V := XF86VMode, KernelLog, Strings ;

(* 
Opens a native X11 window and renders. 
From command line, linux terminal, run with : aos  -x  MyXGear6.Open 
or 
 from oberon window:   MyXGear6.Open ~
*)


CONST 
	debug = TRUE; (* for window creation/closing *)
	debugevents = TRUE; (* for testing events *)
	
	 (* show window with window decorations *)
	
	pi = Math.pi;
	TITLE= "Oberon GL Gear";
	
TYPE PChar = POINTER TO ARRAY OF CHAR;
	
	Hints = RECORD
		flags: SET;
		functions: LONGINT;
		decorations: LONGINT;
		inputMode: LONGINT;
		status: LONGINT;
	END;
		

VAR
	timer : Kernel.MilliTimer; 


	display: X11.DisplayPtr;
	screen: LONGINT;	
	win: X11.Window; (* our window instance *)
	glctx : GL.GLXContext;  (* GL context *)
	
	fullscreen, fullwindow, windecorations : BOOLEAN;
	
	doubleBuffered: BOOLEAN;   	
	winAttr : Api.XSetWindowAttributes; (* set window attributes*)
	wmDelete: X11.Atom;

(* original desktop mode which we save so we can restore it later *)

	 desktopMode: V.XF86VidModeModeInfo;
	 x, y: LONGINT;
	width, height : LONGINT; (* size of window *)
	depth: LONGINT;
	
	alive : BOOLEAN; (* for main loop control *)	
	
CONST
	ML = 0;  MM = 1;  MR = 2;

	Button1Bit = 8; Button2Bit = 9; Button3Bit =10;
	ShiftKeyBit = 0;  ShiftLockBit = 1;  ControlKeyBit = 2;  Mod1KeyBit = 3;
	Mod2KeyBit = 4;  Mod3KeyBit = 5;  Mod4KeyBit = 6;  Mod5KeyBit = 7;
	
VAR
	event: Api.XEvent;  xbuttons: SET;
	compstatus: X11.ComposeStatus;

	MMseen, MRseen: BOOLEAN;
	noEventCount: LONGINT;


VAR
	keySymbol: ARRAY 256 OF LONGINT;
	currX, currY: LONGINT;
		  
  (*  gear variables *)
  	gear1, gear2, gear3: GL.GLuint;
  	rotx, roty, rotz, angle: GL.GLfloat;	


PROCEDURE  MakeGear (innerRadius, outerRadius, width: GL.GLfloat; teeth: LONGINT;  toothDepth: GL.GLfloat);
VAR  r0, r1, r2 , angle, da, u, v, len: GL.GLfloat;
	  i: LONGINT;
BEGIN 
	
	r0 := innerRadius;
	r1 := outerRadius - toothDepth / 2.0;
	r2 := outerRadius + toothDepth / 2.0;
	
	da := 2.0 * pi / teeth / 4.0;
	
	GL.glShadeModel(GLC.GL_FLAT);

	GL.glNormal3f(0.0, 0.0, 1.0);

	(* draw front face *)
	GL.glBegin(GLC.GL_QUAD_STRIP);

	FOR  i := 0 TO teeth DO 
			angle := i * 2.0 * Math.pi / teeth;
			GL.glVertex3f(r0 * Math.cos(angle), r0 * Math.sin(angle), width * 0.5);
			GL.glVertex3f(r1 * Math.cos(angle), r1 * Math.sin(angle), width * 0.5);
			GL.glVertex3f(r0 * Math.cos(angle), r0 * Math.sin(angle), width * 0.5);
			GL.glVertex3f(r1 * Math.cos(angle + 3 * da), r1 * Math.sin(angle + 3 * da), width * 0.5);
	END;
	GL.glEnd;

	(* draw front sides of teeth *)
	GL.glBegin(GLC.GL_QUADS);
		da := 2.0 * Math.pi / teeth / 4.0;
		FOR  i := 0 TO teeth - 1 DO 
			angle := i * 2.0 * Math.pi / teeth;
			GL.glVertex3f(r1 * Math.cos(angle), r1 * Math.sin(angle), width * 0.5);
			GL.glVertex3f(r2 * Math.cos(angle + da), r2 * Math.sin(angle + da), width * 0.5);
			GL.glVertex3f(r2 * Math.cos(angle + 2 * da), r2 * Math.sin(angle + 2 * da), width * 0.5);
			GL.glVertex3f(r1 * Math.cos(angle + 3 * da), r1 * Math.sin(angle + 3 * da), width * 0.5);
		END;
	GL.glEnd;

	GL.glNormal3f(0.0, 0.0, -1.0);

	(* draw back face *)
	GL.glBegin(GLC.GL_QUAD_STRIP);

	 FOR i := 0 TO teeth DO 
			angle := i * 2.0 * Math.pi / teeth;
			GL.glVertex3f(r1 * Math.cos(angle), r1 * Math.sin(angle), -width * 0.5);
			GL.glVertex3f(r0 * Math.cos(angle), r0 * Math.sin(angle), -width * 0.5);
			GL.glVertex3f(r1 * Math.cos(angle + 3 * da), r1 * Math.sin(angle + 3 * da), -width * 0.5);
			GL.glVertex3f(r0 * Math.cos(angle), r0 * Math.sin(angle), -width * 0.5);
	END;
	GL.glEnd;

	(* draw back sides of teeth *)
	GL.glBegin(GLC.GL_QUADS);
		da := 2.0 * Math.pi / teeth / 4.0;
		FOR i := 0 TO teeth - 1 DO
			angle := i * 2.0 * Math.pi / teeth;
			GL.glVertex3f(r1 * Math.cos(angle + 3 * da), r1 * Math.sin(angle + 3 * da), -width * 0.5);
			GL.glVertex3f(r2 * Math.cos(angle + 2 * da), r2 * Math.sin(angle + 2 * da), -width * 0.5);
			GL.glVertex3f(r2 * Math.cos(angle + da), r2 * Math.sin(angle + da), -width * 0.5);
			GL.glVertex3f(r1 * Math.cos(angle), r1 * Math.sin(angle), -width * 0.5);
	END;
	GL.glEnd;

	(* draw outward faces of teeth *)
	GL.glBegin(GLC.GL_QUAD_STRIP);

	FOR i := 0 TO teeth - 1 DO 
			angle := i * 2.0 * Math.pi / teeth;
			GL.glVertex3f(r1 * Math.cos(angle), r1 * Math.sin(angle), width * 0.5);
			GL.glVertex3f(r1 * Math.cos(angle), r1 * Math.sin(angle), -width * 0.5);
			u := r2 * Math.cos(angle + da) - r1 * Math.cos(angle);
			v := r2 * Math.sin(angle + da) - r1 * Math.sin(angle);
			len := Math.sqrt(u * u + v * v);
			u := u / len;  v := v / len;
			GL.glNormal3f(v, -u, 0.0);
			GL.glVertex3f(r2 * Math.cos(angle + da), r2 * Math.sin(angle + da), width * 0.5);
			GL.glVertex3f(r2 * Math.cos(angle + da), r2 * Math.sin(angle + da), -width * 0.5);
			GL.glNormal3f(Math.cos(angle), Math.sin(angle), 0.0);
			GL.glVertex3f(r2 * Math.cos(angle + 2 * da), r2 * Math.sin(angle + 2 * da), width * 0.5);
			GL.glVertex3f(r2 * Math.cos(angle + 2 * da), r2 * Math.sin(angle + 2 * da), -width * 0.5);
			u := r1 * Math.cos(angle + 3 * da) - r2 * Math.cos(angle + 2 * da);
			v := r1 * Math.sin(angle + 3 * da) - r2 * Math.sin(angle + 2 * da);
			GL.glNormal3f(v, -u, 0.0);
			GL.glVertex3f(r1 * Math.cos(angle + 3 * da), r1 * Math.sin(angle + 3 * da), width * 0.5);
			GL.glVertex3f(r1 * Math.cos(angle + 3 * da), r1 * Math.sin(angle + 3 * da), -width * 0.5);
			GL.glNormal3f(Math.cos(angle), Math.sin(angle), 0.0);
	END;

	GL.glVertex3f(r1 * Math.cos(0), r1 * Math.sin(0), width * 0.5);
	GL.glVertex3f(r1 * Math.cos(0), r1 * Math.sin(0), -width * 0.5);

	GL.glEnd;

	GL.glShadeModel(GLC.GL_SMOOTH);

	(* draw inside radius cylinder *)
	GL.glBegin(GLC.GL_QUAD_STRIP);
	FOR i := 0 TO teeth DO
			angle := i * 2.0 * Math.pi / teeth;
			GL.glNormal3f(-Math.cos(angle), -Math.sin(angle), 0.0);
			GL.glVertex3f(r0 * Math.cos(angle), r0 * Math.sin(angle), -width * 0.5);
			GL.glVertex3f(r0 * Math.cos(angle), r0 * Math.sin(angle), width * 0.5);
	END;	
	GL.glEnd;
END MakeGear;

PROCEDURE  InitGears;
VAR
	red, green, blue, lightPos: ARRAY [4] OF GL.GLfloat; 
	
BEGIN 
	rotx := 20;  roty := 30;  rotz := 0;  angle := 20;

(*	(* lightPos := [ 5.0, 5.0, 10.0, 1.0];*)
	lightPos := [ 1.0, 1.0, 1.0, 0.0];  (* directional *)
	red := [ 0.8, 0.1, 0.0, 1.0];  
	green := [ 0.0, 0.8, 0.2, 1.0];  
	blue := [ 0.2, 0.2, 1.0, 1.0];
*)

    lightPos[0] := 5.0;	lightPos[1] := 5.0;  lightPos[2] := 10.0; lightPos[3] := 1.0;
    red[0] := 0.8; red[1] := 0.1; red[2] := 0.0; red[3] := 1.0;
    green[0] := 0.0; green[1] := 0.8; green[2] := 0.2; green[3] := 1.0;
    blue[0] := 0.2; blue[1] := 0.2; blue[2] := 1.0; blue[3] := 1.0;

	GL.glLightfv(GLC.GL_LIGHT0, GLC.GL_POSITION, SYSTEM.ADR(lightPos[0]));
	GL.glEnable(GLC.GL_CULL_FACE);
	GL.glEnable(GLC.GL_LIGHTING);			
	GL.glEnable(GLC.GL_LIGHT0);
	GL.glEnable(GLC.GL_DEPTH_TEST);
	
	(* make the gears *)
	gear1 := GL.glGenLists(1);
	GL.glNewList(gear1, GLC.GL_COMPILE);
	GL.glMaterialfv(GLC.GL_FRONT, GLC.GL_AMBIENT_AND_DIFFUSE, SYSTEM.ADR(red[0]));
	MakeGear( 1.0, 4.0, 1.0, 20, 0.7);
	GL.glEndList;

	
	gear2 := GL.glGenLists(1);
	GL.glNewList(gear2, GLC.GL_COMPILE);
	GL.glMaterialfv(GLC.GL_FRONT, GLC.GL_AMBIENT_AND_DIFFUSE, SYSTEM.ADR(green[0]));
	MakeGear( 0.5, 2.0, 2.0, 10, 0.7);
	GL.glEndList;

	
	gear3 := GL.glGenLists(1);	
	GL.glNewList(gear3, GLC.GL_COMPILE);
	GL.glMaterialfv(GLC.GL_FRONT, GLC.GL_AMBIENT_AND_DIFFUSE, SYSTEM.ADR(blue[0]));
	MakeGear(1.3, 2.0, 0.5, 10, 0.7);
	GL.glEndList;

	 GL.glEnable(GLC.GL_NORMALIZE); 		
END InitGears;


PROCEDURE DrawGears();
VAR angle1, angle2: REAL;
BEGIN

angle1 := -2.0 * angle - 9.0;
angle2 := -2.0 * angle - 25.0;

GL.SetFCR(); 
	GL.glClear(GLC.GL_COLOR_BUFFER_BIT + GLC.GL_DEPTH_BUFFER_BIT);

	GL.glPushMatrix;
	
	GL.glRotatef(rotx, 1.0, 0.0, 0.0);
	GL.glRotatef(roty, 0.0, 1.0, 0.0);
	GL.glRotatef(rotz, 0.0, 0.0, 1.0);
	
	
	GL.glPushMatrix;
	GL.glTranslatef(-3.0, -2.0, 0.0);
	GL.glRotatef(angle, 0.0, 0.0, 1.0);
	GL.glCallList(gear1);
	GL.glPopMatrix;
	
	GL.glPushMatrix;
	GL.glTranslatef(3.1, -2.0, 0.0);
	GL.glRotatef(angle1, 0.0, 0.0, 1.0);
	GL.glCallList(gear2);
	GL.glPopMatrix;
	
	GL.glPushMatrix;
	GL.glTranslatef(-3.1, 4.2, 0.0);
	GL.glRotatef(angle2, 0.0, 0.0, 1.0);
	GL.glCallList(gear3);
	GL.glPopMatrix;

	GL.glPopMatrix;	

 GL.DelFCR();
 
     GL.glXSwapBuffers(display, win);
END DrawGears;

PROCEDURE Reshape(w, h: LONGINT);

BEGIN
GL.SetFCR();
	GL.glViewport(0, 0, w, h);
	GL.glClearColor(0.0, 0.0, 0.0, 0.0);
	GL.glMatrixMode(GLC.GL_PROJECTION);
	GL.glLoadIdentity();
	GL.glFrustum(-1, 1, -1, 1, 5, 100); 
	GL.glMatrixMode(GLC.GL_MODELVIEW);
	GL.glLoadIdentity(); 
	GL.glScaled(h/w, 1,1);
	GL.glTranslatef(0.0, 0.0, -40.0);
GL.DelFCR();
END Reshape;

(* close the window and its resources *)
 PROCEDURE Close;
  VAR res: LONGINT;
 BEGIN
	(* do we have a rendering context *)
	IF glctx # 0 THEN
		(* Release the context *)
	    	res := GL.glXMakeCurrent(display, 0, 0);
	    	(* Delete the context *)
		GL.glXDestroyContext(display, glctx);
		glctx := 0;
		IF debug THEN Trace.String("context deleted"); Trace.Ln; END;
	END;

	(* switch back to original desktop resolution if we were in fullscreen *)
	IF fullscreen THEN                                                                             
		res := V.XF86VidModeSwitchToMode(display, screen, desktopMode);
		res := V.XF86VidModeSetViewPort(display, screen, 0, 0); 
	END;                 

	
	(* do we have a window *)
	IF win # 0 THEN
		(* Unmap the window*)
		Api.UnmapWindow(display, win);
		(* Destroy the window *)
		res:= Api.DestroyWindow(display, win);
		win := 0;
		IF debug THEN Trace.String("window deleted"); Trace.Ln; END;
	END;
	
	(* do we have a display *)
	IF display # 0 THEN	
		res := Api.CloseDisplay(display);
		IF debug THEN Trace.String("display deleted"); Trace.Ln; END;
	END;
	
 END Close;
 
PROCEDURE  InitWindow(): BOOLEAN;
VAR 
	res: LONGINT;
	masks: SET;
	buf: X11.Buffer;
	
	visinfoptr : Api.VisualInfoPtr; (* pointer to X11 VisualInfo *)
	cmap : X11.Colormap; (* colormap for window *)
	att : ARRAY [*] OF GL.GLint;  (* attributes of GL window *) 
	glxMajor, glxMinor, wmMajor, wmMinor: LONGINT;
	dispWidth, dispHeight: LONGINT;
	modes : V.PPXF86VidModeModeInfo;
	bmodes : V.XF86VidModeModeInfo;
	modnum, bestmode: LONGINT;

	i: LONGINT;
	
BEGIN
	display := Api.OpenDisplay(":0.0");
	IF display =0 THEN
		Trace.String(" cannot connect to X server"); Trace.Ln; 			
		RETURN FALSE;
	END;  

	screen := X11.DefaultScreen(display);
	res := V.XF86VidModeQueryVersion(display, wmMajor, wmMinor);
	IF debug THEN
		Trace.String("XF86 VideoMode extension version "); 
		Trace.Int(wmMajor,0); Trace.Char("."); 
		Trace.Int(wmMinor,0); Trace.Ln;
	END;
   	
   	
	res := V.VidModeGetAllModeLines(display, screen, modes); 
	modnum := LEN(modes,0);
  
	(* save desktop-resolution before switching modes *)
	desktopMode := modes[0]^;
	IF debug THEN		
		Trace.String("desktopMode=");
		Trace.Int( desktopMode.hdisplay, 6); 
		Trace.Int(desktopMode.vdisplay, 6); Trace.Ln; 	
		Trace.String(" # of modes= "); Trace.Int(modnum,0); Trace.Ln; 
	END;
   
	bestmode := 0;  (* set best mode to current *)
   
	(* look for mode with requested resolution *)
	 FOR i:=0 TO modnum-1 DO
 		bmodes := modes[i]^;
 		IF (bmodes.hdisplay=width) & (bmodes.vdisplay = height) THEN bestmode:=i; END;
 		IF debug THEN
 			Trace.Int(i+1, 0); Trace.Char(":");
 			Trace.Int( bmodes.hdisplay, 6);
			Trace.Int(bmodes.vdisplay, 6); Trace.Ln;
		END;
	 END;
	bmodes := modes[bestmode]^;
	dispWidth := bmodes.hdisplay;
	dispHeight := bmodes.vdisplay;
 
 	IF debug THEN  
		Trace.String("bestmode: "); Trace.Int(bestmode,0); Trace.Ln;
		Trace.String("resolution:  "); Trace.Int(dispWidth,0); Trace.Char("x"); Trace.Int(dispHeight, 0); Trace.Ln;
 	END;  
   
	doubleBuffered := TRUE;
	
(*  NEW(att, 13);
  att[0] := GLC.GLX_RGBA;
  att[1] := GLC.GLX_DOUBLEBUFFER;
  att[2] := GLC.GLX_DEPTH_SIZE;		att[3] := 24; 
  att[4] := GLC.GLX_STENCIL_SIZE;	att[5] := 8;
  att[6] := GLC.GLX_RED_SIZE;  		att[7] := 8;
  att[8] := GLC.GLX_GREEN_SIZE;	att[9] := 8;
  att[10] := GLC.GLX_RED_SIZE;		att[11] := 8;
  att[12] := 0 ;
*)

 NEW(att, 11);
  att[0] := GLC.GLX_RGBA;
  att[1] := GLC.GLX_DOUBLEBUFFER;
  att[2] := GLC.GLX_DEPTH_SIZE;		att[3] := 16; 
  att[4] := GLC.GLX_RED_SIZE;  		att[5] := 4;
  att[6] := GLC.GLX_GREEN_SIZE;	att[7] := 4;
  att[8] := GLC.GLX_RED_SIZE;		att[9] := 4;
  att[10] := 0 ;


	(* try to find a visual with this attribs *)	
	visinfoptr := GL.glXChooseVisual(display, screen , SYSTEM.ADR(att[0])); 
	 IF visinfoptr = NIL THEN
		IF debug THEN Trace.String(" NO appropriate visual found"); Trace.Ln; END;
		Close;
		RETURN FALSE;
	ELSE 
		IF debug THEN 
			Trace.String("visinfoptr.depth= "); Trace.Int(visinfoptr.depth,0); Trace.Ln;
			Trace.String("visinfoptr.visual ");  Trace.Int(visinfoptr.visualID, 0); Trace.Ln; 
		END;
	END;


	res := GL.glXQueryVersion(display, glxMajor, glxMinor);
	IF debug THEN
		Trace.String("GLX-Version "); Trace.Int(glxMajor,0); Trace.Char("."); Trace.Int(glxMinor,0); Trace.Ln;
	END;   

	(* create GL context *)
	 (* GL_TRUE: Use direct rendering, GL_FLASE: use X server for rendering *)
	glctx := GL.glXCreateContext(display, visinfoptr, 0, GLC.GL_TRUE); 
	IF debug THEN Trace.String("glXCreateContext glctx= "); Trace.Int(glctx, 0); Trace.Ln; END;

	(* create a color map *)
	cmap := X11.CreateColormap(display, Api.RootWindow(display,visinfoptr.screen), visinfoptr.visual, X11.AllocNone);
	IF cmap = 0 THEN
		IF debug THEN 
			Trace.String(" cannot create colormap"); Trace.Ln; 
			X11.GetErrorText(display, cmap, buf, LEN(buf));
			Trace.String("ERROR: CreateColormap = "); Trace.String(buf); Trace.Ln;
		END;
	END;

	(* window attributes *)
	winAttr.colormap := cmap;
	winAttr.borderPixel := 0;
	winAttr.backgroundPixel := 0;    

	
	IF fullscreen THEN
		X11.Lock;
		(* Use the XF86VidMode extension to control video resolution *)
		(* Change the current video mode, switch to fullscreen *)
		(* Unlock mode switch if necessary *)
		res := V.XF86VidModeLockModeSwitch(display, screen, 0);
		(* Change the video mode to the desired mode *)
		res := V.XF86VidModeSwitchToMode(display, screen, bmodes);
		(* Set viewport to upper left corner (where our window will be) *)
       	res:= V.XF86VidModeSetViewPort(display, screen, 0, 0);
       	(* Lock mode switch *)
  		res := V.XF86VidModeLockModeSwitch(display, screen, 1);   
  		  	
		Trace.String("resolution-2 "); Trace.Int(dispWidth,0); Trace.Char("x"); Trace.Int(dispHeight, 0); Trace.Ln;
		winAttr.overrideRedirect := TRUE;
		 (* window event masks *)	
		winAttr.eventMask :=  {Api.ExposureMask, Api.KeyPressMask, Api.ButtonPressMask, Api.StructureNotifyMask };
		masks := { Api.CWBorderPixel, Api.CWColormap, Api.CWEventMask, Api.CWOverrideRedirect};
		 
		win := Api.CreateWindow(display, Api.RootWindow(display, visinfoptr.screen),  0, 0, dispWidth, dispHeight,
		        0, visinfoptr.depth, Api.InputOutput,  visinfoptr.visual, masks, SYSTEM.ADR(winAttr));

		(*Api.WarpPointer(display, Api.None, win, 0, 0, 0, 0, 0, 0);*)
		Api.WarpPointer(display, Api.None, win, 0, 0, 0, 0, dispWidth DIV 2, dispHeight DIV 2);
		Api.MapWindow(display, win);
		res := Api.GrabKeyboard(display, win, Api.True, Api.GrabModeAsync , Api.GrabModeAsync, Api.CurrentTime);
		res := Api.GrabPointer(display, win, Api.True, {Api.ButtonPressMask}, Api.GrabModeAsync, Api.GrabModeAsync, win, X11.None, Api.CurrentTime);
		X11.Unlock;
	ELSE
		(* create a window in windowed mode *)
		(* window event masks *)	
		winAttr.eventMask := {Api.ExposureMask, Api.KeyPressMask, Api.ButtonPressMask, Api.StructureNotifyMask};
		
		masks := { Api.CWBorderPixel, Api.CWColormap, Api.CWEventMask};
		win := Api.CreateWindow(display, Api.RootWindow(display, visinfoptr.screen),  100, 100, width, height,
		        0, visinfoptr.depth, Api.InputOutput,  visinfoptr.visual, masks, SYSTEM.ADR(winAttr));

		(* only set window title and handle wm_delete_events if in windowed mode *)
		wmDelete := Api.InternAtom(display, "WM_DELETE_WINDOW", Api.True);   
		res := Api.SetWMProtocols(display, win, SYSTEM.ADR(wmDelete), 1);
		Api.SetStandardProperties(display, win, TITLE, TITLE, Api.None, NIL, 0, 0);
		Api.MapWindow(display, win);
	END;
	IF win = 0 THEN
		Close;
		RETURN FALSE;
	END;
		
	res := GL.glXMakeCurrent(display, win, glctx);
	IF res = 0 THEN
		Close;
		RETURN FALSE;
	END;
		
	IF debug THEN  
		Trace.String("glXMakeCurrent res= "); Trace.Int(res, 0); Trace.Ln;
		IF GL.glXIsDirect(display, glctx)=1 THEN
			Trace.String("DRI enabled"); Trace.Ln;
		ELSE                                
			Trace.String("no DRI available"); Trace.Ln;
		END;
	END;


 RETURN TRUE; 
END InitWindow;

PROCEDURE ToggleDecorations;
VAR 	hints: Hints; 
	property: X11.Atom;
BEGIN
	IF  ~fullwindow OR  ~fullscreen THEN
		hints.flags := {1};
 		windecorations := ~windecorations;
 		IF windecorations THEN hints.decorations := 0; ELSE hints.decorations := 1; END;
 		X11.Lock;
		property := Api.InternAtom(display, "_MOTIF_WM_HINTS", Api.True); 
		X11.ChangeProperty(display, win, property, property, 32, Api.PropModeReplace, SYSTEM.ADR(hints), 5);
		X11.Unlock;
	END;	
	
END ToggleDecorations;

PROCEDURE Wr(CONST str: ARRAY OF CHAR);
BEGIN
	IF debugevents THEN Trace.StringLn(str); Trace.Ln END;
END Wr;

(* save the rendered image to disk when mouse clicked *)
PROCEDURE SaveImage(CONST fname: ARRAY OF CHAR);
VAR image: Raster.Image;
	i, res: LONGINT;
BEGIN
	NEW(image);
	Raster.Create(image, width, height,Raster.BGRA8888);

(* needs to be flipped in y *)
	FOR i:=0 TO height-1 DO
		GL.glReadPixels(0, height-1-i, width, 1, GLC.GL_BGRA, GLC.GL_UNSIGNED_BYTE, image.adr + i*width*4); 
	END; 

(* GL.glReadPixels(0, 0, width, height, GLC.GL_BGRA, GLC.GL_UNSIGNED_BYTE, image.adr); *)
(* and  flip using Raster module  *)	
	WMGraphics.StoreImage(image, fname,res);
	IF res = 0 THEN
	  Trace.String(fname); Trace.String(" saved"); Trace.Ln;
	END;
	image := NIL;
END SaveImage;

	PROCEDURE CheckAlternateKeys( VAR mb: SET );
	BEGIN
		IF ~MMseen & (ControlKeyBit IN xbuttons) THEN INCL( mb, MM ) END;
		IF ~MRseen & (Mod1KeyBit IN xbuttons) THEN INCL( mb, MR ) END
	END CheckAlternateKeys;

	(* mouse handler *)
	PROCEDURE SendMouseMsg( x, y, dz: LONGINT; xbuttons: SET );
	VAR mm: Inputs.AbsMouseMsg;
	BEGIN
		mm.keys := {};
		mm.x := x;  mm.y := y;  mm.dz := dz;
		IF Button1Bit IN xbuttons THEN  INCL( mm.keys, ML )  END;
		IF Button2Bit IN xbuttons THEN  INCL( mm.keys, MM );  MMseen := TRUE  END;
		IF Button3Bit IN xbuttons THEN  INCL( mm.keys, MR );  MRseen := TRUE  END;
		IF ~(MMseen & MRseen) THEN  CheckAlternateKeys( mm.keys )  END;
(*		Inputs.mouse.Handle( mm );*)
		currX := x; currY := y;
		IF debugevents THEN Trace.Int(x,0); Trace.Int(y, 4);  Trace.Int(dz,5); Trace.Ln;  END;
	END SendMouseMsg;

	(* keyboard handler *)
	PROCEDURE SendKeyboardMsg( km: Inputs.KeyboardMsg );
	BEGIN
	     IF km.ch='q' THEN alive := FALSE; END;
	     IF km.ch = 's' THEN SaveImage('glxgears.bmp'); END;
		IF debugevents THEN Trace.Char(km.ch); Trace.Ln; END;
	END SendKeyboardMsg;

	(* Returns wether key (SHIFT, CTRL or ALT) is pressed *)
	PROCEDURE KeyState( ): SET;
	VAR keys: SET;
	BEGIN
		keys := {};
		IF ShiftKeyBit IN xbuttons THEN  INCL( keys, Inputs.LeftShift )  END;
		IF ControlKeyBit IN xbuttons THEN  INCL( keys, Inputs.LeftCtrl )  END;
		IF Mod1KeyBit IN xbuttons THEN  INCL( keys, Inputs.LeftAlt )  END;
		IF Mod4KeyBit IN xbuttons THEN  INCL( keys, Inputs.LeftMeta )  END;
		IF Mod5KeyBit IN xbuttons THEN  INCL( keys, Inputs.RightAlt )  END;
		RETURN keys
	END KeyState;


	PROCEDURE ToggleFullWindow;
	VAR 
		cm: Api.XClientMessageEvent;
		xev: Api.XEvent;
		dl: Api.Data40l;
		wmstate, wmfullscreen: X11.Atom;
		res: LONGINT;
	BEGIN
	wmstate := Api.InternAtom(display, "_NET_WM_STATE", Api.False);
	wmfullscreen := Api.InternAtom(display, "_NET_WM_STATE_FULLSCREEN", Api.False);

	fullwindow := ~ fullwindow;
	cm.typ := Api.ClientMessage;
	cm.window := win;
	cm.messageType := wmstate;
	cm.format := 32;
	IF fullwindow THEN dl[0] := 1; ELSE dl[0] := 0; END;
	dl[1] := wmfullscreen;
	dl[2] := 0;
	cm.data:=SYSTEM.VAL(Api.Data40, dl);
	xev := SYSTEM.VAL(Api.XEvent, cm);

	res := Api.SendEvent(display, X11.DefaultRootWindow(display), Api.False, {Api.SubstructureNotifyMask}, SYSTEM.ADR(xev));
	
	END ToggleFullWindow;
	
(* process pending X11 events, from Unix.KbdMouse.Mod *)
	PROCEDURE PollXQueue;
	VAR   
		 keysym: X11.KeySym;

		 cm: Api.XClientMessageEvent;
		 ke: Api.XKeyEvent;
		 be: Api.XButtonEvent;
		 cn : Api.XConfigureEvent;
		 ee : Api.XExposeEvent;
		 datal: Api.Data40l;
		 atomName: Api.PChar;
	BEGIN
	 WHILE Api.Pending(display) > 0 DO 
	
				Api.NextEvent( display, event );
				CASE event.typ OF
				| Api.Expose: Wr("Expose, GraphicsExpose");
								ee := SYSTEM.VAL(Api.XExposeEvent, event);
								Trace.String("expose serial"); Trace.Int(ee.serial,5); Trace.Ln;
								IF ee.count = 0 THEN DrawGears(); END;
				
				| Api.ConfigureNotify: Wr("ConfigureNotify");
						cn := SYSTEM.VAL(Api.XConfigureEvent, event);

			                    (* call Reshape only if our window-size changed *)
						IF (cn.width # width) OR  (cn.height # height) THEN
								width := cn.width;
								height := cn.height;
								Reshape(width, height);
						END;
						
				| Api.ButtonPress: Wr("ButtonPress"); 
							be := SYSTEM.VAL(Api.XButtonEvent, event);
							Trace.String("sendEvent="); Trace.Boolean(be.sendEvent); Trace.Ln;
							Trace.String("be.button="); Trace.Int(be.button,2); Trace.Ln;
							IF be.button = Api.Button1 THEN
								alive := FALSE;
							END;
				| Api.KeyPress: Wr("KeyPress");
								ke := SYSTEM.VAL(Api.XKeyEvent, event);								
								keysym := Api.LookupKeysym(ke, 0);
								CASE keysym OF 
									KS.XK_Escape, KS.XK_q1, KS.XK_Q: alive := FALSE;
								|	KS.XK_F1: Wr("F1 pressed"); (* start from begining *)
											Close;
											fullscreen := ~ fullscreen;
											IF InitWindow() THEN
												InitGears;
												Reshape(width, height);
											END;
								| KS.XK_Up: Wr("K_Up"); roty := roty + 5.0;
								| KS.XK_Down: Wr("K_Down"); roty := roty -5.0;
								| KS.XK_F11: ToggleFullWindow;
								| KS.XK_F12: ToggleDecorations;
								ELSE
								END;
				
				| Api.ClientMessage: Wr("ClientMessage");
						cm := SYSTEM.VAL(Api.XClientMessageEvent, event);						
						(* Trace.String("sendEvent="); Trace.Boolean(cm.sendEvent); Trace.Ln; *)
						atomName := Api.GetAtomName(display, cm.messageType);
						KernelLog.String("cm.messageType= "); KernelLog.Int(cm.messageType, 0); KernelLog.Ln; 
						IF atomName # NIL THEN
							KernelLog.String("atomName="); KernelLog.String(atomName^); KernelLog.Ln; 
						END;
						
						datal := SYSTEM.VAL(Api.Data40l, cm.data);
						Trace.String("datal[0]="); Trace.Int(SYSTEM.VAL(X11.Atom,datal[0]), 0); Trace.Ln;
						Trace.String("wmDeleteWindow="); Trace.Int(wmDelete,0); Trace.Ln; 
						atomName := Api.GetAtomName(display, SYSTEM.VAL(X11.Atom,datal[0]));
						IF atomName # NIL THEN
							KernelLog.String("datal[0] atomName="); KernelLog.String(atomName^); KernelLog.Ln; 
						END;

						
						IF  SYSTEM.VAL(X11.Atom,datal[0]) = wmDelete THEN
						    Wr("DeleteWindow");
						    alive := FALSE; 
						END; 
				ELSE
				
				END;
		END;
	END PollXQueue;

(* windows main loop *)
PROCEDURE MainLoop;
VAR	frames : LONGINT; 	
BEGIN
frames := 0;
Kernel.SetTimer(timer, 5000);
alive := TRUE;

WHILE  alive  DO 
		(* process X11 events *)
		PollXQueue;
		DrawGears();
		angle := angle + 0.05;

		 (* measure timing info *)
		INC(frames);
		IF Kernel.Expired(timer) THEN
			Trace.Int(frames,0); Trace.String(" frames in 5 secs."); 
			Trace.String(" FPS = "); Trace.Int(frames DIV 5,0); 
			Trace.Ln;
			Kernel.SetTimer(timer,5000);
			frames := 0;
		END;
END;

END MainLoop;

PROCEDURE Open*;
BEGIN
	width := 320; height := 240; (* window size*)
	fullscreen := FALSE;
	fullwindow := FALSE;
	windecorations := TRUE;
	IF ~ InitWindow() THEN RETURN; END;
	InitGears(); 
	Reshape(width, height);
	
	(* enter to main loop *)
	MainLoop;

	(* finally close the window *)
	Close;
END Open;


BEGIN	
GL.InitOpenGL;
END MyXGear2.

MyXGear2.Open~

SystemTools.Free MyXGear2 ~ 