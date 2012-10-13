MODULE 	m666;
IMPORT XLTLBase , XLTLVoxel, Random, XLTLMarsh, M2:=XLTLM2Space, M3:=XLTLM3Space, XLTLlife,
XLTLFRep, XLTLgeomobj, XLTLCellAutoVox, Out:=KernelLog;

TYPE 	PT=XLTLBase.PT;
		Ray = XLTLBase.Ray;
		Voxel = XLTLBase.Voxel;
		Name = XLTLBase.Name;

TYPE GroVox=OBJECT(XLTLCellAutoVox.FuseVox)
PROCEDURE anonyhook;	
VAR
	v: Voxel;
	g:GroVox;
BEGIN
	v:=XLTLBase.world.probe(center.x+delta,center.y,center.z);
	IF (v=NIL) OR v.passable THEN
		NEW(g);
		g.set(XLTLBase.cursor,XLTLBase.avatarsize);
		XLTLBase.world.stroke(XLTLBase.cursor,XLTLBase.avatarsize, g);
	END
END anonyhook;
END GroVox;

PROCEDURE P*;
VAR
	g: GroVox;
BEGIN
	NEW(g);
	XLTLBase.cursorvox:=g;	
END P;

END	m666.

m666.P