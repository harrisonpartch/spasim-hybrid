MODULE XLTLFRep;

IMPORT Math, XLTLBase,XLTLVoxel,Raster, Graphics:=WMGraphics, Noise:=XLTLNoise;
	
TYPE 
	PT=XLTLBase.PT;
	COLOR=XLTLBase.COLOR;
	Voxel=XLTLBase.Voxel;
	Name = XLTLBase.Name;
	FR=XLTLBase.FR;
	MSV=XLTLBase.MSV

TYPE rprism= OBJECT(FR)

PROCEDURE&init*(c1,c2:PT);
BEGIN
	IF c1.x<c2.x THEN bbc1.x:=c1.x; bbc2.x:=c2.x ELSE bbc1.x:=c2.x; bbc2.x:=c1.x END;
	IF c1.y<c2.y THEN bbc1.y:=c1.y; bbc2.y:=c2.y ELSE bbc1.y:=c2.y; bbc2.y:=c1.y END;
	IF c1.z<c2.z THEN bbc1.z:=c1.z; bbc2.z:=c2.z ELSE bbc1.z:=c2.z; bbc2.z:=c1.z END;	
END init;

PROCEDURE in*(p:PT):BOOLEAN;
VAR
	a,b,c: BOOLEAN;
BEGIN
	a:= ((bbc1.x<p.x)&(p.x<bbc2.x))OR((bbc1.x>p.x)&(p.x>bbc2.x)) ;
	b:= ((bbc1.y<p.y)&(p.y<bbc2.y))OR((bbc1.y>p.y)&(p.y>bbc2.y)) ;
	c:= ((bbc1.x<p.z)&(p.z<bbc2.z))OR((bbc1.z>p.z)&(p.z>bbc2.z)) ;
	RETURN(a&b&c);
END in;
		
END rprism;

TYPE sphere*= OBJECT(FR)
VAR 
	radius*,iradius*: REAL;
	center*:PT;

PROCEDURE &init*(c:PT; r,ir: REAL);
BEGIN
	radius:=r*r;
	iradius:=ir*ir;
	r:=r*1.00001; (* don't want the sphere to quite touch the box *)
	bbc1.x:=c.x-r;
	bbc1.y:=c.y-r;
	bbc1.z:=c.z-r;	
	bbc2.x:=c.x+r;
	bbc2.y:=c.y+r;
	bbc2.z:=c.z+r;	
	center:=c;	
	mir:=0.8;
END init;

PROCEDURE reset*(c:PT; r: REAL);
BEGIN
	radius:=ABS(r);
	r:=r*1.00001; (* don't want the sphere to quite touch the box *)
	bbc1.x:=c.x-r;
	bbc1.y:=c.y-r;
	bbc1.z:=c.z-r;	
	bbc2.x:=c.x+r;
	bbc2.y:=c.y+r;
	bbc2.z:=c.z+r;	
	center:=c;	
END reset;

PROCEDURE setcenter*(x,y,z: REAL);
BEGIN
	center.x:=x; center.y:=y; center.z:=z
END setcenter;

PROCEDURE d2s*(p:PT):REAL;  (* distance to surface *)
BEGIN
	norml.x:= center.x-p.x; 
	norml.y:= center.y-p.y; 	
	norml.z:= center.z-p.z; 
	RETURN((norml.x*norml.x+norml.y*norml.y+norml.z*norml.z)-radius)
END d2s;

PROCEDURE normal*(p:PT):PT;
BEGIN
	XLTLBase.normalizePT(norml);	(* norml is often calculated in d2s but not normalized there *)
	RETURN norml					(* this is the normal for the most recent point handed to d2s *)
END normal;

PROCEDURE mirror*(p:PT):REAL;
BEGIN
	RETURN mir
END mirror;

END sphere;

TYPE noiseball*= OBJECT(sphere)
VAR
	va*: ARRAY 5 OF Voxel;
	seed*:LONGINT;
	octaves*:INTEGER;
	persistence*:LONGREAL;
	a*,b*,c*: REAL;
	
PROCEDURE d2s*(p:PT):REAL;  (* distance to surface *)
VAR
	d,r: REAL;
BEGIN
	norml.x:= center.x-p.x; 
	norml.y:= center.y-p.y; 	
	norml.z:= center.z-p.z; 
	d:=norml.x*norml.x+norml.y*norml.y+norml.z*norml.z;
	IF (d<radius) & (d>iradius) THEN 
		r:=Noise.noise3dperlin(a*p.x,b*p.y, c*p.z, seed,octaves,persistence)/1000 - 1/2000
	ELSE
		r:=1.0
	END;
	RETURN(r)  
END d2s;

END noiseball;

TYPE tilednoise*= OBJECT(FR)
VAR
	va*: ARRAY 5 OF Voxel;
	seed*:LONGINT;
	octaves*:INTEGER;
	persistence*:LONGREAL;
	a*,b*,c*: REAL;

	
PROCEDURE d2s*(p:PT):REAL;  (* distance to surface *)
BEGIN
	IF (p.z>(Noise.noise2dperlin(p.x,b*p.y,555544,3,3.5))) THEN
		RETURN(Noise.noise3dperlin(a*p.x,b*p.y,c*p.z, seed,octaves,persistence)/1000 - 1/2000)
	ELSE
		RETURN 1
	END  
END d2s;

PROCEDURE voxel*(p:PT):Voxel;
BEGIN
(*	RETURN va[(ENTIER(p.z*6) MOD 5)] *)
	RETURN va[XLTLBase.rand.Dice(5)] 
END voxel;

END tilednoise;

TYPE noise*= OBJECT(FR)
VAR
	va*: ARRAY 5 OF Voxel;
	seed*:LONGINT;
	octaves*:INTEGER;
	persistence*:LONGREAL;
	a*,b*,c*: REAL;
	
PROCEDURE d2s*(p:PT):REAL;  (* distance to surface *)
BEGIN
	RETURN(Noise.noise3dperlin(a*p.x,b*p.y, c*p.z, seed,octaves,persistence)/1000 - 1/2000)  
END d2s;

END noise;

TYPE ellipsoid*= OBJECT(FR)
VAR 
	radius: REAL;
	center0,center1,norml0,norml1:PT;	
	
PROCEDURE &init*(a,b:PT; m: REAL);

BEGIN
	center0:=a;	
	center1:=b;
	radius:=m;		
END init;

PROCEDURE setcenter*(x,y,z,a,b,c: REAL);
BEGIN
	center0.x:=x; center0.y:=y; center0.z:=z;
	center1.x:=x; center1.y:=y; center1.z:=z
END setcenter;

PROCEDURE d2s*(p:PT):REAL;  (* distance to surface *)
VAR
	d,e:REAL;
BEGIN
	norml0.x:= center0.x-p.x; 
	norml0.y:= center0.y-p.y; 	
	norml0.z:= center0.z-p.z; 
	norml1.x:= center1.x-p.x; 
	norml1.y:= center1.y-p.y; 	
	norml1.z:= center1.z-p.z; 
	d:= Math.sqrt(norml0.x*norml0.x+norml0.y*norml0.y+norml0.z*norml0.z);
	e:= Math.sqrt(norml1.x*norml1.x+norml1.y*norml1.y+norml1.z*norml1.z);
	norml.x:=(norml0.x+norml1.x)/2;
	norml.y:=(norml0.y+norml1.y)/2;
	norml.y:=(norml0.z+norml1.z)/2;
	RETURN((d+e)-radius)
END d2s;	
END ellipsoid;

TYPE cyl*= OBJECT(FR)
VAR 
	rsquared,lensq: REAL;
	p1,p2,d:PT;
	
PROCEDURE &init*(a,b:PT; r: REAL);

BEGIN
	rsquared:=r*r;
	p1:=a; p2:=b;
	d.x:=p2.x-p1.x; 
	d.y:=p2.y-p1.y;
	d.z:=p2.z-p1.z;
	lensq:=d.x*d.x+d.y*d.y+d.z*d.z;
	XLTLBase.setPT(norml,1,0,0)
END init;

PROCEDURE d2s*(p:PT):REAL;  (* distance to surface *)
VAR
	dot,dsq,a,b,c: REAL;
	pd:PT;
BEGIN
	pd.x:=p.x-p1.x; 
	pd.y:=p.y-p1.y;
	pd.z:=p.z-p1.z;
	dot:=pd.x*d.x+pd.y*d.y+pd.z*d.z;
	dsq:=(pd.x*pd.x+pd.y*pd.y+pd.z*pd.z)-dot*dot/lensq;
	RETURN(dsq-rsquared);	
END d2s;
		
END cyl;

TYPE plane*= OBJECT(FR)
VAR 
	d: REAL;
	p,cp:PT;
		
PROCEDURE &init*(a,b:PT); 
BEGIN
	p:=a;   norml:=b;
	norml.x:= norml.x + (XLTLBase.rand.Uniform()-1/2)/20;
	norml.y:= norml.y + (XLTLBase.rand.Uniform()-1/2)/20;
	norml.z:= norml.z + (XLTLBase.rand.Uniform()-1/2)/20;
	XLTLBase.normalizePT(norml);
	d:= -norml.x*p.x - norml.y*p.y - norml.z*p.z;
END init;

PROCEDURE mirror*(p:PT):REAL;
BEGIN
	IF FALSE THEN
		RETURN(1/2)
	ELSE
		RETURN(0)
	END 
END mirror;

PROCEDURE d2s*(m:PT):REAL;  (* distance to surface *)
BEGIN
	RETURN (m.x*norml.x+m.y*norml.y+m.z*norml.z+d);
END d2s;

PROCEDURE normal*(p:PT):PT;
BEGIN
	RETURN norml					
END normal;
		
END plane;


TYPE halfspace*= OBJECT(FR)
VAR 
	d: REAL;
	p,cp:PT;
		
PROCEDURE &init*(a,b:PT); 
BEGIN
	p:=a;   norml:=b;
	XLTLBase.normalizePT(norml);
	d:= -norml.x*p.x - norml.y*p.y - norml.z*p.z;
END init;

PROCEDURE mirror*(p:PT):REAL;
BEGIN
	IF FALSE THEN
		RETURN(1/2)
	ELSE
		RETURN(0)
	END 
END mirror;

PROCEDURE d2s*(m:PT):REAL;  (* distance to surface *)
VAR
	distance: REAL;
BEGIN
	
	distance:=m.x*norml.x+m.y*norml.y+m.z*norml.z+d;
	IF distance<0 THEN distance:=0 END;
	RETURN distance;
END d2s;

PROCEDURE normal*(p:PT):PT;
BEGIN
	RETURN norml					
END normal;
		
END halfspace;

TYPE landscape*= OBJECT(FR)
VAR 
	d: REAL;
	pt*,cp:PT;
	heightimage, colorimage: Raster.Image;
	fmt: Raster.Format;
	copy : Raster.Mode;
	heightW, heightH, colorW, colorH, bpr,adr: LONGINT;
	rarevox*:Voxel;
	z: REAL;
		
PROCEDURE &init*(a,b:PT; heightmap, colormap: Name); 
BEGIN
	pt:=a;   norml:=b;
	XLTLBase.normalizePT(norml);
	d:= -norml.x*pt.x - norml.y*pt.y - norml.z*pt.z;
	Raster.InitMode(copy, Raster.srcCopy);
	heightimage :=Graphics.LoadImage(heightmap, TRUE);
	colorimage :=Graphics.LoadImage(colormap, TRUE);
	ASSERT(heightimage#NIL);
	ASSERT(colorimage#NIL);
	IF heightimage#NIL THEN heightW := heightimage.width-1; heightH:= heightimage.height-1; END;
	IF colorimage#NIL THEN heightW := heightimage.width-1; heightH:= heightimage.height-1; END;
	z:=1
END init;

PROCEDURE d2s*(p:PT):REAL;  (* distance to surface *)
VAR
	r,b,g: REAL;
	tx,ty: LONGINT;
	pixel:Raster.Pixel;
BEGIN
	IF  heightimage#NIL THEN
		tx:=ENTIER(p.x*heightW); 
		ty:=ENTIER(p.y*heightH); 	
		Raster.Get(heightimage,tx,ty,pixel,copy);
		r := ORD(pixel[2])/255; g := ORD(pixel[1])/255; b := ORD(pixel[0])/255;	
		z:=ABS(p.z-(r+g+b)/20);
		cp.z:=z;
		norml.x:=0; norml.y:=0;norml.z:=-1;
	END;
	RETURN z
END d2s;

PROCEDURE closestPT*(p:PT):PT;  (* returns the closest point found in last d2s *)
BEGIN
	cp.x := p.x;
	cp.y := p.y;
	RETURN cp
END closestPT;

PROCEDURE normal*(p:PT):PT;
BEGIN
	RETURN norml					
END normal;

PROCEDURE voxel*(p:PT):Voxel;
BEGIN
	IF XLTLBase.rand.Uniform()<0.01 THEN 
		RETURN rarevox
	ELSE	
		RETURN vox
	END
END voxel;
		
END landscape;

TYPE cube*= OBJECT(FR)
VAR


PROCEDURE getcolor*(p:PT):COLOR;
VAR
	c:COLOR;
BEGIN
	c.red:=p.x; c.blue:=p.y; c.red:=p.z;
	RETURN c
END getcolor;

BEGIN

END cube;

TYPE hexgrid*= OBJECT(FR)  (*accidentally created from cyl *)
VAR 
	radius, rsquared,lensq: REAL;
	p1,p2,d:PT;
	
PROCEDURE &init*(a,b:PT; r: REAL);

BEGIN
	rsquared:=r*r;
	p1:=a; p2:=b;
	d.x:=p2.x-p1.x; 
	d.y:=p2.y-p1.y;
	d.z:=p2.z-p1.z;
	lensq:=d.x*d.x+d.y*d.y+d.z*d.z;
END init;

PROCEDURE d2s*(p:PT):REAL;  (* distance to surface *)
VAR
	dot,dsq,a,b,c: REAL;
	pd:PT;
BEGIN
	pd.x:=p.x-p1.x; 
	pd.y:=p.y-p1.y;
	pd.z:=p.z-p1.z;
	dot:=pd.x*p.x+pd.y*p.y+pd.z*p.z;
	XLTLBase.normalizePT(pd);
	norml:=pd;
	dsq:=(pd.x*pd.x+pd.y*pd.y+pd.z*pd.z)-dot*dot/lensq;
	RETURN(dsq-rsquared);	
END d2s;
		
END hexgrid;


END XLTLFRep.