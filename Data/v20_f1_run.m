for Y = 1:2 
    if Y == 1
        clc; clear all;

        %%% Set initial conditions for ARM %%%%%%%%%%%%%%%
        T = 30 ;   %    
        H = 10;    % Holding periods 
        people = 1  %������ 100
        n_intsimul = 10 % ������ 1000
        fixperiod = 5   % 5years Hybrid ARM�� ��� ���⼭ fixed rate�� ������ �Ⱓ�� �����Ѵ�. 1/1(��ǻ� �׳� ARM)�� ��� '1'�� �����ϸ� �ȴ�. 
        lookback = 10  %������ 10y, history �Ⱓ�� ������� ���� ���ΰ� , HP���Ϳ��� Ʈ����� �տ� 10�� �����ͷ� �״�� 
        loan =400000    % total loan amount

        %%% Input 1y short interest rate data %%%%%%%%%%%%
        [~,DateStrings_A] = xlsread('Tr','Sheet1','A422 : A963'); 
        Data_1y =  xlsread('Tr','Sheet1','B422 : B590'); 
        Data_1y=Data_1y/100;
        dates_A = datetime(DateStrings_A); %��¥�� ��Ʈ���� ������ �ִ� date time���� �о���̱�
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Input 1y old_short interest rate data %%%%%%%%%%%%
        % [~,DateStrings_A] = xlsread('Treasury_Constant_Maturity_Rate','5y_month','A72 : A240'); %12:2000.1, 72:2005.1,   191:2015.1,  240:2019.1
        [~,DateStrings_B] = xlsread('Tr','Sheet1','A2 : A963'); % 309: 1978.1  273: 1975.1
        Data_1y_b =  xlsread('Tr','Sheet1','B2 : B963'); 
        Data_1y_b=Data_1y_b/100;
        dates_B = datetime(DateStrings_B); %��¥�� ��Ʈ���� ������ �ִ� date time���� �о���̱�
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Input 7y interest rate data  %%%%%%%%%%%%%%%%
        Data_7y = xlsread('Tr','Sheet1','C422 : C963');
        Data_7y = Data_7y/100 ; 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Input FRM (30y) rate data %%%%%%%%%%%%%%%%%%%%
        Data_FRMrate =  xlsread('FRM_ARM','Sheet1','B62 : B230');  
        Data_FRMrate =Data_FRMrate/100 ;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Input ARM 5y initial rate data %%%%%%%%%%%%%%%
        Data_iniARM_5y =  xlsread('FRM_ARM','Sheet1','C62 : C230'); %initial rate�� Freddie������ ������ ���
        Data_marginARM_5y =  xlsread('FRM_ARM','Sheet1','D62 : D230'); %margin�� Freddie������ ������ ���
        Data_marginARM_5y = Data_marginARM_5y / 100;
        Data_iniARM_5y =Data_iniARM_5y/100 ;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Input ARM 1y initial rate data %%%%%%%%%%%%%%%
        Data_iniARM_1y =  xlsread('FRM_ARM','Sheet1','E62 : E230'); %initial rate�� Freddie������ ������ ��� (2015�� ���Ĵ� 5/1ARM���� ���spread�� ���־ ������ ���̴�)
        Data_marginARM_1y =  xlsread('FRM_ARM','Sheet1','F62 : F230'); %margin�� Freddie������ ������ ���
        Data_marginARM_1y = Data_marginARM_1y / 100;
        Data_iniARM_1y =Data_iniARM_1y/100 ;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Input ARM 3y initial rate data %%%%%%%%%%%%%%%
        Data_iniARM_3y =  xlsread('FRM_ARM','Sheet1','G62 : G230'); %initial rate�� Freddie������ ������ ��� (2015�� ���Ĵ� 5/1ARM���� ���spread�� ���־ ������ ���̴�)
        Data_marginARM_3y =  xlsread('FRM_ARM','Sheet1','H62 : H230'); %margin�� Freddie������ ������ ���
        Data_marginARM_3y = Data_marginARM_3y / 100;
        Data_iniARM_3y =Data_iniARM_3y/100 ;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


        if fixperiod ==1  %2015�� ������ ��� (out of sample forecasting������ ���� ����)
            Data_iniARM = Data_iniARM_1y;
            Data_marginARM = Data_marginARM_1y ;
        end

        if fixperiod ==3  %2015�� ������ ��� (out of sample forecasting������ ���� ����)
            Data_iniARM = Data_iniARM_3y;
            Data_marginARM = Data_marginARM_3y ;
        end

        if fixperiod ==5  %2015�� ������ ��� (out of sample forecasting������ ���� ����)
            Data_iniARM = Data_iniARM_5y;
            Data_marginARM = Data_marginARM_5y ;
        end

        ini_cap=0.02;  %initial cap   %�ٲ����~!!!! �������� 0.03
        anu_cap=0.02; % annual cap
        life_cap=0.05; % life time cap
        life_cap_rate_data = Data_iniARM + life_cap; % index �ִ��ѵ�  �̰� ������ ���Ⱑ �ƴϴ�~!!!!!!! ���� f3�ڵ带 �����Ұ� 

        moving_start = find(dates_A=='2005-1-1');  % ����� ����~!!! '2008-1-1'  '2010-1-1'
        moving_start_B = find(dates_B=='2005-1-1');  %
        history_B = moving_start_B - lookback*12;
        moving_end = find(dates_A=='2010-1-1');  % '2010-1-1' 2011-1-1' '2010-12-1'(�ִ�) ����� 8���ֱ������� 2011���� max��. 2011+8=2019���̿���.. 4���ֱ��̸� 2015+4=2019
        moving_end_B= moving_start_B + (moving_end - moving_start) ;


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Moving window period %%%%%%%%%%%%%%%%%%%%%%%%%
        an_itotal_avg2=[];  %�� start point���� i�� �ùķ��̼� ARM_ante ���� ���� ���  
        po_ARM_total2=[];  %�� start point���� i�� �ùķ��̼� ARM_ante ���� ���� ��� 
        benefitante = [];  %  ex_ante���ð� ex_post������ ���Ͽ� ex_ante������ benefit�� ����
        vasicek_coeff_hist=[]; %vasicek parameter ����
        FRM_pmt_total=[];  

        j=1;        %cell column�� start point�����϶����� �����δ�. 
        a1=0;   % moving window�� �ϳ��� �Ű��ִ� ��Ȱ

        for start_point= moving_start : moving_end  % moving window roop ����  (�������� 1���� �ؾ� ��. ���� 2���� �ҷ��� ������ ���� history�����͵� 2������ �����ؾ� �Ѵ�) 
            yearly_string = dates_A( start_point :12 : start_point + (H)*12 - 1 ); % ���⼭ ���� ���� vasicek���� �׸� �׸��� x�� ��¥ ǥ���Ҷ� ����Ѵ�. ���� �������� short rate�� ���� ��ǥ�ϴ� rate���� �ϰ� 
                                                                                 % maturity day���� �ش� ���� ���� ��ǥ�ϴ� rate���� ����

            Discountrate = Data_7y (start_point);   % NPV ������ 
            margin_rate = Data_marginARM (start_point);    %�ش�⵵ ARM margin��
            %%% FRM %%%%%%%%%%%%%%%%%%%%%%
            long_rate =Data_FRMrate; 
            FRM_rate=long_rate(start_point) ;    % FRM ���� ����ϴ� ������ 

            [FRM_i] =fn_FRM( FRM_rate, loan, H, T );    % fn_FRM without refinancing option

            FRM_pmt = FRM_i(1,3);    %refinanace option�� ������ ���⸦  FRM_pmt = FRM_i(:,3) �� �ٲپ�� �Ѵ�. 
            FRM_pmt_total(end+1,1) = FRM_pmt ; 
            FRM_endvalue_H = FRM_i(H*12,6); 

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            %%% ARM Post %%%%%%%%%%%%%%%%%
            initial_rate = Data_iniARM(start_point);  %start point�� ���� initial rate�� �ٲ��. initial rate�� Freddie������ ������ ���
            life_cap_rate = life_cap_rate_data(start_point);
            po_short_rate=Data_1y( start_point :12: start_point + H*12 - 1 ); %�ŷ��������� ���Ե� ���� �ش�⵵�� ��ǥ�ϴ� short rate�� �ǰ�, ���� �ص� �Ȱ��� �ش� ���� �ش� �⵵�� short rate�� �ȴ�.
            [po_ARM_total] = fn_ARM_POST_6(po_short_rate, T, H, loan, fixperiod, margin_rate, initial_rate, ini_cap,  anu_cap, life_cap_rate, FRM_pmt, FRM_rate, FRM_endvalue_H, Discountrate); % fn_post
            po_ARM_total2(end+1,:) = [ po_ARM_total ];   %npv_all, shock1, shock2, AVG_size_shock, risk_index, risk_ARM, ARM_IRR
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            %%% simulation interest rate %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            history_data=Data_1y_b(history_B+a1 : 12 : moving_start_B+a1) ; 
            [X, obj, t, short_trend, vasicek_coeff] = fn_shortrate6_nova_HP(history_data, H);  %fn_interest simulation �ʱ��۾� (interest_simulation_initial2) 
            vasicek_coeff_hist(end+1,:) = vasicek_coeff ;  %vasicek coefficient ����
            for i=1:people % cycle of same routine(���� ������ڿ� ����� ����� �����Ұ����� �����Ѵ�, 100�̸� 100���� ����� �ùķ��̼� ����� ���� ������ ���� ��ȯ�Ѵ�)

            %%% ARM ante     
            [an_itotal_avg] = fn_ARM_ante_11(obj, X, t, T, H, loan, fixperiod, margin_rate, initial_rate, ini_cap,  anu_cap, life_cap_rate, FRM_pmt, FRM_rate, yearly_string, FRM_endvalue_H, Discountrate, n_intsimul, po_short_rate,short_trend, vasicek_coeff); 
            an_itotal_avg2{i,j} = [ an_itotal_avg ]; % npv_all, shock1, shock2, AVG_size_shock, risk_index, risk_ARM, ARM_IRR
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            end  % i cycle end   

            j=j+1;  %cell column�� start point�����϶����� �����δ�.  
            a1=a1+1;  % moving window������ cycle�� �ϳ��� ������Ų��.    
        end   % moving window roop����
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%
        Eshock_an_nosa=[];

        for ii=1:size(an_itotal_avg2, 1)  %����Ŭ��

            for jj=1:size(an_itotal_avg2, 2)  %
               Eshock_an_nosa(ii,jj)=an_itotal_avg2{ii,jj}(14);
            end

        end

        Eshock_an_nosa=mean(Eshock_an_nosa',2);
        %%
        Eshock_an_sa=[];

        for ii=1:size(an_itotal_avg2, 1)  %����Ŭ��

            for jj=1:size(an_itotal_avg2, 2)  %
               Eshock_an_sa(ii,jj)=an_itotal_avg2{ii,jj}(15);
            end

        end

        Eshock_an_sa=mean(Eshock_an_sa',2);
        %%
        Efrmcost_an=[];

        for ii=1:size(an_itotal_avg2, 1)  %����Ŭ��

            for jj=1:size(an_itotal_avg2, 2)  %
               Efrmcost_an(ii,jj)=an_itotal_avg2{ii,jj}(16);
            end

        end

        Efrmcost_an=mean(Efrmcost_an',2);

        save('v20_40_f1')

    else
        clc; clear all;

        %%% Set initial conditions for ARM %%%%%%%%%%%%%%%
        T = 30 ;   %    
        H = 10;    % Holding periods 
        people = 1  %������ 100
        n_intsimul = 10 % ������ 1000
        fixperiod = 1   % 5years Hybrid ARM�� ��� ���⼭ fixed rate�� ������ �Ⱓ�� �����Ѵ�. 1/1(��ǻ� �׳� ARM)�� ��� '1'�� �����ϸ� �ȴ�. 
        lookback = 10  %������ 10y, history �Ⱓ�� ������� ���� ���ΰ� , HP���Ϳ��� Ʈ����� �տ� 10�� �����ͷ� �״�� 
        loan =400000    % total loan amount

        %%% Input 1y short interest rate data %%%%%%%%%%%%
        [~,DateStrings_A] = xlsread('Tr','Sheet1','A422 : A963'); 
        Data_1y =  xlsread('Tr','Sheet1','B422 : B590'); 
        Data_1y=Data_1y/100;
        dates_A = datetime(DateStrings_A); %��¥�� ��Ʈ���� ������ �ִ� date time���� �о���̱�
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Input 1y old_short interest rate data %%%%%%%%%%%%
        % [~,DateStrings_A] = xlsread('Treasury_Constant_Maturity_Rate','5y_month','A72 : A240'); %12:2000.1, 72:2005.1,   191:2015.1,  240:2019.1
        [~,DateStrings_B] = xlsread('Tr','Sheet1','A2 : A963'); % 309: 1978.1  273: 1975.1
        Data_1y_b =  xlsread('Tr','Sheet1','B2 : B963'); 
        Data_1y_b=Data_1y_b/100;
        dates_B = datetime(DateStrings_B); %��¥�� ��Ʈ���� ������ �ִ� date time���� �о���̱�
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Input 7y interest rate data  %%%%%%%%%%%%%%%%
        Data_7y = xlsread('Tr','Sheet1','C422 : C963');
        Data_7y = Data_7y/100 ; 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Input FRM (30y) rate data %%%%%%%%%%%%%%%%%%%%
        Data_FRMrate =  xlsread('FRM_ARM','Sheet1','B62 : B230');  
        Data_FRMrate =Data_FRMrate/100 ;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Input ARM 5y initial rate data %%%%%%%%%%%%%%%
        Data_iniARM_5y =  xlsread('FRM_ARM','Sheet1','C62 : C230'); %initial rate�� Freddie������ ������ ���
        Data_marginARM_5y =  xlsread('FRM_ARM','Sheet1','D62 : D230'); %margin�� Freddie������ ������ ���
        Data_marginARM_5y = Data_marginARM_5y / 100;
        Data_iniARM_5y =Data_iniARM_5y/100 ;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Input ARM 1y initial rate data %%%%%%%%%%%%%%%
        Data_iniARM_1y =  xlsread('FRM_ARM','Sheet1','E62 : E230'); %initial rate�� Freddie������ ������ ��� (2015�� ���Ĵ� 5/1ARM���� ���spread�� ���־ ������ ���̴�)
        Data_marginARM_1y =  xlsread('FRM_ARM','Sheet1','F62 : F230'); %margin�� Freddie������ ������ ���
        Data_marginARM_1y = Data_marginARM_1y / 100;
        Data_iniARM_1y =Data_iniARM_1y/100 ;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Input ARM 3y initial rate data %%%%%%%%%%%%%%%
        Data_iniARM_3y =  xlsread('FRM_ARM','Sheet1','G62 : G230'); %initial rate�� Freddie������ ������ ��� (2015�� ���Ĵ� 5/1ARM���� ���spread�� ���־ ������ ���̴�)
        Data_marginARM_3y =  xlsread('FRM_ARM','Sheet1','H62 : H230'); %margin�� Freddie������ ������ ���
        Data_marginARM_3y = Data_marginARM_3y / 100;
        Data_iniARM_3y =Data_iniARM_3y/100 ;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


        if fixperiod ==1  %2015�� ������ ��� (out of sample forecasting������ ���� ����)
            Data_iniARM = Data_iniARM_1y;
            Data_marginARM = Data_marginARM_1y ;
        end

        if fixperiod ==3  %2015�� ������ ��� (out of sample forecasting������ ���� ����)
            Data_iniARM = Data_iniARM_3y;
            Data_marginARM = Data_marginARM_3y ;
        end

        if fixperiod ==5  %2015�� ������ ��� (out of sample forecasting������ ���� ����)
            Data_iniARM = Data_iniARM_5y;
            Data_marginARM = Data_marginARM_5y ;
        end

        ini_cap=0.02;  %initial cap   %�ٲ����~!!!! �������� 0.03
        anu_cap=0.02; % annual cap
        life_cap=0.05; % life time cap
        life_cap_rate_data = Data_iniARM + life_cap; % index �ִ��ѵ�  �̰� ������ ���Ⱑ �ƴϴ�~!!!!!!! ���� f3�ڵ带 �����Ұ� 

        moving_start = find(dates_A=='2005-1-1');  % ����� ����~!!! '2008-1-1'  '2010-1-1'
        moving_start_B = find(dates_B=='2005-1-1');  %
        history_B = moving_start_B - lookback*12;
        moving_end = find(dates_A=='2010-1-1');  % '2010-1-1' 2011-1-1' '2010-12-1'(�ִ�) ����� 8���ֱ������� 2011���� max��. 2011+8=2019���̿���.. 4���ֱ��̸� 2015+4=2019
        moving_end_B= moving_start_B + (moving_end - moving_start) ;

        %%% Moving window period %%%%%%%%%%%%%%%%%%%%%%%%%
        an_itotal_avg2=[];  %�� start point���� i�� �ùķ��̼� ARM_ante ���� ���� ���  
        po_ARM_total2=[];  %�� start point���� i�� �ùķ��̼� ARM_ante ���� ���� ��� 
        benefitante = [];  %  ex_ante���ð� ex_post������ ���Ͽ� ex_ante������ benefit�� ����
        po_NPV=[]; %po_npv���� �����Ͽ� �ڿ� ȸ�ͽĿ��� ��� Present value of FRM-ARM payment
        po_NPV2=[]; %FRM cost with saving�� ����
        vasicek_coeff_hist=[]; %vasicek parameter ����

        j=1;        %cell column�� start point�����϶����� �����δ�. 
        a1=0;   % moving window�� �ϳ��� �Ű��ִ� ��Ȱ

        for start_point= moving_start : moving_end  % moving window roop ����  (�������� 1���� �ؾ� ��. ���� 2���� �ҷ��� ������ ���� history�����͵� 2������ �����ؾ� �Ѵ�) 
            yearly_string = dates_A( start_point :12: start_point + (H)*12 - 1 ); % ���⼭ ���� ���� vasicek���� �׸� �׸��� x�� ��¥ ǥ���Ҷ� ����Ѵ�. ���� �������� short rate�� ���� ��ǥ�ϴ� rate���� �ϰ� 
                                                                                 % maturity day���� �ش� ���� ���� ��ǥ�ϴ� rate���� ����

            Discountrate = Data_7y (start_point);   % NPV ������ 
            margin_rate = Data_marginARM (start_point);    %�ش�⵵ ARM margin��
            %%% FRM %%%%%%%%%%%%%%%%%%%%%%
            long_rate =Data_FRMrate; 
            FRM_rate=long_rate(start_point) ;    % FRM ���� ����ϴ� ������ 

            po_long_rate = long_rate(start_point : start_point + (H-1)*12-1) ;   %refinancing�ϸ鼭 1�⸶�ٰ� �ƴ� �Ű������� �����Ͱ� �ʿ�. (�Ű��� ���� rate�� ���Ѵ�)
            %     [FRM_i] =fn_FRM( FRM_rate, loan, H, T );    % fn_FRM without refinancing option

            [FRM_i] = fn_FRM_refinance(FRM_rate, loan, H, T, po_long_rate );

            %���� refinancing option�� �ϸ� FRM_pmt�� �ϳ��� ���� �ƴ� seriese�� �ȴ�. 
            %%%%����~!  FRM �����̳ٽ� �ɼ� Ȯ���ϰ� ������~!!!!!!
            %%% FRM refinancing option  %�̿ɼ��� ����ϸ� shock���ϴ� �ͺ��� �ؼ� FRM_pmt�� ���ϰ����� �������� ���ͷ� �ٽ� �� ��ȯ�� �־�� �Ѵ�. 
        %     po_long_rate=long_rate( start_point: end ); % (1) ������ FRM rate�� : 
        %     [FRM_i] =fn_FRM_refinance1( FRM_rate, loan, H, T, po_long_rate );    % (1) ������ FRM rate��: �Լ� ���� ������ ��¥�� �ϳ� ���� �����͸� ����ؾ� �Ѵ�. ������ ���� ���ڶ���. fn_FRM_refinancing    
        %     po_long_rate=long_rate( start_point:12: end ); % (2) year���� FRM rate�� (��೯¥�� FRMrate�� �ش�⵵�� ��ǥ rate���� �����Ͽ� ���Ѵ�. 
        %     [FRM_i] =fn_FRM_refinance2( FRM_rate, loan, H, T, po_long_rate );    % (2) year���� FRM rate��: fn_FRM_refinancing
            %%%%%%%%%

            FRM_pmt = FRM_i(:,3);    %refinanace option�� ������ ���⸦  FRM_pmt = FRM_i(:,3) �� �ٲپ�� �Ѵ�. 
            FRM_endvalue_H = FRM_i(H*12,6); 
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            %%% ARM Post %%%%%%%%%%%%%%%%%
            initial_rate = Data_iniARM(start_point);  %start point�� ���� initial rate�� �ٲ��. initial rate�� Freddie������ ������ ���
            life_cap_rate = life_cap_rate_data(start_point);
            po_short_rate=Data_1y( start_point :12: start_point + H*12 - 1 ); %�ŷ��������� ���Ե� ���� �ش�⵵�� ��ǥ�ϴ� short rate�� �ǰ�, ���� �ص� �Ȱ��� �ش� ���� �ش� �⵵�� short rate�� �ȴ�.
            [po_ARM_total] = fn_ARM_POST_refin_6(po_short_rate, T, H, loan, fixperiod, margin_rate, initial_rate, ini_cap,  anu_cap, life_cap_rate, FRM_pmt, FRM_endvalue_H, Discountrate); % fn_post
            po_ARM_total2(end+1,:) = [ po_ARM_total ];   %npv_all, shock1, shock2, AVG_size_shock, risk_index, risk_ARM, ARM_IRR
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            %%% simulation interest rate %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            history_data=Data_1y_b(history_B+a1 : 12 : moving_start_B+a1) ; 
            [X, obj, t, short_trend, vasicek_coeff] = fn_shortrate6_nova_HP(history_data, H);  %fn_interest simulation �ʱ��۾� (interest_simulation_initial2) 
            vasicek_coeff_hist(end+1,:) = vasicek_coeff ;  %vasicek coefficient ����
            for i=1:people % cycle of same routine(���� ������ڿ� ����� ����� �����Ұ����� �����Ѵ�, 100�̸� 100���� ����� �ùķ��̼� ����� ���� ������ ���� ��ȯ�Ѵ�)

            %%% ARM ante     
            [an_itotal_avg] = fn_ARM_ante_refin_11(obj, X, t, T, H, loan, fixperiod, margin_rate, initial_rate, ini_cap,  anu_cap, life_cap_rate, FRM_pmt, yearly_string, FRM_endvalue_H, Discountrate, n_intsimul, po_short_rate,short_trend, vasicek_coeff); 
            an_itotal_avg2{i,j} = [ an_itotal_avg ]; % npv_all, shock1, shock2, AVG_size_shock, risk_index, risk_ARM, ARM_IRR
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            end  % i cycle end   

            j=j+1;  %cell column�� start point�����϶����� �����δ�.  
            a1=a1+1;  % moving window������ cycle�� �ϳ��� ������Ų��.    
        end   % moving window roop����
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%
        Eshock_an_nosa=[];

        for ii=1:size(an_itotal_avg2, 1)  %����Ŭ��

            for jj=1:size(an_itotal_avg2, 2)  %
               Eshock_an_nosa(ii,jj)=an_itotal_avg2{ii,jj}(14);
            end

        end

        Eshock_an_nosa=mean(Eshock_an_nosa',2);
        %%
        Eshock_an_sa=[];

        for ii=1:size(an_itotal_avg2, 1)  %����Ŭ��

            for jj=1:size(an_itotal_avg2, 2)  %
               Eshock_an_sa(ii,jj)=an_itotal_avg2{ii,jj}(15);
            end

        end

        Eshock_an_sa=mean(Eshock_an_sa',2);
        %%
        Efrmcost_an=[];

        for ii=1:size(an_itotal_avg2, 1)  %����Ŭ��

            for jj=1:size(an_itotal_avg2, 2)  %
               Efrmcost_an(ii,jj)=an_itotal_avg2{ii,jj}(16);
            end

        end

        Efrmcost_an=mean(Efrmcost_an',2);

        save('v20_refin_40_f1')
    end
end

