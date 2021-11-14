import pandas as pd
import FinanceDataReader as fdr

avg = 0.414 # AVG spread

start_date = pd.to_datetime('1970-01-01')  ## 시작 날짜
end_date = pd.to_datetime('2050-02-01')  ## 마지막 날짜

dates = pd.date_range(start_date, end_date, freq='d')  ## 월단위로 생성

Tr= fdr.DataReader('DGS1', data_source='fred')
a = pd.DataFrame(data = dates, columns=['dates'])
a = a.set_index('dates')
Tr = pd.concat([Tr,a],axis=1)
Tr['Date'] = Tr.index
Tr['Date'] = pd.to_datetime(Tr['Date'])
Tr = Tr.groupby(Tr['Date'].dt.strftime('%Y-%m'))['DGS1'].first().reset_index()
Tr['Date'] = Tr['Date'] + '-01'
Tr = Tr.set_index('Date')

Tr7= fdr.DataReader('DGS7',  start='2000-01-01', data_source='fred')
Tr7['Date'] = Tr7.index
Tr7['Date'] = pd.to_datetime(Tr7['Date'])
Tr7 = Tr7.groupby(Tr7['Date'].dt.strftime('%Y-%m'))['DGS7'].first().reset_index()
Tr7['Date'] = Tr7['Date'] + '-01'
Tr7 = Tr7.set_index('Date')

Tr = pd.concat([Tr,Tr7],axis=1)
Tr.to_excel('Tr.xlsx')

FRM= fdr.DataReader('MORTGAGE30US', start='2000-01-01', data_source='fred')
FRM['Date'] = FRM.index
FRM['Date'] = pd.to_datetime(FRM['Date'])
FRM = FRM.groupby(FRM['Date'].dt.strftime('%Y-%m'))['MORTGAGE30US'].first().reset_index()
FRM = FRM.set_index('Date')

ARM5= fdr.DataReader('MORTGAGE5US', start='2005-01-01', data_source='fred')
ARM5['Date'] = ARM5.index
ARM5['Date'] = pd.to_datetime(ARM5['Date'])
ARM5 = ARM5.groupby(ARM5['Date'].dt.strftime('%Y-%m'))['MORTGAGE5US'].first().reset_index()
ARM5 = ARM5.set_index('Date')

ARM5M= fdr.DataReader('MORTMRGN5US', start='2005-01-01', data_source='fred')
ARM5M['Date'] = ARM5M.index
ARM5M['Date'] = pd.to_datetime(ARM5M['Date'])
ARM5M = ARM5M.groupby(ARM5M['Date'].dt.strftime('%Y-%m'))['MORTMRGN5US'].first().reset_index()
ARM5M = ARM5M.set_index('Date')

ARM5_= fdr.DataReader('MORTGAGE5US', start='2005-01-01', data_source='fred')
ARM5M_= fdr.DataReader('MORTMRGN5US', start='2005-01-01', data_source='fred')

ARM5A = ARM5_.loc["2016-1-7":]-avg
ARM5MA = ARM5M_.loc["2016-1-7":]

ARM5A = ARM5A.rename(columns = {'MORTGAGE5US':'MORTGAGE1US'})
ARM5MA = ARM5MA.rename(columns = {'MORTMRGN5US':'MORTMRGN1US'})

ARM1= fdr.DataReader('MORTGAGE1US', start='2005-01-01', data_source='fred')
ARM1 = pd.concat([ARM1,ARM5A])
ARM1['Date'] = ARM1.index
ARM1['Date'] = pd.to_datetime(ARM1['Date'])
ARM1 = ARM1.groupby(ARM1['Date'].dt.strftime('%Y-%m'))['MORTGAGE1US'].first().reset_index()
ARM1 = ARM1.set_index('Date')

ARM1M= fdr.DataReader('MORTMRGN1US', start='2005-01-01', data_source='fred')
ARM1M = pd.concat([ARM1M,ARM5MA])
ARM1M['Date'] = ARM1M.index
ARM1M['Date'] = pd.to_datetime(ARM1M['Date'])
ARM1M = ARM1M.groupby(ARM1M['Date'].dt.strftime('%Y-%m'))['MORTMRGN1US'].first().reset_index()
ARM1M = ARM1M.set_index('Date')

ARM5_= fdr.DataReader('MORTGAGE5US', start='2005-01-01', data_source='fred')
ARM1_= fdr.DataReader('MORTGAGE1US', start='2005-01-01', data_source='fred')
ARM5_ = ARM5_.rename(columns = {'MORTGAGE5US':'MORTGAGE3US'})
ARM1_ = ARM1_.rename(columns = {'MORTGAGE1US':'MORTGAGE3US'})
ARM3 = (ARM5_+ARM1_)/2
ARM3['Date'] = ARM3.index
ARM3['Date'] = pd.to_datetime(ARM3['Date'])
ARM3 = ARM3.groupby(ARM3['Date'].dt.strftime('%Y-%m'))['MORTGAGE3US'].first().reset_index()
ARM3 = ARM3.set_index('Date')

ARM5M_= fdr.DataReader('MORTMRGN5US', start='2005-01-01', data_source='fred')
ARM3M = ARM5M_.rename(columns = {'MORTMRGN5US':'MORTMRGN3US'})
ARM3M['Date'] = ARM3M.index
ARM3M['Date'] = pd.to_datetime(ARM3M['Date'])
ARM3M = ARM3M.groupby(ARM3M['Date'].dt.strftime('%Y-%m'))['MORTMRGN3US'].first().reset_index()
ARM3M = ARM3M.set_index('Date')

FRM_ARM = pd.concat([FRM,ARM5,ARM5M,ARM1,ARM1M,ARM3,ARM3M],axis=1)
FRM_ARM.to_excel('FRM_ARM.xlsx')