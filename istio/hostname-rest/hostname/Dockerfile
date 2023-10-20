# 使用python:3.9-slim作为基础镜像，它是一个精简的Python镜像，适合用于生产环境
FROM python:3.9

# 设置工作目录为/app
WORKDIR /app

# 复制当前目录下的所有文件到/app目录
COPY ./hostname.py /app/

# 安装flask和requests模块
RUN pip install flask requests

# 暴露5000端口
EXPOSE 80

# 设置环境变量FLASK_APP为app.py
ENV FLASK_APP hostname.py

# 使用gunicorn作为生产WSGI服务器，启动4个工作进程，监听0.0.0.0:5000地址
CMD ["flask", "run", "--host=0.0.0.0", "--port=80"]

