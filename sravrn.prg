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
?CPCONVERT(1251,866,' Протокол '+cPrName+' за '+ALLTRIM(DTOC(DATE())))
?REPL('-',(82))
?CPCONVERT(1251,866,':    Дата    : Цех : Пачка : Количество зарегист. : Количество подготовл. :        Тип        :')
?REPL('-',(82))
?

CREATE CURSOR tmp(dt C(10),ci V(4),np V(4),kolvo N,kolvo_real N,invtp V(20))
str_query = "select top 200 convert(varchar(4),ci) as ci,convert(varchar(4),np) as np,kolvo,kolvo_real,convert(varchar(1),invtp) as invtp,";
			+"convert(char(10),dt,104) as dt2 from bpd.registr_documents where doc_type = "+STR(ctype)+" order by dt desc"
b = SQLEXEC(con_bd,str_query,'cur_rn')
SELECT 'cur_rn'
SCAN WHILE ISNULL(kolvo_real)
	cur_date = dt2
	cur_ci = ALLTRIM(ci)
	cur_np = ALLTRIM(np)
	cur_kolvo = kolvo
	cur_invtp = invtp
	IF cur_invtp  = '1'
		str_query = "select COUNT(*) as k FROM bpd.rn WHERE grup<700 AND ce = "+cur_ci+" AND np = "+cur_np+" group by ce,np"
	ELSE
		str_query = "select COUNT(*) as k FROM bpd.brigv WHERE grup<700 AND ce = "+cur_ci+" AND np = "+cur_np+" group by ce,np"
	ENDIF			
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	IF RECCOUNT('tmp_cur')=0
		INSERT INTO tmp(dt,ci,np,kolvo,kolvo_real,invtp) VALUES (cur_date,cur_ci,cur_np,cur_kolvo,0,cur_invtp) 
	ELSE
		SELECT 'tmp_cur'
		cur_kolvo_real = k
		str_query = "UPDATE bpd.registr_documents SET kolvo_real ="+STR(cur_kolvo_real)+" WHERE dt = convert(date,'"+cur_date+"') and CI=";
				+cur_ci+" AND NP="+cur_np+" AND doc_type = "+STR(ctype)
		b = SQLEXEC(con_bd,str_query)
		IF cur_kolvo_real#cur_kolvo
			INSERT INTO tmp(dt,ci,np,kolvo,kolvo_real,invtp) VALUES (cur_date,cur_ci,cur_np,cur_kolvo,cur_kolvo_real,cur_invtp)
		ENDIF
	ENDIF 
	SELECT 'cur_rn'
ENDSCAN 

str_query = "select convert(varchar(4),convert(smallint,Ce)) as ci,convert(varchar(4),convert(smallint,np)) as np,COUNT(*) as k FROM bpd.rn";
			+" WHERE grup<700 group by ce,np"
b = SQLEXEC(con_bd,str_query,'cur_rn')
SELECT 'cur_rn'
SCAN 
	cur_ci = ALLTRIM(ci)
	cur_np = ALLTRIM(np)
	cur_kolvo_real = k
	str_query = "select dvv FROM bpd.rn WHERE np = "+cur_np+" and ce = "+cur_ci
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	SELECT 'tmp_cur'
	cur_date = STUFF(STUFF(dvv,3,0,'.'),6,0,'.')
	str_query = "select kolvo from bpd.registr_documents where dt=convert(date,'"+cur_date+"') and np = "+cur_np+" and ci = "+cur_ci+"and doc_type = ";
				+STR(ctype)+" and invtp = 1"
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	IF RECCOUNT('tmp_cur') = 0
		INSERT INTO tmp(dt,ci,np,kolvo,kolvo_real,invtp) VALUES (cur_date,cur_ci,cur_np,0,cur_kolvo_real,'1')
	ENDIF
	SELECT 'cur_rn'
ENDSCAN

str_query = "select convert(varchar(4),convert(smallint,Ce)) as ci,convert(varchar(4),convert(smallint,np)) as np,COUNT(*) as k FROM bpd.brigv";
			+" WHERE grup<700 group by ce,np"
b = SQLEXEC(con_bd,str_query,'cur_brigv')
SELECT 'cur_brigv'
SCAN 
	cur_ci = ALLTRIM(ci)
	cur_np = ALLTRIM(np)
	cur_kolvo_real = k
	str_query = "select dvv FROM bpd.brigv WHERE np = "+cur_np+" and ce = "+cur_ci
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	SELECT 'tmp_cur'
	cur_date = STUFF(STUFF(dvv,3,0,'.'),6,0,'.')
	str_query = "select kolvo from bpd.registr_documents where dt=convert(date,'"+cur_date+"') and np = "+cur_np+" and ci = "+cur_ci+"and doc_type = ";
				+STR(ctype)+" and invtp = 2"
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	IF RECCOUNT('tmp_cur') = 0
		INSERT INTO tmp(dt,ci,np,kolvo,kolvo_real,invtp) VALUES (cur_date,cur_ci,cur_np,0,cur_kolvo_real,'2')
	ENDIF
	SELECT 'cur_brigv'
ENDSCAN 

UPDATE tmp SET invtp = "Рабочие наряды" WHERE invtp = '1'
UPDATE tmp SET invtp = "Бригадные ведомости" WHERE invtp = '2'

SELECT 'tmp'
IF RECCOUNT()#0
	SCAN 
		cur_date = dt
		cur_ci = PADL(ci,3,' ')
		cur_np = PADL(np,3,' ')
		cur_kolvo = PADL(ALLTRIM(STR(kolvo)),3,' ')
		cur_kolvo_real = PADL(ALLTRIM(STR(kolvo_real)),3,' ')
		cur_invtp = invtp
		?CPCONVERT(1251,866,' '+cur_date+'    '+cur_ci+'   '+cur_np+'             '+ cur_kolvo + '                      '+cur_kolvo_real+'            '+cur_invtp)
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
