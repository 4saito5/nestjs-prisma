# nestjs-prisma

## 環境構築ログ

```sh
npm install -g npm@9.6.5
# npm i -g @nestjs/cli
nest new sample001

# ディレクトリ階層を1つ下げる
mv sample001/* .
mv sample001/.* . > /dev/null 2>&1
rm -rf sample001/

npm run start:dev
```

https://docs.nestjs.com/recipes/prisma
[Nest.jsのORMにPrismaを導入してみる](https://qiita.com/kikikikimorimori/items/5d1098f6a51324ddaab4)

```sh
npm install prisma --save-dev
npx prisma

# セットアップ
npx prisma init
```

.env修正
```
DATABASE_URL="postgresql://test:test@db:5432/test?schema=public"
```

prisma/schema.prismaにモデルを追記


```sh
# Mingration
npx prisma migrate dev --name init
```


```sh
# Prisma Clientのインストール
npm install @prisma/client
```

PrismaClientのインスタンス化とデータベースへの接続を行うPrismaServiceを作成
prisma.service.ts


UsersServiceの作成
```sh
nest g service users
nest g controller users
nest g module users
```


```sh
curl -H "content-type: application/json" -X POST -d'{"name":"田中太郎", "email":"tanaka@sample.com"}' http://localhost:8000/users

curl -X GET http://localhost:8000/users/1

curl -X GET http://localhost:8000/users
```


```sh
# TypeScriptのコードを生成
prisma generate

# 既存のDBからモデルを生成する
prisma db pull

# スキーマファイルをフォーマット
npx prisma format

# ビジュアルエディタで確認
npx prisma studio

```


## クエリの書き方
[Raw database access](https://www.prisma.io/docs/concepts/components/prisma-client/raw-database-access)



```sh
```
```sh
```
```sh
```



[prisma-query-builder](https://www.npmjs.com/package/prisma-query-builder)
[Prismaの概要とTypeORMとの比較を少し](https://zenn.dev/youcangg/articles/b9276537841fb5
)