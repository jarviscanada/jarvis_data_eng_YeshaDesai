
#!/bin/bash


psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

if [ "$#" -ne 5 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

# Save machine statistics in MB and current machine hostname to variables
vmstat_mb=$(vmstat --unit M)
hostname=$(hostname -f)

# CPU data

lscpu_out=$(lscpu)


# xargs is a trick to trim leading and trailing white spaces
cpu_number=$(echo "$lscpu_out" | grep -E "^CPU\(s\):" | awk '{print $2}' | xargs)
cpu_architecture=$(echo "$lscpu_out" | grep -E "Architecture:" \
	| awk '{print $2}' | xargs)
cpu_model=$(lscpu | grep "Model name:" | awk -F ': ' '{print $2}')

cpu_mhz=$(lscpu | grep "CPU mhz" | awk '{print $3}')
l2_cache=$(echo "$lscpu_out" | grep -E "L2 cache:" | awk '{print $3}' | xargs)
timestamp=$(vmstat -t | tail -n1 | awk '{print $18, $19}' | xargs)

# Subquery to find matching id in host_info table
host_id="(SELECT id FROM host_info WHERE hostname='$hostname')";

# PSQL command: Inserts server usage data into host_usage table
# Note: be careful with double and single quotes

insert_stmt="INSERT INTO host_info (hostname, cpu_number, cpu_architecture, cpu_model, cpu_mhz, l2_cache, timestamp, total_mem) VALUES ('$hostname', '$cpu_number', '$cpu_architecture', '$cpu_model', '$cpu_mhz', '$l2_cache', '$timestamp', '$total_mem');"

#set up env var for pql cmd
export PGPASSWORD=$psql_password 
#Insert date into a database
psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "$insert_stmt"
exit $?
