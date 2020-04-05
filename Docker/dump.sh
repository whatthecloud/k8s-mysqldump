#!/bin/bash

DB_USER=${DB_USER:-${MYSQL_ENV_DB_USER}}
DB_PASS=${DB_PASS:-${MYSQL_ENV_DB_PASS}}
DB_NAME=${DB_NAME:-${MYSQL_ENV_DB_NAME}}
DB_HOST=${DB_HOST:-${MYSQL_ENV_DB_HOST}}
DB_PORT=${DB_PORT:-${MYSQL_ENV_DB_PORT}}
CIPHER_ALGORITHM=${CIPHER_ALGORITHM}
CIPHER_PASSWORD=${CIPHER_PASSWORD}
OUTPUT_PATH=${OUTPUT_PATH}
TIME_ZONE=${TIME_ZONE}
ALL_DATABASES=${ALL_DATABASES}
IGNORE_DATABASE=${IGNORE_DATABASE}

output_command() {
  local timestamp="\`date +%Y%m%d%H%M\`"
  local output_file="$DATABASE_NAME-$timestamp.dump"
  local default_output_path="/dump"
  OUTPUT_PATH=${OUTPUT_PATH:-$default_output_path}
  OUTPUT_FILE="${OUTPUT_PATH}/$output_file"
  cat - > ${OUTPUT_FILE}
}

cipher_command() {
  if [[ -n "$CIPHER_ALGORITHM" ]]; then
    if [[ -z "$CIPHER_PASSWORD" ]]; then
      echo "The value of CIPHER_PASSWORD must be set if enc"
      exit
    fi
    openssl $CIPHER_ALGORITHM -k $CIPHER_PASSWORD
  fi
}

build_output() {
	if [[ -z "$CIPHER_ALGORITHM" ]]; then
		db_dump | cipher_command | output_command
	else
		db_dump | output_command

}

if [[ -z "$DB_USER" ]]; then
	echo "Missing DB_USER env variable"
	exit 1
fi
if [[ -z "$DB_PASS" ]]; then
	echo "Missing DB_PASS env variable"
	exit 1
fi
if [[ -z "$DB_HOST" ]]; then
	echo "Missing DB_HOST env variable"
	exit 1
fi
if [[ -z "$ALL_DATABASES" ]]; then
	if [[ -z "$DB_NAME" ]]; then
		echo "Missing DB_NAME env variable"
		exit 1
	fi
	if [[ -z "$DB_PORT" ]]; then
		db_dump() { "mysqldump --user=${DB_USER} --password=${DB_PASS} --host=${DB_HOST} $@ ${DB_NAME}" }

	else
		db_dump() { "mysqldump --user=${DB_USER} --password=${DB_PASS} --host=${DB_HOST} --port=${DB_PORT} $@ ${DB_NAME}" }
	fi
	build_output
else
	databases=`mysql --user="${DB_USER}" --password="${DB_PASS}" --host="${DB_HOST}" -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`
for db in $databases; do
    if [[ "$db" != "information_schema" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != "mysql" ]] && [[ "$db" != _* ]] && [[ ",$IGNORE_DATABASE," =~ ",$db," ]]; then
        echo "Dumping database: $db"
		if [[ -z "$DB_PORT" ]]; then
        	db_dump() { "mysqldump --user=${DB_USER} --password=${DB_PASS} --host=${DB_HOST} --databases $db" }
		else
			db_dump() { "mysqldump --user=${DB_USER} --password=${DB_PASS} --host=${DB_HOST} --port=${DB_PORT} --databases $db" }
		fi
		build_output
    fi
done
fi