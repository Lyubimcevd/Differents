LPARAMETERS ctype,cPrName
cConnString="driver={SQL Server};SERVER=nitel-hp;uid=ldo;pwd=IfLyyz4sCJ;DATABASE=uit;WSID=VFP;APP=VFP;"
con_bd=SQLSTRINGCONNECT(cConnString, .T.)
SET PATH to "D:\PODDANW\" ADDITIVE
SET PATH TO "I:\PODDANW\" ADDITIVE
SET SQLBUFFERING ON
SET DATE GERMAN
SET CENTURY ON

print_path = "&PDTXT/finish.txt"
SET PRIN TO &print_path
SET CONS OFF
SET PRINT ON
?CPCONVERT(1251,866,' �������� '+cPrName+' �� '+ALLTRIM(DTOC(DATE())))
?REPL('-',(67))
?CPCONVERT(1251,866,':    ����    : ��� : ����� : ���������� ��������. : ���������� ���������. :')
?REPL('-',(67))
?

CREATE CURSOR tmp(dt C(10),ci N,np N,kolvo N,kolvo_real N)
str_query = "select top 200 ci,np,kolvo,kolvo_real,convert(char(10),dt,104) as dt2 from bpd.registr_documents where doc_type = "+ALLTRIM(STR(ctype))+" order by dt desc"
b = SQLEXEC(con_bd,str_query,'cur_unic')
SELECT 'cur_unic'
RELEASE Arr
COPY TO ARRAY Arr
k = 1
DO WHILE ISNULL(Arr[k,4]) 
	k = k + 1
	IF (k>ALEN(Arr,1))
		exit 
	ENDIF
ENDDO

FOR i = 1 TO k - 1
	cur_ci = ALLTRIM(STR(Arr[i,1]))
	cur_np = ALLTRIM(STR(Arr[i,2]))
	cur_kolvo = ALLTRIM(STR(Arr[i,3]))
	cur_date = Arr[i,5]
	str_query = "select COUNT(*) FROM bpd.cou WHERE grup<700 and grup != 000 AND ci = ";
		+cur_ci+" AND np = "+cur_np+" group by ci,np "
	b = SQLEXEC(con_bd,str_query,'cur_unic')
	IF RECCOUNT('cur_unic')=0
		INSERT INTO tmp(dt,ci,np,kolvo,kolvo_real) VALUES (cur_date,Arr[i,1],Arr[i,2],Arr[i,3],0)
	ELSE
		SELECT 'cur_unic'
		RELEASE Arr1
		COPY TO array Arr1 
		str_query = "UPDATE bpd.registr_documents SET kolvo_real =";
				+ ALLTRIM(STR(Arr1[1]))+" WHERE dt=convert(date,'"+cur_date+"') and CI=";
				+cur_ci+" AND NP="+cur_np+" AND kolvo="+cur_kolvo+" and doc_type = "+ALLTRIM(STR(ctype))
		b = SQLEXEC(con_bd,str_query)
		IF Arr[i,3]#Arr1[1]
			INSERT INTO tmp(dt,ci,np,kolvo,kolvo_real) VALUES (cur_date,Arr[i,1],Arr[i,2],Arr[i,3],Arr1[1])
		ENDIF
	ENDIF 
ENDFOR
	
str_query = "select convert(smallint,Ci) as ci,convert(smallint,np) as np,COUNT(*) FROM;
 bpd.cou WHERE grup<700 and grup != 000 group by ci,np "
b = SQLEXEC(con_bd,str_query,'cur_unic')
SELECT 'cur_unic'
RELEASE Arr
COPY TO ARRAY Arr
FOR i = 1 TO ALEN(Arr,1)
	cur_ci = ALLTRIM(STR(Arr[i,1]))
	cur_np = ALLTRIM(STR(Arr[i,2]))
	str_query = "select dvv FROM bpd.cou WHERE np = "+cur_np+" and ci = "+cur_ci
	b = SQLEXEC(con_bd,str_query,'cur_unic')
	SELECT 'cur_unic'
	RELEASE Arr1
	COPY TO ARRAY Arr1
	cur_date = STUFF(STUFF(Arr1[1,1],3,0,'.'),6,0,'.')
	str_query = "select kolvo from bpd.registr_documents where dt=convert(date,'";
		+cur_date+"') and ci = "+cur_ci+" and np = "+cur_np+" and doc_type = "+ALLTRIM(STR(ctype))
	b = SQLEXEC(con_bd,str_query,'cur_unic')
	IF RECCOUNT('cur_unic') = 0
		INSERT INTO tmp(dt,ci,np,kolvo,kolvo_real) VALUES (cur_date,Arr[i,1],Arr[i,2],0,Arr[i,3])
	ENDIF
ENDFOR

IF RECCOUNT('tmp')#0
	SELECT 'tmp'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_date = Arr[i,1]
		cur_ci = PADL(ALLTRIM(STR(Arr[i,2])),3,' ')
		cur_np = PADL(ALLTRIM(STR(Arr[i,3])),3,' ')
		cur_kolvo = PADL(ALLTRIM(STR(Arr[i,4])),3,' ')
		cur_kolvo_real = ALLTRIM(STR(Arr[i,5]))
		?CPCONVERT(1251,866,'  '+cur_date+'  '+cur_ci+'     '+cur_np+'           '+ cur_kolvo + '                      '+cur_kolvo_real)
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
