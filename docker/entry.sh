#!/bin/bash
# 
# Copyright 2018-2019 Josua Mayer <josua@solid-run.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 

# include shFlags library
. /shflags

# declare flags
DEFINE_integer 'uid' 1000 'User ID to run as' 'u'
DEFINE_integer 'gid' 100 'Group ID to run as' 'g'

# parse flags
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"

# handle drone.io
if [ "x$CI" = "xtrue" ]; then
	echo "CI environment detected, linkint workspace to $DRONE_WORKSPACE."
	cd /
	rmdir /work
	ln -sv $DRONE_WORKSPACE /work
	cd /work
fi

if [ "x${FLAGS_uid}" != "x0" ]; then
# drop privileges
	groupadd -g ${FLAGS_gid} build 2>/dev/null || true
	useradd -s /bin/bash -u ${FLAGS_uid} -g ${FLAGS_gid} -m build
	sudo -u build /usr/bin/env __FORCE__=yes /bin/bash /work/build.sh $@
	status=$?
else
	sudo -u root /usr/bin/env __FORCE__=yes /bin/bash /work/build.sh $@
	status=$?
fi

exit $status
