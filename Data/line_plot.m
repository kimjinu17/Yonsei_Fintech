load('v20_40_f1')
Eshock_an_nosa_norefin = Eshock_an_nosa
Eshock_an_sa_norefin = Eshock_an_sa
Ecost_an_norefin = Efrmcost_an

load('v20_refin_40_f1')
Eshock_an_nosa_refin = Eshock_an_nosa
Eshock_an_sa_refin = Eshock_an_sa
Ecost_an_refin = Efrmcost_an

t1 = datetime(2005,01,01);
t = dateshift(t1,'start','month',0:60)
 
nexttile
area(t,Eshock_an_nosa_refin,'FaceColor','r','FaceAlpha',.3,'EdgeAlpha',.3)
hold on
area(t,Eshock_an_nosa_norefin,'FaceColor','w')
hold on
area(t,Eshock_an_sa_refin,'FaceColor','b','FaceAlpha',.3,'EdgeAlpha',.3)
hold on
area(t,Eshock_an_sa_norefin,'FaceColor','w')
hold off
 
nexttile
area(t,Ecost_an_norefin,'FaceColor','b','FaceAlpha',.3,'EdgeAlpha',.3, 'basevalue',-10)
hold on
area(t,Ecost_an_refin,'FaceColor','w','basevalue', -30)
hold off
