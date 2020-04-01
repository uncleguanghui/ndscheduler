FROM python:3.6
MAINTAINER guanghui.zhang

WORKDIR /app

ENV NDSCHEDULER_SETTINGS_MODULE=simple_scheduler.settings
EXPOSE 8888

COPY pip.conf /etc/pip.conf
COPY requirements.txt .
COPY ndscheduler ndscheduler
COPY simple_scheduler simple_scheduler

RUN pip install -r requirements.txt && pip install -r simple_scheduler/requirements.txt

CMD PYTHONPATH=. python simple_scheduler/scheduler.py
