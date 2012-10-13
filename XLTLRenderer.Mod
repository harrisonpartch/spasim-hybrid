MODULE XLTLRenderer; (** AUTHOR "fnecati"; PURPOSE ""; *)
 (* axolotl-felix GL implemetation in Oberon
 	http://code.google.com/p/axolotl-felix/ *)
 
IMPORT
	XLTLBase, XLTLGL, Objects, Inputs, X11,  
	Api := X11Api, GL:=OpenGL, GLC := OpenGLConst, Kernel, 
	Math, XLTLMath,  SYSTEM, Random,
	 Out:=KernelLog, XLTLRetina, XLTLMarsh;
	  
CONST
	ML = 0;  MM = 1;  MR = 2;
	Button1Bit = 8; Button2Bit = 9; Button3Bit =10;
	ShiftKeyBit = 0;  ShiftLokBit = 1;  ControlKeyBit = 2;  Mod1KeyBit = 3;
	Mod2KeyBit = 4;  Mod3KeyBit = 5;  Mod4KeyBit = 6;  Mod5KeyBit = 7;	  
	TR = XLTLBase.TR;
	rad2deg=360/6.28318;
	  
TYPE Ray = XLTLBase.Ray;
TYPE Voxel = XLTLBase.Voxel; 
TYPE PT = XLTLBase.PT;
TYPE Aperture = XLTLBase.Aperture;

VAR

	xbuttons: SET;
	timeStart: LONGINT;   (* milliseconds *)
	compstatus: X11.ComposeStatus;
	update: LONGINT;
	MMseen, MRseen: BOOLEAN;	
	noEventCount: LONGINT;
	display : X11.DisplayPtr;
	win : X11.Window ;

	glctx : GL.GLXContext;  

	W,H, width, height, mousex, mousey : LONGINT; (* size of window *)
	alive, debug, debugevents : BOOLEAN; (* for main loop control *)	
	rand:Random.Generator;
	drawMode:LONGINT; (* fill, lines, points *)
	texture: ARRAY [3] OF GL.GLuint;  (* Storage For 3 Textures  *)
	LightAmbient, LightDiffuse, LightPosition: ARRAY [4] OF GL.GLfloat;
	LightAmbient2, LightDiffuse2, LightPosition2: ARRAY [4] OF GL.GLfloat;	
	red, green, blue, lightPos: ARRAY [4] OF GL.GLfloat; 
	xrot, yrot, zrot: REAL;  (* X, Y  rotation *)
	axis: CHAR;
	z, zee : REAL; (* depth into the screen *)
	xspeed, yspeed: REAL;
	light, blend: BOOLEAN; (* Whether or not lighting is on,  Whether or not blending is on *)
	filter: LONGINT; (* type of filter *)		
	ptlist: LONGINT;	
	GO, TRAIL: BOOLEAN;	
	camera:Camera;
	fogdensity:REAL;


TYPE Camera = OBJECT
VAR
	rayschanged, ang1,filter: BOOLEAN;
	fovealeft, fovearight, foveabottom, foveatop: LONGINT;
	aperture: Aperture;
	frame: LONGINT;
	fovea: BOOLEAN;
	cam: PT;
	lookdxyz:PT;
	cx, cy, cz, cvx, cvy, cvz, cvl, cvu: REAL;   
	fward, avward, bward,rward,lward,upward, down, right:PT; 
	croll: REAL;
	cdroll: REAL;
	cameratheta,cameraphi: REAL;
	world:Voxel;	
	positionlock, orientationlock, returntohorizon, suppressz: BOOLEAN;		
	oldcam:PT;
	a,b,c: REAL;	
	tracing, Go:BOOLEAN;
	gravity: BOOLEAN;
	
PROCEDURE & init;
BEGIN
	W:=XLTLBase.W;
	H:=XLTLBase.H;
	filter:=TRUE;
	cam.x:=0.52;
	cam.y:=0.52;
	cam.z:=0.6;
	cameratheta := 0;
	cameraphi := 0;
	aperture.width :=1.6;
	aperture.height :=1.6;
	initrays;
END init;

PROCEDURE hop;
BEGIN
	cam.x :=XLTLBase.rand.Uniform(); cam.y:=XLTLBase.rand.Uniform(); cam.z := XLTLBase.rand.Uniform(); 
END hop;

PROCEDURE stop;
BEGIN
	XLTLBase.speed := XLTLBase.speed/1.05;
	cvx:=0;
	cvy:=0;
	cvz:=0;
	cvl:=0;
	cvu:=0;
END stop;

PROCEDURE deathray(x,y: LONGINT);
BEGIN
	initrays;
	XLTLBase.world.deathray(XLTLBase.rays[x,y]);
END deathray;

PROCEDURE forward;
BEGIN
	cvx := fward.x * XLTLBase.speed; 
	cvy := fward.y * XLTLBase.speed; 
END forward;

PROCEDURE fjet(jet: REAL);
BEGIN
	cvx :=cvx+fward.x * jet*XLTLBase.speed; 
	cvy :=cvy+fward.y * jet*XLTLBase.speed; 
END  fjet;

PROCEDURE backward;
BEGIN
	cvx :=-fward.x * XLTLBase.speed; 
	cvy :=-fward.y * XLTLBase.speed; 
END backward;

PROCEDURE xjet(jet: REAL);
BEGIN
	cvx:=cvx+(jet*XLTLBase.speed);
END xjet;

PROCEDURE yjet(jet: REAL);
BEGIN
	cvy:=cvy+(jet*XLTLBase.speed);
END yjet;

PROCEDURE zjet(jet: REAL);
BEGIN
	cvz:=cvz+(jet);
END zjet;

PROCEDURE ljet(jet: REAL);
BEGIN
	cvx:=cvx+lward.x*jet*XLTLBase.speed;
	cvy:=cvy+lward.y*jet*XLTLBase.speed;
END ljet;

PROCEDURE rjet;
VAR
	p: PT;
BEGIN
	p:=rward;
	cvx:=cvx+(p.x*XLTLBase.speed);
	cvy:=cvy+(p.y*XLTLBase.speed);
	cvz:=cvz+(p.z*XLTLBase.speed);
END  rjet;

PROCEDURE downjet;
VAR
	p: PT;
BEGIN
	p:= down;
	cvx:=cvx+(p.x*XLTLBase.speed);
	cvy:=cvy+(p.y*XLTLBase.speed);
	cvz:=cvz+(p.z*XLTLBase.speed);
END downjet;

PROCEDURE angletoray(VAR ray: XLTLBase.Ray; theta,phi: REAL);
VAR d: REAL;
BEGIN
	ray.dxyz.x := XLTLMath.cos(theta) * XLTLMath.cos(phi);
	ray.dxyz.y := XLTLMath.sin(theta) * XLTLMath.cos(phi);
	ray.dxyz.z := XLTLMath.sin(phi);
	d := Math.sqrt(ray.dxyz.x*ray.dxyz.x + ray.dxyz.y* ray.dxyz.y+ray.dxyz.z*ray.dxyz.z);  (* Norma! Liza! Ray! Front and center, oh dark thirty!*)
	ray.dxyz.x := ray.dxyz.x/d;
	ray.dxyz.y := ray.dxyz.y/d;
	ray.dxyz.z := ray.dxyz.z/d; 
END angletoray; 

PROCEDURE carttosph(VAR p: PT; theta, phi: REAL);
BEGIN
	p.x := XLTLMath.cos(theta) * XLTLMath.cos(phi);
	p.y := XLTLMath.sin(theta) * XLTLMath.cos(phi);
	p.z := XLTLMath.sin(phi);
END carttosph; 

PROCEDURE sphtocart( p: PT; VAR theta, phi: REAL);
VAR
	x,y, z: REAL;
BEGIN
	x := p.x; y := p.y; z := 0;
	XLTLBase.normalize(x,y,z);
	theta := XLTLMath.arccos(x);	
	phi := XLTLMath.arccos(1-p.z);
END sphtocart;

PROCEDURE ddray(VAR ray: XLTLBase.Ray); 
BEGIN
	ray.ddxyz.x := ray.dxyz.x/10000;
	ray.ddxyz.y := ray.dxyz.y/10000;
	ray.ddxyz.z := ray.dxyz.z/10000; 
END ddray; 

PROCEDURE aggle;
BEGIN
	XLTLBase.setPT(rward, 0,0,1);	
	XLTLBase.setPT(fward,1,0,0);	
	XLTLBase.setPT(avward,1,0,0);		
	XLTLBase.setPT(down,0,1,0);	
	XLTLMath.orrot(fward, down, cameratheta); 	
	XLTLMath.orrot(avward, down, cameratheta); 		
	XLTLMath.orrot(avward, rward, cameraphi);  	
END aggle;

PROCEDURE initrays;
VAR
	i, j: LONGINT;
	theta, phi, dtheta, dphi: REAL;
	lookperpray: Ray;
	lookvector:PT;
	look: XLTLBase.PT;
	camtweak: XLTLBase.PT;
	d1,d2,d3: REAL;
BEGIN
	dtheta := aperture.width/ W;
	dphi := aperture.height / H;
	theta := -aperture.width / 2;
	FOR i := 0 TO XLTLBase.W - 1  DO
		theta := theta + dtheta;
		phi :=  -aperture.height / 2; 	(*bottom*)
		FOR j := 0 TO XLTLBase.H - 1 DO
			phi := phi + dphi;
			XLTLBase.rays[i, j] := XLTLBase.blankray;	
			XLTLBase.rays[i, j].theta := theta;
			XLTLBase.rays[i, j].phi := phi;
			angletoray(XLTLBase.rays[i, j],theta,phi);
			XLTLMath.orrot(XLTLBase.rays[i, j].dxyz, rward, cameraphi);  	
		  	XLTLMath.orrot(XLTLBase.rays[i, j].dxyz, down, cameratheta);  								  	  		
			IF XLTLBase.rays[i, j].dxyz.x < 0 THEN XLTLBase.rays[i, j].di := FALSE  ELSE XLTLBase.rays[i, j].di := TRUE END; 
			IF XLTLBase.rays[i, j].dxyz.y < 0 THEN XLTLBase.rays[i, j].dj := FALSE  ELSE XLTLBase.rays[i, j].dj := TRUE END;
			IF XLTLBase.rays[i, j].dxyz.z < 0 THEN XLTLBase.rays[i, j].dk := FALSE  ELSE XLTLBase.rays[i, j].dk := TRUE END;	
			XLTLBase.rays[i, j].ddxyz.x:=XLTLBase.rays[i, j].dxyz.x/10000;
			XLTLBase.rays[i, j].ddxyz.y:=XLTLBase.rays[i, j].dxyz.y/10000;
			XLTLBase.rays[i, j].ddxyz.z:=XLTLBase.rays[i, j].dxyz.z/10000	
		END
	END;
END initrays;

PROCEDURE irays;
VAR
	i, j: LONGINT;
	theta, phi, dtheta, dphi: REAL;
	lookperpray: Ray;
	lookvector:PT;
	look: XLTLBase.PT;
	camtweak: XLTLBase.PT;
	d1,d2,d3: REAL;
BEGIN
	FOR i := 0 TO XLTLBase.W - 1  DO
		FOR j := 0 TO XLTLBase.H - 1 DO	
			XLTLBase.rays[i, j].origin := XLTLBase.camera;
			XLTLBase.rays[i, j].xyz := XLTLBase.camera;
			XLTLBase.rays[i, j].lxyz := XLTLBase.camera;
			XLTLBase.rays[i, j].terminate:=FALSE;
			XLTLBase.rays[i, j].scale:=1;
			XLTLBase.rays[i, j].dtl:=XLTLBase.DTL;
		END
	END;
(*	FOR i := (XLTLBase.W2-30) TO (XLTLBase.W2+29)  DO
		FOR j := (XLTLBase.H2-30) TO (XLTLBase.H2+29) DO	
			XLTLBase.rays[i, j].dtl:=XLTLBase.DTL2;
		END
	END; *)    (* overlapping coplanar polys *)
END irays;

PROCEDURE trace;
BEGIN
	 XLTLRetina.go;
END trace; 

PROCEDURE left (th: REAL);
BEGIN
	cvl:=cvl+th;
END left;

PROCEDURE up (ph: REAL);
BEGIN
	cvu:=cvu+ph;
END up;

PROCEDURE bounce(VAR cam:PT; VAR x,y,z: REAL);
VAR
	ray: Ray;
BEGIN
	ray.origin := cam;
	ray.xyz := cam;
	ray.lxyz := cam;
	ray.dxyz.x:=x-cam.x;
	ray.dxyz.y:=y-cam.y;	
	ray.dxyz.z:=z-cam.z;	
	XLTLBase.world.Shade(ray);               (* correct only for cube face normals not arbitrary normals *)
	IF ray.normal.x#0 THEN cvx:=-cvx 
	ELSIF ray.normal.y#0 THEN cvy:=-cvy 
	ELSIF ray.normal.z#0 THEN cvz:=-cvz	
(*	ELSE cvx:=0; cvy:=0; cvz:=0 *)
	END;
END bounce;

PROCEDURE tick;
VAR
	x,y,z: REAL;
	pass:BOOLEAN;
	timer : Kernel.MilliTimer; 	
	t: LONGINT;
	gz:REAL;
BEGIN
	IF TRAIL THEN XLTLMarsh.cameratrail END;
(*	gz:=cam.z-1/3; *)
	gz:=1;
	IF gravity THEN cvz := cvz+gz*XLTLBase.gravity/10000 END;
	cvx := cvx*0.99; cvy := cvy*0.99; cvz := cvz*0.99;
	cameratheta:=cameratheta+cvl;
	cameraphi := cameraphi + cvu;
	cvl :=cvl*0.6; cvu := cvu*0.6;	
	IF cameraphi>=1.6 THEN cameraphi:=1.6 
	ELSIF cameraphi<=-1.6 THEN cameraphi:=-1.6 
(*	ELSIF (ABS(cameraphi)<1.6) & (ABS(cameraphi)>0.5) THEN cameraphi:=cameraphi*0.9; *)
	END;
	x := cam.x + 3*cvx; y := cam.y+3*cvy; z := cam.z+3*cvz;
	IF ~XLTLBase.world.passprobe(x,y,z) THEN bounce(cam,x,y,z) 
	ELSE cam.x := cam.x + cvx; cam.y := cam.y+cvy; cam.z:= cam.z+cvz
	END;
	a:=avward.x; b:=avward.y; c:=avward.z;	
	XLTLBase.updatecamera(cam.x,cam.y,cam.z,a*XLTLBase.avdist,b*XLTLBase.avdist,c*XLTLBase.avdist);	
	LightPosition[0]:= cam.x; LightPosition[1]:= cam.y; LightPosition[2]:= cam.z; LightPosition[3]:= 1.0;
  	 GL.glLightfv(GLC.GL_LIGHT1, GLC.GL_POSITION, SYSTEM.ADR(LightPosition[0]) );
   	aggle;
	IF TRAIL THEN XLTLMarsh.draw END;
	initrays;
	irays; 
	trace;	
END tick;
END Camera;

PROCEDURE Reshape(w, h: LONGINT);
BEGIN	
GL.SetFCR();
	GL.glViewport(0, 0, w, h);
	GL.glClearColor(0.0, 0.0, 0.0, 0.0);
	GL.glMatrixMode(GLC.GL_PROJECTION);
	GL.glLoadIdentity();
	GL.glFrustum(-1,1,-1,1, 0.5, 60); 
	GL.glMatrixMode(GLC.GL_MODELVIEW);
	GL.glLoadIdentity(); 
GL.DelFCR();
END Reshape;

PROCEDURE Close*;
  VAR res: LONGINT;
 BEGIN    	
 	XLTLBase.worldalive:=FALSE;
 	alive:=FALSE;
	(* do we have a rendering context *)
	IF glctx # 0 THEN
		(* Release the context *)
	    	res := GL.glXMakeCurrent(display, 0, 0);
	    	(* Delete the context *)
		GL.glXDestroyContext(display, glctx);
		glctx := 0;

	END;
	
	(* do we have a window *)
	IF win # 0 THEN
		(* Unmap the window*)
		Api.UnmapWindow(display, win);
		(* Destroy the window *)
		res:= Api.DestroyWindow(display, win);
		win := 0;

	END;
	
	(* do we have a display *)
	IF display # 0 THEN	
		res := Api.CloseDisplay(display);
		display := 0;

	END;
	
 END Close;

PROCEDURE  InitWindow(w, h: LONGINT; CONST title: ARRAY OF CHAR);
VAR 
	res: LONGINT;
	masks: SET;
	buf: X11.Buffer;
	attrib : ARRAY [*] OF GL.GLint;  (* attributes of GL window *) 
	visinfoptr : Api.VisualInfoPtr;
	gwa : Api.XWindowAttributes; (* get window attributes *) 	
	swa : Api.XSetWindowAttributes; (* set window attributes*)
	cmap : X11.Colormap; (* colormap for window *)	
		
BEGIN
 display := X11.OpenDisplay(0);
 IF display =0 THEN
 	Out.String(" cannot connect to X server"); Out.Ln; 
	Close;
     RETURN;
END;  

  NEW(attrib, 13);
  attrib[0] := GLC.GLX_RGBA;
  attrib[1] := GLC.GLX_DOUBLEBUFFER;
  attrib[2] := GLC.GLX_DEPTH_SIZE;	attrib[3] := 24; 
  attrib[4] := GLC.GLX_STENCIL_SIZE;	attrib[5] := 8; 
  attrib[6] := GLC.GLX_RED_SIZE;  	attrib[7] := 8;
  attrib[8] := GLC.GLX_GREEN_SIZE;	attrib[9] := 8;
  attrib[10] := GLC.GLX_RED_SIZE;	attrib[11] := 8;
  attrib[12] := 0 ;

 (* try to find a visual with this attribs *)	
 visinfoptr := GL.glXChooseVisual(display, 0 , SYSTEM.ADR(attrib[0]));
 
 IF visinfoptr = NIL THEN
  	IF debug THEN Out.String(" NO appropriate visual found"); Out.Ln; END;
  	Close;
     RETURN;
 ELSE 
	 IF debug THEN 
		 Out.String("visinfoptr.depth= "); Out.Int(visinfoptr.depth,0); Out.Ln;
	 	Out.String("visinfoptr.visual ");  Out.Int(visinfoptr.visualID, 0); Out.Ln; 
	END;
END;

 cmap := X11.CreateColormap(display, X11.DefaultRootWindow(display), visinfoptr.visual, X11.AllocNone);
 IF cmap = 0 THEN
 	IF debug THEN 
	 	Out.String(" cannot create colormap"); Out.Ln; 
	 	X11.GetErrorText(display, cmap, buf, LEN(buf));
	 	Out.String("ERROR: CreateColormap = "); Out.String(buf); Out.Ln;
 	END;
 END;

 (* window event masks *)	
 masks :=  {Api.KeyPressMask,  Api.KeyReleaseMask, Api.ButtonPressMask,  Api.ButtonReleaseMask,  Api.PointerMotionMask,
   Api.ButtonMotionMask, Api.ExposureMask, Api.StructureNotifyMask, Api.FocusChangeMask};

  (* window attributes *)
 swa.backgroundPixel := 0;
 swa.borderPixel := 0;
 swa.colormap := cmap;
 swa.eventMask := masks;
 
 masks := { Api.CWBackPixel, Api.CWBorderPixel, Api.CWColormap, Api.CWEventMask};
 
 win := Api.CreateWindow(display, X11.DefaultRootWindow(display), 0, 0, w, h,
		        0, visinfoptr.depth, Api.InputOutput,  visinfoptr.visual, masks, SYSTEM.ADR(swa));

 (* show window *)	
  Api.MapWindow(display, win);

 (* set title of window *)	 
 res := Api.StoreName(display, win, title); 

(* create GL context *)
 (* GL_TRUE: Use direct rendering, GL_FLASE: use X server for rendering *)
 glctx := GL.glXCreateContext(display, visinfoptr, 0, GLC.GL_TRUE); 
	 IF debug THEN Out.String("glXCreateContext glctx= "); Out.Int(glctx, 0); Out.Ln; END;
 
 res := GL.glXMakeCurrent(display, win, glctx);
	IF debug THEN  Out.String("glXMakeCurrent res= "); Out.Int(res, 0); Out.Ln; END;

END InitWindow;

PROCEDURE Wr(CONST str: ARRAY OF CHAR);
BEGIN
	IF debugevents THEN Out.String(str); Out.Ln END;
END Wr;


PROCEDURE speedup;
BEGIN
	IF XLTLBase.speed < 0.01 THEN XLTLBase.speed := XLTLBase.speed * 1.8 END
END speedup;

PROCEDURE slowdown;
BEGIN
	IF XLTLBase.speed > 0.0000001 THEN XLTLBase.speed := XLTLBase.speed/1.8 END
END slowdown;


PROCEDURE KeyEvent(ch: CHAR);	     
BEGIN
	CASE ch OF
		 "s" : camera.backward
		| "w" :camera.forward
		| "e" : camera.zjet(XLTLBase.speed)
		| " " :camera.zjet(-XLTLBase.speed)		 
		| "D": drawMode := (drawMode+1) MOD 3; DrawMode(drawMode); 
		| "t": TRAIL:=~TRAIL; Out.String("toggled trail")
		| "z": XLTLMarsh.draw;
		| "x": XLTLMarsh.cycleD;
		| "1" : XLTLBase.DTL:= ENTIER(2*XLTLBase.DTL/3)		
		| "!" : XLTLBase.DTL:= ENTIER(3*XLTLBase.DTL/2)		
		| "2" : INC(XLTLBase.gravity);	
		| "@" : DEC(XLTLBase.gravity);					
		| "h" : 	camera.hop			
		| "k" : GL.glEnable(GLC.GL_LIGHTING)
		| "l" : GL.glDisable(GLC.GL_LIGHTING)		
		| "m" : XLTLBase.mtoggle:=~XLTLBase.mtoggle;
			Out.Char('!')
		| "q" : alive:=FALSE
		| ']': camera.aperture.width := camera.aperture.width * 101/99; camera.aperture.height := camera.aperture.height *101/99
		| '[': camera.aperture.width := camera.aperture.width * 99/101; camera.aperture.height := camera.aperture.height *99/101
		| '+': speedup
		| '-': slowdown
		| '.': camera.stop
		| '9': XLTLBase.avatarsize:=ENTIER(XLTLBase.avatarsize*1.3)
		| '0': XLTLBase.avatarsize:=ENTIER(XLTLBase.avatarsize/1.3)
		| '7': XLTLBase.avdist:=XLTLBase.avdist*1.3
		| '8': XLTLBase.avdist:=XLTLBase.avdist/1.3		
		| 'g': camera.gravity:=~camera.gravity;
		| 'f' : fogdensity:= fogdensity*1.1; 
				IF fogdensity>0.9 THEN fogdensity:=0.01 END			
	ELSE	
	END;	
END KeyEvent;

PROCEDURE MouseVent(x,y: LONGINT);
VAR
	dx,dy: LONGINT;
BEGIN
	dx:=x-mousex;
	dy:=y-mousey;
	camera.left(dx/10000);
	camera.up(dy/20000);	
	IF (x<200)OR(x>400) THEN
		X11.WarpPointer(display,win,win,0,0,1000,1000,300,y);
		mousex:=300;
		mousey:=y;
	ELSIF  (y<100)OR(y>300) THEN
		X11.WarpPointer(display,win,win,0,0,1000,1000,x,200);
		mousey:=200;
		mousex:=x;
	END;
END MouseVent;

PROCEDURE LoopForEvents;
VAR event: Api.XEvent;
	res: LONGINT;
	eventcount, keycount, xr, yr, x, y, dz, i: LONGINT;
	rw, cw: X11.Window;  buffer: X11.Buffer;  keysym: X11.KeySym;  
	newxbuttons, bdiff: SET;
	ch: CHAR;
	(* for type casting of XEvent*)
	ee: Api.XExposeEvent;
	ke: Api.XKeyEvent;
	be : Api.XButtonEvent;
	cne : Api.XConfigureEvent;
	mne: Api.XMotionEvent;
	
BEGIN

	X11.Lock;
	WHILE Api.Pending(display)>0 DO 
			Api.NextEvent(display, event);
			CASE event.typ OF
			Api.Expose: ee := SYSTEM.VAL(Api.XExposeEvent, event);
					IF ee.count=0 THEN draw; END;
					Wr("Expose");
			| Api.KeyPress:	ke := SYSTEM.VAL(Api.XKeyEvent, event);
					Wr("KeyPressed");
					keycount := Api.LookupString(ke , buffer, X11.BufferSize, keysym, compstatus );
					ch := buffer[0];  
					KeyEvent(ch); 
			| Api.KeyRelease: ke := SYSTEM.VAL(Api.XKeyEvent, event);	
						Wr("KeyReleased");
			| Api.ButtonPress: be := SYSTEM.VAL(Api.XButtonEvent, event);
					Wr("ButtonPressed");
					Out.String("MOUSECLICK PRESS: "); Out.Int(be.button,2); Out.Ln;
					IF be.button = Api.Button3 THEN alive := FALSE; END;

					
			| Api.ButtonRelease: be := SYSTEM.VAL(Api.XButtonEvent, event);					
					Wr("ButtonRelease"); 
					Out.String("MOUSECLICK RELEASE: "); Out.Int(be.button,2); Out.Ln;
					
			| Api.MotionNotify:  mne := SYSTEM.VAL(Api.XMotionEvent, event);
			Wr("MotionNotify");				
				x := mne.x; y := mne.y;
				xr := mne.xRoot; yr := mne.yRoot;
				(* X11.QueryPointer( display, event.window, rw, cw, xr, yr, x, y, xbuttons );*)
				Api.WarpPointer( display, mne.window, mne.window, xr, yr, x, y, 400, 400);  (*works somewhat *)
				
				MouseVent(x,y);
				
			| Api.ConfigureNotify: cne := SYSTEM.VAL(Api.XConfigureEvent, event);
					Reshape(cne.width, cne.height);
					Wr("ConfigureNotify");
					
			| Api.FocusIn: Wr("FocusIn");
			| Api.FocusOut: Wr("FocusOut");
			| Api.GraphicsExpose: Wr("GraphicsExpose");
			| Api.NoExpose: Wr("NoExpose");
			| Api.UnmapNotify: Wr("UnmapNotify");
			| Api.MapNotify: Wr("MapNotify");
			| Api.PropertyNotify: Wr("PropertyNotify");						
			| Api.SelectionClear: Wr("SelectionClear");
			| Api.SelectionRequest: Wr("SelectionRequest");
			| Api.SelectionNotify: Wr("SelectionNotify");				
			
			(* and others .... *)
			| Api.ClientMessage: Wr("ClientMessage");
			| Api.MappingNotify: Wr("MappingNotify");
			ELSE	
			END;	
	   	END;
	   	X11.Unlock;
END LoopForEvents;

PROCEDURE InitGL;
BEGIN
	light := FALSE; blend := FALSE;
	xrot := 30.0; yrot := 30.0; z := -10.0;	
	xspeed := 0.0; yspeed := 0.0;
	
	filter := 0;
			

LightAmbient[0] := 0.1; LightAmbient[1] := 0.1; LightAmbient[2] := 0.1; LightAmbient[3] := 0.1;
LightDiffuse[0] := 0.5; LightDiffuse[1] := 0.5; LightDiffuse[2] := 0.5; LightDiffuse[3] := 0.0;
LightPosition[0]:= 0.0; LightPosition[1]:= 1.0; LightPosition[2]:= 1; LightPosition[3]:= 1.0;
LightDiffuse2[0] := 0.7; LightDiffuse2[1] := 0.4; LightDiffuse2[2] := 0.2; LightDiffuse2[3] := 1.0;
red[0]:=0.62; red[1]:=0.42; red[2]:=0.9; red[3]:=0.0; 
blue[0]:=0.21; blue[1]:=0.21; blue[2]:=0.99; blue[3]:=1.0; 

(* context.MakeCurrent(); *)
GL.SetFCR();

  (* Enable Texture Mapping ( NEW ) *)
  GL.glEnable( GLC.GL_TEXTURE_2D );

  (* Enable smooth shading *)
  GL.glShadeModel( GLC.GL_SMOOTH );

  (* Set the background black *)
  GL.glClearColor( 0.22, 0.22, 0.99, 0.0 );

  (* Depth buffer setup *)
  GL.glClearDepth( 1.0 );

  (* Enables Depth Testing *)
  GL.glEnable( GLC.GL_DEPTH_TEST );

  (* The Type Of Depth Test To Do *)
  GL.glDepthFunc( GLC.GL_LEQUAL );

  (* Really Nice Perspective Calculations *)
  GL.glHint( GLC.GL_PERSPECTIVE_CORRECTION_HINT, GLC.GL_NICEST );

  (* Setup The Ambient Light *)
  GL.glLightfv( GLC.GL_LIGHT1, GLC.GL_AMBIENT, SYSTEM.ADR(LightAmbient[0]) );

  (* Setup The Diffuse Light *)
  GL.glLightfv( GLC.GL_LIGHT1, GLC.GL_DIFFUSE, SYSTEM.ADR(LightDiffuse[0]) );

  (* Position The Light *)
  GL.glLightfv( GLC.GL_LIGHT1, GLC.GL_POSITION, SYSTEM.ADR(LightPosition[0]) );

  (* Enable Light One *)
  GL.glEnable( GLC.GL_LIGHT1 );
 
  (* Setup The Ambient Light *)
  GL.glLightfv( GLC.GL_LIGHT2, GLC.GL_AMBIENT, SYSTEM.ADR(LightAmbient[0]) );

  (* Setup The Diffuse Light *)
  GL.glLightfv( GLC.GL_LIGHT2, GLC.GL_DIFFUSE, SYSTEM.ADR(LightDiffuse[0]) );
  
  LightPosition[0]:= -1.0; LightPosition[1]:= -1.0; LightPosition[2]:= 1; LightPosition[3]:= 0.0;
  LightPosition2[0]:= 0.0; LightPosition2[1]:= 1.0; LightPosition2[2]:= 0; LightPosition2[3]:= 0.0; 
  
   GL.glLightfv( GLC.GL_LIGHT1, GLC.GL_POSITION, SYSTEM.ADR(LightPosition[0]) );
   GL.glLightfv( GLC.GL_LIGHT2, GLC.GL_POSITION, SYSTEM.ADR(LightPosition2[0]) );
   
    GL.glEnable( GLC.GL_LIGHT1);
    GL.glEnable( GLC.GL_LIGHT2);
  
  GL.glColorMaterial(GLC.GL_FRONT_AND_BACK, GLC.GL_AMBIENT_AND_DIFFUSE);
  
   GL.glEnable(GLC.GL_LIGHTING);

  (* Full Brightness, 50% Alpha ( NEW ) *)
  GL.glColor4f( 1.0, 1.0, 1.0, 0.5);
  
  GL.glEnable(GLC.GL_FOG);
  GL.glEnable(GLC.GL_COLOR_MATERIAL);
    GL.glFogi(GLC.GL_FOG_MODE, GLC.GL_EXP);
  GL.glFogfv(GLC.GL_FOG_COLOR,SYSTEM.ADR(blue[0]));
  GL.glFogf(GLC.GL_FOG_DENSITY, 0.031);
  

GL.DelFCR();
 
END InitGL;

PROCEDURE LightTick(x,y,z:REAL);
BEGIN
	LightPosition[0]:=x ; LightPosition[1]:=y; LightPosition[2]:= z; LightPosition[3]:=0.0;	
	GL.glLightfv( GLC.GL_LIGHT1, GLC.GL_POSITION, SYSTEM.ADR(LightPosition[0]) );
	
	
(*	GL.glLightf( GLC.GL_LIGHT1, GLC.GL_CONSTANT_ATTENUATION, 2.1); *)
END LightTick;


PROCEDURE DrawMode(dm: LONGINT);
VAR drawMode: LONGINT;
BEGIN
	drawMode := dm;  	
        IF drawMode = 0 THEN       (* fill mode*)
            GL.glPolygonMode(GLC.GL_FRONT_AND_BACK, GLC.GL_FILL);
            GL.glEnable(GLC.GL_DEPTH_TEST);
            GL.glEnable(GLC.GL_CULL_FACE);
        ELSIF drawMode = 1 THEN  (* wireframe mode *)
            GL.glPolygonMode(GLC.GL_FRONT_AND_BACK, GLC.GL_LINE);
            GL.glDisable(GLC.GL_DEPTH_TEST);
            GL.glDisable(GLC.GL_CULL_FACE);
        ELSE                    (* point mode *)

            GL.glPolygonMode(GLC.GL_FRONT_AND_BACK, GLC.GL_POINT);
            GL.glDisable(GLC.GL_DEPTH_TEST);
            GL.glDisable(GLC.GL_CULL_FACE);
	  END;
END DrawMode;

PROCEDURE genptlist;
VAR
	i,j,k: INTEGER;
BEGIN
	ptlist:=GL.glGenLists(1);
	GL.glNewList(ptlist, GLC.GL_COMPILE);  
	GL.glMaterialfv(GLC.GL_FRONT, GLC.GL_AMBIENT_AND_DIFFUSE, SYSTEM.ADR(red[0])); 
	GL.glBegin(GLC.GL_POINTS);
	FOR i:=-20 TO 20 DO FOR j:=-20 TO 20 DO FOR k:=-20 TO 20 DO
		GL.glVertex3f(i/10,j/10,k/10);
	END END END; 
	GL.glEnd;
	GL.glEndList();	
END genptlist;

PROCEDURE draw;
VAR
	i,j,k:LONGINT;
	a: REAL;
BEGIN
	InitGL;
	GL.SetFCR();
	GL.glMatrixMode(GLC.GL_PROJECTION);
	GL.glLoadIdentity();
	GL.glFrustum(-0.001,0.001,-0.001,0.001,0.001,1500); 
	GL.glClear((GLC.GL_COLOR_BUFFER_BIT+GLC.GL_DEPTH_BUFFER_BIT));	
 	GL.glEnable( GLC.GL_TEXTURE_2D );
 	GL.glMatrixMode(GLC.GL_MODELVIEW);
	GL.glLoadIdentity(); 	
	GL.glScalef(TR,TR,TR);	
	GL.DelFCR();
	a:= camera.cameraphi*rad2deg;
	GL.SetFCR();	
	GL.glRotatef(a,1,0,0); 		
	GL.DelFCR();
	a:= 90+camera.cameratheta*rad2deg;
	GL.SetFCR();
	GL.glRotatef(a,0,1,0); 		
	GL.glTranslatef(-camera.cam.x, -camera.cam.z,-camera.cam.y); 	
	GL.glFogf(GLC.GL_FOG_DENSITY, fogdensity);
	GL.DelFCR();
	XLTLGL.draw; 
	GL.glXSwapBuffers(display, win);

END draw;

PROCEDURE MainLoop;
VAR	
	timer : Kernel.MilliTimer; 	
	t: LONGINT;
	frame: LONGINT;
BEGIN
	Kernel.SetTimer(timer,3000);	
	WHILE alive DO	
		INC(frame);
		IF frame=1000 THEN
			frame:=0;
			t:=Kernel.Elapsed(timer);
			Kernel.SetTimer(timer,3000);	
			Out.Int(t,4);
			Out.Ln
		END;
		LoopForEvents; 	
		camera.tick;
		XLTLBase.tick;
		draw;
	END;
END MainLoop;	

PROCEDURE Open*;
BEGIN
	alive:=TRUE;
	debugevents:=FALSE;
	XLTLBase.worldalive:=TRUE;
	XLTLBase.speed:=0.001;
	axis:="y";	
	mousex:=200;
	mousey:=200;
	NEW(rand);
	InitWindow(400,400, 'XOLOTL-HYBRID' );	
	InitGL; 	
	genptlist;
	DrawMode(0);
	fogdensity:=0.031;
	XLTLMarsh.loadmarsh;	
	NEW(camera); 	
	MainLoop;
	Close;	
END Open;

BEGIN
	
END XLTLRenderer.

SystemTools.FreeDownTo  XLTLBase~



