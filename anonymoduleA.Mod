MODULE 	anonymoduleA;
IMPORT XLTLBase , XLTLVoxel, Random, XLTLMarsh, M2:=XLTLM2Space, M3:=XLTLM3Space, XLTLlife,
XLTLFRep, XLTLgeomobj, XLTLCellAutoVox, Out:=KernelLog, Commands, Modules, 
DS:=XLTLDynamicStrings, Streams, Files, XLTLCompiler, XLTLInjectionTarget;

PROCEDURE P*;
VAR
	
BEGIN
	XLTLBase.cursorvox:=XLTLMarsh.pinkhairedgirl;	
END P;

PROCEDURE test*(context : Commands.Context);
VAR
	woggle: DS.DynamicString;
	hash: DS.MD5Hash;
	f: Files.File;
	r: Files.Reader;
	s: DS.String;
	ch: CHAR;
	name, msg : ARRAY 64 OF CHAR; 
	res : LONGINT;
BEGIN
	XLTLBase.context:=context;
	name:="anonymoduleB";
	Modules.FreeModule(name, res, msg);	
	name:="anonymoduleB.Mod";	
	XLTLCompiler.CompileFile(name);
	IF res # 0 THEN context.out.String(msg)
	ELSE context.out.String("done.")
	END;
	NEW(woggle);
	f := Files.Old(name);	(* open an existing file *)
	IF f # NIL THEN
		Files.OpenReader(r, f, 0);
		LOOP
			ch := r.Get();	(* read a character from the buffer *)
			IF r.res # Streams.Ok THEN EXIT END;	(* end-of-file, or other error *)
			woggle.AppendCharacter(ch);
		END;
		s:=woggle.ToArrOfChar();
		Out.String(s^); 
		Out.Ln;		hash:= woggle.MD5();
		Out.String(hash);
		Out.Ln;
	ELSE
		Out.String("WARNING. ILLOGICAL LOGIC DETECTED. DOES NOT COMPUTE.")
	END;
	Out.String("anonymoduleA 65eep");
	Out.Ln
END test; 
BEGIN

END anonymoduleA.test

 anonymoduleB.Mod
