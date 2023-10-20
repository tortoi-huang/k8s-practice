# 导入flask模块
from flask import Flask, jsonify, request
# 导入socket模块，用于获取hostname
import socket
# 导入sys模块，用于获取命令行参数
import sys
import os
import random
import logging

# 创建一个flask应用对象
app = Flask(__name__)
app.logger.setLevel(logging.DEBUG)

def get_status_code():
    # 返回错误码的权重 200_400_500
    err_rate = os.getenv("my_err_rate")
    # app.logger.debug("my_err_rate: ", err_rate)
    if  None is err_rate or len(err_rate) < 3:
        return "200"
    
    err_rate_list = err_rate.split('_')
    if len(err_rate_list) < 2:
        return "200"
    if len(err_rate_list) == 2:
        err_rate_list.append(0)
    r2 = int(err_rate_list[0])
    r4 = int(err_rate_list[1])
    r5 = int(err_rate_list[2])
    rd = random.random()
    if rd <= r2 / (r2 + r4 + r5):
        return "200"
    if rd <= (r2 + r4) / (r2 + r4 + r5):
        return "400"
    return "500"

# 定义一个路由，响应GET请求
@app.route('/hostname', methods=['GET'])
def get_hostname():
    # 获取服务器的hostname
    hostname = socket.gethostname()
    st_code = get_status_code()
    end_user = request.headers.get('end-user')
    query_str = request.query_string.decode()
    return jsonify({'version': os.getenv("my_version"), 'statu_code': st_code, 'endUser': end_user, 'queryString': query_str, 'hostname': hostname}), st_code
    

# 运行flask应用，监听5000端口
if __name__ == '__main__':
    # 获取命令行参数列表，第一个元素是文件名，第二个元素是端口号（如果有）
    args = sys.argv
    # 如果参数列表长度大于1，说明提供了端口号，否则使用默认值5000
    nport = int(args[1]) if len(args) > 1 else 80
    # 启动flask应用，监听指定的端口号
    app.run(port=nport)


