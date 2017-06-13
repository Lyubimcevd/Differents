LPARAMETERS ctype,cPrName
cConnString="driver={SQL Server};SERVER=nitel-hp;uid=ldo;pwd=IfLyyz4sCJ;DATABASE=uit;WSID=VFP;APP=VFP;"
con_bd=SQLSTRINGCONNECT(cConnString, .T.)
SET PATH to "D:\PODDANW\" ADDITIVE
SET PATH TO "I:\PODDANW\" ADDITIVE
SET SQLBUFFERING ON
SET DATE GERMAN
SET CENTURY ON

cur_date = ALLTRIM(DTOC(DATE()))
print_path = "&PDTXT/finish.txt"
SET PRIN TO &print_path
SET CONS OFF
SET PRINT ON
?CPCONVERT(1251,866,' �������� '+cPrName+' �� '+cur_date)
?REPL('-',(67))
?CPCONVERT(1251,866,': ��� : ����� : ���������� ��������. : ���������� ���������. :')
?REPL('-',(67))
?

CREATE CURSOR tmp(ci N,np N,kolvo C(7),kolvo_real C(7))
str_query = "select convert(char(10),dt,104) as dt from bpd.registr_documents where doc_type = ";
			+ALLTRIM(STR(ctype))
b = SQLEXEC(con_bd,str_query,'cur_unic')
SELECT 'cur_unic'
RELEASE Arr
COPY TO ARRAY Arr
cur_date = Arr[ALEN(Arr,1)]
str_query = "select ci,np,kolvo,invtp from bpd.registr_documents where doc_type = ";
			+ALLTRIM(STR(ctype))+ " and dt = convert(date,'"+cur_date+"')"
b = SQLEXEC(con_bd,str_query,'cur_unic')
IF RECCOUNT('cur_unic')#0
	SELECT 'cur_unic'
	RELEASE Arr
	COPY TO ARRAY Arr	
	FOR i = 1 TO ALEN(Arr,1)
		cur_ci = ALLTRIM(STR(Arr[i,1]))
		cur_np = ALLTRIM(STR(Arr[i,2]))
		cur_kolvo = ALLTRIM(STR(Arr[i,3]))
		IF ISNULL(Arr[i,4])
			str_query = "select COUNT(*) FROM bpd.rn WHERE grup<700 AND dvv='";
							+CHRTRAN(cur_date,'.','')+"' AND ce = "+cur_ci+" AND np = ";
							+cur_np+" group by ce,np "
		ELSE
			str_query = "select COUNT(*) FROM bpd.brigv WHERE grup<700 AND dvv='";
							+CHRTRAN(cur_date,'.','')+"' AND ce = "+cur_ci+" AND np = ";
							+cur_np+" group by ce,np "
		ENDIF			
		b = SQLEXEC(con_bd,str_query,'cur_unic')
		IF RECCOUNT('cur_unic')=0
			IF ISNULL(Arr[i,4])
				INSERT INTO tmp(ci,np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],cur_kolvo,'0')
			ELSE
				INSERT INTO tmp(ci,np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],;
 ALLTRIM(STR(Arr[i,4]))+"/"+cur_kolvo,'0')
			ENDIF  
		ELSE
			SELECT 'cur_unic'
			RELEASE Arr1
			COPY TO array Arr1 
			str_query = "UPDATE bpd.registr_documents SET kolvo_real =";
					+ ALLTRIM(STR(Arr1[1]))+" WHERE CI=";
					+cur_ci+" AND NP="+cur_np+" AND dt=convert(date,'";
					+cur_date+"') and doc_type = "+ALLTRIM(STR(ctype))
			b = SQLEXEC(con_bd,str_query)
			IF Arr[i,2]#Arr1[1]
				IF ISNULL(Arr[i,4])
					INSERT INTO tmp(ci,np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],cur_kolvo,;
 ALLTRIM(STR(Arr1[1])))
				ELSE
					INSERT INTO tmp(ci,np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],;
 ALLTRIM(STR(Arr[i,4]))+"/"+cur_kolvo,ALLTRIM(STR(Arr[i,4]))+"/"+ALLTRIM(STR(Arr1[1])))
 				ENDIF
			ENDIF
		ENDIF 
	ENDFOR
ENDIF
str_query = "select convert(smallint,Ce) as ce,convert(smallint,np) as np,COUNT(*) FROM;
 bpd.rn WHERE grup<700 and dvv='"+CHRTRAN(cur_date,'.','')+"' group by ce,np"
b = SQLEXEC(con_bd,str_query,'cur_unic')
IF RECCOUNT('cur_unic')#0
	SELECT 'cur_unic'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_ci = ALLTRIM(STR(Arr[i,1]))
		cur_np = ALLTRIM(STR(Arr[i,2]))
		str_query = "select kolvo from bpd.registr_documents where dt=convert(date,'";
		+cur_date+"') and ci = "+cur_ci+" and np = "+cur_np+" and doc_type = "+ALLTRIM(STR(ctype))
		b = SQLEXEC(con_bd,str_query,'cur_unic')
		IF RECCOUNT('cur_unic') = 0
			INSERT INTO tmp(ci,np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],'0',ALLTRIM(STR(Arr[i,3])))
		ENDIF
	ENDFOR
ENDIF 
str_query = "select convert(smallint,Ce) as ce,convert(smallint,np) as np,COUNT(*) FROM;
 bpd.brigv WHERE grup<700 and dvv='"+CHRTRAN(cur_date,'.','')+"' group by ce,np"
b = SQLEXEC(con_bd,str_query,'cur_unic')
IF RECCOUNT('cur_unic')#0
	SELECT 'cur_unic'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_ci = ALLTRIM(STR(Arr[i,1]))
		cur_np = ALLTRIM(STR(Arr[i,2]))
		str_query = "select kolvo from bpd.registr_documents where dt=convert(date,'";
		+cur_date+"') and ci = "+cur_ci+" and np = "+cur_np+" and doc_type = "+ALLTRIM(STR(ctype))
		b = SQLEXEC(con_bd,str_query,'cur_unic')
		IF RECCOUNT('cur_unic') = 0
			INSERT INTO tmp(ci,np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],'0',"/"+ALLTRIM(STR(Arr[i,3])))
		ENDIF
	ENDFOR
ENDIF 
IF RECCOUNT('tmp')#0
	SELECT 'tmp'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_ci = PADL(ALLTRIM(STR(Arr[i,1])),3,' ')
		cur_np = PADL(ALLTRIM(STR(Arr[i,2])),3,' ')
		?CPCONVERT(1251,866,' '+cur_ci+'    '+cur_np+'          '+ Arr[i,3] + '                    '+Arr[i,4])
	ENDFOR
	SET PRINTER off 
	SET PRINTER TO
	MODIFY COMMAND &print_path as 866
	IF MESSAGEBOX("�������� �������� �� �������������� ������? ",4,"������") = 6 
		copy file &print_path to lpt1
	ENDIF
ELSE
	MESSAGEBOX("������ ���",0,cPrName)
ENDIF