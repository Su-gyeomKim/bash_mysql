#!/bin/bash

NO_ARGS=0
OPTERROR=65

####################################### START OF INTRO #####################################
if [ $1 -z ]  # 인자 없이 불렸군요.
then
	echo "
	      Usage: ./dataCommand.sh [OPTIONS]
	
	      OPTIONS is none or any of:
	      -c                drop & create Table - BYDY_RISK_NTC_PRTC
	      -d                delete all data from Table - BYDY_RISK_NTC_PRTC
	      -e                drop & create Table - SRVR_INFR
	      -s		show Table data - DYBY_RISK_NTC_PRTC & SRVR_INFR
	      -D		desrcibe all Table
	     "
  #echo "사용법: `basename $0` options (-mnopqrs)"
  #exit $OPTERROR          # 인자가 주어지지 않았다면 사용법을 알려주고 종료.
fi

###################################### END OF INTRO #######################################


###################################### START OF OPTION #####################################
while getopts ":decsD" Option
do
  case $Option in

######################################################## START OF -s OPTION #######################################################
    c	  ) 	
	mysql TEST -t <<EOF_MySQL
		\! echo "================Drop & Create SRVR_INFR table======================="
		drop table BYDY_RISK_NTC_PRTC;
		create table BYDY_RISK_NTC_PRTC ( BASE_DT DATE NOT NULL, RISK_CLS_TP VARCHAR(2) NOT NULL, OCR_DTM DATETIME NOT NULL, DATA_SUM_TP VARCHAR(2) NOT NULL, SRVR_NM VARCHAR(20) NOT NULL, TR_NM VARCHAR(8) NOT NULL, SUM_CNT INT(11) NOT NULL, HIGH_CALC_CNT INT(11) NOT NULL, LOW_CALC_CNT INT(11) NOT NULL, SEND_PROC_TP VARCHAR(2) NOT NULL, CRET_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL, PRIMARY KEY (BASE_DT, RISK_CLS_TP, OCR_DTM, DATA_SUM_TP, SRVR_NM, TR_NM) );
		describe BYDY_RISK_NTC_PRTC;
		\! echo "============================Done==================================="
EOF_MySQL
		;;

######################################################## START OF -s OPTION #######################################################
    d	  ) 	
	mysql TEST -t <<EOF_MySQL
		\! echo "================Drop & Create SRVR_INFR table======================="
		drop table SRVR_INFR;
		create table SRVR_INFR ( SRVR_AREA_TP VARCHAR(2) NOT NULL, SRVR_NM VARCHAR(20) NOT NULL, USE_YN VARCHAR(1) NOT NULL, PRIMARY KEY (SRVR_AREA_TP, SRVR_NM) );
		describe SRVR_INFR;
		!\ echo "============================Done==================================="
EOF_MySQL
		;;

######################################################## START OF -s OPTION #######################################################
    e     )     
		echo "Delete all data from Table? (y/n)"
		read answer
        	if [ $answer = "y" ]; then
                	echo "use TEST; delete from BYDY_RISK_NTC_PRTC;" | mysql
        	else
                	echo "Progress stop"
	        fi
		;;


######################################################## START OF -s OPTION #######################################################
    s    )	

		ymd=`date '+%F'`;
		if [ ! -d $ymd ]; then 
			echo "There's no Log Directory"
			mkdir $ymd
			chown mysql:mysql $ymd
		fi;

	mysql TEST -t <<EOF_MySQL

        	\! echo "=================전체 카운트======================="
		select count(*) from BYDY_RISK_NTC_PRTC;

		\! echo -e "\n=================서버명 그룹바이 후 현재 $(date '+%F %T') 보다 30초 이전~현재까지 셀렉트 + 카운트 =======================\n"
		select              * from BYDY_RISK_NTC_PRTC where OCR_DTM < NOW() AND OCR_DTM > SUBDATE(NOW(), INTERVAL 30 SECOND) GROUP BY SRVR_NM;
		select count(SRVR_NM) from BYDY_RISK_NTC_PRTC where OCR_DTM < NOW() AND OCR_DTM > SUBDATE(NOW(), INTERVAL 30 SECOND) GROUP BY SRVR_NM;

		\! echo "      ================현재 $(date '+%F %T') 보다 30초 이전~현재까지 셀렉트 + 카운트 ======================="

		CREATE TEMPORARY TABLE IF NOT EXISTS tempTable1 ( INDEX(TR_NM) ) ENGINE=MEMORY AS (
			select *
                        from(
				select *
				from BYDY_RISK_NTC_PRTC
				where OCR_DTM < NOW() AND OCR_DTM > SUBDATE(NOW(), INTERVAL 30 SECOND) AND SEND_PROC_TP=01
			) A
			where SUM_CNT < LOW_CALC_CNT OR SUM_CNT > HIGH_CALC_CNT 
		);

		select * from tempTable1 ORDER BY OCR_DTM DESC LIMIT 100; 
		select count(*) from tempTable1;

		SET @Output = CONCAT('/root/Bash_Mysql/',  DATE_FORMAT(NOW(),'%Y-%m-%d'), '/tempTable1_', DATE_FORMAT(NOW(), '%Y-%m-%d_%H-%i-%s'), '.csv'); 
		SET @qry = CONCAT ("SELECT * INTO OUTFILE '", @Output, "' FIELDS TERMINATED BY ' ,' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n' FROM tempTable1");
		PREPARE stmt FROM @qry;
		EXECUTE stmt;
		#SET @qry := NULL;
		#DEALLOCATE PREPARE `stmt`;

		\! echo "	=======현재 $(date '+%F %T') 보다 30초 이전~현재까지 DATA 집계구분(DATA_SUM_TP) 건수 확인 ==============="
		CREATE TEMPORARY TABLE IF NOT EXISTS tempTable2 ENGINE=MEMORY AS (
			select OCR_DTM, DATA_SUM_TP, COUNT(*) "전체건수" 
			from tempTable1
			where OCR_DTM < NOW() AND OCR_DTM > SUBDATE(NOW(), INTERVAL 30 SECOND) AND SEND_PROC_TP=01
			group by DATA_SUM_TP
		);
		select * from tempTable2 ORDER BY OCR_DTM DESC LIMIT 100; 
		
		\! echo "	================현재 $(date '+%F %T') 보다 30초 이전~현재까지 위험구분 건수(RISK_CLS_TP)  확인 ======================="
		CREATE TEMPORARY TABLE IF NOT EXISTS tempTable3 ENGINE=MEMORY AS (
			select OCR_DTM, RISK_CLS_TP, COUNT(*) "전체건수" 
			from tempTable1
			where OCR_DTM < NOW() AND OCR_DTM > SUBDATE(NOW(), INTERVAL 30 SECOND) AND SEND_PROC_TP=01
			group by RISK_CLS_TP
		);
		select * from tempTable3 ORDER BY OCR_DTM DESC LIMIT 100; 
		
		\! echo "	================현재 $(date '+%F %T') 보다 30초 이전~현재까지 SRVR-TR모음  확인 ======================="
		CREATE TEMPORARY TABLE IF NOT EXISTS tempTable4 ENGINE=MEMORY AS (
			select SRVR_NM, TR_NM, count(SRVR_NM) 
			from tempTable1 
			group by SRVR_NM, TR_NM
		);

		select SRVR_NM, TR_NM, count(SRVR_NM) from tempTable1 group by SRVR_NM, TR_NM; 

		SET @Output = CONCAT('/root/Bash_Mysql/',  DATE_FORMAT(NOW(),'%Y-%m-%d'), '/tempTable4_', DATE_FORMAT(NOW(), '%Y-%m-%d_%H-%i-%s'), '.csv'); 
		SET @qry = CONCAT ("SELECT SRVR_NM, TR_NM, count(SRVR_NM) INTO OUTFILE '", @Output, "' FIELDS TERMINATED BY ' ,' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n' FROM tempTable1 group by SRVR_NM, TR_NM");
		PREPARE stmt FROM @qry;
		EXECUTE stmt;

		\! echo "	================ 집계용 과거 데이터 가져오기 테스트 ======================="
		CREATE TEMPORARY TABLE IF NOT EXISTS tempTable5 ENGINE=MEMORY AS (
			select * from tempTable4
		);
		delete from tempTable5;

		/*
		SET @input = CONCAT('/root/Bash_Mysql/',  DATE_FORMAT(NOW(),'%Y-%m-%d'), '/tempTable4_2019-09-11_08-15-57.csv'); 
		SET @qry = CONCAT ("LOAD DATA LOCAL INFILE'", @input, "'INTO TABLE tempTable5 FIELDS TERMINATED BY ' ,' ENCLOSED BY '\"'LINES TERMINATED BY '\n'");
		PREPARE stmt FROM @qry;
		EXECUTE stmt;
		*/

		LOAD DATA LOCAL INFILE '/root/Bash_Mysql/2019-09-11/tempTable4_2019-09-11_08-15-57.csv' INTO TABLE tempTable5 FIELDS TERMINATED BY ' ,' ENCLOSED BY '\"'LINES TERMINATED BY '\n';
		LOAD DATA LOCAL INFILE '/root/Bash_Mysql/2019-09-11/tempTable4_2019-09-11_09-56-02.csv' INTO TABLE tempTable5 FIELDS TERMINATED BY ' ,' ENCLOSED BY '\"'LINES TERMINATED BY '\n';
		describe tempTable5;
		select * from tempTable5  LIMIT 100; 
		
		select 'tempTable4', count(*) from tempTable4;
		select 'tempTable5', count(*) from tempTable5;

		select A.SRVR_NM,A.TR_NM,count(A.SRVR_NM+B.SRVR_NM) from tempTable4 as A, tempTable5 as B where A.SRVR_NM=B.SRVR_NM and A.TR_NM=B.TR_NM GROUP BY A.SRVR_NM,A.TR_NM ;


		# SEND_PROC_TP (발송처리구분) = 01 (미처리)인 항목들 02 (처리) 혹은 03 (취소)로 UPDATE QUERY 날리기
		#update SEND_PROC_TP set 02 from BYDY_RISK_NTC_PRTC where OCR_DTM < NOW() AND OCR_DTM > SUBDATE(NOW(), INTERVAL 30 SECOND) AND SEND_PROC_TP=01
	
EOF_MySQL
;;
######################################################## END OF -s OPTION ########################################################

######################################################## START OF -d OPTION #######################################################
    D	)	
mysql TEST -t <<EOF_MySQL
		describe SRVR_INFR; 
		describe BYDY_RISK_NTC_PRTC;
EOF_MySQL
	;;
######################################################## END OF -d OPTION ########################################################

    *  ) echo "UNKWON OPTION"
	;;
  esac
done

###################################### END OF OPTION  #######################################

#shift $(($OPTIND - 1))
# 인자 포인터를 감소시켜서 다음 인자를 가르키게 합니다.

exit 0

############################### END OF PROGRAM ################################################


if [ -z $1 ]; then
	echo
	echo "Usage: ./dataCommand.sh [OPTIONS]"
	echo
	echo "OPTIONS is none or any of:"
	echo "-d		delete all data from Table"
	echo "-c		drop & create Table"      
	echo
	#exit
fi

set -t

if [ $1 = "-d" ]; then
	echo "Delete all data from Table? (Y/N)"
	answer=read
	if [ $answer == "y" ]; then
		echo "use TEST; delete * from BYDY_RISK_NTC_PRTC LIMIT 50;" | mysql
	else
		echo hi
	fi
fi
#
: << Comment
echo "use TEST; drop table BYDY_RISK_NTC_PRTC;" | mysql

#echo "use TEST; create table BYDY_RISK_NTC_PRTC ( BASE_DT DATE NOT NULL, RISK_CLS_TP VARCHAR(2) NOT NULL, DATA_SUM_TP VARCHAR(2) NOT NULL, OCR_DTM DATETIME NOT NULL, SRVR_NM VARCHAR(20) NOT NULL, TR_NM VARCHAR(8) NOT NULL, RISK_CNT VARCHAR(200) NOT NULL, CRET_DTM DATETIME NOT NULL, PRIMARY KEY (BASE_DT, RISK_CLS_TP, DATA_SUM_TP, OCR_DTM, SRVR_NM, TR_NM) )"| mysql

echo "use TEST; drop table BYDY_RISK_NTC_PRTC;" | mysql
echo "use TEST; create table BYDY_RISK_NTC_PRTC ( BASE_DT DATE NOT NULL, RISK_CLS_TP VARCHAR(2) NOT NULL, DATA_SUM_TP VARCHAR(2) NOT NULL, OCR_DTM DATETIME NOT NULL, SRVR_NM VARCHAR(20) NOT NULL, TR_NM VARCHAR(8) NOT NULL, RISK_CNT VARCHAR(200) NOT NULL, CRET_DTM TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL, PRIMARY KEY (BASE_DT, RISK_CLS_TP, DATA_SUM_TP, OCR_DTM, SRVR_NM, TR_NM) )"| mysql

Comment
#
######################################################################################################################################################################
echo =================전체 셀렉트 Limit 50 =======================
echo "use TEST; select * from BYDY_RISK_NTC_PRTC LIMIT 50;" | mysql
echo 
echo =================위험 분류 그룹바이 후 현재\(\"$(date '+%F %T')\"\)보다 이전까지 셀렉트 + 카운트 =======================
echo "use TEST; select RISK_CLS_TP, count(RISK_CLS_TP) from BYDY_RISK_NTC_PRTC where OCR_DTM < \"$(date '+%F %T')\" GROUP BY RISK_CLS_TP ORDER BY RISK_CLS_TP, OCR_DTM ASC;" | mysql
echo
echo =================오름차순 전체 셀렉트 + 카운트 =======================
echo "use TEST; select *, count(*) from BYDY_RISK_NTC_PRTC ORDER BY RISK_CLS_TP, OCR_DTM ASC;" | mysql
echo
echo =================서버명 그룹바이 후 현재\(\"$(date '+%F %T')\"\)보다 6시간 이전~30초 이전까지 셀렉트 + 카운트 =======================
echo "use TEST; select SRVR_NM, count(SRVR_NM) from BYDY_RISK_NTC_PRTC where OCR_DTM < SUBDATE(NOW(), INTERVAL 30 SECOND) AND OCR_DTM > SUBDATE(NOW(), INTERVAL 6 HOUR) GROUP BY SRVR_NM;" | mysql 
echo
echo =================서버명 그룹바이 후 현재\(\"$(date '+%F %T')\"\)보다 30초 이전~현재까지 셀렉트 + 카운트 =======================
echo "use TEST; select SRVR_NM, count(SRVR_NM) from BYDY_RISK_NTC_PRTC where OCR_DTM < NOW() AND OCR_DTM > SUBDATE(NOW(), INTERVAL 30 SECOND) GROUP BY SRVR_NM;" | mysql 
echo
echo =================위험 분류 그룹바이 후 현재\(\"$(date '+%F %T')\"\)보다 30초 이전~현재까지 셀렉트 + 카운트 =======================
echo "use TEST; select RISK_CLS_TP, count(RISK_CLS_TP) from BYDY_RISK_NTC_PRTC where OCR_DTM < SUBDATE(NOW(), INTERVAL 30 SECOND) AND OCR_DTM > SUBDATE(NOW(), INTERVAL 6 HOUR) GROUP BY RISK_CLS_TP;" | mysql
echo
echo =================TR명 그룹바이 후 현재\(\"$(date '+%F %T')\"\)보다 30초 이전~현재까지 셀렉트 + 카운트 =======================
echo "use TEST; select TR_NM, count(TR_NM) from BYDY_RISK_NTC_PRTC where OCR_DTM < SUBDATE(NOW(), INTERVAL 30 SECOND) AND OCR_DTM > SUBDATE(NOW(), INTERVAL 6 HOUR) GROUP BY TR_NM;" | mysql
echo
echo =================전체 현재\(\"$(date '+%F %T')\"\)보다 30초 이전~현재까지 카운트 =======================
echo "use TEST; select count(*) from BYDY_RISK_NTC_PRTC where OCR_DTM < SUBDATE(NOW(), INTERVAL 30 SECOND) AND OCR_DTM > SUBDATE(NOW(), INTERVAL 6 HOUR) ORDER BY RISK_CLS_TP, OCR_DTM ASC;" | mysql

			#where Condtion.SUM_CNT < Condtion.LOW_CALC_CNT OR Condtion.SUM_CNT < Condtion.LOW_CALC_CNT 


		CREATE TEMPORARY TABLE IF NOT EXISTS tempTable1 ( INDEX(TR_NM) ) ENGINE=MEMORY AS (
			select * 
			from( 
				select BASE_DT,RISK_CLS_TP,OCR_DTM,DATA_SUM_TP,SRVR_NM,TR_NM,SUM_CNT,HIGH_CALC_CNT,LOW_CALC_CNT,SEND_PROC_TP
				from BYDY_RISK_NTC_PRTC 
				where OCR_DTM < NOW() AND OCR_DTM > SUBDATE(NOW(), INTERVAL 30 SECOND) AND SEND_PROC_TP=01
			)Condition
			where Condition.SUM_CNT < Condition.LOW_CALC_CNT OR Condition.SUM_CNT > Condition.HIGH_CALC_CNT 
		);

		CREATE TEMPORARY TABLE IF NOT EXISTS tempTable1 ( INDEX(TR_NM) ) ENGINE=MEMORY AS (
			select *
                        from(
				select *
				from BYDY_RISK_NTC_PRTC
			) A
		);

		CREATE TEMPORARY TABLE IF NOT EXISTS tempTable1 ( INDEX(TR_NM) ) ENGINE=MEMORY AS (
			select *
                        from(
				select *
				from BYDY_RISK_NTC_PRTC
				where OCR_DTM < NOW() AND OCR_DTM > SUBDATE(NOW(), INTERVAL 30 SECOND) AND SEND_PROC_TP=01
			) A
			where SUM_CNT < LOW_CALC_CNT OR SUM_CNT > HIGH_CALC_CNT 
		);

#\!  echo "select * from tempTable1 ORDER BY OCR_DTM DESC" | mysql TEST >> $ymd/`date '+%F_%T'_tempTable1` 
#\! echo "select * from BYDY_RISK_NTC_PRTC where OCR_DTM < NOW() AND OCR_DTM > SUBDATE(NOW(), INTERVAL 30 SECOND)" | mysql TEST >> $ymd/`date '+%F_%T'`
#\! echo "select * from BYDY_RISK_NTC_PRTC where OCR_DTM < NOW()" | mysql TEST >> $ymd/`date '+%F_%T'`

######################################################################################################################################################################
