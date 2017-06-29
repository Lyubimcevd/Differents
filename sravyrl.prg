LPARAMETERS ctype,cPrName
cConnString="driver={SQL Server};SERVER=nitel-hp;uid=ldo;pwd=IfLyyz4sCJ;DATABASE=uit;WSID=VFP;APP=VFP;"
con_bd=SQLSTRINGCONNECT(cConnString, .T.)
SET PATH to "D:\PODDANW\" ADDITIVE
SET PATH TO "I:\PODDANW\" ADDITIVE
SET SQLBUFFERING ON
SET DATE GERMAN
SET CENTURY ON

cur_date = ALLTRIM(DTOC(DATE()))
print_path = "&PDTXT/inish.txt"
SET PRINT TO &print_path
SET CONS OFF
SET PRINT ON
?CPCONVERT(1251,866,' �������� '+cPrName+' �� '+cur_date)
?REPL('-',(62))
?CPCONVERT(1251,866,': ��� : ����� : ���������� ��������. : ���������� ���������. :')
?REPL('-',(62))
?

*������������ �������( �������� ���������� ���� � �� ������������ )

str_query = "select ci,np,kolvo from bpd.registr_documents where doc_type = ";
			+ALLTRIM(STR(ctype))+ " and dt = convert(date,'"+cur_date+"')"
b = SQLEXEC(con_bd,str_query,'cur_unic')
IF RECCOUNT('cur_unic')#0
	SELECT 'cur_unic'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_ci = ALLTRIM(STR(Arr[i,1]))
		cur_np = ALLTRIM(STR(Arr[i,2]))
		str_query = "select SUM(kolvo) from bpd.registr_documents where doc_type = ";
			+ALLTRIM(STR(ctype))+ " and dt = convert(date,'"+cur_date+"') and ci = ";
			+cur_ci+" and np = "+cur_np
		b = SQLEXEC(con_bd,str_query,'cur_unic')
		SELECT 'cur_unic'
		RELEASE Arr2
		COPY TO ARRAY Arr2
		IF (Arr[i,3] # Arr2[1])
			str_query = "delete from bpd.registr_documents where doc_type = ";
				+ALLTRIM(STR(ctype))+ " and dt = convert(date,'"+cur_date+"') and ci = ";
				+cur_ci+" and np = "+cur_np
			b = SQLEXEC(con_bd,str_query,'cur_unic')
			str_query = "INSERT INTO bpd.registr_documents(dt,ci,np,kolvo,doc_type);
 VALUES(convert(date,'"+cur_date+"'),"+cur_ci+","+cur_np+","+ALLTRIM(STR(Arr2[1]))+",120)"
 			b = SQLEXEC(con_bd,str_query,'cur_unic')
 		ENDIF
	ENDFOR
ENDIF  

CREATE CURSOR tmp(ci N,np N,kolvo N,kolvo_real N)
str_query = "select ci,np,kolvo from bpd.registr_documents where doc_type = ";
			+ALLTRIM(STR(ctype))+ " and dt = convert(date,'"+cur_date+"')"
b = SQLEXEC(con_bd,str_query,'cur_unic')
IF RECCOUNT('cur_unic')#0
	SELECT 'cur_unic'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_ci = ALLTRIM(STR(Arr[i,1]))
		cur_np = ALLTRIM(STR(Arr[i,2]))
		cur_kolvo = ALLTRIM(STR(Arr[i,3]))
		kolvo_real_ch = 0
		IF cur_ci == '2'
			str_query = "select id_shtrih_kod from bpd.soprovod_yarl_header where grup<700 and ci=002 and np = ";
						+PADL(cur_np,3,'0') +" and dvv = '"+CHRTRAN(cur_date,'.','')+"'"
			b = SQLEXEC(con_bd,str_query,'cur_unic')
			IF RECCOUNT('cur_unic')#0
				SELECT 'cur_unic'
				RELEASE Arr2
				COPY TO ARRAY Arr2
				FOR j = 1 TO ALEN(Arr2,1)
					str_query = "select COUNT(*) from bpd.soprovod_yarl_detail where id_shtrih_kod =";
								+ALLTRIM(STR(Arr2[j],12,0))+" group by id_shtrih_kod"
					b = SQLEXEC(con_bd,str_query,'cur_unic')
					SELECT 'cur_unic'
					RELEASE Arr_tmp
					COPY TO ARRAY Arr_tmp
					mn1 = Arr_tmp[1]
					str_query = "select COUNT(*) from bpd.soprovod_yarl_cou where id_shtrih_kod =";
								+ALLTRIM(STR(Arr2[j],12,0))+" group by id_shtrih_kod"
					b = SQLEXEC(con_bd,str_query,'cur_unic')
					SELECT 'cur_unic'
					RELEASE Arr_tmp
					COPY TO ARRAY Arr_tmp
					kolvo_real_ch = mn1*Arr_tmp[1] + kolvo_real_ch
				ENDFOR 
				RELEASE Arr2,Arr_tmp
			ELSE
				INSERT INTO tmp(ci,np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],Arr[i,3],0)
			ENDIF 			
		ELSE 
			str_query = "select COUNT(*) FROM bpd.predyarl WHERE grup<700 and stat=41 AND dvv='";
						+CHRTRAN(cur_date,'.','')+"' AND ci = "+cur_ci+" AND np = ";
						+cur_np+" group by ci,np "
			b = SQLEXEC(con_bd,str_query,'cur_unic')
			IF RECCOUNT('cur_unic')=0
				INSERT INTO tmp(ci,np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],Arr[i,3],0)
			ELSE
				SELECT 'cur_unic'
				RELEASE Arr1
				COPY TO array Arr1 
				kolvo_real_ch = Arr1[1]
			ENDIF
		ENDIF
		str_query = "UPDATE bpd.registr_documents SET kolvo_real =";
					+ ALLTRIM(STR(kolvo_real_ch))+" WHERE CI=";
					+cur_ci+" AND NP="+cur_np+" AND kolvo=";
					+cur_kolvo+" AND dt=convert(date,'"+cur_date+"') and doc_type = ";
					+ALLTRIM(STR(ctype))
		b = SQLEXEC(con_bd,str_query)
		IF Arr[i,3]#kolvo_real_ch AND kolvo_real_ch#0
			INSERT INTO tmp(ci,np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],Arr[i,3],kolvo_real_ch)		
		ENDIF
	ENDFOR
ENDIF
str_query = "select convert(smallint,Ci) as ci,convert(smallint,np) as np,COUNT(*) FROM;
 bpd.predyarl WHERE grup<700 and stat = 41 and dvv='"+CHRTRAN(cur_date,'.','')+"' group by ci,np "
b = SQLEXEC(con_bd,str_query,'cur_unic')
IF RECCOUNT('cur_unic')#0
	SELECT 'cur_unic'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_ci = ALLTRIM(STR(Arr[i,1]))
		cur_np = ALLTRIM(STR(Arr[i,2]))
		IF NOT cur_ci=='2'
			str_query = "select kolvo from bpd.registr_documents where dt=convert(date,'"+cur_date+"');
	 and ci = "+cur_ci+" and np = "+cur_np+" and doc_type = "+ALLTRIM(STR(ctype))
			b = SQLEXEC(con_bd,str_query,'cur_unic')
			IF RECCOUNT('cur_unic') = 0
				INSERT INTO tmp(ci,np,kolvo,kolvo_real) VALUES (Arr[i,1],Arr[i,2],0,Arr[i,3])
			ENDIF
		ENDIF
	ENDFOR
ENDIF 
str_query = "select np from bpd.soprovod_yarl_header where grup<700 and ci = 002 and dvv ='";
			+CHRTRAN(cur_date,'.','')+"' group by np"
b = SQLEXEC(con_bd,str_query,'cur_unic')
IF RECCOUNT('cur_unic')#0
	SELECT 'cur_unic'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_np = LTRIM(Arr[i,1],'0')
		str_query = "select kolvo from bpd.registr_documents where dt=convert(date,'"+cur_date+"');
	 and ci = 2 and np = "+cur_np+" and doc_type = "+ALLTRIM(STR(ctype))
		b = SQLEXEC(con_bd,str_query,'cur_unic')
		IF RECCOUNT('cur_unic') = 0
			kolvo_real_ch = 0
			str_query = "select id_shtrih_kod from bpd.soprovod_yarl_header where grup<700 and ci=002 and np = ";
						+PADL(cur_np,3,'0') +" and dvv = '"+CHRTRAN(cur_date,'.','')+"'"
			b = SQLEXEC(con_bd,str_query,'cur_unic')
			IF RECCOUNT('cur_unic')#0
				SELECT 'cur_unic'
				RELEASE Arr2
				COPY TO ARRAY Arr2
				FOR j = 1 TO ALEN(Arr2,1)
					str_query = "select COUNT(*) from bpd.soprovod_yarl_detail where id_shtrih_kod =";
								+ALLTRIM(STR(Arr2[j],12,0))+" group by id_shtrih_kod"
					b = SQLEXEC(con_bd,str_query,'cur_unic')
					SELECT 'cur_unic'
					RELEASE Arr_tmp
					COPY TO ARRAY Arr_tmp
					mn1 = Arr_tmp[1]
					str_query = "select COUNT(*) from bpd.soprovod_yarl_cou where id_shtrih_kod =";
								+ALLTRIM(STR(Arr2[j],12,0))+" group by id_shtrih_kod"
					b = SQLEXEC(con_bd,str_query,'cur_unic')
					SELECT 'cur_unic'
					RELEASE Arr_tmp
					COPY TO ARRAY Arr_tmp
					kolvo_real_ch = mn1*Arr_tmp[1] + kolvo_real_ch
				ENDFOR 
			ENDIF
			INSERT INTO tmp(ci,np,kolvo,kolvo_real) VALUES (2,VAL(Arr[i,1]),0,kolvo_real_ch)
		ENDIF
	ENDFOR
ENDIF
IF RECCOUNT('tmp')#0
	SELECT 'tmp'
	RELEASE Arr
	COPY TO ARRAY Arr
	FOR i = 1 TO ALEN(Arr,1)
		cur_ci = PADL(ALLTRIM(STR(Arr[i,1])),3,' ')
		cur_np = PADL(ALLTRIM(STR(Arr[i,2])),3,' ')
		cur_kolvo = PADL(ALLTRIM(STR(Arr[i,3])),3,' ')
		cur_kolvo_real = ALLTRIM(STR(Arr[i,4]))
		?CPCONVERT(1251,866,' '+cur_ci+'    '+cur_np+'          '+ cur_kolvo + '                    '+cur_kolvo_real)
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

