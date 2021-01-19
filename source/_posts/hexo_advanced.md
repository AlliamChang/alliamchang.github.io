---
title: hexo进阶
date: 2020-08-30 04:11:03
tags:
- hexo
categories:
- 学习笔记
---
hexo是个建博客很不错的工具，但是hexo需要依赖很多东西，为了能够随时随地、轻依赖地编写，在引入Travis CI的同时，只对博客进行同步和更新。
<!-- more -->

# 自动化部署
首先，我们选择了使用github page作为博客的部署平台，
Hexo官网推荐的Travis CI配置流程：https://hexo.io/zh-cn/docs/github-pages
```yaml
# .travis.yml
# 以下是本人对配置的一些修改
sudo: required
language: node_js
node_js:
  - 10
cache: npm
branches:
  only:
    - blog # build blog branch only

script:
  - hexo generate # generate static files

deploy:
  provider: pages # for github page
  skip-cleanup: true
  github-token: # access token
  keep-history: true
  target_branch: master # deploy branch
  on:
    branch: blog
  local-dir: public # target dir

notifications:
  email:
    - # email that receive the notifications
  on_success: change
  on_failure: always
```

# 脱离Hexo依赖
既然我们已经完成了自动化部署，那么本地就完全无需依赖hexo了。脱离了hexo框架，我们就可以随时随地进行写博，即使更换设备，也只需在GitHub上进行文章的同步。
为了能够摆脱hexo的依赖，我们先要考虑到我们现在还需要hexo的哪些功能。hexo的生成和部署现在已经有Travis CI帮助我们完成了，剩下的好像只有`hexo new`生成文章的功能了。解决文章生成后，还注意到，整个hexo项目的结构是很复杂的，里面还包含了theme的文件，如果每次同步都要拉取这些文件，则会显得很笨重而且很慢，不符合我们想要的便捷，而且我们不需要对这些文件进行修改。

## 解决方法
对于`hexo new`，其实该功能就是根据`scaffolds`目录下的模板进行自动生成，这功能我们通过shell就能轻松解决。下面的命令可以写在脚本里，方便每次执行。
```shell script
# newpost.sh
# format the date
sed "s/{{ date }}/$(date +"%Y-%m-%d %H:%M:%S")/g" ./scaffolds/post.md >> ./source/_posts/$1.md
```

对于比较庞大的hexo项目结构，我们可以利用git自带的`sparse-checkout`功能，指定某些文件/文件夹，然后git只会更新/拉取这些文件，通过该功能，我们就轻易地达到解耦的目的，后续写博客也无需再关心非博客的文件结构了。
```shell script
git init
git remote add -f origin #your git url
git config core.sparsecheckout true
echo "source\nscaffolds\nnewpost.sh" > .git/info/sparse-checkout #windows下需要添加-e参数
git pull origin blog #the branch you deploy from
git checkout -b blog
echo "Init finish! Just starting write!"
```

按着命令敲完后就可以愉快地开始写博啦！
```shell script
# create a new post
./newpost.sh <filename>
```
