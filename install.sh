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
#    WSPATH=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)
    WSPATH="/v2ray"
    echo "生成随机WebSocket路径：${WSPATH}"
    
    cat >  ${SH_PATH}/IBMYes/test-cloudfoundry/manifest.yml  << EOF
    applications:
    - path: .
      name: ${IBM_APP_NAME}
      random-route: true
      memory: ${IBM_MEM_SIZE}M
EOF

    cat >  ${SH_PATH}/IBMYes/test-cloudfoundry/test/config.json  << EOF
    {
        "policy": null,
        "log": {
          "access": "",
          "error": "",
          "loglevel": "debug"
        },
        "inbounds": [
            {
                "port": 443,
                "protocol": "vmess",
                "settings": {
                    "connectionReuse": true,
                    "clients": [
                        {
                            "id": "${UUID}",
                            "alterId": 4
                        }
                    ]
                },
                "streamSettings": {
                    "network":"ws",
                    "wsSettings": {
                        "path": "${WSPATH}"
                    }
                }
            }
        ],
        "outbounds": null
    }
EOF
    echo "配置完成。"
}

clone_repo(){
    echo "进行初始化。。。"
	rm -rf IBMYes
    git clone https://github.com/hashiqi12138/IBMYes
    cd IBMYes
    git submodule update --init --recursive
    cd test-cloudfoundry/test

    echo "初始化完成。"
}

install(){
    echo "进行安装。。。"
    cd ${SH_PATH}/IBMYes/test-cloudfoundry
    ibmcloud target --cf
    echo "N"|ibmcloud cf install
    ibmcloud cf push
    echo "安装完成。"
    echo "生成的随机 UUID：${UUID}"
    echo "生成的随机 WebSocket路径：${WSPATH}"
    VMESSCODE=$(base64 -w 0 << EOF
    {
      "v": "2",
      "ps": "${IBM_APP_NAME}",
      "add": "${IBM_APP_NAME}.us-south.cf.appdomain.cloud",
      "port": "443",
      "id": "${UUID}",
      "aid": "4",
      "net": "ws",
      "type": "none",
      "host": "",
      "path": "${WSPATH}",
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