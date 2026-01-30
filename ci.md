# splayer AUR Package

这是 SPlayer 音乐播放器的 Arch Linux AUR 包，支持多架构（x86_64 和 aarch64）。

## CI/CD 流程

本项目包含两个自动化 CI/CD 流程：

### 1. 版本更新检查

- **触发条件**: 每天中午12点自动检查，也可以手动触发
- **功能**: 检查上游 SPlayer 项目的最新发布版本，如果发现新版本，则自动更新 PKGBUILD 和 .SRCINFO 文件，并创建 Pull Request
- **工作流文件**: `.github/workflows/check-updates.yml`

### 2. AUR 同步

- **触发条件**: 每天午夜0点自动同步，也可以手动触发，或者当 main 分支有更新时
- **功能**: 将最新的 PKGBUILD 和 .SRCINFO 文件同步到 AUR 仓库
- **工作流文件**: `.github/workflows/sync-aur.yml`

## 配置 AUR 同步

要启用 AUR 自动同步功能，请按以下步骤操作：

1. 生成 SSH 密钥对：
   ```bash
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f ~/.ssh/aur_sync_key
   ```

2. 将公钥添加到您的 AUR 账户：
   - 登录到 AUR 网站
   - 进入 "Edit Profile" 页面
   - 在 "SSH Keys" 部分添加公钥内容（`~/.ssh/aur_sync_key.pub` 的内容）

3. 在 GitHub 仓库中添加私钥作为密钥：
   - 进入 GitHub 仓库的 Settings 页面
   - 选择 Secrets and variables -> Actions
   - 点击 "New repository secret"
   - Name: `AUR_SSH_PRIVATE_KEY`
   - Value: 私钥内容（`~/.ssh/aur_sync_key` 的内容）

## 手动更新版本

如果您需要手动更新版本，可以使用提供的脚本：

```bash
# 更新到新版本（例如 3.0.0_beta.10）
./scripts/update_version.sh 3.0.0_beta.10
```

## 注意事项

- `.SRCINFO` 文件不是通过 `makepkg --printsrcinfo` 生成的，而是由脚本直接管理，以支持多架构解析
- 该包支持 x86_64 和 aarch64 架构
- 所有依赖项都在 PKGBUILD 中定义