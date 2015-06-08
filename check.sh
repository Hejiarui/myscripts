#/bin/bash

CHKFILE="/root/maint/check.out"
RCVFILE="/root/maint/Recovery.Base"
RCVLOG="/root/maint/Recovery.log"
STRSTART="Process"
STRSTAT="Status"
PROSTR="pwconnsrv pwaccsrv pwdbsrv pwctrlsrv pwworldsrv"
DBSTR="pwgdbserver"
OK="[OK]"
FAIL="[FAIL]"
DEVIDE="---------------------------------------------------------------"

ZERO=0
EXIST=1

print_with()
{
	if [ $# -eq 1 ]
	then
		printf "\e[34m%s\e[0m\n" $1
	elif [ $2 = $OK ]
	then
		printf "\e[32m%-20s%43s\e[0m\n" "$1" "$2"
	elif [ $2 = $FAIL ]
	then
		printf "\e[31m%-20s%44s\e[0m\n" "$1" "$2"
	else
		printf "\e[34m%-20s%s\e[0m\n" "$1" "$2"
	fi
}	
#memory used on game1 and database
mem_check()
{
	MEMTOL=$(rsh $1 free -m | gawk 'NR==2{print $2}')
	MEMUSED=$(rsh $1 free -m | gawk 'NR==3{print $3}')
	MEMFREE=$(rsh $1 free -m | gawk 'NR==3{print $4}')
	printf "\e[34mMemory stats of $1\n%-20s%42sM\n%-20s%42sM\n" "Total:" "$MEMTOL" "Used:" "$MEMUSED" 
	
	if [ $MEMFREE -lt 9000 ]
	then
		printf "\e[41m%-20s%42sM\e[0m\n" "Free:" "$MEMFREE"
	else
		printf "\e[34m%-20s%42sM\e[0m\n" "Free:" "$MEMFREE"
	fi
	
	print_with $DEVIDE
}

#check port listening
check_ccu()
{
	if [ $1 -eq $ZERO ]
	then
		LSTN=$(cat $CHKFILE | grep ESTABLISHED | grep 2900$i | wc -l)
		print_with $SHARD "CCU:$LSTN"
	elif [ $1 -eq $EXIST ]
	then
		CCUSUM=$(cat $CHKFILE | grep ESTABLISHED | wc -l)
		print_with "SUMMARY" "SUMCCU:$CCUSUM"
	fi
}

#layout Recovery.Base and append to Recovery.log
co_recovery()
{
	DATE=`date "+[%Y%m%d-%H:%M]"`
	echo "$FAIL $DATE $SHARD $FAILPRO" >> $RCVFILE
	echo "$FAIL $DATE $SHARD $FAILPRO" >> $RCVLOG
}
#check all process on game1
check_game()
{
	rm -f $CHKFILE
	rm -f $RCVFILE
	rsh game1 ps aux | grep pw > $CHKFILE
	PWSUM=`cat $CHKFILE | grep pw | wc -l`
	rsh game1 netstat -antpl | grep 2900 >>$CHKFILE
	rsh database ps aux | grep pw >> $CHKFILE

	if [ $PWSUM -eq $ZERO ]
	then
		printf "\e[31mNO GAME IS RUNNING!"
	else
		check_ccu 1
		for i in {1..8}
		do
			FAILPRO=""
			FAILTAG=0
			SHARD="bh_310$i"
			DB_SHARD="game_db_310$i"
			print_with $DEVIDE
			check_ccu 0
			for p in $PROSTR
			do
				prostat=$(cat $CHKFILE | grep $SHARD | grep $p | wc -l)
				if [ $prostat -eq $ZERO ]
				then
					FAILTAG=1
					FAILPRO="$FAILPRO""$p"" "
					print_with $p $FAIL
				elif [ $prostat -eq $EXIST ]
				then
					print_with $p $OK
				fi
			done
			
			if [ $FAILTAG -eq 1 ]
			then
				co_recovery
			fi

			dbstat=$(cat $CHKFILE | grep $DB_SHARD | grep $DBSTR | wc -l)
			if [ $dbstat -eq $EXIST ]
			then
				print_with $DBSTR $OK
			elif [ $dbstat -eq $ZERO ]
			then
				print_with $DBSTR $FAIL
			fi
			
		done
	fi
	
}


mem_check game1
mem_check database
check_game
rm -f $CHKFILE
