import json
from time import time
from flask import Flask, render_template, make_response
import psutil
import pandas as pd
import FinanceDataReader as fdr

### matlab 데이터 불러오기
i = 0
result = pd.read_excel('result.xlsx')
Eshock_an_nosa_norefin = result["Eshock_an_nosa_norefin"]

start_date = pd.to_datetime('2005-01-01')  ## 시작 날짜
end_date = pd.to_datetime('2010-01-01')  ## 마지막 날짜

time2 = pd.date_range(start_date, end_date, freq='M')  ## 월단위로 생성

data1 = Eshock_an_nosa_norefin[i]
data2 = time2[i].strftime('%Y-%m-%d %H:%M:%S')

print(data1,data2)

cpu = psutil.cpu_percent()
data = [data2, data1]
a = json.dumps(data)
print(a)

print(int(time()%10))

