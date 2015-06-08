#!/bin/bash
set -o xtrace

DIR="/root/bhgame"

for i in {1..8}
do
	sed -i /\<default_agent\>/a\<autofix_server_info\>1\<\/autofix_server_info\> $DIR/bh_310$i/server/server_group.xml
	sed -i /\<pwaccsrv\>/a\<local_auth_relax\>true\<\/local_auth_relax\> $DIR/bh_310$i/server/pwaccsrv.xml
	sed -i /\<mode\>/s/0/1/ $DIR/bh_310$i/server/server_0.xml

done
