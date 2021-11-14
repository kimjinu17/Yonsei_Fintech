load('v20_40_f1')
Eshock_an_nosa_norefin = Eshock_an_nosa
Eshock_an_sa_norefin = Eshock_an_sa
Ecost_an_norefin = Efrmcost_an

load('v20_refin_40_f1')
Eshock_an_nosa_refin = Eshock_an_nosa
Eshock_an_sa_refin = Eshock_an_sa
Ecost_an_refin = Efrmcost_an

filename = "result.xlsx";
T = table(Eshock_an_nosa_norefin, Eshock_an_sa_norefin, Ecost_an_norefin, Eshock_an_nosa_refin, Eshock_an_sa_refin, Ecost_an_refin)
writetable(T,filename,'Sheet','MyNewSheet');
