# searchquassel
A Bash script used to search in the Quassel backlog

```
searchquassel.sh - A tool to search the Quassel logs

Usage: searchquassel.sh -s SEARCHTERM [-b BUFFERNAME] [-i] [-p|-S] | -h
-s|--search: The phrase to look for in the Quassel logs
-b|--buffer: The name of the buffer to look in (optional)
-i|--insensitive: Search for the SEARCHTERM case insensitive
                  (optional, disabled by default)
-p|--postgresql: Force searching in PostgreSQL
-S|--sqlite: Force searching in SQLite
-h|--help: Show this help, then exit

When neither -p or -S is specified, the tool tries to detect what database you
are using automatically.
```
