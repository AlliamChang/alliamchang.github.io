git init
git remote add -f origin git@github.com:AlliamChang/alliamchang.github.io.git
git config core.sparsecheckout true
echo -e "source\nscaffolds\nnewpost.sh" > .git/info/sparse-checkout
git pull origin blog
git checkout -b blog
echo "Init finish! Just starting write!"