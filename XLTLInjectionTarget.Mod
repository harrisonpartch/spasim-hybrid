MODULE XLTLInjectionTarget;
IMPORT XLTLBase, Out:=KernelLog, DS:=XLTLDynamicStrings;

CONST size=1000;

TYPE Entry=RECORD
	key: DS.MD5Hash;
	value: PROCEDURE;
END;
	
VAR
	dict: ARRAY size OF Entry;
	n: LONGINT;

PROCEDURE inject*(key: DS.MD5Hash; value: PROCEDURE);
BEGIN
	IF n<size THEN
		dict[n].key:=key;
		dict[n].value:=value;
		INC(n)
	END;
END inject;

PROCEDURE do(hash:DS.MD5Hash);
VAR
	i: LONGINT;
	p: PROCEDURE;
	done: BOOLEAN;
BEGIN
	FOR i:=0 TO size-1 DO
		IF hash=dict[i].key THEN
			dict[i].value()
		END	
	END	
END do;

END XLTLInjectionTarget.