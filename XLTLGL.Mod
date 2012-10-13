MODULE XLTLGL;

IMPORT
	XLTLBase, XLTLBloom, GL:=OpenGL, GLC := OpenGLConst, Out:=KernelLog;

CONST
	TTP=1048576
TYPE 
	Voxel=XLTLBase.Voxel;
	PT=XLTLBase.PT;
	Texture=XLTLBase.Texture;

TYPE Cube=RECORD
	xyz:PT;
	scale:LONGINT;
	texture: Texture
END;

TYPE NCube=RECORD
	xyz:PT;
	scale:LONGINT;
	normal:PT;
	texture: Texture
END;

TYPE DLCube=RECORD  (*not really a cube*)
	xyz:PT;
	scale:LONGINT;
	rot: REAL;
	dlist: LONGINT
END;

TYPE Cubes=OBJECT
VAR
	q:ARRAY 100000 OF Cube;
	index,dlist*: LONGINT;

PROCEDURE flush;
BEGIN
	index:=0;
END flush;
	
PROCEDURE push(p:PT; scale:LONGINT; texture:Texture);
VAR
	a,b,c,d:LONGINT;
BEGIN{EXCLUSIVE}
	a:=ENTIER(p.x*TTP);
	b:=ENTIER(p.y*TTP);	
	c:=ENTIER(p.z*TTP);	
	IF ~filter.probe(a,b,c,scale) THEN
		filter.hash(a,b,c,scale);
		q[index].xyz:=p;
		q[index].scale:=scale;		
		q[index].texture:=texture;	
		INC(index);
	END
END push;

PROCEDURE draw;
VAR
	i:LONGINT;
	scale:REAL;
BEGIN
	GL.SetFCR();
	GL.glEnable(GLC.GL_LIGHTING);
	GL.glEnable( GLC.GL_TEXTURE_2D);
	FOR i:=0 TO index-1 DO	
		GL.DelFCR();
		scale:=1/q[i].scale;
		GL.SetFCR();
		GL.glPushMatrix;
		GL.glTranslatef(q[i].xyz.x, q[i].xyz.z, q[i].xyz.y); 
		GL.glScalef(scale,scale,scale);
		GL.glBindTexture( GLC.GL_TEXTURE_2D, q[i].texture[0]); 
		GL.glBegin( GLC.GL_QUADS);		
  		GL.glNormal3f( 0.0, 0.0, 1.0);
	  	GL.glTexCoord2f( 1.0, 0.0 ); GL.glVertex3f( 0.0, 0.0,  1.0 );
	  	GL.glTexCoord2f( 0.0, 0.0 ); GL.glVertex3f(  1.0, 0.0,  1.0 );
	  	GL.glTexCoord2f( 0.0, 1.0 ); GL.glVertex3f(  1.0,  1.0,  1.0 );
	  	GL.glTexCoord2f( 1.0, 1.0 ); GL.glVertex3f( 0.0,  1.0,  1.0 );
	  	
	  	GL.glNormal3f( 0.0, 0.0, -1.0);
	  	GL.glTexCoord2f( 0.0, 0.0 ); GL.glVertex3f( 0.0, 0.0, 0.0 );
	  	GL.glTexCoord2f( 0.0, 1.0 ); GL.glVertex3f( 0.0,  1.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 1.0 ); GL.glVertex3f(  1.0,  1.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 0.0 ); GL.glVertex3f(  1.0, 0.0, 0.0 );

	  	GL.glNormal3f( 0.0, 1.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 1.0 ); GL.glVertex3f( 0.0,  1.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 0.0 ); GL.glVertex3f( 0.0,  1.0,  1.0 );
	  	GL.glTexCoord2f( 0.0, 0.0 ); GL.glVertex3f(  1.0,  1.0,  1.0 );
	  	GL.glTexCoord2f( 0.0, 1.0 ); GL.glVertex3f(  1.0,  1.0, 0.0 );
	  	
	  	GL.glNormal3f( 0.0, -1.0, 0.0 );
	  	GL.glTexCoord2f( 0.0, 1.0 ); GL.glVertex3f( 0.0, 0.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 1.0 ); GL.glVertex3f(  1.0, 0.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 0.0 ); GL.glVertex3f(  1.0, 0.0,  1.0 );
	  	GL.glTexCoord2f( 0.0, 0.0 ); GL.glVertex3f( 0.0, 0.0,  1.0 );
	  		
	  	GL.glNormal3f( 1.0, 0.0, 0.0);
	  	GL.glTexCoord2f( 0.0, 0.0 ); GL.glVertex3f( 1.0, 0.0, 0.0 );
	  	GL.glTexCoord2f( 0.0, 1.0 ); GL.glVertex3f( 1.0,  1.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 1.0 ); GL.glVertex3f( 1.0,  1.0,  1.0 );
	  	GL.glTexCoord2f( 1.0, 0.0 ); GL.glVertex3f( 1.0, 0.0,  1.0 );
  	
	  	GL.glNormal3f( -1.0, 0.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 0.0 ); GL.glVertex3f( 0.0, 0.0, 0.0 );
	  	GL.glTexCoord2f( 0.0, 0.0 ); GL.glVertex3f( 0.0, 0.0,  1.0 );
	  	GL.glTexCoord2f( 0.0, 1.0 ); GL.glVertex3f( 0.0,  1.0,  1.0 );
	  	GL.glTexCoord2f( 1.0, 1.0 ); GL.glVertex3f( 0.0,  1.0, 0.0 );	
	  	GL.glEnd;
		GL.glPopMatrix;
	END;
	 GL.DelFCR()	
END draw;

END Cubes;

TYPE fleetingCubes=OBJECT
VAR
	q:ARRAY 10000 OF Cube;
	index,dlist*: LONGINT;

PROCEDURE flush;
BEGIN
	index:=0;
END flush;
	
PROCEDURE push(p:PT; scale:LONGINT; texture:Texture);
VAR
	a,b,c,d:LONGINT;
BEGIN{EXCLUSIVE}
	a:=ENTIER(p.x*TTP);
	b:=ENTIER(p.y*TTP);	
	c:=ENTIER(p.z*TTP);	
	IF ~fleetingfilter.probe(a,b,c,scale) THEN
		fleetingfilter.hash(a,b,c,scale);
		q[index].xyz:=p;
		q[index].scale:=scale;		
		q[index].texture:=texture;	
		INC(index);
	END
END push;

PROCEDURE draw;
VAR
	i:LONGINT;
	scale:REAL;
BEGIN
	GL.SetFCR();
	GL.glEnable(GLC.GL_LIGHTING);
	GL.glEnable( GLC.GL_TEXTURE_2D);
	FOR i:=0 TO index-1 DO	
		GL.DelFCR();
		scale:=1/q[i].scale;
		GL.SetFCR();
		GL.glPushMatrix;
		GL.glTranslatef(q[i].xyz.x, q[i].xyz.z, q[i].xyz.y); 
		GL.glScalef(scale,scale,scale);
		GL.glBindTexture( GLC.GL_TEXTURE_2D, q[i].texture[0]); 
		GL.glBegin( GLC.GL_QUADS);		
  		GL.glNormal3f( 0.0, 0.0, 1.0);
	  	GL.glTexCoord2f( 1.0, 0.0 ); GL.glVertex3f( 0.0, 0.0,  1.0 );
	  	GL.glTexCoord2f( 0.0, 0.0 ); GL.glVertex3f(  1.0, 0.0,  1.0 );
	  	GL.glTexCoord2f( 0.0, 1.0 ); GL.glVertex3f(  1.0,  1.0,  1.0 );
	  	GL.glTexCoord2f( 1.0, 1.0 ); GL.glVertex3f( 0.0,  1.0,  1.0 );
	  	
	  	GL.glNormal3f( 0.0, 0.0, -1.0);
	  	GL.glTexCoord2f( 0.0, 0.0 ); GL.glVertex3f( 0.0, 0.0, 0.0 );
	  	GL.glTexCoord2f( 0.0, 1.0 ); GL.glVertex3f( 0.0,  1.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 1.0 ); GL.glVertex3f(  1.0,  1.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 0.0 ); GL.glVertex3f(  1.0, 0.0, 0.0 );

	  	GL.glNormal3f( 0.0, 1.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 1.0 ); GL.glVertex3f( 0.0,  1.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 0.0 ); GL.glVertex3f( 0.0,  1.0,  1.0 );
	  	GL.glTexCoord2f( 0.0, 0.0 ); GL.glVertex3f(  1.0,  1.0,  1.0 );
	  	GL.glTexCoord2f( 0.0, 1.0 ); GL.glVertex3f(  1.0,  1.0, 0.0 );
	  	
	  	GL.glNormal3f( 0.0, -1.0, 0.0 );
	  	GL.glTexCoord2f( 0.0, 1.0 ); GL.glVertex3f( 0.0, 0.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 1.0 ); GL.glVertex3f(  1.0, 0.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 0.0 ); GL.glVertex3f(  1.0, 0.0,  1.0 );
	  	GL.glTexCoord2f( 0.0, 0.0 ); GL.glVertex3f( 0.0, 0.0,  1.0 );
	  		
	  	GL.glNormal3f( 1.0, 0.0, 0.0);
	  	GL.glTexCoord2f( 0.0, 0.0 ); GL.glVertex3f( 1.0, 0.0, 0.0 );
	  	GL.glTexCoord2f( 0.0, 1.0 ); GL.glVertex3f( 1.0,  1.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 1.0 ); GL.glVertex3f( 1.0,  1.0,  1.0 );
	  	GL.glTexCoord2f( 1.0, 0.0 ); GL.glVertex3f( 1.0, 0.0,  1.0 );
  	
	  	GL.glNormal3f( -1.0, 0.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 0.0 ); GL.glVertex3f( 0.0, 0.0, 0.0 );
	  	GL.glTexCoord2f( 0.0, 0.0 ); GL.glVertex3f( 0.0, 0.0,  1.0 );
	  	GL.glTexCoord2f( 0.0, 1.0 ); GL.glVertex3f( 0.0,  1.0,  1.0 );
	  	GL.glTexCoord2f( 1.0, 1.0 ); GL.glVertex3f( 0.0,  1.0, 0.0 );	
	  	GL.glEnd;
		GL.glPopMatrix;
	END;
	 GL.DelFCR()	
END draw;

END fleetingCubes;

TYPE NCubes=OBJECT
VAR
	q:ARRAY 100000 OF NCube;
	index,dlist*: LONGINT;

PROCEDURE flush;
BEGIN
	index:=0;
END flush;
	
PROCEDURE push(p:PT; scale:LONGINT; normal: PT; texture:Texture);
VAR
	a,b,c,d:LONGINT;
BEGIN{EXCLUSIVE}
	a:=ENTIER(p.x*TTP);
	b:=ENTIER(p.y*TTP);	
	c:=ENTIER(p.z*TTP);	
	IF ~filter.probe(a,b,c,scale) THEN
		filter.hash(a,b,c,scale);
		q[index].xyz:=p;
		q[index].scale:=scale;		
		q[index].normal:=normal;		
		q[index].texture:=texture;	
		INC(index);
	END
END push;

PROCEDURE draw;
VAR
	i:LONGINT;
	scale:REAL;
BEGIN
	GL.SetFCR();
		GL.glEnable(GLC.GL_LIGHTING);
		GL.glEnable( GLC.GL_TEXTURE_2D);
	FOR i:=0 TO index-1 DO	
		GL.DelFCR();
		scale:=1/q[i].scale;
		GL.SetFCR();
		GL.glPushMatrix;
		GL.glTranslatef(q[i].xyz.x, q[i].xyz.z, q[i].xyz.y); 
		GL.glScalef(scale,scale,scale);
		GL.glBindTexture( GLC.GL_TEXTURE_2D, q[i].texture[0]); 
		GL.glBegin( GLC.GL_QUADS);		
  		GL.glNormal3f( q[i].normal.x,q[i].normal.y,q[i].normal.z);
	  	GL.glTexCoord2f( 1.0, 0.0 ); GL.glVertex3f( 0.0, 0.0,  1.0 );
	  	GL.glTexCoord2f( 0.0, 0.0 ); GL.glVertex3f(  1.0, 0.0,  1.0 );
	  	GL.glTexCoord2f( 0.0, 1.0 ); GL.glVertex3f(  1.0,  1.0,  1.0 );
	  	GL.glTexCoord2f( 1.0, 1.0 ); GL.glVertex3f( 0.0,  1.0,  1.0 );
	  	
	  	GL.glTexCoord2f( 0.0, 0.0 ); GL.glVertex3f( 0.0, 0.0, 0.0 );
	  	GL.glTexCoord2f( 0.0, 1.0 ); GL.glVertex3f( 0.0,  1.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 1.0 ); GL.glVertex3f(  1.0,  1.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 0.0 ); GL.glVertex3f(  1.0, 0.0, 0.0 );
	  	
	  	GL.glTexCoord2f( 1.0, 1.0 ); GL.glVertex3f( 0.0,  1.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 0.0 ); GL.glVertex3f( 0.0,  1.0,  1.0 );
	  	GL.glTexCoord2f( 0.0, 0.0 ); GL.glVertex3f(  1.0,  1.0,  1.0 );
	  	GL.glTexCoord2f( 0.0, 1.0 ); GL.glVertex3f(  1.0,  1.0, 0.0 );
	  	

	  	GL.glTexCoord2f( 0.0, 1.0 ); GL.glVertex3f( 0.0, 0.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 1.0 ); GL.glVertex3f(  1.0, 0.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 0.0 ); GL.glVertex3f(  1.0, 0.0,  1.0 );
	  	GL.glTexCoord2f( 0.0, 0.0 ); GL.glVertex3f( 0.0, 0.0,  1.0 );
	  		
	  	GL.glTexCoord2f( 0.0, 0.0 ); GL.glVertex3f( 1.0, 0.0, 0.0 );
	  	GL.glTexCoord2f( 0.0, 1.0 ); GL.glVertex3f( 1.0,  1.0, 0.0 );
	  	GL.glTexCoord2f( 1.0, 1.0 ); GL.glVertex3f( 1.0,  1.0,  1.0 );
	  	GL.glTexCoord2f( 1.0, 0.0 ); GL.glVertex3f( 1.0, 0.0,  1.0 );
  	
	  	GL.glTexCoord2f( 1.0, 0.0 ); GL.glVertex3f( 0.0, 0.0, 0.0 );
	  	GL.glTexCoord2f( 0.0, 0.0 ); GL.glVertex3f( 0.0, 0.0,  1.0 );
	  	GL.glTexCoord2f( 0.0, 1.0 ); GL.glVertex3f( 0.0,  1.0,  1.0 );
	  	GL.glTexCoord2f( 1.0, 1.0 ); GL.glVertex3f( 0.0,  1.0, 0.0 );	
	  	GL.glEnd;
		GL.glPopMatrix;
	END;
	GL.DelFCR()
END draw;

END NCubes;

TYPE Dllist=OBJECT
VAR
	q:ARRAY 100000 OF DLCube;
	index: LONGINT;

PROCEDURE flush;
BEGIN
	index:=0;
END flush;

PROCEDURE push(p:PT; scale:LONGINT; rot: REAL; dlist: LONGINT);
VAR
	a,b,c,d:LONGINT;
BEGIN{EXCLUSIVE}
	a:=ENTIER(p.x*TTP);
	b:=ENTIER(p.y*TTP);	
	c:=ENTIER(p.z*TTP);	
	q[index].xyz:=p;
	q[index].scale:=scale;
	q[index].rot:=rot;	
	q[index].dlist:=dlist;					
	INC(index);
END push;

PROCEDURE draw;
VAR
	i:LONGINT;
	scale:REAL;
BEGIN
	GL.SetFCR();
	GL.glEnable(GLC.GL_CULL_FACE); 
	GL.glColor4f(0.9,0.5,0.95,0.7);
	GL.glEnable(GLC.GL_BLEND);
	GL.glBlendFunc(GLC.GL_SRC_ALPHA, GLC.GL_ONE_MINUS_SRC_ALPHA);
	FOR i:=0 TO index-1 DO	
		GL.DelFCR();
		scale:=1/q[i].scale;
		GL.SetFCR();
		GL.glPushMatrix;
		GL.glTranslatef(q[i].xyz.x, q[i].xyz.z, q[i].xyz.y); 
		GL.glScalef(scale,scale,scale);
		GL.glRotatef(q[i].rot, 0,1,0);
		GL.glCallList(q[i].dlist);
		GL.glPopMatrix;
	END;
	GL.glDisable(GLC.GL_BLEND);
	GL.glEnable(GLC.GL_CULL_FACE); 		
	GL.DelFCR()
END draw;
	
END Dllist;

VAR
	persistentcubes: ARRAY 67 OF Cubes;		
	npersistentcubes: ARRAY 67 OF NCubes;	
	fleetingcubes: fleetingCubes;
	i: INTEGER;
	dllist: Dllist;
	filter, filtera, filterb, fleetingfilter: XLTLBloom.Filter;
	frame, n: INTEGER;
		
PROCEDURE push*(p:PT; scale:LONGINT; texture:Texture; far:BOOLEAN);
BEGIN
	persistentcubes[n].push(p,scale,texture) 
END push;

PROCEDURE fleetingpush*(p:PT; scale:LONGINT; texture:Texture);
BEGIN
	fleetingcubes.push(p,scale,texture)
END fleetingpush;

PROCEDURE npush*(p:PT; scale:LONGINT; normal: PT; texture:Texture);
BEGIN
	npersistentcubes[n].push(p,scale,normal,texture)
END npush;

PROCEDURE dlpush*(p:PT; scale:LONGINT; rot: REAL; dlist: LONGINT);
BEGIN
	dllist.push(p,scale,rot, dlist)
END dlpush;

PROCEDURE draw*;
BEGIN
	FOR i:=0 TO 6 DO
		persistentcubes[i].draw
	END;
	fleetingcubes.draw;	
	fleetingcubes.flush;
	fleetingfilter.flush;		
	dllist.draw;
	dllist.flush;
	INC(frame);
	n:=frame MOD 7;
	persistentcubes[n].flush;	
	IF n=6 THEN filter.flush END
END draw;
		
BEGIN
	FOR i:=0 TO 6 DO
		NEW(persistentcubes[i]);
	END;
	NEW(fleetingcubes);
	NEW(dllist);
	NEW(filtera);
	NEW(filterb);
	NEW(fleetingfilter);
	filter:=filtera;
	frame:=0;
	n:=0	
END XLTLGL.

