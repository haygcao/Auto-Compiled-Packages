#!/bin/bash
# [CTCGFW]Project-OpenWrt
# Use it under GPLv3, please.
# --------------------------------------------------------
# Auto-Compile: LUCI-APP-SSR-PLUS

ulimit -c unlimited

curren_dir="$(pwd)"


# Compile Check
sudo -E apt-get -qq update
sudo -E apt-get -qq install curl
current_commit="$(curl -sL "https://raw.githubusercontent.com/project-openwrt/Auto-Compiled-Packages/ssr-plus/current_commit")"
cloud_commit="$(curl -sL "https://github.com/coolsnowwolf/lede/commits/master/package/lean/luci-app-ssr-plus" |tr -d "\n" | grep -Eo "commit\/[0-9a-z]+" | sed -n "1p" | sed "s#commit/##g")"
[ "${current_commit}" == "${cloud_commit}" ] && { echo -e "Commit is up-to-date."; exit 0; }


# Init Build Dependencies
sudo -E apt-get -qq update
sudo -E apt-get -qq install build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs git-core gcc g++ gcc-multilib g++-multilib p7zip-full msmtp libssl-dev texinfo libreadline-dev libglib2.0-dev xmlto qemu-utils upx libelf-dev elfutils autoconf automake libtool autopoint ccache curl wget python python3

svn co "https://github.com/coolsnowwolf/luci/trunk/modules/luci-base/src" "po2lmo"
pushd "po2lmo"
make "po2lmo"
sudo -E mv -f "po2lmo" "/usr/bin/po2lmo"
popd

upx_version="$(curl -s https://github.com/upx/upx/releases/latest/download | grep -Eo "[0-9]+.[0-9]+")"
curl -L "https://github.com/upx/upx/releases/download/v${upx_version}/upx-${upx_version}-amd64_linux.tar.xz" -o "upx-${upx_version}-amd64_linux.tar.xz"
tar -xf "upx-${upx_version}-amd64_linux.tar.xz" -C "./"
sudo -E rm -f "/usr/bin/upx" "/usr/bin/upx-ucl"
sudo -E mv "upx-${upx_version}-amd64_linux/upx" "/usr/bin/upx-ucl"
sudo -E chmod 0755 "/usr/bin/upx-ucl"
sudo -E ln -sf "/usr/bin/upx-ucl" "/usr/bin/upx"
rm -rf "upx-${upx_version}-amd64_linux.tar.xz" "upx-${upx_version}-amd64_linux"


# Init Build Source
curl -L "https://downloads.openwrt.org/releases/19.07.2/targets/x86/64/openwrt-sdk-19.07.2-x86-64_gcc-7.5.0_musl.Linux-x86_64.tar.xz" -o "openwrt-sdk-19.07.2-x86-64_gcc-7.5.0_musl.Linux-x86_64.tar.xz"
[ "$(sha256sum openwrt-sdk-19.07.2-x86-64_gcc-7.5.0_musl.Linux-x86_64.tar.xz | awk -F ' ' '{print $1}')" != "$(curl -sL https://downloads.openwrt.org/releases/19.07.2/targets/x86/64/sha256sums | grep openwrt-sdk-19.07.2-x86-64_gcc-7.5.0_musl.Linux-x86_64.tar.xz | awk -F ' ' '{print $1}')" ] && { echo -e "Failed to verify the SDK."; exit 1; }
tar -xf "openwrt-sdk-19.07.2-x86-64_gcc-7.5.0_musl.Linux-x86_64.tar.xz"
sudo chown -R runner:runner "openwrt-sdk-19.07.2-x86-64_gcc-7.5.0_musl.Linux-x86_64"

pushd "openwrt-sdk-19.07.2-x86-64_gcc-7.5.0_musl.Linux-x86_64"

cat <<-EOF > "feeds.conf.default"
src-git base https://github.com/coolsnowwolf/lede
src-git packages https://github.com/coolsnowwolf/packages
src-git luci https://github.com/coolsnowwolf/luci
src-git routing https://git.openwrt.org/feed/routing.git;openwrt-19.07
src-git telephony https://git.openwrt.org/feed/telephony.git;openwrt-19.07
EOF
./scripts/feeds update -a
./scripts/feeds install -a

sed -i 's#$(STAGING_DIR_HOST)/bin#/usr/bin#g' 'feeds/base/package/lean/kcptun/Makefile'
sed -i 's#$(STAGING_DIR_HOST)/bin#/usr/bin#g' 'feeds/base/package/lean/v2ray/Makefile'
sed -i 's#$(STAGING_DIR_HOST)/bin#/usr/bin#g' 'feeds/base/package/lean/v2ray-plugin/Makefile'

mkdir -p "dl"
curl -L "https://www.openssl.org/source/openssl-1.1.1d.tar.gz" -o "dl/openssl-1.1.1d.tar.gz"

cat <<-EOF > ".config"
# CONFIG_LUCI_SRCDIET is not set

# CONFIG_PACKAGE_libelektra-boost is not set
# CONFIG_boost-context-exclude is not set
# CONFIG_boost-coroutine-exclude is not set
# CONFIG_boost-fiber-exclude is not set
# CONFIG_boost-compile-visibility-global is not set
# CONFIG_boost-compile-visibility-protected is not set
# CONFIG_boost-shared-libs is not set
# CONFIG_boost-static-libs is not set
# CONFIG_boost-variant-debug is not set
# CONFIG_boost-variant-profile is not set
# CONFIG_boost-use-name-tags is not set
# CONFIG_boost-libs-all is not set
# CONFIG_boost-test-pkg is not set
# CONFIG_boost-graph-parallel is not set
# CONFIG_PACKAGE_boost-atomic is not set
# CONFIG_PACKAGE_boost-container is not set
# CONFIG_PACKAGE_boost-context is not set
# CONFIG_PACKAGE_boost-contract is not set
# CONFIG_PACKAGE_boost-coroutine is not set
# CONFIG_PACKAGE_boost-fiber is not set
# CONFIG_PACKAGE_boost-filesystem is not set
# CONFIG_PACKAGE_boost-graph is not set
# CONFIG_PACKAGE_boost-iostreams is not set
# CONFIG_PACKAGE_boost-log is not set
# CONFIG_PACKAGE_boost-math is not set
# CONFIG_PACKAGE_boost-regex is not set
# CONFIG_PACKAGE_boost-serialization is not set
# CONFIG_PACKAGE_boost-wserialization is not set
# CONFIG_PACKAGE_boost-stacktrace is not set
# CONFIG_PACKAGE_boost-thread is not set
# CONFIG_PACKAGE_boost-timer is not set
# CONFIG_PACKAGE_boost-type_erasure is not set
# CONFIG_PACKAGE_boost-wave is not set

CONFIG_PACKAGE_boost=m
CONFIG_boost-compile-visibility-hidden=m
CONFIG_boost-static-and-shared-libs=m
CONFIG_boost-runtime-shared=m
CONFIG_boost-variant-release=m
CONFIG_PACKAGE_boost-chrono=m
CONFIG_PACKAGE_boost-date_time=m
CONFIG_PACKAGE_boost-program_options=m
CONFIG_PACKAGE_boost-random=m
CONFIG_PACKAGE_boost-system=m

CONFIG_PACKAGE_luci-app-ssr-plus=m
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Simple_obfs=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_V2ray_plugin=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_V2ray=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Trojan=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Redsocks2=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Kcptun=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_ShadowsocksR_Server=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_DNS2SOCKS=y
EOF

make defconfig 2>"/dev/null"

popd


# Compile Package
pushd "openwrt-sdk-19.07.2-x86-64_gcc-7.5.0_musl.Linux-x86_64"
make package/luci-app-ssr-plus/compile -j$(nproc) 2>"/dev/null" || { echo -e "Failed to build LUCI-APP-SSR-PLUS."; exit 1; }
popd

rm -rf "luci"; mkdir -p "luci"
rm -rf "packages"; mkdir -p "packages"
cp -fp openwrt-sdk-19.07.2-x86-64_gcc-7.5.0_musl.Linux-x86_64/bin/packages/x86_64/base/luci-app-ssr-plus* luci/
cp -fp openwrt-sdk-19.07.2-x86-64_gcc-7.5.0_musl.Linux-x86_64/bin/packages/x86_64/base/{ipt2socks*,kcptun*,microsocks*,pdnsd-alt*,redsocks2*,shadowsocksr-libev*,simple-obfs*,v2ray*} packages/
cp -fp openwrt-sdk-19.07.2-x86-64_gcc-7.5.0_musl.Linux-x86_64/bin/packages/x86_64/packages/shadowsocks-libev* packages/

mkdir -p "scripts"
echo -e "${cloud_commit}" > "scripts/current_commit"


# Push Files
git config user.name CN_SZTL
git config user.email cnsztl@project-openwrt.eu.org
git add "scripts" "luci" "packages"
git commit -m "Compile commit: coolsnowwolf/lede@$(cat "scripts/current_commit" | head -c 6)"
git push
