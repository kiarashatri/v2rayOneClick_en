#!/bin/bash

red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'
_red() { echo -e ${red}$*${none}; }
_green() { echo -e ${green}$*${none}; }
_yellow() { echo -e ${yellow}$*${none}; }
_magenta() { echo -e ${magenta}$*${none}; }
_cyan() { echo -e ${cyan}$*${none}; }

# Root
[[ $(id -u) != 0 ]] && echo -e "\n oops...please use ${red}root ${none}user run ${yellow}~(^_^) ${none}\n" && exit 1

cmd="apt-get"

sys_bit=$(uname -m)

case $sys_bit in
# i[36]86)
# 	v2ray_bit="32"
# 	caddy_arch="386"
# 	;;
'amd64' | x86_64)
    v2ray_bit="64"
    caddy_arch="amd64"
    ;;
# *armv6*)
# 	v2ray_bit="arm32-v6"
# 	caddy_arch="arm6"
# 	;;
# *armv7*)
# 	v2ray_bit="arm32-v7a"
# 	caddy_arch="arm7"
# 	;;
*aarch64* | *armv8*)
    v2ray_bit="arm64-v8a"
    caddy_arch="arm64"
    ;;
*)
    echo -e " 
	haha...this个 ${red}spicy chicken script${none} Your system is not supported. ${yellow}(-_-) ${none}

	Note: only supports Ubuntu 16+ / Debian 8+ / CentOS 7+ system
	" && exit 1
    ;;
esac

# stupid detection method
if [[ $(command -v apt-get) || $(command -v yum) ]] && [[ $(command -v systemctl) ]]; then

    if [[ $(command -v yum) ]]; then

        cmd="yum"

    fi

else

    echo -e " 
	haha...this个 ${red}spicy chicken script${none} Your system is not supported. ${yellow}(-_-) ${none}

	Note: only supports Ubuntu 16+ / Debian 8+ / CentOS 7+ system
	" && exit 1

fi

uuid=$(cat /proc/sys/kernel/random/uuid)
old_id="e55c8d17-2cf3-b21a-bcf1-eeacb011ed79"
v2ray_server_config="/etc/v2ray/config.json"
v2ray_client_config="/etc/v2ray/233blog_v2ray_config.json"
backup="/etc/v2ray/233blog_v2ray_backup.conf"
_v2ray_sh="/usr/local/sbin/v2ray"
systemd=true
# _test=true

transport=(
    TCP
    TCP_HTTP
    WebSocket
    "WebSocket + TLS"
    HTTP/2
    mKCP
    mKCP_utp
    mKCP_srtp
    mKCP_wechat-video
    mKCP_dtls
    mKCP_wireguard
    QUIC
    QUIC_utp
    QUIC_srtp
    QUIC_wechat-video
    QUIC_dtls
    QUIC_wireguard
    TCP_dynamicPort
    TCP_HTTP_dynamicPort
    WebSocket_dynamicPort
    mKCP_dynamicPort
    mKCP_utp_dynamicPort
    mKCP_srtp_dynamicPort
    mKCP_wechat-video_dynamicPort
    mKCP_dtls_dynamicPort
    mKCP_wireguard_dynamicPort
    QUIC_dynamicPort
    QUIC_utp_dynamicPort
    QUIC_srtp_dynamicPort
    QUIC_wechat-video_dynamicPort
    QUIC_dtls_dynamicPort
    QUIC_wireguard_dynamicPort
    VLESS_WebSocket_TLS
)

ciphers=(
    aes-128-gcm
    aes-256-gcm
    chacha20-ietf-poly1305
)

_load() {
    local _dir="/etc/v2ray/233boy/v2ray/src/"
    . "${_dir}$@"
}
_sys_timezone() {
    IS_OPENVZ=
    if hostnamectl status | grep -q openvz; then
        IS_OPENVZ=1
    fi

    echo
    timedatectl set-timezone Asia/Shanghai
    timedatectl set-ntp true
    echo "Your host has been set to Asia/Shanghai timezone and automatically synced with systemd-timesyncd."
    echo

    if [[ $IS_OPENVZ ]]; then
        echo
        echo -e "your host environment is ${yellow}Openvz${none} ，It is recommended to use${yellow}v2ray mkcp${none}series of agreements."
        echo -e "Notice: ${yellow}Openvz${none} The system time cannot be controlled and synchronized by the program inside the virtual machine. "
        echo -e "If the host time is different from the actual time${yellow}more than 90 seconds${none}, v2ray will not be able to communicate normally, please send a ticket to contact the vps host company for adjustment."
    fi
}

_sys_time() {
    echo -e "\nHost time: ${yellow}"
    timedatectl status | sed -n '1p;4p'
    echo -e "${none}"
    [[ $IS_OPENV ]] && pause
}
v2ray_config() {
    # clear
    echo
    while :; do
        echo -e "please choose "$yellow"V2Ray"$none" Transfer Protocol [${magenta}1-${#transport[*]}$none]"
        echo
        for ((i = 1; i <= ${#transport[*]}; i++)); do
            Stream="${transport[$i - 1]}"
            if [[ "$i" -le 9 ]]; then
                # echo
                echo -e "$yellow  $i. $none${Stream}"
            else
                # echo
                echo -e "$yellow $i. $none${Stream}"
            fi
        done
        echo
        echo "Note 1: The dynamic port is enabled if it contains [dynamicPort].."
        echo "Note 2: [utp | srtp | wechat-video | dtls | wireguard] Disguised as [BT Download | Video Call | WeChat Video Call | DTLS 1.2 Packet | WireGuard Packet]"
        echo
        read -p "$(echo -e "(Default protocol: ${cyan}TCP$none)"):" v2ray_transport
        [ -z "$v2ray_transport" ] && v2ray_transport=1
        case $v2ray_transport in
        [1-9] | [1-2][0-9] | 3[0-3])
            echo
            echo
            echo -e "$yellow V2Ray Transfer Protocol = $cyan${transport[$v2ray_transport - 1]}$none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        *)
            error
            ;;
        esac
    done
    v2ray_port_config
}
v2ray_port_config() {
    case $v2ray_transport in
    4 | 5 | 33)
        tls_config
        ;;
    *)
        local random=$(shuf -i20001-65535 -n1)
        while :; do
            echo -e "Please enter "$yellow"V2Ray"$none" port ["$magenta"1-65535"$none"]"
            read -p "$(echo -e "(default port: ${cyan}${random}$none):")" v2ray_port
            [ -z "$v2ray_port" ] && v2ray_port=$random
            case $v2ray_port in
            [1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
                echo
                echo
                echo -e "$yellow V2Ray port = $cyan$v2ray_port$none"
                echo "----------------------------------------------------------------"
                echo
                break
                ;;
            *)
                error
                ;;
            esac
        done
        if [[ $v2ray_transport -ge 18 && $v2ray_transport -ne 33 ]]; then
            v2ray_dynamic_port_start
        fi
        ;;
    esac
}

v2ray_dynamic_port_start() {

    while :; do
        echo -e "Please enter "$yellow" V2Ray dynamic port start "$none" range ["$magenta"1-65535"$none"]"
        read -p "$(echo -e "(default start port: ${cyan}10000$none):")" v2ray_dynamic_port_start_input
        [ -z $v2ray_dynamic_port_start_input ] && v2ray_dynamic_port_start_input=10000
        case $v2ray_dynamic_port_start_input in
        $v2ray_port)
            echo
            echo "Can't be as bad as the V2Ray port...."
            echo
            echo -e "Current V2Ray port: ${cyan}$v2ray_port${none}"
            error
            ;;
        [1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
            echo
            echo
            echo -e "$yellow V2Ray dynamic port start = $cyan$v2ray_dynamic_port_start_input$none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        *)
            error
            ;;
        esac

    done

    if [[ $v2ray_dynamic_port_start_input -lt $v2ray_port ]]; then
        lt_v2ray_port=true
    fi

    v2ray_dynamic_port_end
}
v2ray_dynamic_port_end() {

    while :; do
        echo -e "Please enter "$yellow" V2Ray dynamic port end "$none" range ["$magenta"1-65535"$none"]"
        read -p "$(echo -e "(default end port: ${cyan}20000$none):")" v2ray_dynamic_port_end_input
        [ -z $v2ray_dynamic_port_end_input ] && v2ray_dynamic_port_end_input=20000
        case $v2ray_dynamic_port_end_input in
        [1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])

            if [[ $v2ray_dynamic_port_end_input -le $v2ray_dynamic_port_start_input ]]; then
                echo
                echo "Cannot be less than or equal to V2Ray dynamic port start range"
                echo
                echo -e " The current V2Ray dynamic port starts: ${cyan}$v2ray_dynamic_port_start_input${none}"
                error
            elif [ $lt_v2ray_port ] && [[ ${v2ray_dynamic_port_end_input} -ge $v2ray_port ]]; then
                echo
                echo "V2Ray dynamic port end range cannot include V2Ray ports..."
                echo
                echo -e " Current V2Ray ports: ${cyan}$v2ray_port${none}"
                error
            else
                echo
                echo
                echo -e "$yellow V2Ray dynamic port end = $cyan$v2ray_dynamic_port_end_input$none"
                echo "----------------------------------------------------------------"
                echo
                break
            fi
            ;;
        *)
            error
            ;;
        esac

    done

}

tls_config() {

    echo
    local random=$(shuf -i20001-65535 -n1)
    while :; do
        echo -e "Please enter "$yellow"V2Ray"$none" port ["$magenta"1-65535"$none"], cannot select "$magenta"80"$none" or "$magenta"443"$none" port"
        read -p "$(echo -e "(default port: ${cyan}${random}$none):")" v2ray_port
        [ -z "$v2ray_port" ] && v2ray_port=$random
        case $v2ray_port in
        80)
            echo
            echo " ...we said You can't choose port 80..."
            error
            ;;
        443)
            echo
            echo " ...we said You can't choose port 443..."
            error
            ;;
        [1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
            echo
            echo
            echo -e "$yellow V2Ray port = $cyan$v2ray_port$none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        *)
            error
            ;;
        esac
    done

    while :; do
        echo
        echo -e "Please enter a ${magenta}correct domain name${none}, it must be correct!"
        read -p "(eg: devbykia.space): " domain
        [ -z "$domain" ] && error && continue
        echo
        echo
        echo -e "$yellow your domain = $cyan$domain$none"
        echo "----------------------------------------------------------------"
        break
    done
    get_ip
    echo
    echo
    echo -e "$yellow please resolve $magenta$domain$none $yellow to: $cyan$ip$none"
    echo
    echo -e "$yellow please resolve $magenta$domain$none $yellow to: $cyan$ip$none"
    echo
    echo -e "$yellow please resolve $magenta$domain$none $yellow to: $cyan$ip$none"
    echo "----------------------------------------------------------------"
    echo

    while :; do

        read -p "$(echo -e "(whether it has been parsed correctly: [${magenta}Y$none]):") " record
        if [[ -z "$record" ]]; then
            error
        else
            if [[ "$record" == [Yy] ]]; then
                domain_check
                echo
                echo
                echo -e "$yellow domain name resolution = ${cyan} I'm sure $none has been resolved"
                echo "----------------------------------------------------------------"
                echo
                break
            else
                error
            fi
        fi

    done

    if [[ $v2ray_transport -eq 4 ]]; then
        auto_tls_config
    else
        caddy=true
        install_caddy_info="Open"
    fi

    if [[ $caddy ]]; then
        path_config_ask
    fi
}
auto_tls_config() {
    echo -e "

		Install Caddy to automatically configure TLS
		
		If you have Nginx or Caddy installed

		$yellow and.. you can configure TLS yourself $none

		then there is no need to turn on auto-config TLS
		"
    echo "----------------------------------------------------------------"
    echo

    while :; do

        read -p "$(echo -e "(whether TLS is automatically configured: [${magenta}Y/N$none]):") " auto_install_caddy
        if [[ -z "$auto_install_caddy" ]]; then
            error
        else
            if [[ "$auto_install_caddy" == [Yy] ]]; then
                caddy=true
                install_caddy_info="Open"
                echo
                echo
                echo -e "$yellow Automatic configuration TLS = $cyan$install_caddy_info$none"
                echo "----------------------------------------------------------------"
                echo
                break
            elif [[ "$auto_install_caddy" == [Nn] ]]; then
                install_caddy_info="closure"
                echo
                echo
                echo -e "$yellow Automatic configuration TLS = $cyan$install_caddy_info$none"
                echo "----------------------------------------------------------------"
                echo
                break
            else
                error
            fi
        fi

    done
}
path_config_ask() {
    echo
    while :; do
        echo -e "Whether to enable website masquerading and path diversion [${magenta}Y/N$none]"
        read -p "$(echo -e "(default: [${cyan}N$none]):")" path_ask
        [[ -z $path_ask ]] && path_ask="n"

        case $path_ask in
        Y | y)
            path_config
            break
            ;;
        N | n)
            echo
            echo
            echo -e "$yellow site masquerading and path splitting = $cyan doesn't want to configure $none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        *)
            error
            ;;
        esac
    done
}
path_config() {
    echo
    while :; do
        echo -e "Please enter the path you want ${magenta} to use to divert $none , such as /devbykia , then just enter devbykia ."
        read -p "$(echo -e "(default: [${cyan}devbykia$none]):")" path
        [[ -z $path ]] && path="devbykia"

        case $path in
        *[/$]*)
            echo
            echo -e "Because this script is too spicy.. so the diversion path cannot contain the two symbols $red / $none or $red $ $none..."
            echo
            error
            ;;
        *)
            echo
            echo
            echo -e "$yellow diversion path = ${cyan}/${path}$none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        esac
    done
    is_path=true
    proxy_site_config
}
proxy_site_config() {
    echo
    while :; do
        echo -e "Please enter ${magenta} a valid $none ${cyan} URL$none to use as a $none for the ${cyan} site, eg https://liyafly.com"
        echo -e "Example...your current domain name is $green$domain$none , the fake URL is https://liyafly.com"
        echo -e "Then when you open your domain... the content displayed is the content from https://liyafly.com"
        echo -e "Actually it's an anti-generation... Just understand..."
        echo -e "If you can't disguise successfully...you can use v2ray config to modify the disguised URL"
        read -p "$(echo -e "(default: [${cyan}https://liyafly.com$none]):")" proxy_site
        [[ -z $proxy_site ]] && proxy_site="https://liyafly.com"

        case $proxy_site in
        *[#$]*)
            echo
            echo -e "Because this script is too spicy.. so the fake URL cannot contain the symbols $red # $none or $red $ $none..."
            echo
            error
            ;;
        *)
            echo
            echo
            echo -e "$yellow 伪装的网址 = ${cyan}${proxy_site}$none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        esac
    done
}

blocked_hosts() {
    echo
    while :; do
        echo -e "Whether to enable ad blocking (affects performance) [${magenta}Y/N$none]"
        read -p "$(echo -e "(default [${cyan}N$none]):")" blocked_ad
        [[ -z $blocked_ad ]] && blocked_ad="n"

        case $blocked_ad in
        Y | y)
            blocked_ad_info="turn on"
            ban_ad=true
            echo
            echo
            echo -e "$yellow adblock = $cyan on $none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        N | n)
            blocked_ad_info="closure"
            echo
            echo
            echo -e "$yellow adblock = $cyan off $none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        *)
            error
            ;;
        esac
    done
}
shadowsocks_config() {

    echo

    while :; do
        echo -e "Whether to configure ${yellow}Shadowsocks${none} [${magenta}Y/N$none]"
        read -p "$(echo -e "(default [${cyan}N$none]):") " install_shadowsocks
        [[ -z "$install_shadowsocks" ]] && install_shadowsocks="n"
        if [[ "$install_shadowsocks" == [Yy] ]]; then
            echo
            shadowsocks=true
            shadowsocks_port_config
            break
        elif [[ "$install_shadowsocks" == [Nn] ]]; then
            break
        else
            error
        fi

    done

}

shadowsocks_port_config() {
    local random=$(shuf -i20001-65535 -n1)
    while :; do
        echo -e "Please enter "$yellow"Shadowsocks"$none" port ["$magenta"1-65535"$none"], cannot be the same as "$yellow"V2Ray"$none" port"
        read -p "$(echo -e "(default port: ${cyan}${random}$none):") " ssport
        [ -z "$ssport" ] && ssport=$random
        case $ssport in
        $v2ray_port)
            echo
            echo "Can't be the same as V2Ray port...."
            error
            ;;
        [1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
            if [[ $v2ray_transport == [45] ]]; then
                local tls=ture
            fi
            if [[ $tls && $ssport == "80" ]] || [[ $tls && $ssport == "443" ]]; then
                echo
                echo -e "Because you have selected "$green"WebSocket + TLS $none or $green HTTP/2"$none" transport."
                echo
                echo -e "so "$magenta"80"$none" or "$magenta"443"$none" ports cannot be selected"
                error
            elif [[ $v2ray_dynamic_port_start_input == $ssport || $v2ray_dynamic_port_end_input == $ssport ]]; then
                local multi_port="${v2ray_dynamic_port_start_input} - ${v2ray_dynamic_port_end_input}"
                echo
                echo "Sorry, this port conflicts with V2Ray dynamic port, the current V2Ray dynamic port range is: $multi_port"
                error
            elif [[ $v2ray_dynamic_port_start_input -lt $ssport && $ssport -le $v2ray_dynamic_port_end_input ]]; then
                local multi_port="${v2ray_dynamic_port_start_input} - ${v2ray_dynamic_port_end_input}"
                echo
                echo "Sorry, this port conflicts with V2Ray dynamic port, the current V2Ray dynamic port range is: $multi_port"
                error
            else
                echo
                echo
                echo -e "$yellow Shadowsocks port = $cyan$ssport$none"
                echo "----------------------------------------------------------------"
                echo
                break
            fi
            ;;
        *)
            error
            ;;
        esac

    done

    shadowsocks_password_config
}
shadowsocks_password_config() {

    while :; do
        echo -e "Please enter "$yellow"Shadowsocks"$none" password"
        read -p "$(echo -e "(default password: ${cyan}devbykia.space$none)"): " sspass
        [ -z "$sspass" ] && sspass="devbykia.space"
        case $sspass in
        *[/$]*)
            echo
            echo -e "Because this script is too spicy.. so the password cannot contain the two symbols $red / $none or $red $ $none..."
            echo
            error
            ;;
        *)
            echo
            echo
            echo -e "$yellow Shadowsocks password = $cyan$sspass$none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        esac

    done

    shadowsocks_ciphers_config
}
shadowsocks_ciphers_config() {

    while :; do
        echo -e "Please select "$yellow"Shadowsocks"$none" encryption protocol [${magenta}1-${#ciphers[*]}$none]"
        for ((i = 1; i <= ${#ciphers[*]}; i++)); do
            ciphers_show="${ciphers[$i - 1]}"
            echo
            echo -e "$yellow $i. $none${ciphers_show}"
        done
        echo
        read -p "$(echo -e "(default encryption protocol: ${cyan}${ciphers[1]}$none)"):" ssciphers_opt
        [ -z "$ssciphers_opt" ] && ssciphers_opt=2
        case $ssciphers_opt in
        [1-3])
            ssciphers=${ciphers[$ssciphers_opt - 1]}
            echo
            echo
            echo -e "$yellow Shadowsocks encryption protocol = $cyan${ssciphers}$none"
            echo "----------------------------------------------------------------"
            echo
            break
            ;;
        *)
            error
            ;;
        esac

    done
    pause
}

install_info() {
    clear
    echo
    echo ".... ready to install... see if the configuration is correct..."
    echo
    echo "---------- Installation Information -------------"
    echo
    echo -e "$yellow V2Ray Transfer Protocol = $cyan${transport[$v2ray_transport - 1]}$none"

    if [[ $v2ray_transport == [45] || $v2ray_transport == 33 ]]; then
        echo
        echo -e "$yellow V2Ray port = $cyan$v2ray_port$none"
        echo
        echo -e "$yellow your domain name = $cyan$domain$none"
        echo
        echo -e "$yellow DNS = ${cyan}I'm sure it's already parsed$none"
        echo
        echo -e "$yellow Automatic configuration TLS = $cyan$install_caddy_info$none"

        if [[ $ban_ad ]]; then
            echo
            echo -e "$yellow ad blocking = $cyan$blocked_ad_info$none"
        fi
        if [[ $is_path ]]; then
            echo
            echo -e "$yellow path diversion = ${cyan}/${path}$none"
        fi
    elif [[ $v2ray_transport -ge 18 && $v2ray_transport -ne 33 ]]; then
        echo
        echo -e "$yellow V2Ray port = $cyan$v2ray_port$none"
        echo
        echo -e "$yellow V2Ray dynamic port range = $cyan${v2ray_dynamic_port_start_input} - ${v2ray_dynamic_port_end_input}$none"

        if [[ $ban_ad ]]; then
            echo
            echo -e "$yellow ad blocking = $cyan$blocked_ad_info$none"
        fi
    else
        echo
        echo -e "$yellow V2Ray port = $cyan$v2ray_port$none"

        if [[ $ban_ad ]]; then
            echo
            echo -e "$yellow ad blocking = $cyan$blocked_ad_info$none"
        fi
    fi
    if [ $shadowsocks ]; then
        echo
        echo -e "$yellow Shadowsocks port = $cyan$ssport$none"
        echo
        echo -e "$yellow Shadowsocks password = $cyan$sspass$none"
        echo
        echo -e "$yellow Shadowsocks encryption protocol = $cyan${ssciphers}$none"
    else
        echo
        echo -e "$yellow Whether to configure Shadowsocks = ${cyan}Not configured${none}"
    fi
    echo
    echo "---------- END -------------"
    echo
    pause
    echo
}

domain_check() {
    # if [[ $cmd == "yum" ]]; then
    # 	yum install bind-utils -y
    # else
    # 	$cmd install dnsutils -y
    # fi
    # test_domain=$(dig $domain +short)
    # test_domain=$(ping $domain -c 1 -4 | grep -oE -m1 "([0-9]{1,3}\.){3}[0-9]{1,3}")
    # test_domain=$(wget -qO- --header='accept: application/dns-json' "https://cloudflare-dns.com/dns-query?name=$domain&type=A" | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" | head -1)
    test_domain=$(curl -sH 'accept: application/dns-json' "https://cloudflare-dns.com/dns-query?name=$domain&type=A" | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" | head -1)
    if [[ $test_domain != $ip ]]; then
        echo
        echo -e "$red detects a domain name resolution error....$none"
        echo
        echo -e " Your domain: $yellow$domain$none did not resolve to: $cyan$ip$none"
        echo
        echo -e " Your domain currently resolves to: $cyan$test_domain$none"
        echo
        echo "Note...if your domain is resolved with Cloudflare..click on the icon in Status..make it greyed out"
        echo
        exit 1
    fi
}

install_caddy() {
    # download caddy file then install
    _load download-caddy.sh
    _download_caddy_file
    _install_caddy_service
    caddy_config

}
caddy_config() {
    # local email=$(shuf -i1-10000000000 -n1)
    _load caddy-config.sh

    # systemctl restart caddy
    do_service restart caddy
}

install_v2ray() {
    $cmd update -y
    if [[ $cmd == "apt-get" ]]; then
        $cmd install -y lrzsz git zip unzip curl wget qrencode libcap2-bin dbus
    else
        # $cmd install -y lrzsz git zip unzip curl wget qrencode libcap iptables-services
        $cmd install -y lrzsz git zip unzip curl wget qrencode libcap
    fi
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    [ -d /etc/v2ray ] && rm -rf /etc/v2ray
    # date -s "$(curl -sI g.cn | grep Date | cut -d' ' -f3-6)Z"
    _sys_timezone
    _sys_time

    if [[ $local_install ]]; then
        if [[ ! -d $(pwd)/config ]]; then
            echo
            echo -e "$red oops...install failed...$none"
            echo
            echo -e "Please make sure you have the complete V2Ray one-click installation script & management script uploaded from 233v2.com to the current ${green}$(pwd) $none directory"
            echo
            exit 1
        fi
        mkdir -p /etc/v2ray/233boy/v2ray
        cp -rf $(pwd)/* /etc/v2ray/233boy/v2ray
    else
        pushd /tmp
        git clone https://github.com/233boy/v2ray -b "$_gitbranch" /etc/v2ray/233boy/v2ray --depth=1
        popd

    fi

    if [[ ! -d /etc/v2ray/233boy/v2ray ]]; then
        echo
        echo -e "$red Oops... Error cloning script repository...$none"
        echo
        echo -e " Reminder..... Please try to install it yourself Git: ${green}$cmd install -y git $none Install this script later"
        echo
        exit 1
    fi

    # download v2ray file then install
    _load download-v2ray.sh
    _download_v2ray_file
    _install_v2ray_service
    _mkdir_dir
}

config() {
    cp -f /etc/v2ray/233boy/v2ray/config/backup.conf $backup
    cp -f /etc/v2ray/233boy/v2ray/v2ray.sh $_v2ray_sh
    chmod +x $_v2ray_sh

    v2ray_id=$uuid
    alterId=0
    ban_bt=true
    if [[ $v2ray_transport -ge 18 && $v2ray_transport -ne 33 ]]; then
        v2ray_dynamicPort_start=${v2ray_dynamic_port_start_input}
        v2ray_dynamicPort_end=${v2ray_dynamic_port_end_input}
    fi
    _load config.sh

    # if [[ $cmd == "apt-get" ]]; then
    # 	cat >/etc/network/if-pre-up.d/iptables <<-EOF
    # 		#!/bin/sh
    # 		/sbin/iptables-restore < /etc/iptables.rules.v4
    # 		/sbin/ip6tables-restore < /etc/iptables.rules.v6
    # 	EOF
    # 	chmod +x /etc/network/if-pre-up.d/iptables
    # 	# else
    # 	# 	[ $(pgrep "firewall") ] && systemctl stop firewalld
    # 	# 	systemctl mask firewalld
    # 	# 	systemctl disable firewalld
    # 	# 	systemctl enable iptables
    # 	# 	systemctl enable ip6tables
    # 	# 	systemctl start iptables
    # 	# 	systemctl start ip6tables
    # fi

    # systemctl restart v2ray
    do_service restart v2ray
    backup_config

}

backup_config() {
    sed -i "18s/=1/=$v2ray_transport/; 21s/=2333/=$v2ray_port/; 24s/=$old_id/=$uuid/" $backup
    if [[ $v2ray_transport -ge 18 && $v2ray_transport -ne 33 ]]; then
        sed -i "30s/=10000/=$v2ray_dynamic_port_start_input/; 33s/=20000/=$v2ray_dynamic_port_end_input/" $backup
    fi
    if [[ $shadowsocks ]]; then
        sed -i "42s/=/=true/; 45s/=6666/=$ssport/; 48s/=233blog.com/=$sspass/; 51s/=chacha20-ietf/=$ssciphers/" $backup
    fi
    [[ $v2ray_transport == [45] || $v2ray_transport == 33 ]] && sed -i "36s/=233blog.com/=$domain/" $backup
    [[ $caddy ]] && sed -i "39s/=/=true/" $backup
    [[ $ban_ad ]] && sed -i "54s/=/=true/" $backup
    if [[ $is_path ]]; then
        sed -i "57s/=/=true/; 60s/=233blog/=$path/" $backup
        sed -i "63s#=https://liyafly.com#=$proxy_site#" $backup
    fi
}

get_ip() {
    ip=$(curl -s https://ipinfo.io/ip)
    [[ -z $ip ]] && ip=$(curl -s https://api.ip.sb/ip)
    [[ -z $ip ]] && ip=$(curl -s https://api.ipify.org)
    [[ -z $ip ]] && ip=$(curl -s https://ip.seeip.org)
    [[ -z $ip ]] && ip=$(curl -s https://ifconfig.co/ip)
    [[ -z $ip ]] && ip=$(curl -s https://api.myip.com | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
    [[ -z $ip ]] && ip=$(curl -s icanhazip.com)
    [[ -z $ip ]] && ip=$(curl -s myip.ipip.net | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
    [[ -z $ip ]] && echo -e "\n$red 这垃圾小鸡扔了吧！$none\n" && exit
}

error() {

    echo -e "\n$red 输入错误！$none\n"

}

pause() {

    read -rsp "$(echo -e "Press $green Enter $none to continue....or $red Ctrl + C $none to cancel.")" -d $'\n'
    echo
}
do_service() {
    if [[ $systemd ]]; then
        systemctl $1 $2
    else
        service $2 $1
    fi
}
show_config_info() {
    clear
    _load v2ray-info.sh
    _v2_args
    _v2_info
    _load ss-info.sh

}

install() {
    if [[ -f /usr/bin/v2ray/v2ray && -f /etc/v2ray/config.json ]] && [[ -f $backup && -d /etc/v2ray/233boy/v2ray ]]; then
        echo
        echo " Boss...you already installed V2Ray...no need to reinstall"
        echo
        echo -e " $yellow enter ${cyan}v2ray${none} $yellow ready to manage V2Ray${none}"
        echo
        exit 1
    elif [[ -f /usr/bin/v2ray/v2ray && -f /etc/v2ray/config.json ]] && [[ -f /etc/v2ray/233blog_v2ray_backup.txt && -d /etc/v2ray/233boy/v2ray ]]; then
        echo
        echo "  If you need to continue the installation.. please uninstall the old version first"
        echo
        echo -e " $yellow enter ${cyan}v2ray uninstall${none} $yellowto uninstall${none}"
        echo
        exit 1
    fi
    v2ray_config
    blocked_hosts
    shadowsocks_config
    install_info
    # [[ $caddy ]] && domain_check
    install_v2ray
    if [[ $caddy || $v2ray_port == "80" ]]; then
        if [[ $cmd == "yum" ]]; then
            [[ $(pgrep "httpd") ]] && systemctl stop httpd
            [[ $(command -v httpd) ]] && yum remove httpd -y
        else
            [[ $(pgrep "apache2") ]] && service apache2 stop
            [[ $(command -v apache2) ]] && apt-get remove apache2* -y
        fi
    fi
    [[ $caddy ]] && install_caddy

    ## bbr
    # _load bbr.sh
    # _try_enable_bbr

    get_ip
    config
    show_config_info
}
uninstall() {

    if [[ -f /usr/bin/v2ray/v2ray && -f /etc/v2ray/config.json ]] && [[ -f $backup && -d /etc/v2ray/233boy/v2ray ]]; then
        . $backup
        if [[ $mark ]]; then
            _load uninstall.sh
        else
            echo
            echo -e " $yellow输入 ${cyan}v2ray uninstall${none} $yellow to uninstall${none}"
            echo
        fi

    elif [[ -f /usr/bin/v2ray/v2ray && -f /etc/v2ray/config.json ]] && [[ -f /etc/v2ray/233blog_v2ray_backup.txt && -d /etc/v2ray/233boy/v2ray ]]; then
        echo
        echo -e " $yellow enter ${cyan}v2ray uninstall${none} $yellow to uninstall${none}"
        echo
    else
        echo -e "
		$red big tits...you seem to have V2Ray installed....uninstall a dick...$none

		Remarks...Only supports uninstalling and using the V2Ray one-click installation script provided by me (devbykia.space)
		" && exit 1
    fi

}

args=$1
_gitbranch=$2
[ -z $1 ] && args="online"
case $args in
online)
    #hello world
    [[ -z $_gitbranch ]] && _gitbranch="master"
    ;;
local)
    local_install=true
    ;;
*)
    echo
    echo -e " The parameter you entered <$red $args $none>...what the hell is this...the script doesn't recognize it"
    echo
    echo -e " This spicy chicken script only supports input $green local / online $none parameter"
    echo
    echo -e "Enter $yellow local $none to use local installation"
    echo
    echo -e " Type $yellow online $none to use online installation (default)"
    echo
    exit 1
    ;;
esac

clear
while :; do
    echo
    echo ".......... V2Ray One-Click Installation Script & Admin Script by devbykia.space ..........."
    echo
    echo
    echo " 1. Install"
    echo
    echo " 2. uninstall"
    echo
    echo
    echo
    if [[ $local_install ]]; then
        echo -e "$yellow Reminder.. Local installation is enabled ..$none"
        echo
    fi
    read -p "$(echo -e "please choose [${magenta}1-2$none]:")" choose
    case $choose in
    1)
        install
        break
        ;;
    2)
        uninstall
        break
        ;;
    *)
        error
        ;;
    esac
done
