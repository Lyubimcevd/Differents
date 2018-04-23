LPARAMETERS ctype,cPrName
cConnString="driver={SQL Server};SERVER=nitel-hp;uid=ldo;pwd=IfLyyz4sCJ;DATABASE=uit;WSID=VFP;APP=VFP;"
con_bd=SQLSTRINGCONNECT(cConnString, .T.)
SET PATH to "D:\PODDANW\" ADDITIVE
SET PATH TO "I:\PODDANW\" ADDITIVE
SET SQLBUFFERING ON
SET DATE GERMAN
SET CENTURY ON

print_path = "&PDTXT/finish.txt"
SET PRINT TO &print_path
SET CONS OFF
SET PRINT ON
?CPCONVERT(1251,866,' �������� '+cPrName+' �� '+ALLTRIM(DTOC(DATE())))
?REPL('-',(83))
?CPCONVERT(1251,866,':   ����   : ��� : ����� : ���������� ��������. : ���������� ���������. : ��� �������������� :')
?REPL('-',(83))
?

CREATE CURSOR tmp(dt V(10),ci V(4),np V(4),kolvo N,kolvo_real N,invtp V(12))
str_query = "select convert(varchar(4),ci) as ci,convert(varchar(4),np) as np,kolvo,convert(varchar(1),invtp) as invtp,convert(char(10),dt,104) as dt2";
	+" from bpd.registr_documents where doc_type = "+STR(ctype)+" and is_check = 0"
b = SQLEXEC(con_bd,str_query,'cur_inv')
SELECT 'cur_inv'
SCAN
	cur_date = dt2
	cur_ci = ALLTRIM(ci)
	cur_np = ALLTRIM(np)
	cur_kolvo = kolvo
	cur_invtp = ALLTRIM(STR(invtp))
	str_query = "select COUNT(*) as k FROM bpd.inven WHERE grup<700 and ci = "+cur_ci+" AND npat = "+cur_np
	DO CASE
 		CASE cur_invtp = '1'
			str_query = str_query+" and nk=nc and no='0000' group by ci,npat "
		CASE cur_invtp = '2'
			str_query = str_query+" and nk=nc and no!='0000' group by ci,npat "
		CASE cur_invtp = '3'
			str_query = str_query+" and nk!=nc and prs!='1' group by ci,npat "
		CASE cur_invtp = '4'
			str_query = str_query+" and nk!=nc and prs='1' group by ci,npat "
	ENDCASE
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	IF RECCOUNT('tmp_cur')=0
		INSERT INTO tmp(dt,ci,np,kolvo,kolvo_real,invtp) VALUES (cur_date,cur_ci,cur_np,cur_kolvo,0,cur_invtp)
	ELSE 
		cur_kolvo_real = k
		str_query = "UPDATE bpd.registr_documents SET kolvo_real ="+STR(cur_kolvo_real)+",is_check = 1 WHERE CI="+cur_ci+" AND NP="+cur_np;
			+" AND is_check = 0 and doc_type = "+STR(ctype)
		b = SQLEXEC(con_bd,str_query)
		IF cur_kolvo_real#cur_kolvo		
			INSERT INTO tmp(dt,ci,np,kolvo,kolvo_real,invtp) VALUES (cur_date,cur_ci,cur_np,cur_kolvo,cur_kolvo_real,cur_invtp)
		ENDIF
	ENDIF
	SELECT 'cur_inv'
ENDSCAN

str_query = "select convert(varchar(4),convert(smallint,Ci)) as ci,convert(varchar(4),convert(smallint,npat)) as np,COUNT(*) as k FROM";
			+" bpd.inven WHERE grup<700 and nk=nc and no='0000' group by ci,npat"
b = SQLEXEC(con_bd,str_query,'cur_inv_oper')
SELECT 'cur_inv_oper'
SCAN
	cur_ci = ALLTRIM(ci)
	cur_np = ALLTRIM(np)
	cur_kolvo_real = k
	str_query = "select dvv FROM bpd.inven WHERE npat = "+cur_np+" and ci = "+cur_ci
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	cur_date = STUFF(STUFF(dvv,3,0,'.'),6,0,'.')
	SELECT * FROM cur_inv WHERE np = cur_np AND ci = cur_ci AND invtp = '1' INTO CURSOR tmp_cur
	IF RECCOUNT('tmp_cur') = 0
		INSERT INTO tmp(dt,ci,np,kolvo,kolvo_real,invtp) VALUES (cur_date,cur_ci,cur_np,0,cur_kolvo_real,'1')
	ENDIF
	SELECT 'cur_inv_oper'
ENDSCAN

str_query = "select convert(varchar(4),convert(smallint,Ci)) as ci,convert(varchar(4),convert(smallint,npat)) as np,COUNT(*) as k FROM";
			+" bpd.inven WHERE grup<700 and nk=nc and no!='0000' group by ci,npat"
b = SQLEXEC(con_bd,str_query,'cur_inv_oper')
SELECT 'cur_inv_oper'
SCAN
	cur_ci = ALLTRIM(ci)
	cur_np = ALLTRIM(np)
	cur_kolvo_real = k
	str_query = "select dvv FROM bpd.inven WHERE npat = "+cur_np+" and ci = "+cur_ci
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	cur_date = STUFF(STUFF(dvv,3,0,'.'),6,0,'.')
	SELECT * FROM cur_inv WHERE np = cur_np AND ci = cur_ci AND invtp = '2' INTO CURSOR tmp_cur
	IF RECCOUNT('tmp_cur') = 0
		INSERT INTO tmp(dt,ci,np,kolvo,kolvo_real,invtp) VALUES (cur_date,cur_ci,cur_np,0,cur_kolvo_real,'2')
	ENDIF
	SELECT 'cur_inv_oper'
ENDSCAN 

str_query = "select convert(varchar(4),convert(smallint,Ci)) as ci,convert(varchar(4),convert(smallint,npat)) as np,COUNT(*) as k FROM";
			+" bpd.inven WHERE grup<700 and nk!=nc and prs!='1' group by ci,npat"
b = SQLEXEC(con_bd,str_query,'cur_inv_oper')
SELECT 'cur_inv_oper'
SCAN
	cur_ci = ALLTRIM(ci)
	cur_np = ALLTRIM(np)
	cur_kolvo_real = k
	str_query = "select dvv FROM bpd.inven WHERE npat = "+cur_np+" and ci = "+cur_ci
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	cur_date = STUFF(STUFF(dvv,3,0,'.'),6,0,'.')
	SELECT * FROM cur_inv WHERE np = cur_np AND ci = cur_ci AND invtp = '3' INTO CURSOR tmp_cur
	IF RECCOUNT('tmp_cur') = 0
		INSERT INTO tmp(dt,ci,np,kolvo,kolvo_real,invtp) VALUES (cur_date,cur_ci,cur_np,0,cur_kolvo_real,'3')
	ENDIF
	SELECT 'cur_inv_oper'
ENDSCAN

str_query = "select convert(varchar(4),convert(smallint,Ci)) as ci,convert(varchar(4),convert(smallint,npat)) as np,COUNT(*) as k FROM";
			+" bpd.inven WHERE grup<700 and nk!=nc and prs='1' group by ci,npat"
b = SQLEXEC(con_bd,str_query,'cur_inv_oper')
SELECT 'cur_inv_oper'
SCAN
	cur_ci = ALLTRIM(ci)
	cur_np = ALLTRIM(np)
	cur_kolvo_real = k
	str_query = "select dvv FROM bpd.inven WHERE npat = "+cur_np+" and ci = "+cur_ci
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	cur_date = STUFF(STUFF(dvv,3,0,'.'),6,0,'.')
	SELECT * FROM cur_inv WHERE np = cur_np AND ci = cur_ci AND invtp = '4' INTO CURSOR tmp_cur
	IF RECCOUNT('tmp_cur') = 0
		INSERT INTO tmp(dt,ci,np,kolvo,kolvo_real,invtp) VALUES (cur_date,cur_ci,cur_np,0,cur_kolvo_real,'4')
	ENDIF
	SELECT 'cur_inv_oper'
ENDSCAN

UPDATE tmp SET invtp = "�������" WHERE invtp = '1'
UPDATE tmp SET invtp = "�� ��������" WHERE invtp = '2'
UPDATE tmp SET invtp = "��� ����" WHERE invtp = '3'
UPDATE tmp SET invtp = "� ���" WHERE invtp = '4'

SELECT 'tmp'
IF RECCOUNT()#0
	SCAN 
		cur_date = dt
		cur_ci = PADL(ci,3,' ')
		cur_np = PADL(np,3,' ')
		cur_kolvo = PADL(ALLTRIM(STR(kolvo)),3,' ')
		cur_kolvo_real = PADL(ALLTRIM(STR(kolvo_real)),3,' ')
		cur_invtp = invtp
		?CPCONVERT(1251,866,' '+cur_date+'   '+cur_ci+'    '+cur_np+'             '+ cur_kolvo + '                   '+cur_kolvo_real+'                  '+cur_invtp)
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
