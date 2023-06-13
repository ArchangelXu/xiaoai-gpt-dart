# 本项目的作用

让小爱音箱连接ChatGPT，部署在群晖的linux系统（或其他linux和mac系统）上

# 步骤

## 准备工作

### 群晖环境

>- 在群晖网页后台安装python
>
>- 在群晖网页后台的控制面板中开启ssh登录，参考
>
>> <https://blog.csdn.net/stone0823/article/details/120823717/>
>
>- ssh登录到群晖的linux，用户名和密码与登录群晖网页后台的一样
>
>- 手动安装dart sdk（因为没有包管理器）
>
>> 参考 <https://dart.dev/get-dart/archive> 的Linux部分

### linux或者mac环境

>> 注意：不可部署在云服务器上，会被风控导致调用失败
>
>- 安装python
>> 参考 <https://www.python.org/downloads/>
>
>- 安装dart sdk
>
>> 参考 <https://dart.dev/get-dart>

## 部署

- 获取openAI的access token，参考：

> <https://github.com/pengzhile/pandora#%E4%BD%93%E9%AA%8C%E5%9C%B0%E5%9D%80>里面的拿Token部分

- 将本项目代码下载到目标机器上，进入项目目录

- 重命名config.example.json => config.json，并填入相关信息（以*开头的都需要填）

- 进入scripts目录，执行
> ./build.sh
> （如果提示没有权限，可能要先chmod一下）

- 结束后执行
> ./run.sh

- 也可以执行以下命令打包可执行文件。但dart不支持跨平台编译，只能编译成当前机器平台的可执行文件。
换句话说在x86架构的mac上打包后不能在m1芯片的mac上运行，也不能在arm架构的群晖linux上运行。
所以推荐在要运行服务的机器上打包

> ./compile.sh
- 这个脚本运行后会在output目录下生成dart_gpt文件。可以复制到项目目录使用以下命令执行
> ./dart_gpt

# 截图
![screenshot](https://raw.githubusercontent.com/ArchangelXu/xiaoai-gpt-dart/main/screenshot.png)