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
?REPL('-',(67))
?CPCONVERT(1251,866,':   Дата   : Пачка : Количество зарегист. : Количество подготовл. :')
?REPL('-',(67))
?

CREATE CURSOR tmp(dt C(10),np N,kolvo N,kolvo_real N)
str_query = "select convert(char(10),dt,104) as dt from bpd.registr_documents where doc_type = ";
			+ALLTRIM(STR(ctype))
b = SQLEXEC(con_bd,str_query,'cur_unic')
SELECT 'cur_unic'
RELEASE Arr
COPY TO ARRAY Arr
cur_date = Arr[ALEN(Arr,1)]
str_query = "select np,kolvo from bpd.registr_documents where dt = convert(date,'";
			+cur_date+"') and doc_type = "+ALLTRIM(STR(ctype))
b = SQLEXEC(con_bd,str_query,'cur_unic')
IF RECCOUNT('cur_unic')#0
	SELECT 'cur_unic'
	RELEASE Arr
	COPY TO ARRAY Arr	
	FOR i = 1 TO ALEN(Arr,1)
		cur_np = ALLTRIM(STR(Arr[i,1]))
		cur_kolvo = ALLTRIM(STR(Arr[i,2]))
		str_query = "select COUNT(*) FROM bpd.bank1 WHERE grup<700 and dvv='";
					+CHRTRAN(cur_date,'.','')+"' AND npat = "+cur_np+" group by npat"
		b = SQLEXEC(con_bd,str_query,'cur_unic')
		IF RECCOUNT('cur_unic')=0
			INSERT INTO tmp(dt,np,kolvo,kolvo_real) VALUES (cur_date,VAL(cur_np),VAL(cur_kolvo),0)
		ELSE
			SELECT 'cur_unic'
			RELEASE Arr1
			COPY TO array Arr1 
			str_query = "UPDATE bpd.registr_documents SET kolvo_real =";
							+ALLTRIM(STR(Arr1[1,1]))+" WHERE NP=";
							+cur_np+" AND kolvo="+ALLTRIM(STR(Arr[i,2]))+" AND dt=convert(date,'";
							+cur_date+"') and doc_type = "+ALLTRIM(STR(ctype))
			b = SQLEXEC(con_bd,str_query)
			IF Arr[i,2]#Arr1[1,1]
				INSERT INTO tmp(dt,np,kolvo,kolvo_real) VALUES (cur_date,VAL(cur_np),VAL(cur_kolvo),Arr1[1,1])
			ENDIF
		ENDIF
	ENDFOR
ENDIF
str_query = "select convert(smallint,npat) as np,COUNT(*) FROM bpd.bank1 WHERE grup<700 and dvv='";
			+CHRTRAN(cur_date,'.','')+"' group by npat"
b = SQLEXEC(con_bd,str_query,'cur_unic')
SELECT 'cur_unic'
RELEASE Arr
COPY TO ARRAY Arr
FOR i = 1 TO ALEN(Arr,1)
	cur_np = ALLTRIM(STR(Arr[i,1]))
	str_query = "select kolvo from bpd.registr_documents where dt=convert(date,'";
				+cur_date+"') and np = "+cur_np+" and doc_type = "+ALLTRIM(STR(ctype))
	b = SQLEXEC(con_bd,str_query,'cur_unic')
	IF RECCOUNT('cur_unic') = 0
		INSERT INTO tmp(dt,np,kolvo,kolvo_real) VALUES (cur_date,Arr[i,1],0,Arr[i,2])
	ENDIF
ENDFOR
IF RECCOUNT('tmp')#0
	SELECT 'tmp'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_np = PADL(ALLTRIM(STR(Arr[i,2])),3,' ')
		cur_kolvo = PADL(ALLTRIM(STR(Arr[i,3])),3,' ')
		cur_kolvo_real = ALLTRIM(STR(Arr[i,4]))
		?CPCONVERT(1251,866,' '+cur_date+'   '+cur_np+'            '+ cur_kolvo + '                     '+cur_kolvo_real)
	ENDFOR
	SET PRINTER off 
	SET PRINTER TO 
	MODIFY COMMAND &print_path as 866
	IF MESSAGEBOX("Печатать протокол по подготовленным данным? ",4,"Печать") = 6
		copy file &print_path to lpt1
	ENDIF
ELSE
	MESSAGEBOX("Ошибок нет",0,cPrName)
ENDIF
