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
?REPL('-',(56))
?CPCONVERT(1251,866,':   ����   : ����� : ���������� ��������. : ���������� ������. :')
?REPL('-',(56))
?

str_query = "select convert(varchar(4),np) as np,kolvo,convert(char(10),dt,104) as dt2 from bpd.registr_documents where doc_type = "+STR(ctype);
	+" and invtp = 5 and is_check = 0"
b = SQLEXEC(con_bd,str_query,'cur_tmpk')
SELECT 'cur_tmpk'
SCAN 
	cur_date = dt2
	cur_np = ALLTRIM(np)
	cur_kolvo = kolvo
	str_query = "select COUNT(*) as k FROM bpd.dopspzv WHERE grup<700 AND np = "+cur_np+" group by np"
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	IF RECCOUNT('tmp_cur')=0
		INSERT INTO tmp(dt,np,kolvo,kolvo_real) VALUES (cur_date,cur_np,cur_kolvo,0)
	ELSE
		SELECT 'tmp_cur'
		cur_kolvo_real = k
		str_query = "UPDATE bpd.registr_documents SET kolvo_real ="+STR(cur_kolvo_real)+",is_check = 1 WHERE np="+cur_np+" and doc_type = "+STR(ctype);
			+" and invtp = 1 and is_check = 0"
		b = SQLEXEC(con_bd,str_query)
		IF cur_kolvo#cur_kolvo_real
			INSERT INTO tmp(dt,np,kolvo,kolvo_real) VALUES (cur_date,cur_np,cur_kolvo,cur_kolvo_real)
		ENDIF		
	ENDIF
	SELECT 'cur_tmpk'
ENDSCAN

str_query = "select convert(varchar(4),convert(smallint,np)) as np,COUNT(*) as k FROM bpd.dopspzv WHERE grup<700 group by np"
b = SQLEXEC(con_bd,str_query,'cur_tmpk_oper')
SELECT 'cur_tmpk_oper'
SCAN
	cur_np = Alltrim(np) 
	cur_kolvo_real = k
	str_query = "select dvv FROM bpd.dopspzv WHERE np = "+cur_np
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	SELECT 'tmp_cur'
	cur_date = STUFF(STUFF(dvv,3,0,'.'),6,0,'.')
	SELECT * FROM cur_tmpk WHERE np = cur_np INTO CURSOR tmp_cur
	IF RECCOUNT('tmp_cur') = 0
		INSERT INTO tmp(dt,np,kolvo,kolvo_real) VALUES (cur_date,cur_np,0,cur_kolvo_real)
	ENDIF
	SELECT 'cur_tmpk_oper'
ENDSCAN

SELECT 'tmp'
IF RECCOUNT()#0
	SCAN 
		cur_date = dt
		cur_np = PADL(np,3,' ')
		cur_kolvo = PADL(ALLTRIM(STR(kolvo)),3,' ')
		cur_kolvo_real = ALLTRIM(STR(kolvo_real))
		?CPCONVERT(1251,866,'  '+cur_date+'   '+cur_np+'            '+ cur_kolvo + '                     '+cur_kolvo_real)
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


