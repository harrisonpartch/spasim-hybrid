MODULE mdemo6;
IMPORT XLTLBase, Commands, Modules, DS:=XLTLDynamicStrings, Streams, Files, XLTLCompiler,  Out:=KernelLog;

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
	name:="mdemo5";
	Modules.FreeModule(name, res, msg);	
	name:="mdemo5.Mod";	
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
(*		Out.String(s^); *)
		Out.Ln;
		Out.Ln;
		hash:= woggle.MD5();
		Out.String(hash);
		Out.Ln;
	(*	woggle.Append("a");
		hash:= woggle.MD5();
		Out.String(hash);	*)
	ELSE
		Out.String("WARNING. ILLOGICAL LOGIC DETECTED. DOES NOT COMPUTE.")
	END;
	Out.String("mdemo5 zxeep");
	Out.Ln;
END test; 

END mdemo6.test ~

mdemo5.test ~



