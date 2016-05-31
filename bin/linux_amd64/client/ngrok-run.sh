#!/bin/bash

basepath=$(cd `dirname $0`; pwd)
cd ${basepath}

./ngrok -config=ngrok.conf start-all
