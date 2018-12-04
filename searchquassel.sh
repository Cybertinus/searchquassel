#!/bin/bash

# The usage function to show when -h or --help is specified, or when an error situation is detected
function usage()
{
	echo "${0} - A tool to search the Quassel logs

Usage: ${0} -s SEARCHTERM [-b BUFFERNAME] [-i] [-p|-S] | -h
-s|--search: The phrase to look for in the Quassel logs
-b|--buffer: The name of the buffer to look in (optional)
-i|--insensitive: Search for the SEARCHTERM case insensitive
                  (optional, disabled by default)
-p|--postgresql: Force searching in PostgreSQL
-S|--sqlite: Force searching in SQLite
-h|--help: Show this help, then exit

When neither -p or -S is specified, the tool tries to detect what database you
are using automatically."
}

# Give an error when no arguments are given, because the searchterm is required
if [ "${#}" -eq 0 ] ; then
	echo 'No arguments given' 1>&2
	usage
	exit 1
fi

# Set some defaults for some optional arguments
insensitive='N'
force_psql='N'
force_sqlite='N'

# Parse the arguments, give an error when an option can't be parsed
options="$(getopt -o s:b:ipSh --long search:,buffer:,insensitive,postgresql,sqlite,help -- "${@}")"
if [ "${?}" -ne 0 ] ; then
	usage
	exit 2
fi
eval set -- "${options}"

# Loop through the specified arguments
while [ -n "${1}" ]; do
	case "${1}" in
		'-s'|'--search')
			searchterm="${2}"
			shift 2
			;;
		'-b'|'--buffer')
			# Add a '#' before the buffername if it isn't given yet
			if [ "${2:0:1}" != '#' ] ; then
				buffername="#${2}"
			else
				buffername="${2}"
			fi
			shift 2
			;;
		'-i'|'--insensitive')
			insensitive='Y'
			shift
			;;
		'-p'|'--postgresql')
			force_psql='Y'
			shift
			;;
		'-S'|'--sqlite')
			force_sqlite='Y'
			shift
			;;
		'-h'|'--help')
			usage
			exit 0
			;;
		--) 
			shift
			;;
		*)
			echo "Unknown argument ${1}" 1>&2
			usage
			exit 3
			;;
	esac
done

# If no searchterm is specified, show an error
if [ -z "${searchterm}" ] ; then
	echo 'No searchterm specified' 1>&2
	usage
	exit 4
fi
# If both PostgreSQL and SQLite are forced, show an error, we can only search in one DBMS
if [ "${force_psql}" = 'Y' -a "${force_sqlite}" = 'Y' ] ; then
	echo "You can't search in both databases at the same time, please pick only one" 1>&2
	usage
	exit 5
fi

# Build the actual query to send to the selected DBMS
query="SELECT bu.buffername || \
    ' - [' || \
    date_trunc('second', bl.time) || \
    '] <' || \
    split_part(s.sender, '!', 1) || \
    '> ' || \
    bl.message
FROM backlog AS bl
INNER JOIN buffer AS bu ON bl.bufferid = bu.bufferid
INNER JOIN sender AS s ON bl.senderid = s.senderid"
# Add the searchterm, case-insensitive if requested, case-sensitive by default
if [ "${insensitive}" = 'Y' ] ; then
	query="${query} WHERE UPPER(bl.message) LIKE UPPER('%${searchterm}%')"
else
	query="${query} WHERE bl.message LIKE '%${searchterm}%'"
fi

# Also add the buffername, if requested, search in all buffers by default
if [ -n "${buffername}" ] ; then
	query="${query} AND bu.buffername = '${buffername}'"
fi

# If no DBMS is forced, try to detect which DBMS is running on this machine
found_psql='N'
found_sqlite='N'
if [ "${force_psql}" = 'N' -a "${force_sqlite}" = 'N' ] ; then
	# Check if PostgreSQL is running
	ps aux | grep postmaster | grep -v grep >/dev/null 2>&1
	if [ "${?}" -eq 0 ] ; then
		# PostgreSQL is running
		found_psql='Y'
	fi
fi

# Fire the query at the correct DBMS
if [ "${force_psql}" = 'Y' -o "${found_psql}" = 'Y' ] ; then
	psql --tuples-only --command="${query}" quassel
else
	echo 'SQLite stuff, to be implemented, sorry'
fi
