#!/bin/sh

if [ ! -d "stf" ]; then
    git clone git://github.com/stf-storage/stf.git stf
fi

if [ ! -f dotcloud.yml ]; then
    cat <<EOM > dotcloud.yml
dispatcher101:
    approot: dispatcher
    type: perl
    requirements:
        - TheSchwartz
    environment:
        DEPLOY_HOME: /home/dotcloud/current
        STF_DEBUG: 1
        STF_HOST_ID: 101
        STF_QUEUE_TYPE: TheSchwartz
        STF_NGINX_STYLE_REPROXY: 1
storage101:
    approot: storage
    type: perl
    environment:
        DEPLOY_HOME: /home/dotcloud/current
        STF_DEBUG: 1
        STF_BACKEND_ROOT: /home/dotcloud/stf
admin101:
    approot: admin
    type: perl
    environment:
        DEPLOY_HOME: /home/dotcloud/current
worker101:
    approot: worker
    type: perl-worker
    requirements:
        - TheSchwartz
    environment:
        DEPLOY_HOME: /home/dotcloud/current
        STF_QUEUE_TYPE: TheSchwartz
        STF_DEBUG: 1
db:
    type: mysql
EOM
fi

rsync -a stf/ dispatcher/
rsync -a stf/ admin/
rsync -a stf/ storage/
rsync -a stf/ worker/

[ -f dispatcher/app.psgi ] && rm dispatcher/app.psgi
[ -f storage/app.psgi ] && rm storage/app.psgi
[ -f admin/app.psgi ] && rm admin/app.psgi

ln -s etc/dispatcher.psgi dispatcher/app.psgi
ln -s etc/storage.psgi storage/app.psgi
ln -s etc/admin.psgi admin/app.psgi

if [ ! -f "dispatcher/nginx.conf" ]; then
    cat <<'EOM' > "dispatcher/nginx.conf"
location = /reproxy {
    resolver 64.27.57.11;
    internal;
    set $reproxy $upstream_http_x_reproxy_url;
    proxy_pass $reproxy;
    proxy_hide_header Content-Type;
}
EOM
fi

if [ ! -f "worker/supervisord.conf" ]; then
    cat <<EOM > worker/supervisord.conf
[program:stf-worker]
command = perl /home/dotcloud/current/bin/stf-worker
stderr_logfile = /var/log/supervisor/stf-worker.error.log
stdout_logfile = /var/log/supervisor/stf-worker.log
EOM
fi