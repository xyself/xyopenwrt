#!/bin/bash

# 1. 添加必要包
git clone --depth=1 https://github.com/ophub/luci-app-amlogic package/luci-app-amlogic

# 2. 修复依赖问题
sed -i 's/LUCI_DEPENDS:=+tailscale +ip +luci-base/LUCI_DEPENDS:=+tailscale +ip-full +luci-base/g' feeds/luci/applications/luci-app-tailscale-community/Makefile
sed -i 's/+ip +libminiupnpc/+ip-full +libminiupnpc/g' feeds/packages/net/zerotier/Makefile

# 3. 创建开箱即用初始化配置脚本 (首次开机自动执行并永久固化)
mkdir -p package/base-files/files/etc/uci-defaults
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-custom-bypass-init
#!/bin/sh

# ================= 1. 旁路由基础网络 =================
uci set network.lan.ipaddr='192.168.3.2'
uci set network.lan.netmask='255.255.255.0'
uci set network.lan.gateway='192.168.3.1'
uci set network.lan.dns='192.168.3.1'
# 禁用旁路由分配 IPv6 前缀，防止与主路由抢占
uci delete network.lan.ip6assign 2>/dev/null

# ================= 2. 彻底禁用旁路由 DHCP 与 IPv6 广播 =================
uci set dhcp.lan.ignore='1'
uci set dhcp.lan.dhcpv4='disabled'
uci set dhcp.lan.dhcpv6='disabled'
uci set dhcp.lan.ra='disabled'
uci set dhcp.odhcpd.maindhcp='0'

# ================= 3. 防火墙配置 (彻底修复断网与假死) =================
# 开启 LAN 动态伪装 (单臂旁路网关必须，防止非对称路由断网)
uci set firewall.@zone[0].masq='1'
uci set firewall.@zone[0].mtu_fix='1'
# 彻底关闭流量卸载与 Fullcone (防止与 TUN 虚拟网卡冲突)
uci set firewall.@defaults[0].flow_offloading='0'
uci set firewall.@defaults[0].flow_offloading_hw='0'
uci set firewall.@defaults[0].fullcone='0'

# ================= 4. 彻底消除旧版 iptables 冲突警告 =================
# 禁止 Docker 调用旧版 iptables，转由 fw4 原生接管
uci set dockerd.globals.iptables='0' 2>/dev/null
# 禁止 Tailscale 注入冲突的 mangle 规则
uci set tailscale.settings.fw_mode='off' 2>/dev/null

# ================= 5. Nikki (Mihomo) 旁路由开箱即用 =================
uci set nikki.config.enabled='1' 2>/dev/null
# 启用 TUN 模式并创建专用 nikki 接口
uci set nikki.proxy.tcp_mode='tun' 2>/dev/null
uci set nikki.proxy.udp_mode='tun' 2>/dev/null
uci set nikki.mixin.tun_enabled='1' 2>/dev/null
# 开启大陆白名单直连 (减轻旁路由负担并防止死循环)
uci set nikki.proxy.bypass_china_mainland_ip='1' 2>/dev/null
# 旁路由无 IPv6 网关，禁用 IPv6 劫持
uci set nikki.proxy.ipv6_dns_hijack='0' 2>/dev/null
uci set nikki.proxy.ipv6_proxy='0' 2>/dev/null
uci set nikki.mixin.dns_ipv6='0' 2>/dev/null

# 提交生效
uci commit

exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/99-custom-bypass-init
