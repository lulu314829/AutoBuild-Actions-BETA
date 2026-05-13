# AutoBuild-Actions-BETA 项目文档

## 一、项目概述

**AutoBuild-Actions-BETA** 是一个基于 **GitHub Actions** 的 OpenWrt 固件自动化编译与分发项目，由 [Hyy2001X](https://github.com/Hyy2001X) 开发维护。项目通过 GitHub Actions 的 CI/CD 能力，实现了 OpenWrt 固件的**自动编译、自动打包、自动发布**以及**一键在线更新**的完整工作流。

- 稳定版仓库: [AutoBuild-Actions-Template](https://github.com/Hyy2001X/AutoBuild-Actions-Template)
- 自用修改版软件包: [AutoBuild-Packages](https://github.com/Hyy2001X/AutoBuild-Packages)

## 二、支持的 OpenWrt 源码

| 源码 | 仓库地址 |
| --- | --- |
| Lean's LEDE | `coolsnowwolf/lede` |
| ImmortalWrt | `immortalwrt/immortalwrt` |
| OpenWrt 官方 | `openwrt/openwrt` |
| Lienol's OpenWrt | `lienol/openwrt` |
| ImmortalWrt ARM | `padavanonly/immortalwrtARM` |
| ImmortalWrt MT798x | `hanwckf/immortalwrt-mt798x` |

## 三、项目目录结构

```
AutoBuild-Actions-BETA/
├── .github/
│   └── workflows/                    # GitHub Actions 工作流配置
│       ├── AutoBuild-x86_64.yml      # x86_64 设备编译工作流
│       ├── AutoBuild-d-team_newifi-d2.yml   # 新路由3 编译工作流
│       ├── AutoBuild-asus_rt-acrh17.yml     # 华硕 ACRH17 编译工作流
│       ├── AutoBuild-p2w_r619ac-128m.yml    # 竞斗云 2.0 编译工作流
│       ├── AutoBuild-xiaomi_*.yml           # 小米系列路由器编译工作流
│       ├── AutoBuild-xiaoyu_xy-c5.yml       # 小娱 C5 编译工作流
│       ├── Module-Refresh_API.yml           # Release API 刷新模块
│       └── Module-Synchronise_Forks.yml     # Fork 同步模块
├── Configs/                          # 编译配置文件 (.config)
│   ├── x86_64                        # x86_64 默认配置
│   ├── x86_64-AP                     # x86_64 AP 模式配置
│   ├── d-team_newifi-d2              # 新路由3 配置
│   ├── d-team_newifi-d2-Clash        # 新路由3 Clash 版配置
│   ├── d-team_newifi-d2-Lite         # 新路由3 精简版配置
│   └── ...                           # 其他设备配置
├── CustomFiles/                      # 自定义文件与补丁
│   ├── Depends/                      # 固件依赖文件（植入到固件中）
│   │   ├── tools                     # AutoBuild 工具箱脚本
│   │   ├── banner                    # 终端 Banner 显示模板
│   │   ├── profile                   # 终端 profile（系统信息展示）
│   │   ├── automount                 # USB 自动挂载脚本
│   │   ├── coremark.sh               # CoreMark 性能跑分脚本
│   │   ├── cpuset                    # CPU 调频工具
│   │   ├── base-files-essential      # 固件更新时保留的文件列表
│   │   └── openwrt_release_immortalwrt  # ImmortalWrt 版本信息模板
│   ├── Kconfig/                      # 内核配置覆盖文件
│   │   ├── generic/config-generic    # 通用内核配置
│   │   ├── ramips/mt7621/config-5.4  # MT7621 平台内核配置
│   │   └── x86/config-generic        # x86 平台内核配置
│   ├── Patches/                      # 源码补丁
│   │   ├── *-generic.patch           # 通用补丁（所有设备生效）
│   │   ├── *-ramips.patch            # ramips 平台专用补丁
│   │   └── *-x86_64.patch            # x86_64 专用补丁
│   └── d-team_newifi-d2_system       # 新路由3 系统配置文件
├── Scripts/                          # 核心脚本
│   ├── AutoBuild_DiyScript.sh        # 用户自定义脚本入口
│   ├── AutoBuild_Function.sh         # 编译流程核心函数库
│   └── Sync.sh                       # Fork 同步脚本
```

## 四、核心模块详解

### 4.1 GitHub Actions 工作流 (`.github/workflows/`)

每个设备都有独立的 YAML 工作流文件，以 `AutoBuild-x86_64.yml` 为例，完整编译流程如下：

#### 4.1.1 环境变量

```yaml
env:
  CONFIG_FILE: x86_64              # 编译使用的 .config 配置文件名
  DEFAULT_SOURCE: coolsnowwolf/lede:master  # 源码仓库:分支
  UPLOAD_RELEASES: true            # 上传固件到 GitHub Releases
  UPLOAD_ARTIFACTS: false          # 上传固件到 Artifacts
  UPLOAD_BIN_ARTIFACTS: false      # 上传完整 bin 目录到 Artifacts
  DELETE_USELESS_FILES: true       # 删除无用文件增加编译空间
  DELETE_OLD_WORKFLOW: false       # 删除旧的 workflow 记录
  CACHE_ACCELERATE: false          # 是否启用 Cache 加速编译
```

#### 4.1.2 编译流程（Step by Step）

| 步骤 | 说明 |
| --- | --- |
| **Maximize Build Space** | 清理 GitHub Actions 运行环境，释放磁盘空间 |
| **Checkout** | 检出当前仓库代码 |
| **Load Custom Variables** | 加载自定义变量（支持临时修改 IP、配置文件、固件标签） |
| **Initialize Environment** | 安装编译所需的系统依赖包 |
| **Clone Openwrt Source Code** | 克隆 OpenWrt 源码并更新 feeds |
| **Accelerate** | 可选的 Cache 加速（使用 `cachewrtbuild`） |
| **Run Diy Scripts** | 执行自定义脚本（定制固件的核心步骤） |
| **Pre-download Libraries** | 预下载软件包 |
| **Build OpenWrt** | 编译固件（先 `make -j4`，失败则 `make -j1 V=s`） |
| **Checkout Firmware** | 整理编译产物，重命名固件文件 |
| **Upload Firmware** | 上传固件到 Release / Artifacts |

#### 4.1.3 触发方式

```yaml
on:
  workflow_dispatch:        # 手动触发（支持临时修改 IP、配置、标签）
  repository_dispatch:     # API 触发
  # push:                   # 推送触发（默认注释）
  # schedule:               # 定时触发（默认注释）
  #   - cron: 0 8 * * 5
  # watch:                  # Star 触发（默认注释）
  #   types: [started]
```

#### 4.1.4 辅助工作流

| 工作流 | 说明 |
| --- | --- |
| `Module-Refresh_API.yml` | 定时刷新 GitHub Release API（每天 04:00/16:00），确保 autoupdate 能正常获取固件信息 |
| `Module-Synchronise_Forks.yml` | Fork 仓库与上游仓库同步，支持全量同步或按 `Sync_List` 列表同步 |

---

### 4.2 Scripts 脚本详解

#### 4.2.1 AutoBuild_DiyScript.sh — 用户自定义入口

这是用户**主要编辑**的文件，包含两个核心函数：

##### `Firmware_Diy_Core()` — 固件核心变量配置

| 变量 | 说明 | 默认值 |
| --- | --- | --- |
| `Author` | 作者名称 | `AUTO`（自动从 Git 配置获取） |
| `Author_URL` | 作者网站/域名 | `AUTO` |
| `Default_Flag` | 固件标签（名称后缀） | `AUTO`（自动从配置文件名提取） |
| `Default_IP` | 固件默认 IP 地址 | `192.168.1.1` |
| `Default_Title` | 终端首页额外显示信息 | `Powered by AutoBuild-Actions` |
| `Short_Fw_Date` | 简短固件日期格式 | `true`（20210601）/ `false`（202106012359） |
| `x86_Full_Images` | x86 额外上传虚拟磁盘镜像 | `false` |
| `Fw_Format` | 自定义固件格式 | `false`（自动识别） |
| `Regex_Skip` | 输出固件时排除的文件模式 | `packages\|buildinfo\|sha256sums\|...` |
| `AutoBuild_Features` | 是否启用 AutoBuild 特性 | `true` |

##### `Firmware_Diy()` — 固件定制主函数

用户在此函数中添加软件包、修改源码等操作。可用的预设变量：

| 变量 | 说明 |
| --- | --- |
| `${OP_AUTHOR}` | OpenWrt 源码作者 |
| `${OP_REPO}` | OpenWrt 仓库名称 |
| `${OP_BRANCH}` | OpenWrt 源码分支 |
| `${TARGET_PROFILE}` | 设备名称（代号） |
| `${TARGET_BOARD}` | 设备架构 |
| `${TARGET_FLAG}` | 固件名称后缀 |
| `${WORK}` | OpenWrt 源码位置 |
| `${CONFIG_FILE}` | 使用的配置文件名称 |
| `${FEEDS_CONF}` | feeds.conf.default 文件路径 |
| `${CustomFiles}` | CustomFiles 目录绝对路径 |
| `${Scripts}` | Scripts 目录绝对路径 |
| `${FEEDS_LUCI}` | package/feeds/luci 目录路径 |
| `${FEEDS_PKG}` | package/feeds/packages 目录路径 |
| `${BASE_FILES}` | package/base-files/files 目录路径 |

函数中通过 `case` 语句根据不同源码和设备进行定制，示例：

```bash
case "${OP_AUTHOR}/${OP_REPO}:${OP_BRANCH}" in
coolsnowwolf/lede:master)
    # 针对 LEDE 源码的定制
    # 添加软件包、修改配置等
    ;;
immortalwrt/immortalwrt*)
    # 针对 ImmortalWrt 源码的定制
    ;;
esac
```

---

#### 4.2.2 AutoBuild_Function.sh — 编译流程核心函数库

这是项目的核心引擎，包含编译流程中所有自动化处理逻辑：

##### 主要函数列表

| 函数名 | 调用时机 | 功能说明 |
| --- | --- | --- |
| `Firmware_Diy_Before()` | 编译前 | 解析配置、识别设备信息、设置环境变量、生成固件命名规则 |
| `Firmware_Diy_Main()` | 编译中 | 应用 AutoBuild 特性（banner、版本信息、autoupdate 配置）、设置默认 IP |
| `Firmware_Diy_Other()` | 编译中 | 应用补丁文件（Patches）、合并内核配置（Kconfig） |
| `Firmware_Diy_End()` | 编译后 | 整理编译产物、重命名固件文件、计算 SHA256 |

##### 辅助函数

| 函数名 | 功能 |
| --- | --- |
| `AddPackage()` | 从 GitHub 下载软件包到编译目录（支持 git/svn 协议） |
| `Copy()` | 复制文件/目录到指定位置 |
| `PKG_Finder()` | 在指定路径搜索文件或目录 |
| `Process_Fw()` | 处理固件输出（重命名、SHA256 计算） |
| `ECHO()` | 带时间戳的日志输出 |
| `CD()` | 安全切换目录 |
| `MKDIR()` | 安全创建目录 |
| `Get_Branch()` | 获取当前 Git 分支名 |
| `gz_Check()` | 检查是否启用了 GZIP 压缩镜像 |

##### `AddPackage()` 用法

```bash
AddPackage <git|svn> <目录> <包名> <GitHub用户/仓库> <分支>
# 示例:
AddPackage git themes luci-theme-argon jerrykuku 18.06
AddPackage svn apps luci-app-openclash vernesong/OpenClash/branches/dev
```

---

#### 4.2.3 Sync.sh — Fork 同步脚本

用于将上游仓库（`Hyy2001X/AutoBuild-Actions`）的更新同步到用户 Fork 的仓库。

##### 可配置项

```bash
INPUT_UPSTREAM_REPOSITORY=Hyy2001X/AutoBuild-Actions  # 上游仓库
INPUT_UPSTREAM_BRANCH=master                           # 上游分支

Sync_List=(                                            # 同步文件列表
    CustomFiles/Depends/*
    CustomFiles/Patches/*
    CustomFiles/Kconfig/*
    Scripts/AutoBuild_Function.sh
    ...
)
```

##### 运行模式

| 模式 | 说明 |
| --- | --- |
| `--sync-all` | 全量同步：将上游所有内容强制推送到本地仓库 |
| 默认模式 | 按 `Sync_List` 列表选择性同步文件 |

---

### 4.3 CustomFiles 自定义文件

#### 4.3.1 Depends/ — 固件植入文件

这些文件会在编译时被复制到固件的对应目录中：

| 文件 | 植入位置 | 功能 |
| --- | --- | --- |
| `tools` | `/bin/tools` | **AutoBuild 工具箱**，提供 USB 扩展、Samba 设置、端口查看、硬盘信息、网络检查、系统监控、在线设备列表、虚拟内存创建等功能 |
| `banner` | `/etc/banner` | SSH/TTYD 终端登录 Banner，显示 AutoBuild 标识和固件版本 |
| `profile` | `/etc/profile` | 系统登录 profile，显示设备信息、CPU 温度、内存/存储使用情况等 |
| `automount` | 自动挂载脚本 | USB 设备热插拔自动挂载，支持 NTFS/exFAT/vfat 等文件系统 |
| `coremark.sh` | CoreMark 跑分脚本 | 首次启动后自动运行 CoreMark 性能测试并记录结果 |
| `cpuset` | `/bin/cpuset` | CPU 调频工具，支持查看/设置 governor 和频率 |
| `base-files-essential` | `/lib/upgrade/keep.d/` | 固件更新时默认保留的关键文件列表（hosts、passwd、shadow 等） |
| `openwrt_release_immortalwrt` | `/etc/openwrt_release` | ImmortalWrt 版本信息模板 |

#### 4.3.2 Patches/ — 源码补丁

补丁文件按命名规则自动匹配生效范围：

| 命名规则 | 生效范围 |
| --- | --- |
| `*-generic.patch` | 所有设备 |
| `*-{TARGET_BOARD}.patch` | 特定架构（如 `ramips`） |
| `*-{TARGET_PROFILE}.patch` | 特定设备（如 `x86_64`） |

内置补丁列表：

| 补丁文件 | 功能 |
| --- | --- |
| `01-improve_ssr-rule_log-generic.patch` | 改善 SSR 规则日志 |
| `02-add_custom_proxy_port_support-generic.patch` | 添加自定义代理端口支持 |
| `fix_aria2_auto_create_download_path-generic.patch` | 修复 Aria2 自动创建下载路径 |
| `fix_coremark-generic.patch` | 修复 CoreMark |
| `fix_luci-app-autoreboot-generic.patch` | 修复自动重启插件 |
| `upgrade_intel_igpu_drv-x86_64.patch` | 升级 Intel 核显驱动（x86_64） |
| `dualband_wifi-ramips.patch` | 双频 WiFi 支持（ramips 平台） |

#### 4.3.3 Kconfig/ — 内核配置覆盖

用于向 OpenWrt 的 `target/linux/` 目录下的内核配置文件追加额外配置：

| 路径 | 目标 |
| --- | --- |
| `generic/config-generic` | 追加到所有架构的 `config-*` 文件 |
| `x86/config-generic` | 追加到 x86 平台的内核配置 |
| `ramips/mt7621/config-5.4` | 追加到 MT7621 平台的 5.4 内核配置 |

---

### 4.4 Configs/ — 编译配置文件

存放各设备的 OpenWrt `.config` 编译配置文件，以 `TARGET_PROFILE` 命名。配置文件支持通过后缀区分不同版本，例如：

- `x86_64` — 标准版
- `x86_64-AP` — AP 模式版
- `d-team_newifi-d2-Clash` — Clash 专用版
- `d-team_newifi-d2-Lite` — 精简版

以 `Configs/x86_64` 为例，主要配置包括：

| 配置项 | 说明 |
| --- | --- |
| 目标平台 | `CONFIG_TARGET_x86_64` |
| 内核分区 | 32MB |
| 根文件系统分区 | 480MB |
| 镜像格式 | GRUB + GZIP 压缩 |
| IPv6 支持 | 启用 |
| USB 驱动 | ehci/uhci/ohci/usb3 |
| 无线驱动 | mt7921e/mt7921u/mac80211 |
| Luci 应用 | OpenClash、PassWall、SmartDNS、Docker、Samba、Aria2 等 |
| 主题 | Argon、NeoBird |

---

## 五、固件更新系统 (AutoUpdate)

项目内置了完整的固件在线更新系统：

### 5.1 autoupdate 命令

```bash
autoupdate              # 更新固件（保留配置）
autoupdate -P           # 使用镜像加速更新
autoupdate -n           # 更新固件（不保留配置）
autoupdate -F           # 强制刷写固件（危险）
autoupdate -f           # 强制下载并刷写
autoupdate -x           # 更新脚本自身
autoupdate --log        # 打印运行日志
autoupdate --help       # 查看帮助
autoupdate --list       # 查看当前固件信息
autoupdate --clean      # 清除下载缓存
autoupdate --flag XXX   # 更改固件标签
autoupdate --backup     # 备份系统配置
autoupdate -B UEFI/BIOS # 指定引导方式（x86）
```

### 5.2 AutoBuild 工具箱 (tools)

在终端输入 `tools` 即可启动工具箱，提供以下功能：

1. USB 空间扩展 — 将外接存储设备格式化为 ext4 并挂载为系统根目录
2. Samba 设置 — 自动生成/删除 Samba 共享、设置密码
3. 端口占用列表 — 显示系统端口使用情况
4. 硬盘信息 — 显示硬盘型号、温度、健康状况等 SMART 信息
5. 网络检查 — 检测基础网络、DNS、Google 连通性
6. 环境修复 — 恢复固件默认配置文件
7. 系统信息监控 — 实时显示 CPU、内存、存储、网络等信息
8. 在线设备列表 — 显示当前连接的局域网设备
9. 创建虚拟内存 — 创建 swap 交换文件

### 5.3 Release API 刷新

`Module-Refresh_API.yml` 工作流每天定时（04:00/16:00 UTC）刷新 GitHub Release API 文件，确保 autoupdate 能正确获取最新固件信息。

---

## 六、使用指南

### 6.1 快速开始

1. **Fork** 本仓库到自己的 GitHub 账号
2. 编辑 `Configs/` 下的配置文件，或上传本地生成的 `.config`
3. 编辑对应设备的 `.github/workflows/AutoBuild-*.yml`：
   - 修改 `name:` 为便于识别的名称
   - 修改 `CONFIG_FILE:` 为配置文件名
   - 修改 `DEFAULT_SOURCE:` 为目标源码仓库
4. 按需编辑 `Scripts/AutoBuild_DiyScript.sh`

### 6.2 编译触发方式

| 方式 | 操作 |
| --- | --- |
| **手动编译** | Actions → 选择设备 → Run workflow |
| **Star 编译** | 取消 yml 中 `watch` 的注释，点亮 Star ⭐ |
| **定时编译** | 取消 yml 中 `schedule` 的注释，配置 cron 表达式 |
| **推送编译** | 取消 yml 中 `push` 的注释 |

### 6.3 手动编译可选参数

手动触发编译时支持临时指定：

- **固件 IP 地址** — 临时覆盖默认 IP
- **配置文件** — 临时使用其他 `.config`
- **固件标签** — 临时修改固件名称后缀

### 6.4 Fork 同步

运行 `Module-Synchronise_Forks.yml` 工作流：
- 默认模式：按 `Sync.sh` 中的 `Sync_List` 同步指定文件
- 全量模式：勾选「同步上游所有内容」，将上游完整覆盖到本地

---

## 七、编译流程总览

```
┌──────────────────────────────────────────────────────────────────┐
│                    GitHub Actions Runner                         │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. 释放磁盘空间, 检出仓库代码                                    │
│                        ↓                                         │
│  2. 加载环境变量 (CONFIG_FILE, REPO_URL, Compile_Date 等)         │
│                        ↓                                         │
│  3. 安装编译依赖 (build-essential, cmake, git 等)                 │
│                        ↓                                         │
│  4. 克隆 OpenWrt 源码 → 更新 feeds                               │
│                        ↓                                         │
│  5. [可选] Cache 加速编译                                        │
│                        ↓                                         │
│  6. ┌─────────────────────────────────────────┐                  │
│     │  Firmware_Diy_Before()                  │                  │
│     │  - 解析 .config 识别设备信息             │                  │
│     │  - 生成固件命名规则                      │                  │
│     │  - 设置所有环境变量                      │                  │
│     └─────────────────────────────────────────┘                  │
│                        ↓                                         │
│  7. ┌─────────────────────────────────────────┐                  │
│     │  Firmware_Diy_Main()                    │                  │
│     │  - 植入 AutoBuild 特性                   │                  │
│     │  - 设置 Banner / 版本信息                │                  │
│     │  - 配置默认 IP 地址                      │                  │
│     │  - 复制 tools / profile 等文件           │                  │
│     └─────────────────────────────────────────┘                  │
│                        ↓                                         │
│  8. ┌─────────────────────────────────────────┐                  │
│     │  Firmware_Diy()  [用户自定义]            │                  │
│     │  - 添加第三方软件包                      │                  │
│     │  - 修改源码/配置                         │                  │
│     │  - 设备特定定制                          │                  │
│     └─────────────────────────────────────────┘                  │
│                        ↓                                         │
│  9. ┌─────────────────────────────────────────┐                  │
│     │  Firmware_Diy_Other()                   │                  │
│     │  - 应用 Patches 补丁                     │                  │
│     │  - 合并 Kconfig 内核配置                 │                  │
│     └─────────────────────────────────────────┘                  │
│                        ↓                                         │
│  10. 预下载软件包 → make download                                │
│                        ↓                                         │
│  11. 编译固件 → make -j4                                         │
│                        ↓                                         │
│  12. ┌─────────────────────────────────────────┐                 │
│      │  Firmware_Diy_End()                     │                 │
│      │  - 整理编译产物                          │                 │
│      │  - 计算 SHA256 并重命名固件              │                 │
│      └─────────────────────────────────────────┘                 │
│                        ↓                                         │
│  13. 上传固件到 GitHub Releases / Artifacts                       │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## 八、固件命名规则

编译产物按照以下规则命名：

```
AutoBuild-{源码名}-{设备代号}-{版本号}-{启动方式}-{标签}-{SHA256前5位}.{格式}
```

示例：
```
AutoBuild-lede-x86_64-R23.5.5-20230513-UEFI-Full-a1b2c.img.gz
AutoBuild-lede-x86_64-R23.5.5-20230513-BIOS-Full-d4e5f.img.gz
AutoBuild-lede-d-team_newifi-d2-R23.5.5-20230513-Full-12345.bin
```

---

## 九、维护设备列表

| 状态 | 设备型号 | TARGET_PROFILE | 源码 |
| --- | --- | --- | --- |
| ✅ | x86_64 | `x86_64` | immortalwrt |
| ✅ | 中国移动 RAX3000M | `cmcc_rax3000m` | immortalwrt-mt798x |
| ✅ | 捷希 Q30 | `jcg_q30` | immortalwrt-mt798x |
| ❎ | 新路由3 | `d-team_newifi-d2` | lede |
| ❎ | 华硕 ACRH17 | `asus_rt-acrh17` | lede |
| ❎ | 竞斗云 2.0 | `p2w_r619ac-128m` | lede |
| ❎ | 小娱 C5 | `xiaoyu_xy-c5` | lede |
| ❎ | 红米 AC2100 | `xiaomi_redmi-router-ac2100` | lede |
| ❎ | 红米 AX6S | `xiaomi_redmi-router-ax6s` | lede |
| ❎ | 小米 4A 千兆版 | `xiaomi_mi-router-4a-gigabit` | lede |

---

## 十、鸣谢

- [Lean's OpenWrt Source](https://github.com/coolsnowwolf/lede)
- [P3TERX's Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt)
- [ImmortalWrt](https://github.com/immortalwrt/immortalwrt)
- [eSir's workflow template](https://github.com/esirplayground/AutoBuild-OpenWrt)
- [openwrt-autoupdate](https://github.com/mab-wien/openwrt-autoupdate)
