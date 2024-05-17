
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

# host_usage data
memory_free=$(echo "$vmstat_mb" | awk '{print $4}'| tail -n1 | xargs)
cpu_idle=$(echo "$vmstat_mb" | awk '{print $15}')
cpu_kernel=$(echo "$vmstat_mb" | awk '{print $14}') 
disk_io=$(vmstat -d | awk '{print $10}') 
disk_available=$(df -BM / | awk 'NR==2{print $4}' | tr -d 'M') 
timestamp=$(vmstat -t | awk 'NR==3{print $18 " " $19}') 


host_id="(SELECT id FROM host_info WHERE hostname='$hostname')";


# insert into table
insert_stmt="INSERT INTO host_usage(timestamp, host_id, memory_free, cpu_idle, cpu_kernel, disk_io, disk_available) VALUES('$timestamp', $host_id, '$memory_free', '$cpu_idle', '$cpu_kernel', '$disk_io', '$disk_available');"
#set up env var for pql cmd
export PGPASSWORD=$psql_password


#Insert date into a database
psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "$insert_stmt"
exit $?



