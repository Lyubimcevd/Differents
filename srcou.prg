LPARAMETERS ctype,cPrName
cConnString="driver={SQL Server};SERVER=nitel-hp;uid=ldo;pwd=IfLyyz4sCJ;DATABASE=uit;WSID=VFP;APP=VFP;"
con_bd=SQLSTRINGCONNECT(cConnString, .T.)
SET PATH to "D:\PODDANW\" ADDITIVE
SET PATH TO "I:\PODDANW\" ADDITIVE
SET SQLBUFFERING ON
SET DATE GERMAN
SET CENTURY ON

cur_date = ALLTRIM(DTOC(DATE()))
print_path = "&PDTXT\finish.txt"
SET PRIN TO &print_path
SET CONS OFF
SET PRINT ON
?CPCONVERT(1251,866,' �������� '+cPrName+' �� '+cur_date)
?REPL('-',(67))
?CPCONVERT(1251,866,': ��� : ����� : ���������� ��������. : ���������� ���������. :')
?REPL('-',(67))
?

CREATE CURSOR tmp(ci N,np N,kolvo N,kolvo_real N)
susp
str_query = "select ci,np,kolvo from bpd.registr_documents where doc_type = ";
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
		str_query = "select COUNT(*) FROM bpd.�ou WHERE grup<700 AND dvv='";
						+CHRTRAN(cur_date,'.','')+"' AND ci = "+cur_ci+" AND np = ";
						+cur_np+" group by ci,np "
			b = SQLEXEC(con_bd,str_query,'cur_unic')
		IF RECCOUNT('cur_unic')=0
			INSERT INTO tmp(ci,np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],Arr[i,3],0)
		ELSE
			SELECT 'cur_unic'
			RELEASE Arr1
			COPY TO array Arr1 
			str_query = "UPDATE bpd.registr_documents SET kolvo_real =";
					+ ALLTRIM(STR(Arr1[1]))+" WHERE CI=";
					+cur_ci+" AND NP="+cur_np+" AND kolvo=";
					+cur_kolvo+" AND dt=convert(date,'"+cur_date+"') and doc_type = ";
					+ALLTRIM(STR(ctype))
			b = SQLEXEC(con_bd,str_query)
			IF Arr[i,2]#Arr1[1]
				INSERT INTO tmp(ci,np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],Arr[i,3],Arr1[1])
			ENDIF
		ENDIF 
	ENDFOR
ENDIF
str_query = "select convert(smallint,Ci) as ci,convert(smallint,np) as np,COUNT(*) FROM;
 bpd.cou WHERE grup<700 and dvv='"+CHRTRAN(cur_date,'.','')+"' group by ci,np "
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
			INSERT INTO tmp(ci,np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],0,Arr[i,3])
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
		cur_kolvo = PADL(ALLTRIM(STR(Arr[i,3])),3,' ')
		cur_kolvo_real = ALLTRIM(STR(Arr[i,4]))
		?CPCONVERT(1251,866,' '+cur_ci+'    '+cur_np+'          '+ cur_kolvo + '                    '+cur_kolvo_real)
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