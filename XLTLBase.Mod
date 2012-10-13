MODULE XLTLBase;

IMPORT  Math, Random, GL:=OpenGL, GLC := OpenGLConst, Out:=KernelLog, 
		SYSTEM, Raster, WMGraphics, WMFontManager, Commands;
CONST
	W*=150;
	H*=150;
	W2*=W DIV 2;
	W25*=W DIV 25;
	H2*=H DIV 2;
	H25*=H DIV 25;	
	TR*=100;  (* tracer to rasterizer scaling constant *)
			
TYPE Name* = ARRAY 32 OF CHAR;

TYPE PT*= RECORD
	x*,y*,z*: REAL
END;

TYPE COLOR*=RECORD
	red*,green*,blue*,alpha*:REAL
END;

TYPE FRF*=PROCEDURE(p:PT):BOOLEAN;

TYPE P=PROCEDURE (v:Voxel):Voxel;

TYPE Texture*=ARRAY 1 OF GL.GLuint; 

TYPE IPT*=RECORD
	i*,j*,k*: INTEGER
END;

TYPE BOX*=RECORD
	p*,q*: PT;
END;

TYPE Cube=RECORD
	xyz:PT;
	scale:REAL;
	texture: Texture
END;

TYPE Aperture* = RECORD
	width*, height*: REAL
END;

TYPE Ray* = RECORD
	theta*, phi*: REAL;
	origin*, xyz*, dxyz*, ddxyz*, lxyz*, popdelta*: PT;	
	terminalvoxel*: Voxel; 
	terminate*: BOOLEAN;
	i*, j*, k* (* , recursion* *) : INTEGER;
	scale*: LONGINT;
	length*: REAL; 
	di*,dj*,dk*: BOOLEAN;
	changed*,traced, far*: BOOLEAN; 
	face*: INTEGER;
	normal*,bloxnorm*: PT;  
	corner*:PT;
	dtl*: LONGINT;
END; 

TYPE RAYS*= POINTER TO ARRAY W, H OF Ray;

TYPE V*= OBJECT
PROCEDURE tick*;
END tick;
PROCEDURE register*;
VAR i: INTEGER;
BEGIN
	i := 0;
	WHILE voxelist[i] # NIL DO INC(i) END;
	IF i < 99 THEN voxelist[i] := SELF END; 
END register;

END V;

TYPE Voxel*=OBJECT(V)
VAR
	passable*, lock*: BOOLEAN;
	imposter*: Voxel;
	copymarker*: BOOLEAN;	
	
PROCEDURE Shade*(VAR ray: Ray);
END Shade;
PROCEDURE deathray*(VAR ray: Ray);
END deathray;
PROCEDURE move*(VAR dx, dy, dz: REAL; VAR blocked: BOOLEAN);
END move;
PROCEDURE probe*(x,y,z: REAL):Voxel;
BEGIN
	RETURN(SELF);
END probe;
PROCEDURE passprobe*(x,y,z: REAL):BOOLEAN;
BEGIN
	RETURN(passable);
END passprobe;

PROCEDURE add*(VAR a,b: Voxel);
END add;
PROCEDURE clone*():Voxel;
BEGIN
	RETURN(SELF)
END clone;

PROCEDURE copyclear*;
BEGIN
	copymarker:=FALSE;
END copyclear;

PROCEDURE dlist*;
BEGIN
	
END dlist;

PROCEDURE ddlist*(corner: PT; scale: REAL);
BEGIN
	
END ddlist;

END Voxel; 

TYPE MSV*= OBJECT(Voxel)		(* Base type for all mspace cell types. *)

PROCEDURE stroke*(p:PT; resolution: LONGINT; voxel:Voxel); (* VAR to return actual center and resolution in place of requested *)
END stroke;
PROCEDURE strokep*(x,y,z: REAL; resolution: LONGINT; voxel:Voxel); (* VAR to return actual center and resolution in place of requested *)
VAR p:PT;
BEGIN
	p.x:=x; p.y:=y; p.z:=z;
	stroke(p,resolution,voxel);
END strokep;
PROCEDURE strokerec*(p:PT; resolution,scale: LONGINT; voxel:Voxel);
END strokerec;
PROCEDURE erase*(p:PT; resolution:LONGINT);
END erase;
PROCEDURE eraserec*(p:PT; resolution,scale:LONGINT);
END eraserec;
PROCEDURE split*;
END split;
PROCEDURE clear*(p:PT; level: LONGINT);
END clear;
PROCEDURE clearrec*(p:PT; level: LONGINT);
END clearrec;

PROCEDURE FRaster*( f: FR; resolution: LONGINT); 
END FRaster;

PROCEDURE FRasterSolid*( f: FR; resolution: LONGINT); 
END FRasterSolid;

PROCEDURE FRasterrec*(f:FR; resolution: LONGINT; origin: PT; scale: LONGINT); 
END FRasterrec;

PROCEDURE FRasterrecSolid*(f:FR; resolution: LONGINT; origin: PT; scale: LONGINT); 
END FRasterrecSolid;

PROCEDURE deepclone*():Voxel;
VAR	v:Voxel;
BEGIN
	NEW(v);
	RETURN(v)
END deepclone;

END MSV;

TYPE FR*=OBJECT
VAR
	bbc1*,bbc2*,norml*: PT;		(*any two diagonally opposite corners of the bounding box of the object *)
	scale*: REAL; 	(*might be needed as this object is handed down to mcell levels in v-rasterization*)
	vox*,imposter*: Voxel;
	mir*: REAL;
	allowdeath*,passable*:BOOLEAN;
	
PROCEDURE in*(p:PT):BOOLEAN;
VAR
	d:REAL;
BEGIN
	d:=d2s(p);
	RETURN(d<0)
END in;

PROCEDURE d2s*(p:PT):REAL;  (* distance to surface *)
BEGIN
	norml:=p;
	RETURN 0
END d2s;

PROCEDURE closestPT*(p:PT):PT;  
VAR
	cp: PT;
BEGIN
	RETURN cp
END closestPT;

PROCEDURE normal*(p:PT):PT;
BEGIN
	normalizePT(norml);		(* norml is often calculated in d2s but not normalized there *)
	RETURN norml					(* this is the normal for the most recent point handed to d2s *)
END normal;

PROCEDURE setvoxel*(v:Voxel);  
BEGIN
	vox:=v;
END setvoxel;

PROCEDURE setimposter*(v:Voxel);  
BEGIN
	imposter:=v
END setimposter;

PROCEDURE getimposter*(p:PT):Voxel;
BEGIN
	RETURN imposter
END getimposter;

PROCEDURE mirror*(p:PT):REAL;
BEGIN
	RETURN mir
END mirror;

PROCEDURE voxel*(p:PT):Voxel;
BEGIN
	RETURN vox
END voxel;

PROCEDURE death*(p:PT):BOOLEAN;
BEGIN
	RETURN allowdeath
END death;

PROCEDURE pass*(p:PT):BOOLEAN;
BEGIN
	RETURN passable
END pass;

END FR;

VAR
	voxelist: ARRAY 100 OF V;
	fog*:REAL;
	rlimit*: INTEGER;
	iterlimit*: LONGINT;
	speed*:REAL;
	frame*: LONGINT;
	rand*:Random.Generator;
	worldalive*, mtoggle*: BOOLEAN;
	gravity*:LONGINT;
	fuzzon*, STOP*: BOOLEAN;
	singleray*: Ray;	(* for when a single ray is most convenient *)
	blankray*: Ray;
	Face*: ARRAY 6 OF PT;
	EMPTY*,SOLID*: Voxel;
	deathflag*:BOOLEAN;
	rays*:RAYS;
	LOOK*, LLOOK*: Ray;
	copybrowserworld*, injection*: Voxel;
	world*: MSV;
	camera*,cursor*,previouscursor*,Origin*: PT;
	cursorvox*:Voxel;

	m2sdelta*,m3sdelta*:REAL;
	DTL*,DTL2*: LONGINT;
	avatar*,imposter*:Voxel;
	avatarsize*: LONGINT;
	avdist*:REAL;
	axotex*:Texture; 
PROCEDURE updatecamera*(x,y,z,a,b,c:  REAL);
BEGIN
	previouscursor:=cursor;
	camera.x:=x; camera.y:=y; camera.z:=z;
	cursor.x:=x+a; cursor.y:=y+b; cursor.z:=z+c; 
END updatecamera;
	
PROCEDURE clearvoxelist*;
VAR i: INTEGER;
BEGIN
	FOR i:=0 TO 99 DO voxelist[i]:=NIL END 
END clearvoxelist;

PROCEDURE clamp*(VAR x: REAL);
BEGIN
	IF x < 0 THEN x := 0 ELSIF x>1 THEN x := 0.9999999 END;
END clamp;

PROCEDURE clamp3*(VAR r,g,b: REAL);
BEGIN
	IF r < 0 THEN r := 0 ELSIF r>1 THEN r := 0.9999999 END;
	IF g < 0 THEN g := 0 ELSIF g>1 THEN g := 0.9999999 END;
	IF b < 0 THEN b := 0 ELSIF b>1 THEN b := 0.9999999 END;
END clamp3;

PROCEDURE clamPT*(VAR a: PT);
BEGIN
	IF a.x < 0 THEN a.x := 0 ELSIF a.x>=1 THEN a.x := 0.9999999 END;
	IF a.y < 0 THEN a.y := 0 ELSIF a.y>=1 THEN a.y := 0.9999999 END;
	IF a.z < 0 THEN a.z := 0 ELSIF a.z>=1 THEN a.z := 0.9999999 END;
END clamPT;

PROCEDURE inzerodotdotonePT*(a: PT):BOOLEAN;
BEGIN
	IF a.x < 0 THEN  RETURN FALSE END;	
	IF a.x >1  THEN  RETURN FALSE END;
	IF a.y < 0 THEN  RETURN FALSE END;	
	IF a.y >1  THEN  RETURN FALSE END;
	IF a.z < 0 THEN  RETURN FALSE END;	
	IF a.z >1  THEN  RETURN FALSE END;	
	RETURN TRUE;
END inzerodotdotonePT;

PROCEDURE addPT*(p,q: PT):PT;
VAR
	r: PT;
BEGIN
	r.x:=p.x+q.x; r.y:=p.y+q.y; r.z:=p.z+q.z;
	RETURN(r);
END addPT;

PROCEDURE subPT*(p,q: PT):PT;
VAR
	r: PT;
BEGIN
	r.x:=p.x-q.x; r.y:=p.y-q.y; r.z:=p.z-q.z;
	RETURN(r);
END subPT;

PROCEDURE mulPT*(p: PT; d: REAL):PT;
VAR
	r: PT;
BEGIN
	r.x:=p.x*d; r.y:=p.y*d; r.z:=p.z*d;
	RETURN(r);
END mulPT;

PROCEDURE divPT*(p: PT; d: REAL):PT;
VAR
	r: PT;
BEGIN
	r.x:=p.x/d; r.y:=p.y/d; r.z:=p.z/d;
	RETURN(r);
END divPT;


PROCEDURE mkPT*(x,y,z: REAL): PT;
VAR
	p:PT;
BEGIN
	p.x:=x; p.y:=y; p.z:=z;
	RETURN(p);
END mkPT;

PROCEDURE fuzz3*(VAR x,y,z: REAL; fuzz: REAL);
VAR
	q: REAL;
BEGIN
	q := rand.Uniform()*fuzz - fuzz/2;
	x := x+q; y := y + q; z :=z + q;
	clamp3(x,y,z);
END fuzz3;

PROCEDURE fuzz3noclamp*(VAR x,y,z: REAL; fuzz: REAL);
VAR
	q: REAL;
BEGIN
	q := rand.Uniform()*fuzz - fuzz;
	x := x+q; y := y + q; z :=z + q;
END fuzz3noclamp;

PROCEDURE fuzznorm3*(VAR x,y,z: REAL; fuzz: REAL);
VAR
	q: REAL;
BEGIN
	q := rand.Uniform()*fuzz - fuzz;
	x := x+q; y := y + q; z :=z + q;
	normalize(x,y,z);
END fuzznorm3;

PROCEDURE fzz3*(VAR x,y,z: REAL; fuzz: REAL);
VAR
	q: REAL;
BEGIN
	q := rand.Uniform()*fuzz - fuzz;
	x := x+q; y := y + q; z :=z + q;
END fzz3;

PROCEDURE tick*;
VAR i: INTEGER;
BEGIN
    i := 0;
	WHILE i < 20 DO
		IF voxelist[i] # NIL THEN voxelist[i].tick END;
		INC(i);
	END;
	INC(frame);    
END tick; 


PROCEDURE cleartick*;
VAR i: INTEGER;
BEGIN
	i:=0;
	WHILE voxelist[i]#NIL DO
		voxelist[i]:=NIL;
		INC(i)
	END
END cleartick; 

PROCEDURE RESET*;
BEGIN
  frame:=0;
END RESET;

PROCEDURE STOPGO*;
BEGIN
 	STOP := ~STOP;
END STOPGO;

PROCEDURE normalize*(VAR x,y,z: REAL);
VAR
	d: REAL;
BEGIN
	d := Math.sqrt(x*x + y*y+z*z);
	IF d = 0 THEN 
		x := 1;
		d := 1;
	END;
	x := x/d; y := y/d; z:= z/d
END normalize;	

PROCEDURE printPT*(p:PT);
BEGIN
(* Where is AosOut.Real()? *)
(*	Out.Real(p.x, 10);
	Out.Real(p.y, 10);
	Out.Real(p.z, 10);
	Out.Ln; *)
END printPT;

PROCEDURE normalizePT*(VAR n:PT);
VAR
	d: REAL;
BEGIN
	d := Math.sqrt(n.x*n.x + n.y*n.y +n.z*n.z);
	IF d = 0 THEN 
		n.x := 1;
		d := 1;
	END;
	n.x := n.x/d; n.y := n.y/d; n.z:=n.z/d
END normalizePT;	

PROCEDURE normalizePTd*(VAR n:PT; VAR d:REAL);
BEGIN
	d := Math.sqrt(n.x*n.x + n.y*n.y +n.z*n.z);
	IF d = 0 THEN 
		n.x := 1;
		d := 1;
	END;
	n.x := n.x/d; n.y := n.y/d; n.z:=n.z/d
END normalizePTd;	

PROCEDURE distance*(a,b: PT):REAL;
VAR
	x,y,z,d: REAL;
BEGIN
	x := (b.x-a.x);
	y := (b.y-a.y);
	z := (b.z-a.z);
	RETURN(Math.sqrt(x*x+y*y+z*z)); 
END distance;

PROCEDURE string*(CONST s: ARRAY OF CHAR);
BEGIN
	Out.String(s); Out.Ln;
END string;

PROCEDURE setPT*(VAR p:PT; x,y,z: REAL);
BEGIN
	p.x := x; 
	p.y := y;
	p.z := z;
END setPT;

PROCEDURE setnormPT*(VAR p:PT; x,y,z: REAL);
BEGIN
	p.x := x; 
	p.y := y;
	p.z := z;
	normalizePT(p);
END setnormPT;

PROCEDURE randPT*():PT;
VAR
	p:PT;
BEGIN
	p.x := rand.Uniform();	
	p.y := rand.Uniform();	
	p.z := rand.Uniform();	
	RETURN p
END randPT;

PROCEDURE randnormPT*():PT;
VAR
	p:PT;
BEGIN
	p.x := (rand.Uniform()*2)-1;	
	p.y := (rand.Uniform()*2)-1;	
	p.z := (rand.Uniform()*2)-1;	
	normalizePT(p);
	RETURN(p)
END randnormPT;

PROCEDURE randsphPT*(VAR p,n,center:PT; radius: REAL);
(*random point and surface normal on sphere *)
BEGIN
	p.x := (rand.Uniform()*2)-1;	
	p.y := (rand.Uniform()*2)-1;	
	p.z := (rand.Uniform()*2)-1;	
	normalizePT(p);
	n:=p;
	p.x:= center.x+(p.x*radius);
	p.y:= center.y+(p.y*radius);
	p.z:= center.z+(p.z*radius);	
END randsphPT;

PROCEDURE dot*(a,b:PT):REAL;
BEGIN
	normalizePT(a);
	normalizePT(b);
	RETURN(ABS(a.x*b.x+a.y*b.y+a.z+b.z));
END dot;

PROCEDURE dist*(a,b:PT):REAL;
VAR
	dx,dy,dz:REAL;
BEGIN
	dx := a.x-b.x;
	dy := a.y-b.y;
	dz := a.z-b.z;
	RETURN(Math.sqrt(dx*dx+dy*dy+dz*dz));
END dist;

PROCEDURE distsquared*(a,b:PT):REAL;
VAR
	dx,dy,dz:REAL;
BEGIN
	dx := a.x-b.x;
	dy := a.y-b.y;
	dz := a.z-b.z;
	RETURN(dx*dx+dy*dy+dz*dz);
END distsquared;

PROCEDURE midPT*(a,b:PT):PT;
VAR
	m:PT;
BEGIN
	m.x:=(a.x+b.x)/2;
	m.y:=(a.y+b.y)/2;
	m.z:=(a.z+b.z)/2;
	RETURN(m)
END midPT;

PROCEDURE Exit*(ray: Ray):PT;
VAR
	drx, dry, drz: REAL;
	exit:PT;
BEGIN
	clamPT(ray.lxyz);
	IF ray.dxyz.x>0 THEN
		drx:= (1-ray.lxyz.x)/ ray.dxyz.x
	ELSE
		drx :=  (-ray.lxyz.x) / ray.dxyz.x
	END;
	IF ray.dxyz.y > 0 THEN
		dry := (1 - ray.lxyz.y) / ray.dxyz.y
	ELSE
		dry :=  (-ray.lxyz.y) / ray.dxyz.y
	END;
	IF ray.dxyz.z > 0 THEN
		drz := (1-ray.lxyz.z) / ray.dxyz.z
	ELSE
		drz :=  (-ray.lxyz.z) / ray.dxyz.z
	END;
	IF (drx < dry) THEN
		IF (drx < drz ) THEN
			IF ray.dxyz.x>0 THEN
				exit.x:=1; exit.y:=ray.lxyz.y+drx*ray.dxyz.y; exit.z:=ray.lxyz.z+ drx*ray.dxyz.z;
			ELSE
				exit.x:=0; exit.y:=ray.lxyz.y+drx*ray.dxyz.y; exit.z:=ray.lxyz.z+ drx*ray.dxyz.z;
			END;	
		ELSE
			IF ray.dxyz.z>0 THEN
				exit.x:=ray.lxyz.x+drz*ray.dxyz.x; exit.y:=ray.lxyz.y+drz*ray.dxyz.y; exit.z:=1;
			ELSE
				exit.x:=ray.lxyz.x+drz*ray.dxyz.x; exit.y:=ray.lxyz.y+drz*ray.dxyz.y; exit.z:=0;
			END;		
		END;
	ELSIF (dry < drz) THEN
		IF ray.dxyz.y>0 THEN
			exit.x:=ray.lxyz.x+dry*ray.dxyz.x; exit.y:=1; exit.z:=ray.lxyz.z+dry*ray.dxyz.z;
		ELSE
			exit.x:=ray.lxyz.x+dry*ray.dxyz.x; exit.y:=0; exit.z:=ray.lxyz.z+dry*ray.dxyz.z;
		END;
	ELSE
		IF ray.dxyz.z>0 THEN
			exit.x:=ray.lxyz.x+drz*ray.dxyz.x; exit.y:=ray.lxyz.y+drz*ray.dxyz.y; exit.z:=1;
		ELSE
			exit.x:=ray.lxyz.x+drz*ray.dxyz.x; exit.y:=ray.lxyz.y+drz*ray.dxyz.y; exit.z:=0;
		END;		
	END;
	RETURN(exit);
END Exit;
	
BEGIN
	NEW(rand);
	NEW(rays);
	NEW(EMPTY);
	NEW(SOLID);
	EMPTY.passable:=TRUE;
	worldalive := TRUE;
	frame:=0;
	fog := 1/10;
	rlimit := 4;
	iterlimit := 500;
	STOP:=TRUE;
	Origin:=mkPT(0,0,0);   (* unneeded initialization *)
	blankray.scale := 1; 
	blankray.dtl:=125;
 	Face[0].x := 1; Face[0].y := 0; Face[0].z := 0; 
	Face[3].x := -1; Face[3].y := 0; Face[3].z := 0; 
	Face[1].x := 0; Face[1].y := 1; Face[1].z := 0; 
	Face[4].x := 0; Face[4].y := -1; Face[4].z := 0; 
	Face[2].x := 0; Face[2].y := 0; Face[2].z := 1; 
	Face[5].x := 0; Face[5].y := 0; Face[5].z := -1; 	
	m2sdelta:=25;
	m3sdelta:=25;
	DTL:=250;
	DTL2:=250;
	avatarsize:= 729;
	avdist:=0.01;
	GL.InitOpenGL;
	WMFontManager.Install;	
END XLTLBase.