#!/bin/bash
SH_PATH=$(cd "$(dirname "$0")";pwd)
cd ${SH_PATH}


create_mainfest_file(){
    echo "进行配置。。。"
    read -p "请输入你的应用名称：" IBM_APP_NAME
    echo "应用名称：${IBM_APP_NAME}"
    read -p "请输入你的应用内存大小(默认256)：" IBM_MEM_SIZE
    if [ -z "${IBM_MEM_SIZE}" ];then
    IBM_MEM_SIZE=256
    fi
    echo "内存大小：${IBM_MEM_SIZE}"
    UUID=$(cat /proc/sys/kernel/random/uuid)
    echo "生成随机UUID：${UUID}"
    
    cat >  ${SH_PATH}/IBMYes/demo-cloudfoundry/manifest.yml  << EOF
    applications:
    - path: .
      name: ${IBM_APP_NAME}
      random-route: true
      memory: ${IBM_MEM_SIZE}M
EOF


    cat >  ${SH_PATH}/IBMYes/demo-cloudfoundry/demo/test  <  cat ${SH_PATH}/IBMYes/demo-cloudfoundry/template.json | base64
    echo "base64 str is "
    cat ${SH_PATH}/IBMYes/demo-cloudfoundry/demo/test
    echo "配置完成。"
}

clone_repo(){
    echo "进行初始化。。。"
	rm -rf IBMYes
    git clone https://github.com/hashiqi12138/IBMYes
    cd IBMYes
    git submodule update --init --recursive
    cd demo-cloudfoundry/demo

    echo "初始化完成。"
}

install(){
    echo "进行安装。。。"
    cd ${SH_PATH}/IBMYes/demo-cloudfoundry
    ibmcloud target --cf
    echo "N"|ibmcloud cf install
    ibmcloud cf push
    echo "安装完成。"
    echo "生成的随机 UUID：${UUID}"
#    echo "生成的随机 WebSocket路径：${WSPATH}"
    VMESSCODE=$(base64 -w 0 << EOF
    {
      "v": "2",
      "ps": "${IBM_APP_NAME}",
      "add": "${IBM_APP_NAME}.us-south.cf.appdomain.cloud",
      "port": "8080",
      "id": "${UUID}",
      "aid": "64",
      "net": "ws",
      "type": "none",
      "host": "",
      "path": "",
      "tls": "tls"
    }
EOF
    )
	echo "配置链接："
    echo vmess://${VMESSCODE}

}

clone_repo
create_mainfest_file
install
exit 0