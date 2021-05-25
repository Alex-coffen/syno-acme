#!/bin/bash

# path of this script
BASE_ROOT=/volume2/homes/biao.zhong/Sync/alexzhong.top
BASE_NEW=/volume2/homes/biao.zhong/Sync/alexzhong.top/new
# date time
DATE_TIME=`date +%Y%m%d%H%M%S`

# base crt path
CRT_BASE_PATH="/usr/syno/etc/certificate"
PKG_CRT_BASE_PATH="/usr/local/etc/certificate"
CRT_PATH_NAME=`cat ${CRT_BASE_PATH}/_archive/DEFAULT`
CRT_PATH=${CRT_BASE_PATH}/_archive/${CRT_PATH_NAME}

backupCrt () {
  echo 'begin backupCrt'
  BACKUP_PATH=${BASE_ROOT}/backup/${DATE_TIME}
  mkdir -p ${BACKUP_PATH}
  cp -r ${CRT_BASE_PATH} ${BACKUP_PATH}
  cp -r ${PKG_CRT_BASE_PATH} ${BACKUP_PATH}/package_cert
  echo ${BACKUP_PATH} > ${BASE_ROOT}/backup/latest
  echo 'done backupCrt'
  return 0
}

generateCrt () {
  echo 'begin generateCrt'
  cp -rf ${BASE_NEW}/* ${CRT_PATH}

  if [ -s "${CRT_PATH}/cert.pem" ]; then
    echo 'done generateCrt'
    return 0
  else
    echo '[ERR] fail to generateCrt'
    echo "begin revert"
    revertCrt
    exit 1;
  fi
}

updateService () {
  echo 'begin updateService'
  echo 'cp cert path to des'
  /bin/python2 /root/syno-acme/crt_cp.py ${CRT_PATH_NAME}
  echo 'done updateService'
}

reloadWebService () {
  echo 'begin reloadWebService'
  echo 'reloading new cert...'
  /usr/syno/etc/rc.sysv/nginx.sh reload
  echo 'relading Apache 2.2'
  stop pkg-apache22
  start pkg-apache22
  reload pkg-apache22
  echo 'done reloadWebService'  
}

revertCrt () {
  echo 'begin revertCrt'
  BACKUP_PATH=${BASE_ROOT}/backup/$1
  if [ -z "$1" ]; then
    BACKUP_PATH=`cat ${BASE_ROOT}/backup/latest`
  fi
  if [ ! -d "${BACKUP_PATH}" ]; then
    echo "[ERR] backup path: ${BACKUP_PATH} not found."
    return 1
  fi
  echo "${BACKUP_PATH}/certificate ${CRT_BASE_PATH}"
  cp -rf ${BACKUP_PATH}/certificate/* ${CRT_BASE_PATH}
  echo "${BACKUP_PATH}/package_cert ${PKG_CRT_BASE_PATH}"
  cp -rf ${BACKUP_PATH}/package_cert/* ${PKG_CRT_BASE_PATH}
  reloadWebService
  echo 'done revertCrt'
}

updateCrt () {
  echo '------ begin updateCrt ------'
  backupCrt
  generateCrt
  updateService
  reloadWebService
  echo '------ end updateCrt ------'
}

case "$1" in
  update)
    echo "begin update cert"
    updateCrt
    ;;

  revert)
    echo "begin revert"
      revertCrt $2
      ;;
  backup)
      echo "begin backup cert"
	  backupCrt
	  ;;

    *)
        echo "Usage: $0 {update|revert}"
        exit 1
esac
