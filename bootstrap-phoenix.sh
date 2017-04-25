#!/bin/bash

: ${HADOOP_PREFIX:=/opt/hadoop}
#: ${ZOO_HOME:=/opt/zookeeper}
: ${HBASE_HOME:=/opt/hbase}
: ${PHOENIX_HOME:=/opt/phoenix}

if [[ $1 == "-stop" ]]; then
	$HADOOP_PREFIX/sbin/stop-dfs.sh
	$HADOOP_PREFIX/sbin/stop-yarn.sh
	$HBASE_HOME/bin/stop-hbase.sh
	$PHOENIX_HOME/bin/queryserver.py stop
else

	rm /tmp/*.pid

	# installing libraries if any - (resource urls added comma separated to the ACP system variable)
	cd $HADOOP_PREFIX/share/hadoop/common ; for cp in ${ACP//,/ }; do  echo == $cp; curl -LO $cp ; done; cd -

	service sshd start

	export JAVA_HOME=/opt/jre

	declare -a files=(
		'/opt/hbase/conf/hbase-site.xml'
	)

	for file in "${files[@]}"; do
		if [ -f "${file}.bak" ]; then
			cp "${file}.bak" "${file}"
		else
			cp "${file}" "${file}.bak"
		fi

		sed -i "s/HOST_NAME/${HOSTNAME}/g" "${file}"
	done

	$HADOOP_PREFIX/sbin/start-dfs.sh
	$HADOOP_PREFIX/sbin/start-yarn.sh
	$HBASE_HOME/bin/start-hbase.sh

	if [[ $1 == "-d" ]]; then
	  while true; do sleep 1000; done
	fi

	if [[ $1 == "-bash" ]]; then
	  /bin/bash
	fi

	if [[ $1 == "-sqlline" ]]; then
	  $PHOENIX_HOME/bin/sqlline-thin.py localhost
	fi

	if [[ $1 == "-qs" ]]; then
	  echo "Starting queryserver"
	  $PHOENIX_HOME/bin/queryserver.py
	fi
fi
