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

# create build user group
USER=root
if [ ${FLAGS_uid} -ne 0 ]; then
	USER=build
	useradd -s /bin/bash -u ${FLAGS_uid} -g ${FLAGS_gid} -m $USER
fi

# create build user
groupadd -g ${FLAGS_gid} build 2>/dev/null || true

# drop privileges
sudo -u $USER /bin/bash /main.sh $@

exit 0
