# 本项目的作用

让小爱音箱连接ChatGPT，部署在群晖的linux系统上

# 步骤

- 在群晖网页后台安装python

- 在群晖网页后台的控制面板中开启ssh登录，参考

> <https://blog.csdn.net/stone0823/article/details/120823717/>

- ssh登录到群晖的linux，用户名和密码与登录群晖网页后台的一样

- 获取root权限

> sudo su

- 获取pip安装脚本：

> wget https://bootstrap.pypa.io/get-pip.py

- 安装pip：

> python get-pip.py

- 安装pandora：

> pip install pandora-chatgpt

- 获取openAI的access token，参考：

> <https://github.com/pengzhile/pandora#%E4%BD%93%E9%AA%8C%E5%9C%B0%E5%9D%80>里面的拿Token部分

- 新建一个文件token.txt，将token贴在里面，然后运行：

> pandora --server 127.0.0.1:45555 --token_file token.txt --verbose

- 手动安装dart sdk（因为没有包管理器）

> 参考 <https://dart.dev/get-dart/archive> 的Linux部分

- 下载本项目代码

- 重命名config.example.json=>config.json，并填入你的小米账号，以及小爱音箱的设备ID（DID）、型号（hardware），ID和型号的获取可参考

> <https://github.com/Yonsm/MiService>

- ssh到群晖linux，进入项目script目录执行：

> ./compile.sh
>
> 如果提示没有权限，可能要先chmod一下

- 运行编译好的程序

> dart_gpt