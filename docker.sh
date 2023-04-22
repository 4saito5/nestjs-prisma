# 使い方：
#  Dcokcer初めての起動[Setup]
#    ./docker.sh -s [フロントの名称]
#    ※ Setupが終わったら、一旦終了[Down]してください
#
#  Dcokcer起動[Up]
#    ./docker.sh -u [フロントの名称]
#    Dockerイメージのビルドをして起動
#    ./docker.sh -u --build
#
#  Dcokcer終了[Down]
#    ./docker.sh -d [フロントの名称]

#!/bin/zsh
SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

declare -a ARG_OPTION=()

abort() { echo "$*" >&2; exit 1; }
unknown() { abort "unrecognized option '$1'"; }
required() { [ $# -gt 1 ] || abort "option '$1' requires an argument"; }

setOption() {
    for value in ${ARG_OPTION[@]}; do
        if [ `echo "${value}" | grep '^--'` ] ; then
            COMMAND_OPTION="${value}"
        elif [ `echo "${value}" | grep '^/'` ] ; then
            SUB_DIRECTORY="${value}"
        else
            MODULE="${value}"
        fi
    done
}

DOCKER_COMPOSE="docker compose"

# セットアップ環境起動
setup() {
    echo "setup ... ${ARG_OPTION[@]}"

    setOption
    ${DOCKER_COMPOSE} -f ./infra/docker${SUB_DIRECTORY}/docker-compose-setup.yml up -d --build

    # tmp_nuxt2のセットアップ
    _setup_nuxt tmp_nuxt

    # tmp_laravelのセットアップ
    _setup_laravel tmp_laravel-app

    # セットアップが終わったら終了する
    down
}

_setup_nuxt() {
	docker exec $1 yarn
    # 環境変数ファイルを作成
	docker exec $1 cp -pf ./env/local.env .env
}

_setup_laravel() {
    echo "$1 container"
    ## リポジトリのミラーサーバーpackagist.jpが死んでいるため、本家を見るように変更
    docker exec $1 composer config -g repositories.packagist composer https://packagist.org

    # PHPのパッケージをインストール
    docker exec $1 sh -c "export COMPOSER_PROCESS_TIMEOUT=1200"
    docker exec $1 composer clear-cache
    docker exec $1 composer install

    # .env反映のためのファイル削除
    docker exec $1 rm -f bootstrap/cache/config.php

    # 環境変数ファイルを作成
    docker exec $1 cp -f ./env/local.env .env
    # 暗号化キーを作成。.envに書き込まれる
    docker exec $1 php artisan key:generate

    # DB構築 & 初期データを投入
    docker exec $1 php artisan migrate --seed --force
}

# 通常環境起動
up() {
    echo "up ... ${ARG_OPTION[@]}"

    setOption
    ${DOCKER_COMPOSE} -f ./infra/docker${SUB_DIRECTORY}/docker-compose.yml up -d ${COMMAND_OPTION}
}

# テスト環境起動
test() {
    echo "API Test ... ${ARG_OPTION[@]}"

    setOption
    ${DOCKER_COMPOSE} -f ./infra/docker${SUB_DIRECTORY}/docker-compose-api-test.yml up -d ${COMMAND_OPTION}
}

# 終了
down() {
    echo "down ... ${ARG_OPTION[@]}"

    setOption
    ${DOCKER_COMPOSE} -f ./infra/docker${SUB_DIRECTORY}/docker-compose.yml down --volumes --remove-orphans
}

change() {
    echo "change name ${ARG_SRC} to ${ARG_DST}"

    # _trash_file
    _change_path
    _replace_content
}

# コミットしないファイルを削除（未使用）
_trash_file() {
    echo "remove file ${ARG_SRC}"
    rm -rf ${ARG_SRC}/src/.env
    rm -rf ${ARG_SRC}/src/.nuxt
    rm -rf ${ARG_SRC}/src/node_modules
    rm -rf ${ARG_SRC}/src/vendor
}

# ディレクトリ、ファイル名の変更
_change_path() {
    echo 'ディレクトリ、ファイル名の変更'
    while : ;do
        src=$(find . -name "${ARG_SRC}*" | head -1)
        if [ -z "${src}" ]; then
            return
        fi
        dst=$(echo "${src}" | gsed -e "s/${ARG_SRC}/${ARG_DST}/g")
        echo ${src} ${dst}
        mv ${src} ${dst}
        # return
    done
}

# ファイルの内容を置換
_replace_content() {
    echo 'ファイルの内容を置換'
    for src in `gfind . -type f -regex '\(.*\.\(yml\|env\|json\|js\|ts\|php\|local\|conf\|sh\)\|.*Dockerfile\|.*dockerignore\)'`; do
    # for src in `gfind . \( -type f -regex '\.\/README\.md' -prune -o -type f -regex '\(.*\.\(yml\|env\|json\|js\|ts\|php\|local\|conf\|sh\)\|.*Dockerfile\|.*dockerignore\)' \) -print`; do
        # grepして置換ワードに引っかかったファイルのみ、gsedで置換する
        # grep -q ${ARG_SRC} ${src} && echo ${src}
        grep -q ${ARG_SRC} ${src} && echo ${src} && gsed -i -e "s/${ARG_SRC}/${ARG_DST}/g" ${src}
    done
}

while [ $# -gt 0 ]; do
    case $1 in
        -s | --setup ) shift; ARG_OPTION+=($1); setup ;;
        -u | --up ) shift; ARG_OPTION+=($1); ARG_OPTION+=($2); up ;;
        -t | --test ) shift; ARG_OPTION+=($1); ARG_OPTION+=($2); test ;;
        -d | --down ) shift; ARG_OPTION+=($1); down ;;
        -c | --change ) shift; ARG_SRC+=($1); ARG_DST+=($2); change ;;
        -r | --reset ) shift; ARG_SRC+=($1); _trash_file ;;
        -q | --quiet ) ;;
        -?*) unknown "$@" ;;
        *) break
    esac
    shift
done
