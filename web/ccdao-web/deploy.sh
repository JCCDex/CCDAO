# 进入工作目录
cd `dirname $0`

# 编译
npm run build

# 移动favicon
# mv dist/static/favicon.ico dist

# 拷贝到服务器

rsync -avzr -e 'ssh -p 6422' dist/ --exclude=dist/public/config.json front@58.243.201.56:/home/front/xubo/cross-chain-dao