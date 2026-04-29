#!/bin/bash

# 添加包
git clone --depth=1 https://github.com/ophub/luci-app-amlogic package/luci-app-amlogic
# 修改 luci-app-tailscale-community
sed -i 's/LUCI_DEPENDS:=+tailscale +ip +luci-base/LUCI_DEPENDS:=+tailscale +ip-full +luci-base/g' feeds/luci/applications/luci-app-tailscale-community/Makefile

# 修改 zerotier
sed -i 's/+ip +libminiupnpc/+ip-full +libminiupnpc/g' feeds/packages/net/zerotier/Makefile
