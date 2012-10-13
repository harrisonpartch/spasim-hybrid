MODULE XLTLGL; (** AUTHOR "fnecati"; PURPOSE "Adjusted for commandline run"; *)

IMPORT
	XLTLBase, GL:=OpenGL, GLC := OpenGLConst;

TYPE 
	Voxel=XLTLBase.Voxel;
	PT=XLTLBase.PT;
	Texture=XLTLBase.Texture;


TYPE Cube=RECORD
	xyz:PT;
	scale:REAL;
	texture: Texture
END;

TYPE Dirty=OBJECT
VAR
	q:ARRAY 100000 OF Voxel;
	index: LONGINT

PROCEDURE flush*;
VAR
	i: LONGINT;
BEGIN
(*	FOR i:=0 TO index-1 DO	
		q[i].dirty:=FALSE;
	END;	
*)	index:=0
END flush;
	
PROCEDURE push*(vox: Voxel);
BEGIN{EXCLUSIVE}
	q[index]:=vox;	
	INC(index);
END push;

END Dirty;

TYPE Cubes=OBJECT
VAR
	q:ARRAY 100000 OF Cube;
	index,dlist: LONGINT;
	
PROCEDURE flush*;
BEGIN
	index:=0;
END flush;
	
PROCEDURE push*(xyz:PT; scale:REAL; texture:Texture);
BEGIN{EXCLUSIVE}
	q[index].xyz:=xyz;
	q[index].scale:=1/scale;		
	q[index].texture:=texture;	
	INC(index);
END push;

PROCEDURE gendlist*;
VAR
	i,j,k:LONGINT
BEGIN
	GL.SetFCR();
	dlist:=GL.glGenLists(1);
	GL.glNewList(dlist, GLC.GL_COMPILE); 
	FOR i:=0 TO index-1 DO	
		GL.glPushMatrix;
		GL.glTranslatef(q[i].xyz.x, q[i].xyz.z, q[i].xyz.y); 
		GL.glScalef(q[i].scale, q[i].scale, q[i].scale);
		GL.glBindTexture( GLC.GL_TEXTURE_2D, q[i].texture[0]); 
		GL.glBegin( GLC.GL_QUADS);		
  		GL.glNormal3f( 0.0, 0.0, 1.0 );
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
	  	GL.glEnd();
		GL.glPopMatrix;
	END;
	GL.glEndList();	
 GL.DelFCR();	
END gendlist;

PROCEDURE draw*;
VAR
	i:LONGINT;
BEGIN
 GL.SetFCR();	
	FOR i:=0 TO index-1 DO	
		GL.glPushMatrix;
		GL.glTranslatef(q[i].xyz.x, q[i].xyz.y, q[i].xyz.z); 
		GL.glScalef(q[i].scale, q[i].scale, q[i].scale); 
		GL.glBegin( GLC.GL_QUADS );
 	 		
	  	GL.glNormal3f( 0.0, 0.0, 1.0 );
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
	  	GL.glEnd();
		GL.glPopMatrix;
	END;	
 GL.DelFCR();	
END draw;

END Cubes;

VAR
	cubelist*:Cubes;	
	dirtylist*: Dirty;

BEGIN
	NEW(cubelist);
	NEW(dirtylist)

END XLTLGL.

