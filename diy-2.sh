#!/bin/bash

# 1. 添加必要包
git clone --depth=1 https://github.com/ophub/luci-app-amlogic package/luci-app-amlogic

# 2. 修复依赖问题
sed -i 's/LUCI_DEPENDS:=+tailscale +ip +luci-base/LUCI_DEPENDS:=+tailscale +ip-full +luci-base/g' feeds/luci/applications/luci-app-tailscale-community/Makefile
sed -i 's/+ip +libminiupnpc/+ip-full +libminiupnpc/g' feeds/packages/net/zerotier/Makefile

# 3. 设置默认密码为 password (SHA-512)
mkdir -p package/base-files/files/etc
sed -i 's/root:::0:99999:7:::/root:$6$V4UetPzk$CYXluq4wUazHjmCDBCq61.nEcKAIShF2CWbNgWDA89LNT1O2oh06k5Oq\/t4Xm.zE4Uu8H69Wsmk3W11504i0:19800:0:99999:7:::/g' package/base-files/files/etc/shadow 2>/dev/null || true

# 4. 内核漏洞规避: 强制禁用 MPTCP
mkdir -p package/base-files/files/etc/sysctl.d
cat << 'EOF' > package/base-files/files/etc/sysctl.d/11-mptcp-disable.conf
net.mptcp.enabled = 0
EOF

# 5. 创建开箱即用初始化配置脚本 (首次开机自动执行并永久固化)
mkdir -p package/base-files/files/etc/uci-defaults
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-custom-bypass-init
#!/bin/sh

# ================= 1. 默认密码兜底 =================
echo "root:password" | chpasswd -c SHA512 2>/dev/null || true

# ================= 2. 旁路由基础网络 =================
uci set network.lan.ipaddr='192.168.3.2'
uci set network.lan.netmask='255.255.255.0'
uci set network.lan.gateway='192.168.3.1'
uci set network.lan.dns='192.168.3.1 223.5.5.5'
# 禁用旁路由分配 IPv6 前缀，防止与主路由抢占
uci delete network.lan.ip6assign 2>/dev/null

# ================= 3. 彻底禁用旁路由 DHCP 与 IPv6 广播 =================
uci set dhcp.lan.ignore='1'
uci set dhcp.lan.dhcpv4='disabled'
uci set dhcp.lan.dhcpv6='disabled'
uci set dhcp.lan.ra='disabled'
uci set dhcp.odhcpd.maindhcp='0'

# ================= 4. 防火墙配置 (彻底修复断网与假死) =================
# 开启 LAN 动态伪装与 MTU 修复 (单臂旁路网关必须，防止非对称路由断网)
uci set firewall.@zone[0].masq='1'
uci set firewall.@zone[0].mtu_fix='1'
uci set firewall.@zone[0].input='ACCEPT'
uci set firewall.@zone[0].output='ACCEPT'
uci set firewall.@zone[0].forward='ACCEPT'

# 彻底关闭流量卸载与 Fullcone (防止与 TUN 虚拟网卡冲突)
uci set firewall.@defaults[0].flow_offloading='0'
uci set firewall.@defaults[0].flow_offloading_hw='0'
uci set firewall.@defaults[0].fullcone='0'

# 【核心安全加固】拦截公网 IPv6 对管理与代理端口的主动访问，严防公网裸奔
uci add firewall rule
uci set firewall.@rule[-1].name='Block-Public-IPv6-Services'
uci set firewall.@rule[-1].src='lan'
uci set firewall.@rule[-1].family='ipv6'
uci set firewall.@rule[-1].proto='tcp'
uci add_list firewall.@rule[-1].dest_port='22'
uci add_list firewall.@rule[-1].dest_port='80'
uci add_list firewall.@rule[-1].dest_port='445'
uci add_list firewall.@rule[-1].dest_port='139'
uci add_list firewall.@rule[-1].dest_port='7681'
uci add_list firewall.@rule[-1].dest_port='7890'
uci add_list firewall.@rule[-1].dest_port='7891'
uci add_list firewall.@rule[-1].dest_port='7892'
uci add_list firewall.@rule[-1].dest_port='8080'
uci add_list firewall.@rule[-1].dest_port='9090'
uci set firewall.@rule[-1].target='DROP'

# ================= 5. Docker 与 Tailscale 兼容 =================
# 禁止 Docker 调用旧版 iptables，转由 fw4 原生接管
uci set dockerd.globals.iptables='0' 2>/dev/null
# 禁止 Tailscale 注入冲突的 mangle 规则
uci set tailscale.settings.fw_mode='off' 2>/dev/null

# ================= 6. Nikki (Mihomo) 零冲突精准适配 =================
# 默认保持关闭，避免首次启动无订阅导致核心无限报错死循环
uci set nikki.config.enabled='0' 2>/dev/null
uci set nikki.config.start_delay='5' 2>/dev/null
# 开启大陆白名单直连 (减轻旁路由负担并防止回环)
uci set nikki.proxy.bypass_china_mainland_ip='1' 2>/dev/null
# 旁路由无 IPv6 网关，禁用 IPv6 劫持与代理防环路
uci set nikki.proxy.ipv6_dns_hijack='0' 2>/dev/null
uci set nikki.proxy.ipv6_proxy='0' 2>/dev/null
uci set nikki.mixin.ipv6='0' 2>/dev/null

# ================= 7. NTP 时间同步 (解决 N1 无 RTC 电池导致证书握手失败) =================
uci set system.@system[0].zonename='Asia/Shanghai'
uci set system.@system[0].timezone='CST-8'
uci delete system.ntp.server 2>/dev/null
uci add_list system.ntp.server='ntp.aliyun.com'
uci add_list system.ntp.server='time1.cloud.tencent.com'
uci add_list system.ntp.server='cn.pool.ntp.org'

# 提交生效
uci commit

exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/99-custom-bypass-init
