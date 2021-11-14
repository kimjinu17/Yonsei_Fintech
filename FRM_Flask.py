import json
from time import time
from flask import Flask, render_template, make_response
import psutil
import pandas as pd
import FinanceDataReader as fdr

i = 0

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/live_resource') +  +
def live_resource():
    global i
    ### matlab 데이터 불러오기
    result = pd.read_excel('result.xlsx')
    Eshock_an_nosa_norefin = result["Ecost_an_refin"]

    start_date = pd.to_datetime('2005-01-01')  ## 시작 날짜
    end_date = pd.to_datetime('2010-01-01')  ## 마지막 날짜

    time1 = pd.date_range(start_date, end_date, freq='M')  ## 월단위로 생성

    data1 = time1[i].strftime('%Y-%m-%d %H:%M:%S')
    data2 = Eshock_an_nosa_norefin[i]

    data = [data1, data2]
    print(i)
    i = i + 1
    response = make_response(json.dumps(data))
    response.content_type = 'application/json'
    return response


if __name__ == '__main__':
    app.run(debug=True)