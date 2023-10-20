# 导入flask模块
from flask import Flask, jsonify, request
# 导入requests模块，用于发送HTTP请求
import requests
import logging

# 创建一个flask应用对象
app = Flask(__name__)
app.logger.setLevel(logging.DEBUG)

# 定义一个路由，响应GET请求
@app.route('/proxy', methods=['GET'])
def proxy_hostname():
    # 定义目标接口的URL
    target_url = 'http://anotherservice/hostname'
    # target_url = 'http://localhost:18080/hostname'
    
    query_str = request.query_string.decode()
    if not (None is query_str):
        target_url = target_url + '?' + query_str
    end_user = request.headers.get('end-user')
    
    app.logger.debug("call end_user: %s, url: %s", end_user, target_url)
    if None is end_user:
        response = requests.get(target_url)
    else:
        response = requests.get(target_url, headers = {'end-user': end_user})
    
    data = response.json()
    st = str(response.status_code);
    return jsonify({'data': data}), st

# 运行flask应用，监听5000端口
if __name__ == '__main__':
    app.run(port=5000)

