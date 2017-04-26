from flask import Flask
from redis import Redis
import os
import socket

app = Flask(__name__)
redis = Redis(host='redis', port=6379)

@app.route('/')
def hello():
    count = redis.incr('hits')
    return 'Hello! I am tiny service on <br> Hostname:"'+socket.gethostname()+'"<br> Color:"'+ os.getenv("COLOR", 'uncolored') + '"<br> Version:"'+ os.getenv("TAG", 'Not defined,') +'"<br> Visit count:{} times.\n'.format(count)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv('PORT', 8080)), debug=True)
