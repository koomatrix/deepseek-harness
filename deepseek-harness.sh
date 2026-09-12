#!/bin/zsh

#SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
#!/bin/zsh
set -e
# 获取脚本真实所在目录
SCRIPT_DIR="${0:A:h}"
echo "Script directory: $SCRIPT_DIR"
# 将工作目录切换到项目目录
cd "$SCRIPT_DIR" || {
  echo "Failed to cd into: $SCRIPT_DIR"
  exit 1
}
echo "Working directory: $PWD"
# 解析参数
zparseopts -D -E -- -build=BUILD_OPT
# 构建
if (( $#BUILD_OPT )); then
#  echo "Running git pull"
#  git pull

  echo "Running pnpm install"
  pnpm install

  echo "Running build..."
  pnpm run build
fi
# 启动
echo "Running pnpm dsh web..."
pnpm dsh web
