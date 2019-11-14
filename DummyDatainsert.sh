#!/bin/bash

#: <<'END'

# while 반복문은 프로그램이 도는 동안 계속 실행된다.
while true
do
	# `date` 명령으로 받아온 현재 시간의 '초'값이 30초 보다 작으면 0초로,         #
	# 30초보다 크거나 같으면 30초로 바꾼 시간값 문자열을 'today'변수에 저장한다 #
	if [ `date +%S` -lt 30 ]; then
		today=`date "+%Y-%m-%d %H:%M:00"`
	else
		today=`date "+%Y-%m-%d %H:%M:30"`
	fi	

	# 'time'변수는 'today'에 저장한 현재시간을 가져와 timestamp 형식으로 저장한다 #
	time="`date -d "$today" +%s`"
	# for 반복문은 1분동안 2회 수행된다.
	for i in {1..2};	do

		# 'rand_[0-9]' 변수들은 0~[1-9]까지의 값을 같는 변수들이다.                             #
		# 'rand100' 변수의 경우 아래 for 문이 0~99회까지 돌면서 DB에 INSERT시키는 과정을 반복한다. #
		rand_100=`expr $RANDOM % 100`
		for ((j=0; j<rand_100; j++));	do


			tr_nm=("tr_login" "tr_stock" "tr_view " "tr_trade")

			# 'rand_2' 변수는 1,2 두가지 값을 랜덤하게 같는다, 'rand_4'는 1~4의 값을 같는다. 'rand5'는 1~5의 값을 갖는다. #
			rand_2=`expr $RANDOM % 2 + 1`
			rand_4=`expr $RANDOM % 4 + 1`
			rand_5=`expr $RANDOM % 5 + 1`
			
			tr_nm=("tr_login" "tr_stock" "tr_view " "tr_trade")

			RISK_CLS_TYPE=0;
			
			SUM_CNT=$RANDOM
			HIGH_CALC_CNT=$RANDOM
			LOW_CALC_CNT=$(($HIGH_CALC_CNT-$RANDOM))
			
			if [ $LOW_CALC_CNT -lt 0 ];then LOW_CALC_CNT=0; fi;
			if [ $SUM_CNT -gt $HIGH_CALC_CNT ];then RISK_CLS_TYPE=1; fi;
			if [ $SUM_CNT -lt $LOW_CALC_CNT  ];then RISK_CLS_TYPE=2; fi;
			
			#침해($SUM_CNT > $HIGH_CALC_CNT) OR 이상($SUM_CNT < $LOW_CALC_CNT) 현상이 아닐 때,
			if [ $RISK_CLS_TYPE -eq 0 ];then
				continue;
			fi

			date_adjust=`date -d @$time +%Y-%m-%d" "%T`

			#RISK_CLS_TP=01(FULL) => 서버명, TR명 전부 FULL이 옴
			if [ $rand_4 -eq 1 ]; then
	 		  echo "INSERT IGNORE INTO BYDY_RISK_NTC_PRTC (BASE_DT,RISK_CLS_TP,OCR_DTM,DATA_SUM_TP,SRVR_NM,TR_NM,SUM_CNT,HIGH_CALC_CNT,LOW_CALC_CNT,SEND_PROC_TP) VALUES ("\"${date_adjust:0:10}\"","0$RISK_CLS_TYPE","\"$date_adjust"\","0$rand_4",\"FULL    \",\"FULL    \",\"$RANDOM\",\"$HIGH_CALC_CNT\",\"$LOW_CALC_CNT\",\"01\")" | mysql TEST;

			#RISK_CLS_TP=02(SRVR-TR) => 서버명, TR명 전부 옴
			elif [ $rand_4 -eq 2 ]; then
			  echo "INSERT IGNORE INTO BYDY_RISK_NTC_PRTC (BASE_DT,RISK_CLS_TP,OCR_DTM,DATA_SUM_TP,SRVR_NM,TR_NM,SUM_CNT,HIGH_CALC_CNT,LOW_CALC_CNT,SEND_PROC_TP) VALUES ("\"${date_adjust:0:10}\"","0$RISK_CLS_TYPE","\"$date_adjust"\","0$rand_4",\"server0$rand_5\",\"${tr_nm[$(($RANDOM%4))]}\",\"$RANDOM\",\"$HIGH_CALC_CNT\",\"$LOW_CALC_CNT\",\"01\")" | mysql TEST;

			#RISK_CLS_TP=03(SRVR) => 서버명, TR 옴
			elif [ $rand_4 -eq 3 ]; then
			  echo "INSERT IGNORE INTO BYDY_RISK_NTC_PRTC (BASE_DT,RISK_CLS_TP,OCR_DTM,DATA_SUM_TP,SRVR_NM,TR_NM,SUM_CNT,HIGH_CALC_CNT,LOW_CALC_CNT,SEND_PROC_TP) VALUES ("\"${date_adjust:0:10}\"","0$RISK_CLS_TYPE","\"$date_adjust"\","0$rand_4",\"server0$rand_5\",\"TR\",\"$RANDOM\",\"$HIGH_CALC_CNT\",\"$LOW_CALC_CNT\",\"01\")" | mysql TEST;

			#RISK_CLS_TP=04(TR) => SRVR, TR명 옴
			elif [ $rand_4 -eq 4 ]; then
			  echo "INSERT IGNORE INTO BYDY_RISK_NTC_PRTC (BASE_DT,RISK_CLS_TP,OCR_DTM,DATA_SUM_TP,SRVR_NM,TR_NM,SUM_CNT,HIGH_CALC_CNT,LOW_CALC_CNT,SEND_PROC_TP) VALUES ("\"${date_adjust:0:10}\"","0$RISK_CLS_TYPE","\"$date_adjust"\","0$rand_4",\"SRVR\",\"${tr_nm[$(($RANDOM%4))]}\",\"$RANDOM\",\"$HIGH_CALC_CNT\",\"$LOW_CALC_CNT\",\"01\")" | mysql TEST;
			fi;

		#sleep 3
		done
		# for 반복문이 수행되고 난 이후에는 timestamp 형식인 'time'변수에 30초를 더해준다. #
		time=$(($time+30))
	# 30초 동안 `sleep` 명령으로 대기 시킨다. #
	sleep 30
	# 1회돌고 30초동안 대기하고 2회째 돌고 30초 대기한후에 1분이 종료된다. #
	done
done

###############################################
#echo "use TEST; INSERT INTO BYDY_RISK_NTC_PRTC (BASE_DT,RISK_CLS_TP,DATA_SUM_TP,OCR_DTM,SRVR_NM,TR_NM,CRET_DTM) VALUES ("2019-08-05","02","02","2019-08-05 17:56:27","server1","tr_trade","2019-08-05 17:56:27")" | mysql
#echo "use TEST; select RISK_CLS_TP, count(RISK_CLS_TP) from BYDY_RISK_NTC_PRTC where OCR_DTM < \"$(date '+%F %T')\" GROUP BY RISK_CLS_TP ORDER BY RISK_CLS_TP, OCR_DTM ASC;" | mysql
date -d "2019-01-02 09:00:00" +%Y-%m-%d" "%T
#\"$(date '+%F %T')\"
#echo "use TEST; INSERT INTO BYDY_RISK_NTC_PRTC (BASE_DT,RISK_CLS_TP,DATA_SUM_TP,OCR_DTM,SRVR_NM,TR_NM) VALUES ("${today:0:10}","0$rand_2","0$rand_4","\"$date\"","server$rand_5","${tr_nm[$(($RANDOM%4))]}")" | mysql

#Insert into SRVR_INFR (SRVR_AREA_TP, SRVR_NM, USE_YN) VALUES ('01','server05','Y');
#############################################

#END
