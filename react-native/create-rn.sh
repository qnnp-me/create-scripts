#!/bin/bash

# [ 初始化相关操作 ]
SCRIPT=$(readlink -f "$0")
BASEDIR=$(dirname "$SCRIPT")
WORKDIR=$(pwd)

PROJECT_NAME=$1
PACKAGE_NAME=$2

if [ -z "$PROJECT_NAME" ]; then
  read -r -p "Enter project name: " PROJECT_NAME
  if [ -z "$PROJECT_NAME" ]; then
    echo "Please provide a project name"
    exit 1
  fi
fi

if [ -d "$PROJECT_NAME" ]; then
  echo "$PROJECT_NAME already exists"
  exit 1
fi

if [ -z "$PACKAGE_NAME" ]; then
  read -r -p "Enter package name: " PACKAGE_NAME
  if [ -z "$PACKAGE_NAME" ]; then
    echo "Please provide a package name"
    exit 1
  fi
fi

PROJECT_DIR="$WORKDIR/$PROJECT_NAME"

# clone template
git_exists=$(which git)
yarn_exists=$(which git)

if [ -z "$git_exists" ]; then
  echo "git not found"
  exit 1
fi

# [ clone 相关文件 ]

git clone https://github.com/qnnp-me/taro-rn-template.git "$PROJECT_NAME"
rm -rf "$PROJECT_NAME/.git"

cd "$PROJECT_NAME" || exit

{
  # [ 如果使用 yarn 则创建 .yarnrc.yml ]
  function create_yarnrc_yaml() {
    if [ -z "$yarn_exists" ]; then
      return
    fi
    sleep 5
    if [ -f "$PROJECT_DIR/.yarnrc.yml" ]; then
      echo "
.yarnrc.yml created"
      return
    fi
    if [ ! -d "$PROJECT_DIR" ]; then
      create_yarnrc_yaml
      return
    fi
    echo "nodeLinker: node-modules" >>"$PROJECT_DIR/.yarnrc.yml"
    echo "npmRegistryServer: https://registry.npmmirror.com" >>"$PROJECT_DIR/.yarnrc.yml"
  }
  create_yarnrc_yaml
} &

npx @react-native-community/cli@latest init "$PROJECT_NAME" --package-name="$PACKAGE_NAME" --template @react-native-community/template

if [ ! -f "$PROJECT_DIR/package.json" ]; then
  echo "Failed to initialize project"
  rm -rf "$PROJECT_DIR"
  exit 1
fi

rm -rf "$PROJECT_NAME/.git"

if [ -n "$yarn_exists" ]; then
  cd "$PROJECT_DIR" || exit
  yarn
fi

file_path="${PROJECT_DIR}/.tools/update-version.sh"
# 检查文件是否存在
if [ -f "$file_path" ]; then
  # 替换 PROJECT_NAME
  sed -i '' -E "s|PROJECT_NAME=\"[^\"]*\"|PROJECT_NAME=\"$PROJECT_NAME\"|g" "$file_path"
  # 替换 RNDIR_NAME
  sed -i '' -E "s|RNDIR_NAME=\"[^\"]*\"|RNDIR_NAME=\"$RNDIR_NAME\"|g" "$file_path"
fi

cd "$WORKDIR" || exit

rm -rf "${PROJECT_DIR}/.tools/create-project.sh"
rm -rf "${PROJECT_DIR}/.gitignore"
