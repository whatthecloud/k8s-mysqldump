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

output_gen() {
  TIMESTAMP="\`date +%Y%m%d%H%M\`"
  OUTPUT_FILE="$1-${TIMESTAMP}.dump"
  DEFAULT_OUTPUTPATH="/dump"
  OUTPUT_PATH=${OUTPUT_PATH:-$DEFAULT_OUTPUTPATH}
  OUTPUT_FULL="${OUTPUT_PATH}/${OUTPUT_FILE}"
  return "${OUTPUT_FULL}"
}

cipher_command() {
  if [[ -n "${CIPHER_ALGORITHM}" ]]; then
    if [[ -z "${CIPHER_PASSWORD}" ]]; then
      echo "The value of CIPHER_PASSWORD must be set if enc" >&2
      exit
    fi
    openssl ${CIPHER_ALGORITHM} -salt -pbkdf2 -k ${CIPHER_PASSWORD}
  fi
}

build_output() {
	OUTPUT_FULL=$(output_gen $1)
	if [[ -z "${CIPHER_ALGORITHM}" ]]; then
		db_dump | cat - > "${OUTPUT_FULL}"
		echo "Completed: Exported ${OUTPUT_FULL}" 2>&1
	else
		db_dump | cipher_command | cat - > "${OUTPUT_FULL}"
		echo "Completed: Exported ${OUTPUT_FULL}" 2>&1
	fi
}

if [[ -z "${DB_USER}" ]]; then
	echo "Missing DB_USER env variable" >&2
	exit 1
fi
if [[ -z "${DB_PASS}" ]]; then
	echo "Missing DB_PASS env variable" >&2
	exit 1
fi
if [[ -z "${DB_HOST}" ]]; then
	echo "Missing DB_HOST env variable" >&2
	exit 1
fi
if [[ -z "${ALL_DATABASES}" ]]; then
	if [[ -z "${DB_NAME}" ]]; then
		echo "Missing DB_NAME env variable" >&2
		exit 1
	fi
	if [[ -z "${DB_PORT}" ]]; then
		db_dump() {
			"mysqldump --user=${DB_USER} --password=${DB_PASS} --host=${DB_HOST} $@ ${DB_NAME}"
			}
		echo "Created DB_DUMP command for ${DB_NAME}" 2>&1
		echo "Calling build command" 2>&1
		build_output ${DB_NAME}
	else
		db_dump() {
			"mysqldump --user=${DB_USER} --password=${DB_PASS} --host=${DB_HOST} --port=${DB_PORT} $@ ${DB_NAME}"
			}
		echo "Created DB_DUMP command for ${DB_NAME}" 2>&1
		echo "Calling build command" 2>&1
		build_output ${DB_NAME}
	fi
else
	databases=`mysql --user="${DB_USER}" --password="${DB_PASS}" --host="${DB_HOST}" -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`
	for db in $databases; do
		if [[ "$db" != "information_schema" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != "mysql" ]] && [[ "$db" != _* ]] && [[ ",${IGNORE_DATABASE}," =~ ",$db," ]]; then
			echo "Dumping database: $db"
			if [[ -z "${DB_PORT}" ]]; then
				db_dump() {
					"mysqldump --user=${DB_USER} --password=${DB_PASS} --host=${DB_HOST} --databases $db" 
					}
				echo "Created DB_DUMP command for $db" 2>&1
			else
				db_dump() {
					"mysqldump --user=${DB_USER} --password=${DB_PASS} --host=${DB_HOST} --port=${DB_PORT} --databases $db"
					}
				echo "Created DB_DUMP command for $db" 2>&1
			fi
			echo "Calling build command" 2>&1
			build_output "$db"
		fi
	done
fi