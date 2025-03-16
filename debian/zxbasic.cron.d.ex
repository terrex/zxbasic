#
# Regular cron jobs for the zxbasic package.
#
0 4	* * *	root	[ -x /usr/bin/zxbasic_maintenance ] && /usr/bin/zxbasic_maintenance
