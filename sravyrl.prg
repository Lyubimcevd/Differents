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
SET PRINT TO &print_path
SET CONS OFF
SET PRINT ON
?CPCONVERT(1251,866,' �������� '+cPrName+' �� '+cur_date)
?REPL('-',(62))
?CPCONVERT(1251,866,': ��� : ����� : ���������� ��������. : ���������� ���������. :')
?REPL('-',(62))
?

*������������ �������( �������� ���������� ���� � �� ������������ )

str_query = "select convert(varchar(4),ci) as ci,convert(varchar(4),np) as np,kolvo from bpd.registr_documents where doc_type = ";
			+STR(ctype)+ " and dt = convert(date,'"+cur_date+"')"
b = SQLEXEC(con_bd,str_query,'cur_yarl')
SELECT 'cur_yarl'
SCAN
	cur_ci = ALLTRIM(ci)
	cur_np = ALLTRIM(np)
	cur_kolvo = kolvo
	str_query = "select SUM(kolvo) as k from bpd.registr_documents where doc_type = "+STR(ctype)+" and dt = convert(date,'"+cur_date+"') and ci = ";
				+cur_ci+" and np = "+cur_np
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	SELECT 'tmp_cur'
	real_kolvo = k
	IF real_kolvo # cur_kolvo
		str_query = "delete from bpd.registr_documents where doc_type = "+STR(ctype)+" and dt = convert(date,'"+cur_date+"') and ci = ";
					+cur_ci+" and np = "+cur_np
		b = SQLEXEC(con_bd,str_query)
		str_query = "INSERT INTO bpd.registr_documents(dt,ci,np,kolvo,doc_type) VALUES (convert(date,'"+cur_date+"'),"+cur_ci+","+cur_np+",";
 					+ALLTRIM(STR(real_kolvo))+",120)"
 		b = SQLEXEC(con_bd,str_query)
 	ENDIF
 	SELECT 'cur_yarl'
ENDSCAN

CREATE CURSOR tmp(ci V(4),np V(4),kolvo N,kolvo_real N)
str_query = "select top 200 convert(varchar(4),ci) as ci,convert(varchar(4),np) as np,kolvo,kolvo_real,convert(char(10),dt,104) as dt2";
			+" from bpd.registr_documents where doc_type = "+STR(ctype)+" order by dt desc"
b = SQLEXEC(con_bd,str_query,'cur_yarl')
SELECT 'cur_yarl'
SCAN WHILE ISNULL(kolvo_real)
	cur_ci = ALLTRIM(ci)
	cur_np = ALLTRIM(np)
	cur_kolvo = kolvo
	cur_kolvo_real = 0
	IF cur_ci == '2'
		str_query = "select convert(varchar(12),id_shtrih_kod) as sk from bpd.soprovod_yarl_header where grup<700 and ci=002 and np = ";
					+PADL(cur_np,3,'0') +" and dvv = '"+CHRTRAN(cur_date,'.','')+"'"
		b = SQLEXEC(con_bd,str_query,'tmp_cur')
		SELECT 'tmp_cur'
		IF RECCOUNT('tmp_cur')#0
			SCAN
				cur_sk = sk
				str_query = "select COUNT(*) as k from bpd.soprovod_yarl_detail where id_shtrih_kod ="+cur_sk+" group by id_shtrih_kod"
				b = SQLEXEC(con_bd,str_query,'tmp_cur2')
				SELECT 'tmp_cur2'
				cur_det = k
				str_query = "select COUNT(*) as k from bpd.soprovod_yarl_cou where id_shtrih_kod ="+cur_sk+" group by id_shtrih_kod"
				b = SQLEXEC(con_bd,str_query,'tmp_cur2')
				SELECT 'tmp_cur2'
				cur_cou = k
				cur_kolvo_real = cur_det*cur_cou + cur_kolvo_real
				SELECT 'tmp_cur'
			ENDSCAN
		ELSE
			INSERT INTO tmp(ci,np,kolvo,kolvo_real) VALUES (cur_ci,cur_np,cur_kolvo,0)
		ENDIF 			
	ELSE 
		str_query = "select COUNT(*) as k FROM bpd.predyarl WHERE grup<700 and stat = 41 and dvv='"+CHRTRAN(cur_date,'.','')+"' AND ci = ";
					+cur_ci+" AND np = "+cur_np+" group by ci,np"
		b = SQLEXEC(con_bd,str_query,'tmp_cur')
		IF RECCOUNT('tmp_cur')=0
			INSERT INTO tmp(ci,np,kolvo,kolvo_real) VALUES (cur_ci,cur_np,cur_kolvo,0)
		ELSE
			SELECT 'tmp_cur'
			cur_kolvo_real = k
		ENDIF
	ENDIF
	str_query = "UPDATE bpd.registr_documents SET kolvo_real ="+STR(cur_kolvo_real)+" WHERE CI="+cur_ci+" AND NP="+cur_np+" AND kolvo=";
				+STR(cur_kolvo)+" AND dt=convert(date,'"+cur_date+"') and doc_type = "+STR(ctype)
	b = SQLEXEC(con_bd,str_query)
	IF cur_kolvo_real # 0 AND cur_kolvo_real # cur_kolvo
		INSERT INTO tmp(ci,np,kolvo,kolvo_real) VALUES (cur_ci,cur_np,cur_kolvo,cur_kolvo_real)		
	ENDIF
	SELECT 'cur_yarl'
ENDSCAN

str_query = "select convert(varchar(4),convert(smallint,Ci)) as ci,convert(varchar(4),convert(smallint,np)) as np,COUNT(*) as k FROM bpd.predyarl";
			+" WHERE grup<700 and stat = 41 and dvv='"+CHRTRAN(cur_date,'.','')+"' group by ci,np "
b = SQLEXEC(con_bd,str_query,'cur_yarl')
SELECT 'cur_yarl'
SCAN
	cur_ci = ALLTRIM(ci)
	cur_np = ALLTRIM(np)
	cur_kolvo_real = k
	IF cur_ci#'2'
		str_query = "select kolvo from bpd.registr_documents where dt=convert(date,'"+cur_date+"') and ci = "+cur_ci+" and np = ";
					+cur_np+" and doc_type = "+STR(ctype)
		b = SQLEXEC(con_bd,str_query,'tmp_cur')
		IF RECCOUNT('tmp_cur') = 0
			INSERT INTO tmp(ci,np,kolvo,kolvo_real) VALUES (cur_ci,cur_np,0,cur_kolvo_real)
		ENDIF
	ENDIF
	SELECT 'cur_yarl'
ENDSCAN

str_query = "select distinct np from bpd.soprovod_yarl_header where grup<700 and ci = 002 and dvv ='"+CHRTRAN(cur_date,'.','')+"'"
b = SQLEXEC(con_bd,str_query,'cur_np')
SELECT 'cur_np'
SCAN
	cur_np = LTRIM(np,'0')
	str_query = "select kolvo from bpd.registr_documents where dt=convert(date,'"+cur_date+"') and ci = 2 and np = "+cur_np+" and doc_type = "+STR(ctype)
	b = SQLEXEC(con_bd,str_query,'tmp_cur')
	IF RECCOUNT('tmp_cur') = 0
		cur_kolvo_real = 0
		str_query = "select convert(varchar(12),id_shtrih_kod) as sk from bpd.soprovod_yarl_header where grup<700 and ci=002 and np = ";
					+PADL(cur_np,3,'0')+" and dvv = '"+CHRTRAN(cur_date,'.','')+"'"
		b = SQLEXEC(con_bd,str_query,'tmp_cur')
		SELECT 'tmp_cur'
		IF RECCOUNT('tmp_cur')#0
			SCAN
				cur_sk = ALLTRIM(sk)
				str_query = "select COUNT(*) as k from bpd.soprovod_yarl_detail where id_shtrih_kod ="+ALLTRIM(cur_sk)+" group by id_shtrih_kod"
				b = SQLEXEC(con_bd,str_query,'tmp_cur2')
				SELECT 'tmp_cur2'
				cur_det = k
				str_query = "select COUNT(*) as k from bpd.soprovod_yarl_cou where id_shtrih_kod ="+ALLTRIM(cur_sk)+" group by id_shtrih_kod"
				b = SQLEXEC(con_bd,str_query,'tmp_cur2')
				SELECT 'tmp_cur2'
				cur_cou = k
				cur_kolvo_real = cur_det*cur_cou + cur_kolvo_real
				SELECT 'tmp_cur'
			ENDSCAN
		ENDIF 	
		INSERT INTO tmp(ci,np,kolvo,kolvo_real) VALUES ('2',cur_np,0,cur_kolvo_real)
	ENDIF
ENDSCAN

SELECT 'tmp'
IF RECCOUNT()#0
	SCAN 
		cur_ci = PADL(ALLTRIM(ci),3,' ')
		cur_np = PADL(ALLTRIM(np),3,' ')
		cur_kolvo = PADL(ALLTRIM(STR(kolvo)),3,' ')
		cur_kolvo_real = ALLTRIM(STR(kolvo_real))
		?CPCONVERT(1251,866,' '+cur_ci+'    '+cur_np+'          '+ cur_kolvo + '                    '+cur_kolvo_real)
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