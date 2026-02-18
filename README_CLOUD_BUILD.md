# 云端编译与重打包说明

功能
- 在 GitHub Actions 上交叉编译播放器二进制（示例使用 Go）
- 可选：下载原厂固件并尝试提取 rootfs (squashfs)，将二进制注入并重建 squashfs
- 输出构建产物供下载

注意与限制
- 最后生成的固件是否能刷入设备取决于厂商打包格式与签名机制。
- 脚本仅作为通用自动化示例，实际打包通常需要厂商工具（例如 mkimage、特定 header 操作、签名等）。
- 请先备份原厂固件并确认有恢复手段（如 SD 卡紧急刷机/串口恢复）。

使用方法（在 GitHub Actions 手动触发 workflow）
- 填写 target_arch（例如 armv7），若要 repack，请选择 do_repack=yes 并提供固件 URL。
- CI 会生成 build/artifacts，包含交叉编译的二进制与重打包的 squashfs（若找到的话）。

后续我能为你做的事
1. 如果你把原厂固件上传（或提供下载链接），我可以在 fork 的仓库里跑一次自动化 repack，给你分析报告（是否找到 squashfs、rootfs 内容、是否含签名、播放器二进制名称与路径）。
2. 我可以把 workflow 调整成：自动从 release asset 下载原厂固件（需要你把固件作为 release 上传或放到可信 URL）。
3. 我可以为具体 SoC（识别后）加入厂商专用打包步骤，或生成可直接刷写的 update.bin（若没有签名限制）。
