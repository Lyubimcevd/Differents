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
?CPCONVERT(1251,866,':    ����    : ����� : ���������� ��������. : ���������� ���������. :')
?REPL('-',(67))
?

CREATE CURSOR tmp(dt C(10),np V(4),kolvo N,kolvo_real N)
str_query = "select convert(varchar(4),np) as np,kolvo,convert(char(10),dt,104) as dt2 from bpd.registr_documents where doc_type = ";
	+STR(ctype)+" and is_check = 0"
b = SQLEXEC(con_bd,str_query,'cur_zak')
SELECT 'cur_zak'
SCAN
 	cur_date = dt2
 	cur_np = ALLTRIM(np)
 	cur_kolvo = kolvo
 	str_query = "select COUNT(*) as k FROM bpd.vzak1 WHERE grup<700 AND np = "+cur_np+" group by np "
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	IF RECCOUNT('tmp_cur')=0
		INSERT INTO tmp(dt,np,kolvo,kolvo_real) VALUES (cur_date,cur_np,cur_kolvo,0)
	ELSE
		SELECT 'tmp_cur'
		cur_kolvo_real = k
		str_query = "UPDATE bpd.registr_documents SET kolvo_real ="+STR(cur_kolvo_real)+",is_check = 1 WHERE NP="+cur_np+" and doc_type = "+STR(ctype);
			+" and is_check = 0"
		b = SQLEXEC(con_bd,str_query)
		IF cur_kolvo_real # cur_kolvo
			INSERT INTO tmp(dt,np,kolvo,kolvo_real) VALUES (cur_date,cur_np,cur_kolvo,cur_kolvo_real)
		ENDIF
	ENDIF 
	SELECT 'cur_zak'
ENDSCAN

str_query = "select convert(varchar(4),convert(smallint,np)) as np,COUNT(*) as k FROM bpd.vzak1 WHERE grup<700 group by np"
b = SQLEXEC(con_bd,str_query,'cur_zak_oper')
SELECT 'cur_zak_oper'
SCAN
	cur_np = ALLTRIM(np) 
	cur_kolvo_real = k
	str_query = "select datpod FROM bpd.vzak1 WHERE np = "+cur_np
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	SELECT 'tmp_cur'
	cur_date = STUFF(STUFF(datpod,3,0,'.'),6,0,'.')
	SELECT * FROM cur_zak WHERE np = cur_np INTO CURSOR tmp_cur
	IF RECCOUNT('tmp_cur') = 0
		INSERT INTO tmp(dt,np,kolvo,kolvo_real) VALUES (cur_date,cur_np,0,cur_kolvo_real)
	ENDIF
	SELECT 'cur_zak_oper'
ENDSCAN

SELECT 'tmp'
IF RECCOUNT()#0
	SCAN
		cur_date = dt
		cur_np = PADL(ALLTRIM(np),3,' ')
		cur_kolvo = PADL(ALLTRIM(STR(kolvo)),3,' ')
		cur_kolvo_real = ALLTRIM(STR(kolvo_real))
		?CPCONVERT(1251,866,'  '+cur_date+'   '+cur_np+'           '+ cur_kolvo + '                      '+cur_kolvo_real)
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
