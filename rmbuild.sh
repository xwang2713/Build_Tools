#!/bin/bash
if [ -z "$1" ] 
then
   echo "Usage: $(basename $0) [build pattern]"
   exit 1
fi
build_pattern=$1
work_dir=$(dirname $0)

SCRIPT_FILE=/tmp/rmbuild_$$

[ -e $SCRIPT_FILE ] && rm -rf $SCRIPT_FILE

cat >> $SCRIPT_FILE <<EOF
#!/bin/bash

ip=\$1
systems_list=${work_dir}/systems
line=\$(cat \$systems_list | grep \$ip | sed -n "s/[[:space:]][[:space:]]*/ /gp")

user=\$(echo \$line | cut -d' ' -f 2)
#worspace=\$(echo \$line | cut -d' ' -f 3)

if ping -c 1 -w 5 -n \${ip} > /dev/null 2>&1
then
# Single quote around first SSHCMD is important otherwise cannot define variables
# in SSH session.
       ssh  \${user}@\${ip} << 'SSHCMD' 

# Add anyting you want to do for the jenkins slave between tow SSHCMD marks
# Just remember for any vairable expanding at runtime need escape char
# Without escape char the variable will expand when this script is created which.
# is useful since we cannot pass any variable to SSH session but it can be set
# when the script is generated.

PATTERN=$build_pattern
WORKSPACE=/var/lib/jenkins/workspace
[ ! -d \$WORKSPACE ] && WORKSPACE=\${HOME}/jenkins/workspace
echo "Workspace: \$WORKSPACE"
if [ -d \${WORKSPACE} ]
then
    ls -d \${WORKSPACE}/*\${PATTERN}* | while read f
    do
        echo "\$(hostname): rm -rf \$f"
        [ -e "\$f" ] &&  rm -rf \$f
    done
fi

SSHCMD

else
  echo "can not ping the ip"
  exit 1
fi

EOF

chmod +x $SCRIPT_FILE
log_file=cluster_script.log
[ -e $log_file ] && rm -rf $log_file
echo "${work_dir}/cluster_script.py -o $log_file -n 10 -f $SCRIPT_FILE -h ${work_dir}/ips.txt"
#eval ${work_dir}/cluster_script.py -o $log_file -n 10 -f $SCRIPT_FILE -h ${work_dir}/ips.txt -l DEBUG
eval ${work_dir}/cluster_script.py -o $log_file -n 10 -f $SCRIPT_FILE -h ${work_dir}/ips.txt 

rm -rf $SCRIPT_FILE
