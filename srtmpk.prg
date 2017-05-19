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
?CPCONVERT(1251,866,' Протокол '+cPrName+' за '+cur_date)
?REPL('-',(56))
?CPCONVERT(1251,866,' Результаты по трудам ')
?CPCONVERT(1251,866,': Пачка : Количество зарегист. : Количество подгот. :')

CREATE CURSOR tmp(np N,kolvo N,kolvo_real N)
str_query = "select convert(char(10),dt,104) as dt from bpd.registr_documents where doc_type = ";
			+ALLTRIM(STR(ctype))
b = SQLEXEC(con_bd,str_query,'cur_unic')
SELECT 'cur_unic'
RELEASE Arr
COPY TO ARRAY Arr
cur_date = Arr[ALEN(Arr,1)]
str_query = "select np,kolvo from bpd.registr_documents where dt = convert(date,'";
			+cur_date+"') and doc_type = "+ALLTRIM(STR(ctype))+" and ci = 1"
b = SQLEXEC(con_bd,str_query,'cur_unic')
IF RECCOUNT('cur_unic')
	SELECT 'cur_unic'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_np = ALLTRIM(STR(Arr[i,1]))
		str_query = "select COUNT(*) FROM bpd.ktr1 WHERE grup<700 and dvv='";
					+CHRTRAN(cur_date,'.','')+"' AND np = "+cur_np+" group by np"
		b = SQLEXEC(con_bd,str_query,'cur_unic')
		IF RECCOUNT('cur_unic')=0
			INSERT INTO tmp(np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],0)
		ELSE
			SELECT 'cur_unic'
			RELEASE Arr1
			COPY TO array Arr1 
			str_query = "UPDATE bpd.registr_documents SET kolvo_real =";
							+ALLTRIM(STR(Arr1[1,1]))+" WHERE np=";
							+cur_np+" AND dt=convert(date,'";
							+cur_date+"') and doc_type = "+ALLTRIM(STR(ctype))+" and ci = 1"
			b = SQLEXEC(con_bd,str_query)
			IF Arr[i,2]#Arr1[1,1]
				INSERT INTO tmp(np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],Arr1[1,1])
			ENDIF
			
		ENDIF
	ENDFOR
ENDIF
str_query = "select convert(smallint,np) as np,COUNT(*) FROM bpd.ktr1 WHERE grup<700 and dvv='";
			+CHRTRAN(cur_date,'.','')+"' group by np"
b = SQLEXEC(con_bd,str_query,'cur_unic')
IF RECCOUNT('cur_unic')#0
	SELECT 'cur_unic'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_np = ALLTRIM(STR(Arr[i,1]))
		str_query = "select kolvo from bpd.registr_documents where dt=convert(date,'";
					+cur_date+"') and np = "+cur_np+" and doc_type = "+ALLTRIM(STR(ctype))
		b = SQLEXEC(con_bd,str_query,'cur_unic')
		IF RECCOUNT('cur_unic') = 0
			INSERT INTO tmp(np,kolvo,kolvo_real) VALUES (Arr[i,1],0,Arr[i,2])
		ENDIF
	ENDFOR
ENDIF
IF RECCOUNT('tmp')#0
	SELECT 'tmp'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_np = PADL(ALLTRIM(STR(Arr[i,2])),3,' ')
		cur_kolvo = PADL(ALLTRIM(STR(Arr[i,3])),3,' ')
		IF ISNULL(Arr[i,4])
			Arr[i,4] = 0
		ENDIF
		cur_kolvo_real = ALLTRIM(STR(Arr[i,4]))
		?CPCONVERT(1251,866,'  '+cur_np+'            '+ cur_kolvo + '                     '+cur_kolvo_real)
	ENDFOR
ENDIF
ZAP IN 'tmp'

?REPL('-',(56))
?CPCONVERT(1251,866,' Результаты по материалам ')
?CPCONVERT(1251,866,': Пачка : Количество зарегист. : Количество подгот. :')

str_query = "select np,kolvo from bpd.registr_documents where dt = convert(date,'";
			+cur_date+"') and doc_type = "+ALLTRIM(STR(ctype))+" and ci = 2"
b = SQLEXEC(con_bd,str_query,'cur_unic')
IF RECCOUNT('cur_unic')#0
	SELECT 'cur_unic'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_np = ALLTRIM(STR(Arr[i,1]))
		str_query = "select COUNT(*) FROM bpd.m56k WHERE grup<700 and dvv='";
					+CHRTRAN(cur_date,'.','')+"' AND np = "+cur_np+" group by np"
		b = SQLEXEC(con_bd,str_query,'cur_unic')
		IF RECCOUNT('cur_unic')=0
			INSERT INTO tmp(np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],0)
		ELSE
			SELECT 'cur_unic'
			RELEASE Arr1
			COPY TO array Arr1 
			str_query = "UPDATE bpd.registr_documents SET kolvo_real =";
							+ALLTRIM(STR(Arr1[1,1]))+" WHERE np=";
							+cur_np+" AND dt=convert(date,'";
							+cur_date+"') and doc_type = "+ALLTRIM(STR(ctype))+" and ci = 2"
			b = SQLEXEC(con_bd,str_query)				
			IF Arr[i,2]#Arr1[1,1]
				INSERT INTO tmp(np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],Arr1[1,1])
			ENDIF	
		ENDIF
	ENDFOR
ENDIF
str_query = "select convert(smallint,np) as np,COUNT(*) FROM bpd.m56k WHERE grup<700 and dvv='";
			+CHRTRAN(cur_date,'.','')+"' group by np"
b = SQLEXEC(con_bd,str_query,'cur_unic')
IF RECCOUNT('cur_unic')#0
	SELECT 'cur_unic'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_np = ALLTRIM(STR(Arr[i,1]))
		str_query = "select kolvo from bpd.registr_documents where dt=convert(date,'";
					+cur_date+"') and np = "+cur_np+" and doc_type = "+ALLTRIM(STR(ctype))
		b = SQLEXEC(con_bd,str_query,'cur_unic')
		IF RECCOUNT('cur_unic') = 0
			INSERT INTO tmp(np,kolvo,kolvo_real) VALUES (Arr[i,1],0,Arr[i,2])
		ENDIF
	ENDFOR
ENDIF 
IF RECCOUNT('tmp')#0
	SELECT 'tmp'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_np = PADL(ALLTRIM(STR(Arr[i,2])),3,' ')
		cur_kolvo = PADL(ALLTRIM(STR(Arr[i,3])),3,' ')
		IF ISNULL(Arr[i,4])
			Arr[i,4] = 0
		ENDIF
		cur_kolvo_real = ALLTRIM(STR(Arr[i,4]))
		?CPCONVERT(1251,866,'  '+cur_np+'            '+ cur_kolvo + '                     '+cur_kolvo_real)
	ENDFOR
ENDIF
ZAP IN 'tmp'

?REPL('-',(56))
?CPCONVERT(1251,866,' Результаты по покрытиям ')
?CPCONVERT(1251,866,': Пачка : Количество зарегист. : Количество подгот. :')

str_query = "select np,kolvo from bpd.registr_documents where dt = convert(date,'";
			+cur_date+"') and doc_type = "+ALLTRIM(STR(ctype))+" and ci = 3"
b = SQLEXEC(con_bd,str_query,'cur_unic')
IF RECCOUNT('cur_unic')#0
	SELECT 'cur_unic'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_np = ALLTRIM(STR(Arr[i,1]))
		str_query = "select COUNT(*) FROM bpd.m57k WHERE grup<700 and dvv='";
					+CHRTRAN(cur_date,'.','')+"' AND np = "+cur_np+" group by np"
		b = SQLEXEC(con_bd,str_query,'cur_unic')
		IF RECCOUNT('cur_unic')=0
			INSERT INTO tmp(np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],0)
		ELSE
			SELECT 'cur_unic'
			RELEASE Arr1
			COPY TO array Arr1
			str_query = "UPDATE bpd.registr_documents SET kolvo_real =";
							+ALLTRIM(STR(Arr1[1,1]))+" WHERE np=";
							+cur_np+" AND dt=convert(date,'";
							+cur_date+"') and doc_type = "+ALLTRIM(STR(ctype))+" and ci = 3" 
			b = SQLEXEC(con_bd,str_query)
			IF Arr[i,2]#Arr1[1,1]
				INSERT INTO tmp(np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],Arr1[1,1])
			ENDIF
		ENDIF
	ENDFOR
ENDIF 
str_query = "select convert(smallint,np) as np,COUNT(*) FROM bpd.m57k WHERE grup<700 and dvv='";
			+CHRTRAN(cur_date,'.','')+"' group by np"
b = SQLEXEC(con_bd,str_query,'cur_unic')
IF RECCOUNT('cur_unic')#0
	SELECT 'cur_unic'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_np = ALLTRIM(STR(Arr[i,1]))
		str_query = "select kolvo from bpd.registr_documents where dt=convert(date,'";
					+cur_date+"') and np = "+cur_np+" and doc_type = "+ALLTRIM(STR(ctype))
		b = SQLEXEC(con_bd,str_query,'cur_unic')
		IF RECCOUNT('cur_unic') = 0
			INSERT INTO tmp(np,kolvo,kolvo_real) VALUES (Arr[i,1],0,Arr[i,2])
		ENDIF
	ENDFOR
ENDIF
IF RECCOUNT('tmp')#0
	SELECT 'tmp'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_np = PADL(ALLTRIM(STR(Arr[i,2])),3,' ')
		cur_kolvo = PADL(ALLTRIM(STR(Arr[i,3])),3,' ')
		IF ISNULL(Arr[i,4])
			Arr[i,4] = 0
		ENDIF
		cur_kolvo_real = ALLTRIM(STR(Arr[i,4]))
		?CPCONVERT(1251,866,'  '+cur_np+'            '+ cur_kolvo + '                     '+cur_kolvo_real)
	ENDFOR
ENDIF
ZAP IN 'tmp'

?REPL('-',(56))
?CPCONVERT(1251,866,' Результаты по картам раскроя ')
?CPCONVERT(1251,866,': Пачка : Количество зарегист. : Количество подгот. :')

str_query = "select np,kolvo from bpd.registr_documents where dt = convert(date,'";
			+cur_date+"') and doc_type = "+ALLTRIM(STR(ctype))+" and ci = 4"
b = SQLEXEC(con_bd,str_query,'cur_unic')
IF RECCOUNT('cur_unic')#0
	SELECT 'cur_unic'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_np = ALLTRIM(STR(Arr[i,1]))
		str_query = "select COUNT(*) FROM bpd.razzag WHERE grup<700 and dvv='";
					+CHRTRAN(cur_date,'.','')+"' AND np = "+cur_np+" group by np"
		b = SQLEXEC(con_bd,str_query,'cur_unic')
		IF RECCOUNT('cur_unic')=0
			INSERT INTO tmp(np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],0)	
		ELSE
			SELECT 'cur_unic'
			RELEASE Arr1
			COPY TO array Arr1
			str_query = "UPDATE bpd.registr_documents SET kolvo_real =";
							+ALLTRIM(STR(Arr1[1,1]))+" WHERE np=";
							+cur_np+" AND dt=convert(date,'";
							+cur_date+"') and doc_type = "+ALLTRIM(STR(ctype))+" and ci = 4" 
			b = SQLEXEC(con_bd,str_query)
			IF Arr[i,2]#Arr1[1,1]
				INSERT INTO tmp(np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],Arr1[1,1])	
			ENDIF
		ENDIF
	ENDFOR
ENDIF
str_query = "select convert(smallint,np) as np,COUNT(*) FROM bpd.razzag WHERE grup<700 and dvv='";
			+CHRTRAN(cur_date,'.','')+"' group by np"
b = SQLEXEC(con_bd,str_query,'cur_unic')
IF RECCOUNT('cur_unic')#0
	SELECT 'cur_unic'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_np = ALLTRIM(STR(Arr[i,1]))
		str_query = "select kolvo from bpd.registr_documents where dt=convert(date,'";
					+cur_date+"') and np = "+cur_np+" and doc_type = "+ALLTRIM(STR(ctype))
		b = SQLEXEC(con_bd,str_query,'cur_unic')
		IF RECCOUNT('cur_unic') = 0
			INSERT INTO tmp(np,kolvo,kolvo_real) VALUES (Arr[i,1],0,Arr[i,2])
		ENDIF
	ENDFOR
ENDIF
IF RECCOUNT('tmp')#0
	SELECT 'tmp'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_np = PADL(ALLTRIM(STR(Arr[i,2])),3,' ')
		cur_kolvo = PADL(ALLTRIM(STR(Arr[i,3])),3,' ')
		IF ISNULL(Arr[i,4])
			Arr[i,4] = 0
		ENDIF
		cur_kolvo_real = ALLTRIM(STR(Arr[i,4]))
		?CPCONVERT(1251,866,'  '+cur_np+'            '+ cur_kolvo + '                     '+cur_kolvo_real)
	ENDFOR
ENDIF
SET PRINTER off 
SET PRINTER TO 
MODIFY COMMAND &print_path as 866
IF MESSAGEBOX("Печатать протокол по подготовленным данным? ",4,"Печать") = 6
	copy file &print_path to lpt1
ENDIF