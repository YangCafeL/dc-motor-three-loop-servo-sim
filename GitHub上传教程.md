# GitHub 上传完整教程（Windows / macOS / Linux 通用）

> 本项目已完成整理：新增 `README.md`、`LICENSE`、`.gitignore`，清理规则见第 1 部分。
> 从零到推送成功共 7 步，每条命令可直接复制执行（`$` 是提示符，不要复制）。

---

## 0. 前置检查：安装并确认 Git

```bash
git --version
```

- **Windows**：未安装则到 https://git-scm.com/download/win 下载安装（一路默认即可，会同时获得 Git Bash 终端）。
- **macOS**：`xcode-select --install`（首次运行 `git` 也会自动提示安装）。
- **Linux (Debian/Ubuntu)**：`sudo apt install git`；**(Fedora)**：`sudo dnf install git`。

## 1. 项目整理说明（已完成）

**新增的文件及其作用：**

| 文件 | 作用 |
|---|---|
| `README.md`（根目录） | 项目首页：GitHub 打开仓库首先展示的内容，含结果一览、结构、运行方法 |
| `LICENSE`（MIT） | 开源许可证：没有它，别人默认无权复制/修改你的代码；MIT 最宽松常用 |
| `.gitignore` | 告诉 Git 哪些文件**不纳入版本管理**（见下） |

**`.gitignore` 排除的内容及原因：**

| 排除项 | 原因 |
|---|---|
| `自动控制课程设计.pptx`、`ppt_images/`、`ppt_text.txt` | 课程原始材料（12MB，含版权），公开仓库不宜上传；确认有权限可自行删除这几行 |
| `.workbuddy/` | 工作区工具数据，与项目无关 |
| `matlab/slprj/`、`*.slxc` | Simulink 缓存，运行时自动重新生成（本机缓存因安全策略未删掉，不影响，Git 不会上传它们） |
| `*.asv`、`*.mex*`、`matlab_crash_dump.*` | MATLAB 编辑器自动保存/二进制/崩溃转储 |
| `*.mat`、`*.log` | 仿真结果数据与日志，运行脚本即可再生，避免仓库膨胀 |

**保留上传**：`设计报告.md`、`matlab/`（9 个脚本 + 4 个模型 + 8 张结果图）。

## 2. 第一步：配置身份（每台机器只需一次）

```bash
git config --global user.name "你的名字或GitHub用户名"
git config --global user.email "你的邮箱@example.com"
```

**作用**：每条提交都会记录作者身份。⚠️ 本机当前只配置了邮箱，`user.name` 为空，不配置无法提交。
建议邮箱与 GitHub 账号一致；如不想暴露真实邮箱，可用 GitHub 提供的匿名邮箱（GitHub → Settings → Emails 查看形如 `12345678+username@users.noreply.github.com`）。

## 3. 第二步：初始化本地仓库

```bash
cd "项目目录路径"          # Windows 示例: cd "C:\Users\Prima\Desktop\自动控制原理课程设计"
git init
```

**作用**：`cd` 进入项目根目录；`git init` 在当前目录创建 `.git/` 隐藏文件夹，把它变成 Git 仓库（只执行一次）。

## 4. 第三步：添加文件到暂存区并确认

```bash
git add .
git status
```

**作用**：`git add .` 把新文件/修改文件放入暂存区（`.gitignore` 中的文件自动跳过）；`git status` 列出将要提交的内容，检查 PPT、`slprj/`、`*.slxc` 等确实没被包含。

> 补充：只想撤销某个已 add 的文件用 `git restore --staged 文件名`（Git ≥2.23）或 `git rm --cached 文件名`。

## 5. 第四步：提交到本地仓库

```bash
git commit -m "完成自动控制课程设计：三环伺服系统建模与仿真（任务1-5）"
```

**作用**：把暂存区内容生成一个版本快照（commit），`-m` 后是提交说明。之后每次改动重复「`git add` → `git commit`」即可持续记录版本。

## 6. 第五步：在 GitHub 上创建远程仓库

1. 登录 https://github.com → 右上角 **＋** → **New repository**；
2. Repository name 填 `auto-control-course-design`（示例，不要用中文）；
3. 选择 **Private**（私有）或 Public（公开）；
4. ⚠️ **不要**勾选 "Add a README / .gitignore / license"（本地已有，勾了会造成推送冲突）；
5. 点击 **Create repository**，**不要关闭页面**，复制给出的仓库地址，形如：
   - HTTPS：`https://github.com/用户名/auto-control-course-design.git`
   - SSH：`git@github.com:用户名/auto-control-course-design.git`

## 7. 第六步：关联远程仓库并首次推送

```bash
git branch -M main
git remote add origin https://github.com/用户名/auto-control-course-design.git
git push -u origin main
```

**作用**：
- `git branch -M main`：把默认分支重命名为 `main`（GitHub 现行默认分支名）；
- `git remote add origin <地址>`：给远程仓库起别名 `origin` 并记录地址；
- `git push -u origin main`：把本地 `main` 分支推送到远程，`-u` 建立跟踪关系，之后推送/拉取只需 `git push` / `git pull`。

## 8. 第七步：日常更新（以后修改代码后）

```bash
git add .
git commit -m "说明本次改动"
git push
```

---

## 9. 常见问题与解决方法

### 9.1 身份认证（推送时要求登录）

- **HTTPS（推荐新手）**：首次 `git push` 会弹出浏览器/窗口登录 GitHub。⚠️ 密码框里要填 **Personal Access Token（PAT）**，不是账号密码——GitHub 已于 2021 年停用密码推送。生成路径：GitHub → Settings → Developer settings → Personal access tokens → **Tokens (classic)** → Generate new token，勾选 `repo` 权限，复制 token 粘贴到密码框。Token 只显示一次，请保存好。
  - 凭据会被记住（Windows 用"凭据管理器"，macOS 用钥匙串）。想更换账号：Windows 在「控制面板 → 凭据管理器 → Windows 凭据」删除 `git:https://github.com`；macOS 执行 `printf "protocol=https\nhost=github.com\n" | git credential-osxkeychain erase`。
- **SSH（推荐长期开发者）**：
  ```bash
  ssh-keygen -t ed25519 -C "你的邮箱"     # 一路回车，生成密钥对
  cat ~/.ssh/id_ed25519.pub               # Windows Git Bash 同样可用；复制输出内容
  ```
  把公钥粘贴到 GitHub → Settings → SSH and GPG keys → New SSH key，然后远程地址改用 SSH 形式：
  ```bash
  git remote set-url origin git@github.com:用户名/auto-control-course-design.git
  ssh -T git@github.com    # 测试，首次询问 fingerprint 输 yes
  ```

### 9.2 `! [rejected] ... fetch first`（推送被拒）

远程仓库已有内容（比如创建时勾选了 README），或他处有新提交：

```bash
git pull origin main --rebase    # 先把远程内容合并进本地
git push -u origin main
```

若确定远程内容无用且以本地为准（⚠️ 会覆盖远程，仅限自己的新仓库）：

```bash
git push -u origin main --force
```

### 9.3 远程仓库为空 / `error: src refspec main does not match any`

前者说明 GitHub 上还没有任何提交——这是正常的，**先完成本地 init/add/commit 再推送**即可；后者说明本地还没有任何 commit（或分支名不是 main），检查第四、五步是否执行成功：`git status`、`git branch`。

### 9.4 `fatal: not a git repository`

当前目录没有执行过 `git init`，或不在项目根目录。`cd` 到项目根目录重新执行。

### 9.5 换行符警告 `LF will be replaced by CRLF`

Windows 常见提示，不影响使用。统一处理：

```bash
# Windows：
git config --global core.autocrlf true
# macOS / Linux：
git config --global core.autocrlf input
```

### 9.6 中文文件/提交信息乱码

Windows Git Bash 中执行：

```bash
git config --global core.quotepath false    # 正常显示中文文件名
git config --global i18n.commitEncoding utf-8
git config --global i18n.logOutputEncoding utf-8
```

### 9.7 推送很慢 / 连接超时

检查代理（若使用 VPN/代理，让 Git 走同一端口，端口按实际替换）：

```bash
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890
# 取消代理：
git config --global --unset http.proxy
git config --global --unset https.proxy
```

### 9.8 误提交了大文件想撤销最近一次提交

```bash
git reset --soft HEAD~1    # 撤销提交但保留文件，补充 .gitignore 后重新 add/commit
```

## 10. Windows 与 macOS/Linux 差异速查

| 事项 | Windows | macOS / Linux |
|---|---|---|
| 终端 | Git Bash / PowerShell / CMD 均可 | 系统自带 Terminal |
| 路径分隔符 | `/` 与 `\` 均可，含空格路径加引号 | `/`，含空格路径加引号 |
| 密钥/配置位置 | `C:\Users\用户名\.ssh`、`C:\Users\用户名\.gitconfig` | `~/.ssh`、`~/.gitconfig` |
| 凭据存储 | Windows 凭据管理器 | macOS 钥匙串 / Linux 需 `git config --global credential.helper store` |
| 其余 Git 命令 | **完全一致** | **完全一致** |
