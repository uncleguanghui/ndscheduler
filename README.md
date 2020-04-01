# Nextdoor Scheduler

![Apache](https://img.shields.io/hexpm/l/plug.svg) 
[![Build Status](https://travis-ci.org/Nextdoor/ndscheduler.svg)](https://travis-ci.org/Nextdoor/ndscheduler)

## docker 的 python3 支持改造

非常感谢 Nextdoor 提供的这个任务调度平台~

新手教程已经很详细了，但我发现 Nextdoor 提供的 docker 镜像并不支持 python3，所以自己稍加改造，使用说明如下：

### 运行容器

首先构建一个名为 scheduler 的镜像

```
 docker build -t scheduler . 
```

由于新的任务并不方便添加到容器中，所以在外部创建一个脚本文件夹，并挂在到容器上。那么新的脚本就可以直接放在这个文件夹下面使用了。

我的新文件夹地址是本地的 /docker_data/scheduler_jobs

```
sudo mkdir -p /docker_data/scheduler_jobs
```

然后，启动容器

```
docker run -itd --restart=always --name scheduler -p 3222:8888 -v /docker_data/scheduler_jobs:/app/simple_scheduler/jobs scheduler
```

参数说明：

* -i：让容器的标准输入保持打开
* -t：让 Docker 分配一个伪终端并绑定到容器的标准输入上
* -d: 后台运行容器，并返回容器ID
* --restart=always：当 Docker 重启时，容器会自动启动。
* --name scheduler：将容器命名为scheduler
* -p 3222:8888 ：映射容器服务的 8888 端口到宿主机的 3222 端口(也可以改成别的)，外部主机可以直接通过宿主机 IP:3222 访问到服务。
* -v /docker_data/scheduler_jobs:/app/simple_scheduler/jobs: 挂载脚本目录

大功告成，打开浏览器输入 localhost:3222 即可看到。

### 添加任务

首先将任务脚本文件放在 /docker_data/scheduler_jobs 下，格式如 simple_scheduler/jobs 下的样例，然后在网页上就可以正常管理任务了。

如果任务文件要引入新的模块，如何在 docker 里 pip install 新的模块呢？

首先进入容器

```
docker exec -it scheduler bash
```

然后安装模块

```
pip install xxxx
```

最后退出即可

```
exit
```

以下是原文。

----

``ndscheduler`` is a flexible python library for building your own cron-like system to schedule jobs, which is to run a tornado process to serve REST APIs and a web ui.

Check out our blog post - [We Don't Run Cron Jobs at Nextdoor](https://engblog.nextdoor.com/we-don-t-run-cron-jobs-at-nextdoor-6f7f9cc62040#.d2erw1pl6)

**``ndscheduler`` currently supports Python 2 & 3 on Mac OS X / Linux.**

## Table of contents
  
  * [Key Abstractions](#key-abstractions)
  * [Try it NOW](#try-it-now)
  * [How to build Your own cron-replacement](#how-to-build-your-own-cron-replacement)
    * [Install ndscheduler](#install-ndscheduler)
    * [Three things](#three-things)
    * [Reference Implementation](#reference-implementation)   
  * [Contribute code to ndscheduler](#contribute-code-to-ndscheduler)
  * [REST APIs](#rest-apis)
  * [Web UI](#web-ui)

## Key Abstractions

* [CoreScheduler](https://github.com/Nextdoor/ndscheduler/tree/master/ndscheduler/corescheduler): encapsulates all core scheduling functionality, and consists of:
  * [Datastore](https://github.com/Nextdoor/ndscheduler/tree/master/ndscheduler/corescheduler/datastore): manages database connections and makes queries; could support Postgres, MySQL, and sqlite.
    * Job: represents a schedule job and decides how to run a paricular job.
    * Execution: represents an instance of job execution.
    * AuditLog: logs when and who runs what job.
  * [ScheduleManager](https://github.com/Nextdoor/ndscheduler/blob/master/ndscheduler/corescheduler/scheduler_manager.py): access Datastore to manage jobs, i.e., schedule/modify/delete/pause/resume a job.
* [Server](https://github.com/Nextdoor/ndscheduler/tree/master/ndscheduler/server): a tornado server that runs ScheduleManager and provides REST APIs and serves UI.
* [Web UI](https://github.com/Nextdoor/ndscheduler/tree/master/ndscheduler/static): a single page HTML app; this is a default implementation.

Note: ``corescheduler`` can also be used independently within your own service if you use a different Tornado server / Web UI.

## Try it NOW

From source code:

    git clone https://github.com/Nextdoor/ndscheduler.git
    cd ndscheduler
    make simple

Or use docker:

    docker run -it -p 8888:8888 wenbinf/ndscheduler
    
Open your browser and go to [localhost:8888](http://localhost:8888). 

**Demo**
(Click for fullscreen play)
![ndscheduler demo](https://giant.gfycat.com/NastyBossyBeaver.gif)

## How to build Your own cron-replacement

### Install ndscheduler
Using pip (from GitHub repo)

    #
    # Put this in requirements.txt, then run
    #    pip install -r requirements.txt
    #

    # If you want the latest build
    git+https://github.com/Nextdoor/ndscheduler.git#egg=ndscheduler

    # Or put this if you want a specific commit
    git+https://github.com/Nextdoor/ndscheduler.git@5843322ebb440d324ca5a66ba55fea1fd00dabe8

    # Or put this if you want a specific tag version
    git+https://github.com/Nextdoor/ndscheduler.git@v0.1.0#egg=ndscheduler
    
    #
    # Run from command line
    #

    pip install -e git+https://github.com/Nextdoor/ndscheduler.git#egg=ndscheduler

(We'll upload the package to PyPI soon.)

### Three things

You have to implement three things for your scheduler, i.e., ``Settings``, ``Server``, and ``Jobs``.

**Settings**

In your implementation, you need to provide a settings file to override default settings (e.g., [settings in simple_scheduler](https://github.com/Nextdoor/ndscheduler/blob/master/simple_scheduler/settings.py)). You need to specify the python import path in the environment variable ``NDSCHEDULER_SETTINGS_MODULE`` before running the server.

All available settings can be found in [default_settings.py](https://github.com/Nextdoor/ndscheduler/blob/master/ndscheduler/default_settings.py) file.

**Server**

You need to have a server file to import and run ``ndscheduler.server.server.SchedulerServer``.

**Jobs**

Each job should be a standalone class that is a subclass of ``ndscheduler.job.JobBase`` and put the main logic of the job in ``run()`` function.

After you set up ``Settings``, ``Server`` and ``Jobs``, you can run the whole thing like this:

    NDSCHEDULER_SETTINGS_MODULE=simple_scheduler.settings \
    PYTHONPATH=.:$(PYTHONPATH) \
		    python simple_scheduler/scheduler.py
		  
### Upgrading

It is best practice to backup your database before doing any upgrade. ndscheduler relies on [apscheduler](https://apscheduler.readthedocs.io/en/latest/) to serialize jobs to the database, and while it is usually backwards-compatible (i.e. jobs created with an older version of apscheduler will continue to work after upgrading apscheduler) this is not guaranteed, and it is known that downgrading apscheduler can cause issues. See [this PR comment](https://github.com/Nextdoor/ndscheduler/pull/54#issue-262152050) for more details.

### Reference Implementation

See code in the [simple_scheduler/](https://github.com/Nextdoor/ndscheduler/tree/master/simple_scheduler) directory for inspiration :)

Run it

    make simple
    
Access the web ui via [localhost:8888](http://localhost:8888)

The reference implementation also comes with [several sample jobs](https://github.com/Nextdoor/ndscheduler/tree/master/simple_scheduler/jobs).
* AwesomeJob: it just prints out 2 arguments you pass in.
* SlackJob: it sends a slack message periodically, for example, team standup reminder.
* ShellJob: it runs an executable command, for example, run curl to crawl web pages.
* CurlJob: it's like running [curl](http://curl.haxx.se/) periodically.

And it's [dockerized](https://github.com/Nextdoor/ndscheduler/tree/master/simple_scheduler/docker).

## Contribute code to ndscheduler

**Install dependencies**

    # Each time we introduce a new dependency in setup.py, you have to run this
    make install

**Run unit tests**

    make test
    
**Clean everything and start from scratch**
    
    make clean

Finally, send pull request. Please make sure the [CI](https://travis-ci.org/Nextdoor/ndscheduler) passes for your PR.

## REST APIs

Please see [README.md in ndscheduler/server/handlers](https://github.com/Nextdoor/ndscheduler/blob/master/ndscheduler/server/handlers/README.md).

## Web UI

We provide a default implementation of web ui. You can replace the default web ui by overwriting these settings

    STATIC_DIR_PATH = :static asset directory paths:
    TEMPLATE_DIR_PATH = :template directory path:
    APP_INDEX_PAGE = :the file name of the single page app's html:
    
### The default web ui

**List of jobs**

![List of jobs](http://i.imgur.com/dGILbkZ.png)

**List of executions**

![List of executions](http://i.imgur.com/JpjzrlU.png)

**Audit Logs**

![Audit logs](http://i.imgur.com/eHLzHhw.png)

**Modify a job**

![Modify a job](http://i.imgur.com/aWv6xOR.png)
