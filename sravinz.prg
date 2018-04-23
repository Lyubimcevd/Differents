LPARAMETERS ctype,cPrName
cConnString="driver={SQL Server};SERVER=nitel-hp;uid=ldo;pwd=IfLyyz4sCJ;DATABASE=uit;WSID=VFP;APP=VFP;"
con_bd=SQLSTRINGCONNECT(cConnString, .T.)
SET PATH to "D:\PODDANW\" ADDITIVE
SET PATH TO "I:\PODDANW\" ADDITIVE
SET SQLBUFFERING ON
SET DATE GERMAN
SET CENTURY ON

print_path = "&PDTXT\finish.txt"
SET PRINT TO &print_path
SET CONS OFF
SET PRINT ON
?CPCONVERT(1251,866,' Протокол '+cPrName+' за '+ALLTRIM(DTOC(DATE())))
?REPL('-',(83))
?CPCONVERT(1251,866,':   Дата   : Цех : Пачка : Количество зарегист. : Количество подготовл. : Тип инвентаризации :')
?REPL('-',(83))
?

CREATE CURSOR tmp(dt V(10),ci V(4),np V(4),kolvo N,kolvo_real N,invtp V(12))
str_query = "select convert(varchar(4),ci) as ci,convert(varchar(4),np),kolvo,convert(varchar(1),invtp) as invtp,convert(char(10),dt,104)";
	+" as dt2 from bpd.registr_documents where doc_type = "+STR(ctype)+" and is_check = 0"
b = SQLEXEC(con_bd,str_query,'cur_inz')
SELECT 'cur_inz'
SCAN 
	cur_date = dt2
	cur_ci = ALLTRIM(ci)
	cur_np = ALLTRIM(np)
	cur_kolvo = kolvo
	cur_invtp = ALLTRIM(STR(invtp))
	str_query = "select COUNT(*) as k FROM bpd.invnez WHERE grup<700 and ci = "+cur_ci+" AND np = "+cur_np
	DO CASE
		CASE cur_invtp = '5'
			str_query = str_query+" and bs=56 group by ci,np"
		CASE cur_invtp = '6'
			str_query = str_query+" and bs=57 group by ci,np "
	ENDCASE
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	IF RECCOUNT('tmp_cur')=0
		INSERT INTO tmp(dt,ci,np,kolvo,kolvo_real,invtp) VALUES (cur_date,cur_ci,cur_np,cur_kolvo,0,cur_invtp)
	ELSE 
		cur_kolvo_real = k
		str_query = "UPDATE bpd.registr_documents SET kolvo_real ="+STR(cur_kolvo_real)+",is_check = 1 WHERE CI="+cur_ci+" AND NP="+cur_np;
			+" AND is_check = 0 and doc_type = "+STR(ctype)
		b = SQLEXEC(con_bd,str_query)
		IF cur_kolvo#cur_kolvo_real
			INSERT INTO tmp(dt,ci,np,kolvo,kolvo_real,invtp) VALUES (cur_date,cur_ci,cur_np,cur_kolvo,cur_kolvo_real,cur_invtp)
		ENDIF
	ENDIF
	SELECT 'cur_inz'
ENDSCAN 

str_query = "select convert(varchar(4),convert(smallint,Ci)) as ci,convert(varchar(4),convert(smallint,np)) as np,COUNT(*) as k FROM bpd.invnez ";
			+"WHERE grup<700 and bs=56 group by ci,np"
b = SQLEXEC(con_bd,str_query,'cur_inz_oper')
SELECT 'cur_inz_oper'
SCAN 
	cur_ci = ALLTRIM(ci)
	cur_np = ALLTRIM(np)
	cur_kolvo_real = k
	str_query = "select dvv FROM bpd.invnez WHERE npat = "+cur_np+" and ci = "+cur_ci
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	cur_date = STUFF(STUFF(dvv,3,0,'.'),6,0,'.')
	SELECT * FROM cur_inz WHERE np = cur_np AND ci = cur_ci AND invtp = '5' INTO CURSOR tmp_cur
	IF RECCOUNT('tmp_cur') = 0
		INSERT INTO tmp(dt,ci,np,kolvo,kolvo_real,invtp) VALUES (cur_date,cur_ci,cur_np,0,cur_kolvo_real,'5')
	ENDIF
	SELECT 'cur_inz_oper'
ENDSCAN 
	
str_query = "select convert(varchar(4),convert(smallint,Ci)) as ci,convert(varchar(4),convert(smallint,np)) as np,COUNT(*) as k FROM bpd.invnez ";
			+"WHERE grup<700 and bs=57 group by ci,np"
b = SQLEXEC(con_bd,str_query,'cur_inz_oper')
SELECT 'cur_inz_oper'
SCAN 
	cur_ci = ALLTRIM(ci)
	cur_np = ALLTRIM(np)
	cur_kolvo_real = k
	str_query = "select dvv FROM bpd.invnez WHERE npat = "+cur_np+" and ci = "+cur_ci
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	cur_date = STUFF(STUFF(dvv,3,0,'.'),6,0,'.')
	SELECT * FROM cur_inz WHERE np = cur_np AND ci = cur_ci AND invtp = '6' INTO CURSOR tmp_cur
	IF RECCOUNT('tmp_cur') = 0
		INSERT INTO tmp(dt,ci,np,kolvo,kolvo_real,invtp) VALUES (cur_date,cur_ci,cur_np,0,cur_kolvo_real,'6')
	ENDIF
	SELECT 'cur_inz_oper'
ENDSCAN 	
	
UPDATE tmp SET invtp = "Материалы" WHERE invtp = '5'
UPDATE tmp SET invtp = "Покупные" WHERE invtp = '6'

SELECT 'tmp'
IF RECCOUNT()#0
	SCAN 
		cur_date = dt
		cur_ci = PADL(ci,3,' ')
		cur_np = PADL(np,3,' ')
		cur_kolvo = PADL(ALLTRIM(STR(kolvo)),3,' ')
		cur_kolvo_real = PADL(ALLTRIM(STR(kolvo_real)),3,' ')
		cur_inv_type = invtp
		?CPCONVERT(1251,866,' '+cur_date+'   '+cur_ci+'    '+cur_np+'             '+ cur_kolvo + '                   '+cur_kolvo_real+'                  '+cur_inv_type)
	ENDSCAN 
	SET PRINTER off 
	SET PRINTER TO
	MODIFY COMMAND &print_path as 866
	IF MESSAGEBOX("Печатать протокол по подготовленным данным? ",4,"Печать") = 6 
		copy file &print_path to lpt1
	ENDIF
ELSE
	MESSAGEBOX("Ошибок нет",0,cPrName)
ENDIF

