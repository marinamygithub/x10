#!/usr/bin/ksh

#
# (c) IBM Corporation 2008
#
# $Id: run.sh,v 1.1 2008-02-22 12:34:03 srkodali Exp $
#
# Interactive script for benchmarking bfs.java.kgraph programs.
#

TOP=../../../..
prog_name=bfs.java.kgraph
. ${TOP}/config/run.header

_CMD_="java -d64 -Xdump:heap:none -Xdump:system:none -Xtrace:none"
_CMD_="${_CMD_} -Xdisablejavadump -Xcheck:memory:quick"
_CMD_="${_CMD_} -Xgcpolicy:gencon -Xjit:count=0"
_CMD_="${_CMD_} -cp ${TOP}/../xwsn.jar"
_CMD_="${_CMD_} -Xmx3G"
_CMD_="${_CMD_} graph.AdaptiveBFS"

seq=1
while [[ $seq -le $MAX_RUNS ]]
do
	printf "#\n# Run: %d\n#\n" $seq 2>&1| tee -a $OUT_FILE
	for size in 250000 1000000 4000000 9000000
	do
		printf "\n## Size: %d\n" $size 2>&1| tee -a $OUT_FILE
		for nproc in 1 2 4 6 8 10 12 14 16
		do
			printf "\n### nproc: %d\n" $nproc 2>&1| tee -a $OUT_FILE
			CMD="${_CMD_} $nproc K $size 4 false false true"
			printf "${CMD}\n" 2>&1| tee -a $OUT_FILE
			${CMD} 2>&1| tee -a $OUT_FILE
		done
	done
	let 'seq = seq + 1'
done
. ${TOP}/config/run.footer
