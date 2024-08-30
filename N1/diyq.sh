#!/bin/bash

rm -rf feeds/packages/net/v2ray-geodata
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata
git clone --depth=1 https://github.com/ophub/luci-app-amlogic package/amlogic
git clone https://github.com/morytyann/OpenWrt-mihomo package/luci-app-mihomo
git clone https://github.com/asvow/luci-app-tailscale package/luci-app-tailscale
# 插件
echo "
CONFIG_PACKAGE_luci-app-mosdns=y
CONFIG_PACKAGE_luci-app-mihomo=y
CONFIG_PACKAGE_luci-app-tailscale=y
CONFIG_PACKAGE_luci-luci-app-amlogic=y
" >> .config
# Default IP
sed -i 's/192.168.1.1/192.168.3.2/g' package/base-files/files/bin/config_generate

# Remove packages
rm -rf feeds/luci/applications/luci-app-passwall

# Add packages
git clone https://github.com/nantayo/My-Pkg package/my-pkg

