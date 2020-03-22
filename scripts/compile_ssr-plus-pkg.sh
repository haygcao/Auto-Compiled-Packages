#!/bin/bash
# [CTCGFW]Project-OpenWrt
# Use it under GPLv3, please.
# --------------------------------------------------------
# Auto-Compile: LUCI-APP-SSR-PLUS PKG ONLY

ulimit -c unlimited

current_dir="$(pwd)"


# Compile Check
sudo -E apt-get -qq update
sudo -E apt-get -qq install curl subversion
current_commit="$(cat "scripts/current_commit")"
cloud_commit="$(curl -sL "https://github.com/coolsnowwolf/lede/commits/master/package/lean/luci-app-ssr-plus" |tr -d "\n" | grep -Eo "commit\/[0-9a-z]+" | sed -n "1p" | sed "s#commit/##g")"
[ "${current_commit}" == "${cloud_commit}" ] && { echo -e "Commit is up-to-date."; exit 0; }


# Init Build Dependencies
svn co "https://github.com/coolsnowwolf/luci/trunk/modules/luci-base/src" "po2lmo"
pushd "po2lmo"
make "po2lmo"
popd


# Init Build Source
svn co "https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-ssr-plus" "luci-app-ssr-plus_src"
mkdir -p "luci-app-ssr-plus/CONTROL" "luci-app-ssr-plus/etc" "luci-app-ssr-plus/usr/lib/lua/luci/i18n"

cat <<-EOF > "luci-app-ssr-plus/CONTROL/conffiles"
/etc/china_ssr.txt
/etc/config/shadowsocksr
/etc/config/white.list
/etc/config/black.list
/etc/config/netflix.list
/etc/dnsmasq.ssr/ad.conf
/etc/dnsmasq.ssr/gfw_list.conf
EOF

pkg_version="$(curl -sL "https://raw.githubusercontent.com/coolsnowwolf/lede/master/package/lean/luci-app-ssr-plus/Makefile" | grep "PKG_VERSION" | awk -F '=' '{print $2}')"
pkg_release="$(curl -sL "https://raw.githubusercontent.com/coolsnowwolf/lede/master/package/lean/luci-app-ssr-plus/Makefile" | grep "PKG_RELEASE" | awk -F '=' '{print $2}')"

cat <<-EOF > "luci-app-ssr-plus/CONTROL/control"
Architecture: all
Depends: libc, shadowsocksr-libev-alt, ipset, ip-full, iptables-mod-tproxy, dnsmasq-full, coreutils, coreutils-base64, pdnsd-alt, wget, lua, libuci-lua, microsocks, ipt2socks, dns2socks, shadowsocks-libev-ss-local, shadowsocksr-libev-ssr-local, shadowsocks-libev-ss-redir, simple-obfs, proxychains-ng, tcpping, v2ray-plugin, v2ray, trojan, redsocks2, kcptun-client, shadowsocksr-libev-server
Description:  SS/SSR/V2Ray/Trojan LuCI interface
Maintainer: lean <coolsnowwolf@gmail.com>
Package: luci-app-ssr-plus
Priority: optional
Section: base
Source: https://github.com/coolsnowwolf/lede/tree/master/package/lean/luci-app-ssr-plus
SourceName: luci-app-ssr-plus
Version: ${pkg_version}-${pkg_release}
EOF

cat <<-EOF > "luci-app-ssr-plus/CONTROL/postinst"
#!/bin/sh
if [ -z "${IPKG_INSTROOT}" ]; then
	( . /etc/uci-defaults/luci-ssr-plus ) && rm -f /etc/uci-defaults/luci-ssr-plus
	rm -f /tmp/luci-indexcache
	/etc/init.d/shadowsocksr enable >/dev/null 2>&1
fi
exit 0
EOF
chmod 0755 "luci-app-ssr-plus/CONTROL/postinst"

cat <<-EOF > "luci-app-ssr-plus/CONTROL/postrm"
#!/bin/sh
rm -rf /etc/china_ssr.txt /etc/dnsmasq.ssr /etc/dnsmasq.oversea /etc/config/shadowsocksr /etc/config/black.list /etc/config/gfw.list /etc/config/white.list >/dev/null 2>&1
exit 0
EOF
chmod 0755 "luci-app-ssr-plus/CONTROL/postrm"

cat <<-EOF > "luci-app-ssr-plus/CONTROL/prerm"
#!/bin/sh
if [ -z "${IPKG_INSTROOT}" ]; then
	/etc/init.d/shadowsocksr disable
	/etc/init.d/shadowsocksr stop
fi
exit 0
EOF
chmod 0755 "luci-app-ssr-plus/CONTROL/prerm"

cp -fpR luci-app-ssr-plus_src/luasrc/* luci-app-ssr-plus/usr/lib/lua/luci/
cp -fpR luci-app-ssr-plus_src/root/etc/* luci-app-ssr-plus/etc/
cp -fpR luci-app-ssr-plus_src/root/usr/* luci-app-ssr-plus/usr/
po2lmo/po2lmo "luci-app-ssr-plus_src/po/zh-cn/ssr-plus.po" "luci-app-ssr-plus/usr/lib/lua/luci/i18n/ssr-plus.zh-cn.lmo"

# Compile Package
git rm -f luci-app-ssr-plus_*_all.ipk
sh <(curl -sL "https://raw.githubusercontent.com/openwrt/openwrt/master/scripts/ipkg-build") -o "root" -g "root" "${current_dir}/luci-app-ssr-plus" "${current_dir}" || { echo -e "Failed to compile package."; exit 1; }

mkdir -p "scripts"
echo -e "${cloud_commit}" > "scripts/current_commit"

# Push Files
git config user.name CN_SZTL
git config user.email cnsztl@project-openwrt.eu.org
git add "scripts" luci-app-ssr-plus_*_all.ipk
git commit -m "Compile commit: coolsnowwolf/lede@${cloud_commit::6}"
git push
