# 产品官网

[English](WEBSITE.md) · [简体中文](WEBSITE.zh-CN.md)

无需构建的产品介绍网站位于 `website/`：`/` 为简体中文，`/en/` 为英文。使用含虚构数据的本地截图、已批准的应用图标、生成的礼物插画，以及附带 OFL 授权的 Nunito 字体。网站提供 Android 下载入口，不是浏览器版应用。没有修改应用源码、记录、数据库或 Android 安装包。

## 预览

在仓库根目录运行 `python -m http.server 4173 --bind 127.0.0.1 --directory website`，然后打开 `http://127.0.0.1:4173/`。语言切换使用普通链接，问答使用 HTML 原生 details，无需 JavaScript 或构建步骤。

## 发布

集成目标：`main`；任务分支：`codex/product-website`。计划公开地址为 `https://naclarb.github.io/Wallehog/`，目前尚未上线。原本地 `main` 有七个未发布提交，包含等待评审的宣传片工作，因此集成待处理。本任务在独立工作区从远端 `main`（`9b41625`）开始，避免意外发布那些更改。

集成阻塞解除后，保留待处理工作并将官网分支合入 `main`。在仓库 Settings → Pages 中选择 **GitHub Actions** 作为来源。将官网集成推送到已确认的 `origin/main`；`.github/workflows/website.yml` 只上传 `website/` 并部署到 Pages，也支持从 `main` 手动触发。核实部署结果和两种语言的公开地址后，才能标记发布完成。无需购买域名。本任务未更改 GitHub Pages 访问设置或仓库权限。

## 验证（2026-11-13）

- 本地中英文页面正常提供服务；本地资源和锚点有效，每页有一个主标题。
- 浏览器检查：360 × 800、390 × 844 手机尺寸和 1440 × 1000 桌面尺寸；未观察到横向溢出。截图加载、双向语言切换和问答展开通过。
- 两个官方 APK 下载链接、版本页、仓库、中英文素材鸣谢和托管隐私链接均返回 HTTP 200。发布前，计划中的 Pages 中英文地址均返回 404。
- 未添加 JavaScript、统计、Cookie、远程字体请求或用户数据表单。文案区分应用隐私和 GitHub 托管 IP 日志，并解释金额为自行记录、备份未加密。
- 提交前须运行 `git diff --check`。仅官网改动无需 Flutter 分析、APK 构建或真机安装。浏览器截图留在已忽略的 `.buildlog/website/`。

Pages 工作流尚未在远端运行。公开部署和集成仍待完成；本地预览不代表已发布。
