## 这套配置文件的目标
* 满足C/C++、PHP、Python、JAVA以及Common Lisp（ELisp）开发人员的一般需求
    * JAVA支持采用eclim+eclipse
* 支持多个系统图形界面和命令行界面
    * 目前支持OS X图形界面，OS X终端，CentOS 终端， Ubuntu 终端

## 感谢
感谢原作者[tuhdo](https://github.com/tuhdo "")，这份配置以tuhdo的配置为基础不断修改。

## 特点：
* 为 C/C++、PHP、Python、Common Lisp编程进行专门定制，满足代码编写过程中快速浏览代码、代码提醒/补足等需要。
* 代码阅读和编写支持
    * 通过company进行代码补全。
    * 使用GTAGS、ETAGS帮助阅读代码。 
    * 统一C/C++、PHP、Python在阅读过程中代码的跳转使用的快捷键等。
    * python使用jedi来完成代码补足的功能。 
* 项目管理
    * 使用projectile 进行项目管理，可以快速的在项目内部查找文件，在项目中grep，在和helm结合起来使用后，非常方便，唯一的缺点是，在数千个文件构成的项目初始化时需要约1分钟的初始化时间。[projectile项目](https://github.com/bbatsov/projectile "")在此。
* ANYTHING
    * 使用强大的helm,参考[helm项目](https://emacs-helm.github.io/helm/ "")在此。
    * Helm是Emacs的增量选择框架，具体一点类似google search框当中给你的输入提示，但是强大很多，可以支持的范围很广，包括查找文件是，打开的buffer等，可以这么说，用过helm才会知道写代码的时候需要记住的东西可以那么少，而要找到的时候又是那么快
    * 需要特别说明的是，当你用了Helm以后，emacs的快捷键记不住也没什么，你可以用过helm-M-x命令（该配置已经绑定在M-x）来快速的查找适合的命令。

* 强大的编辑能力
    * undo-tree可以有效地管理你的编辑历史，提供类树形图形管理界面。
    * helm-ring.el提供了一套工具，能够帮你展示之前你copy-cut(使用更准确的emacs用语kill)的内容，本配置中使用M-y(命令helm-show-kill-ring）就能展示你的编辑历史中使用过的编辑历史，使用C-n,C-p可以来回查看，RET（回车）即可把内容复制到当前的光标位置。
* 拥有几套theme，可以耍酷。
    * 自动识别代码文件的编码（使用unicad)
* 当前emacs自带的package也非常强大，比如，org-mode非常适合写作和管理TODO-LIST。
* 自动加载配置文件依赖的包文件。
    * 个别还未纳入package archives管理的包，放在manual-install目录下管理（包括自动识别文件编码的unicad)
* 可以不依赖于系统提供的外部输入法，使用chinese-pyim包，无缝的在中英文输入之间切换（其实还是有点缝...)

# 使用方法简介
## emacs安装：
当然需要先安装emacs，mac系统个人推荐 http://emacsformacosx.com/  。

## 配置文件的使用
使用方法:  
<pre><code>
cd
git clone https://github.com/quanyufang/emacs-config-files .emacs.d
</code></pre>

## 常用命令
我整理了该配置下可以使用的命令，还比较初级，但基本常用的都能找到 ，见  [EmacsCommand.md](https://github.com/quanyufang/emacs-config-files/blob/master/EmacsCommand.md "")

# 注意事项：
* 第一次打开运行eamcs时，需要下载所有依赖的包，需要消耗一些时间，主要是从melpa.milkbox.net下载需要的包。
* 最近几次测试访问melpa.milkbox.net:80速度已经可以接受，但还是需要十分钟左右时间下载。
* (or (= emacs-major-version 24) (= emacs-major-version 25))。低于24版的版本不行。如果当您使用到emacs25需要到php-mode 下执行rm *.elc,具体的原因我还没有分析。
* CentOS上面我使用源码安装GNU Global


# python注意事项:
1. 参考 http://tkf.github.io/emacs-jedi/latest/ 
2. 我们把一些快捷键尽量统一了，可以参考custom/setup-programming.el

# GTAGS使用(GNU GLOBAL)
* 为什么选用GTAGS?
    * 对GNU Global进行了解之后，特别是快速所以符号引用，对于阅读代码来说这个是非常高效的，这是对比etags的一个重要优势，但是支持得语言比etags少，比如Lisp就不支持，不过写Lisp程序的人也比较少。
    * 确实更快，对比一般IDE，你可以在每次操作赢得1秒以上的操作性能和数秒的查询性能（当然IDE也在改进），这个数是我的主观体验。而且我说的是你在8G+ 内存和SSD硬盘这样的机器上。
    * 建立的索引更多。
* 这个配置中为方便使用GTAGS做了哪些定制？
    * 尽量统一不同语言使用GTAGS的快捷键。
* 外部依赖
    * 这个配置中C/C++和PHP代码使用gtags，在OS X上面使用Homebrew安装global即可。安装完成之后，在项目目录下面执行gtags，也可以使用helm提供的命令直接在emacs内部生产和更新tags(helm-gtags-update-tags)


# Lisp注意事项:
1. 目前gtags还不支持lisp语言，使用etags来建立标签: 
示例：find . -name "*.el"|xargs etags。


# flycheck的说明：

1.通过执行 M-x flycheck-verify-setup 检查当前语言需要的lint工具是否准备好了

2.不同的语言需要在不同的OS下，需要的lint工具有所不同，查询对应的安装工具来安装相应的工具。我在OS X下使用Homebrew安装相应工具，比如php语言的支持
brew install homebrew/php/php-code-sniffer homebrew/php/phpmd
