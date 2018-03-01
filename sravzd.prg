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
?REPL('-',(89))
?CPCONVERT(1251,866,':    ����    : ����� : ����� ����������� : ���������� ��������. : ���������� ���������. :')
?REPL('-',(89))
?

CREATE CURSOR tmp(dt C(10),ci V(4),np V(4),kolvo N,kolvo_real N)
str_query = "select top 200 convert(varchar(4),ci) as ci,convert(varchar(4),np) as np,kolvo,kolvo_real,convert(char(10),dt,104) as dt2 from";
			+" bpd.registr_documents where doc_type = "+STR(ctype)+" order by dt desc"
b = SQLEXEC(con_bd,str_query,'cur_zd')
SELECT 'cur_zd'
SCAN WHILE ISNULL(kolvo_real)	
	cur_date = dt2
	IF ISNULL(ci)
		cur_ci = ''
	ELSE 
		cur_ci = ALLTRIM(ci)
	ENDIF
	cur_np = ALLTRIM(np)
	cur_kolvo = kolvo
	str_query = "select COUNT(*) as k FROM bpd.mlpd WHERE grup<700 and np = "+cur_np+" AND mak = '"+cur_ci+"' and dvv = '";
				+CHRTRAN(cur_date,'.','')+"' group by np,mak"
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	IF RECCOUNT('tmp_cur')=0		  			
		INSERT INTO tmp(dt,ci,np,kolvo,kolvo_real) VALUES (cur_date,cur_ci,cur_np,cur_kolvo,0)
	ELSE
		cur_kolvo_real = k
		str_query = "UPDATE bpd.registr_documents SET kolvo_real ="+STR(cur_kolvo_real)+" WHERE dt = convert(date,'"+cur_date+"') and NP=";
						+cur_np+" AND kolvo="+STR(cur_kolvo)+" and doc_type=" +STR(ctype)
		b = SQLEXEC(con_bd,str_query)
		IF cur_kolvo#cur_kolvo_real				
			INSERT INTO tmp(dt,ci,np,kolvo,kolvo_real) VALUES (cur_date,cur_ci,cur_np,cur_kolvo,cur_kolvo_real)
		ENDIF
	ENDIF
	SELECT 'cur_zd'
ENDSCAN 

str_query = "select convert(varchar(4),mak) as cex,convert(varchar(4),convert(smallint,np)) as np,COUNT(*) as k FROM bpd.mlpd";
			+" WHERE grup<700 group by mak,np"
b = SQLEXEC(con_bd,str_query,'cur_zd')
SELECT 'cur_zd'
SCAN
	cur_ci = ALLTRIM(cex)
	cur_np = ALLTRIM(np)
	cur_kolvo_real = k
	str_query = "select dvv FROM bpd.mlpd WHERE np = "+cur_np
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	SELECT 'tmp_cur'
	cur_date = STUFF(STUFF(dvv,3,0,'.'),6,0,'.')
	str_query = "select kolvo from bpd.registr_documents where dt=convert(date,'"+cur_date+"') and np = "+cur_np+" and doc_type = ";
				+STR(ctype)
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	IF RECCOUNT('tmp_cur') = 0
		INSERT INTO tmp(dt,ci,np,kolvo,kolvo_real) VALUES (cur_date,cur_ci,cur_np,0,cur_kolvo_real)
	ENDIF
	SELECT 'cur_zd'
ENDSCAN

SELECT 'tmp'
IF RECCOUNT()#0
	SCAN 
		cur_date = dt
		cur_ci = PADL(ci,3,' ')
		cur_np = PADL(np,3,' ')
		cur_kolvo = PADL(ALLTRIM(STR(kolvo)),3,' ')
		cur_kolvo_real = ALLTRIM(STR(kolvo_real))
		?CPCONVERT(1251,866,' '+cur_date+'    '+cur_np+'           '+cur_ci+'                  '+ cur_kolvo + '                       '+cur_kolvo_real)
	ENDSCAN
	SET PRINTER off
	SET PRINTER TO
	MODIFY COMMAND &print_path as 866
	IF MESSAGEBOX("�������� �������� �� �������������� ������? ",4,"������") = 6
		copy file &print_path to lpt1
	ENDIF
ELSE
	MESSAGEBOX("������ ���",0,cPrName)
ENDIF