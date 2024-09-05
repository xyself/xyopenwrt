#!/bin/bash
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}
sed -i '/\/etc\/init\.d\/tailscale/d;/\/etc\/config\/tailscale/d;' feeds/packages/net/tailscale/Makefile
# rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/packages/net/v2ray-geodata
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata
git clone --depth=1 https://github.com/ophub/luci-app-amlogic package/amlogic
git clone https://github.com/morytyann/OpenWrt-mihomo package/luci-app-mihomo
git clone https://github.com/asvow/luci-app-tailscale package/luci-app-tailscale
#git clone https://github.com/linkease/istore package/istore/luci-app-store
git_sparse_clone master https://github.com/linkease/istore luci/luci-app-store
#定时限速
git clone https://github.com/sirpdboy/luci-app-eqosplus package/luci-app-eqosplus
git clone https://github.com/sirpdboy/luci-app-lucky package/lucky
git clone -b js https://github.com/sirpdboy/luci-theme-kucat package/luci-theme-kucat
#git clone https://github.com/sirpdboy/luci-app-advancedplus package/luci-app-advancedplus
#git clone https://github.com/destan19/OpenAppFilter package/OpenAppFilter
#git clone https://github.com/zzsj0928/luci-app-pushbot package/luci-app-pushbot
#git clone https://github.com/lucikap/luci-app-nettask package/luci-app-nettask
# 插件
echo "
CONFIG_PACKAGE_luci-theme-kucat=y
CONFIG_PACKAGE_luci-app-lucky=y
CONFIG_PACKAGE_luci-app-mosdns=y
CONFIG_PACKAGE_luci-app-mihomo=y
CONFIG_PACKAGE_luci-app-tailscale=y
CONFIG_PACKAGE_luci-app-amlogic=y
CONFIG_PACKAGE_luci-app-eqosplus=y
CONFIG_PACKAGE_luci-app-store=y
" >> .config
#CONFIG_PACKAGE_luci-app-advancedplus=y
#CONFIG_PACKAGE_luci-app-pushbot=y
#CONFIG_PACKAGE_luci-app-nettask=y
# Default IP
sed -i 's/192.168.1.1/192.168.3.2/g' package/base-files/files/bin/config_generate

# Remove packages


# Add packages
#git clone https://github.com/nantayo/My-Pkg package/my-pkg
