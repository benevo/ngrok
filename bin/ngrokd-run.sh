#!/bin/bash

basepath=$(cd `dirname $0`; pwd)
cd ${basepath}

./ngrokd -tlsKey=./ca/server.key -tlsCrt=./ca/server.crt -domain="benevo.cc" -httpAddr=":80" -httpsAddr=":443"
