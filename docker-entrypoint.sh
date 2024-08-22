#!/bin/sh
#modify from 
set -e

pg_version=$(pg_versions get-default)
name="PostgreSQL $pg_version"
description="PostgreSQL $pg_version server"
user="postgres"
group="postgres"
auto_setup="yes"
start_timeout=10

data_dir="/var/lib/postgresql/$pg_version/data"
conf_dir="/etc/postgresql"
logfile="/var/log/postgresql/postmaster.log"
port=5432
pg_opts=

command="/usr/libexec/postgresql$pg_version/postgres"

conffile="$conf_dir/postgresql.conf"
pidfile="$data_dir/postmaster.pid"
start_stop_daemon_args=""

start_pre() {
	if [ ! -d "$data_dir/base" ]; then
		if [ "$auto_setup" == "yes" ]; then
			setup || return 1
		else
			echo "Database not found at: $data_dir"
			echo "Please make sure that 'data_dir' points to the right path."
			echo "You can run '/etc/init.d/postgresql setup' to setup a new database cluster."
			return 1
		fi
	fi

	# This is mainly for backward compatibility with the former $conf_dir default value.
	if [ "$conf_dir" = /etc/postgresql ] && ! [ -f "$conf_dir/postgresql.conf" ]; then
		conf_dir=$data_dir
	fi

	local socket_dirs=$(get_config "unix_socket_directories" "/run/postgresql")
	local port=$(get_config "port" "$port")

    if [ ! -d "$socket_dirs" ]; then
        mkdir -p "$socket_dirs"
        chown -R $user:$group "$socket_dirs"
	fi

	start_stop_daemon_args="$start_stop_daemon_args --env PGPORT=$port"

	local var; for var in $env_vars; do
		start_stop_daemon_args="$start_stop_daemon_args --env $var"
	done

	(
		# Set the proper permission for the socket paths and create them if
		# they don't exist.
		set -f; IFS=","
		for dir in $socket_dirs; do
			if [ -e "${dir%/}/.s.PGSQL.$port" ]; then
				echo "Socket conflict. A server is already listening on:"
				echo "    ${dir%/}/.s.PGSQL.$port"
				echo "Hint: Change 'port' to listen on a different socket."
				return 1
			elif [ "${dir%/}" != "/tmp" ]; then
                chown -R $user:$group "$dir"
                chmod 1775 "$dir"
			fi
		done
	)
}

start() {
	echo "Starting $name"

	rm -f "$pidfile"
	su $user -c  \
		"/usr/bin/pg_ctl \
		-- start \
			-w --timeout=$start_timeout \
			--log=$logfile \
			--pgdata=$conf_dir \
			-o '--data-directory=$data_dir $pg_opts'"

	if [ $? -eq 0 ]; then
		echo "command" "$command"
		echo "pidfile" "$pidfile"
	else
	    echo "Failed to start $name"
		echo "Check the log for a possible explanation of the above error:"
		echo "    $logfile"
		return 1
	fi
}


setup() {
	local bkpdir

	echo "Creating a new $name database cluster"

	if [ -d "$data_dir/base" ]; then
		echo 1 "$data_dir/base already exists!"; return 1
	fi

	if [ "$pg_version" -ge 15 ]; then
		initdb_opts="-E UTF-8 --locale-provider=icu --icu-locale=en-001-x-icu --data-checksums"
	else
		initdb_opts="-E UTF-8 --locale=C --data-checksums"
	fi

	# If data_dir exists, backup configs.
	if [ -d "$data_dir" ]; then
		bkpdir="$(mktemp -d)"
		find "$data_dir" -type f -name "*.conf" -maxdepth 1 \
			-exec mv -v {} "$bkpdir"/ \;
		rm -rf "$data_dir"/*
	fi

	install -d -m 0700 -o $user -g $group "$data_dir"
	install -d -m 0750 -o $user -g $group "$conf_dir"

	cd "$data_dir"  # to avoid the: could not change directory to "/root"
	su $user -c "/usr/bin/initdb $initdb_opts --pgdata $data_dir"
	local retval=$?

	if [ -d "$bkpdir" ]; then
		# Move backuped configs back.
		mv -v "$bkpdir"/* "$data_dir"/
		rm -rf "$bkpdir"
	fi

	local conf_dir=$(readlink -f "$conf_dir")

	if [ "${data_dir%/}" != "${conf_dir%/}" ]; then
		# Move configs from data_dir to conf_dir and symlink them to data_dir.
		local name newname
		for name in postgresql.conf pg_hba.conf pg_ident.conf; do
			newname="$name"
			[ ! -e "$conf_dir"/$name ] || newname="$name.new"

			mv "$data_dir"/$name "$conf_dir"/$newname
			ln -s "$conf_dir"/$name "$data_dir"/$name
		done
	fi

	return $retval
} 

get_config() {
	local name="$1"
	local default="${2:-}"

	if [ ! -f "$conffile" ]; then
		printf '%s\n' "$default"
		return 1
	fi
	sed -En "/^\s*${name}\b/{                      # find line starting with the name
		  s/^\s*${name}\s*=?\s*([^#]+).*/\1/;  # capture the value
		  s/\s*$//;                            # trim trailing whitespaces
		  s/^['\"](.*)['\"]$/\1/;              # remove delimiting quotes
		  p
		}" "$conffile" \
		| grep . || printf '%s\n' "$default"
}

psql_command() {
	su $user -c "psql --no-psqlrc --no-align --tuples-only -q -c \"$1\""
}

# postgres
start_pre

POSTGRES_CONFIG_PATH="/etc/postgresql$pg_version"
POSTGRES_DATABASE_CONFIG_PATH="${POSTGRES_CONFIG_PATH}/postgresql.conf"
POSTGRES_HBA_CONFIG_PATH="${POSTGRES_CONFIG_PATH}/pg_hba.conf"

# openssl rand -base64 33
if [ -z "${POSTGRES_ROOT_PASSWORD}" ]; then {
    POSTGRES_ROOT_PASSWORD=$(openssl rand -base64 33)
    echo " Generate Random postgres root password:${POSTGRES_ROOT_PASSWORD}"
}
fi

# Modifying configuration file postgresql.conf
# https://wiki.alpinelinux.org/wiki/Postgresql
# https://wiki.alpinelinux.org/wiki/Postgresql_16
if [ "${POSTGRES_DISALLOW_USER_LOGIN_REMOTELY}" -eq 0 ]; then {
	sed -i "s|\#*listen_addresses\s*=\s*'localhost'|listen_addresses = '*'|g" ${POSTGRES_DATABASE_CONFIG_PATH}
}
fi

if [ "${POSTGRES_PORT}" -gt 0 ]; then {
	sed -i "s|\#*port\s*=\s*[0-9]+|port = ${POSTGRES_PORT}|g" ${POSTGRES_DATABASE_CONFIG_PATH}
}
fi

if [ -n "${POSTGRES_HOST_AUTH_METHOD}" ] && [ "${POSTGRES_HOST_AUTH_METHOD}" != "trust" ] ; then {
	sed -i "s|\#*password_encryption\s*=\s*scram-sha-256\|md5\|password|password_encryption = ${POSTGRES_HOST_AUTH_METHOD}|g" ${POSTGRES_DATABASE_CONFIG_PATH}
}
fi

if [ "${POSTGRES_MAX_CONNECTIONS}" -gt 0 ]; then {
	sed -i "s|\#*max_connections\s*=\s*[0-9]+|max_connections = ${POSTGRES_MAX_CONNECTIONS}|g" ${POSTGRES_DATABASE_CONFIG_PATH}
}
fi

# Modifying configuration file pg_hba.conf
# https://wiki.alpinelinux.org/wiki/Postgresql_16
if [ "${POSTGRES_DISALLOW_USER_LOGIN_REMOTELY}" -eq 0 ]; then {
	sed -i "/^host  all  all 0.0.0.0/0 ${POSTGRES_HOST_AUTH_METHOD}/d" "${POSTGRES_HBA_CONFIG_PATH}"
	echo "host  all  all 0.0.0.0/0 ${POSTGRES_HOST_AUTH_METHOD}" >> "${POSTGRES_HBA_CONFIG_PATH}"
}
fi

# postgres
start

# exec commands
if [ -n "$*" ]; then
    sh -c "$*"
fi

# keep the docker container running
# https://github.com/docker/compose/issues/1926#issuecomment-422351028
if [ "${KEEPALIVE}" -eq 1 ]; then
    trap : TERM INT
    tail -f /dev/null & wait
    # sleep infinity & wait
fi