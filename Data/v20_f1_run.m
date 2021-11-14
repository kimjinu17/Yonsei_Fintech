for Y = 1:2 
    if Y == 1
        clc; clear all;

        %%% Set initial conditions for ARM %%%%%%%%%%%%%%%
        T = 30 ;   %    
        H = 10;    % Holding periods 
        people = 1  %원래는 100
        n_intsimul = 10 % 원래는 1000
        fixperiod = 5   % 5years Hybrid ARM의 경우 여기서 fixed rate을 적용할 기간을 선정한다. 1/1(사실상 그냥 ARM)의 경우 '1'을 대입하면 된다. 
        lookback = 10  %원래는 10y, history 기간을 몇년으로 잡을 것인가 , HP필터에서 트랜드로 앞에 10개 데이터로 그대로 
        loan =400000    % total loan amount

        %%% Input 1y short interest rate data %%%%%%%%%%%%
        [~,DateStrings_A] = xlsread('Tr','Sheet1','A422 : A963'); 
        Data_1y =  xlsread('Tr','Sheet1','B422 : B590'); 
        Data_1y=Data_1y/100;
        dates_A = datetime(DateStrings_A); %날짜를 매트랩이 읽을수 있는 date time으로 읽어들이기
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Input 1y old_short interest rate data %%%%%%%%%%%%
        % [~,DateStrings_A] = xlsread('Treasury_Constant_Maturity_Rate','5y_month','A72 : A240'); %12:2000.1, 72:2005.1,   191:2015.1,  240:2019.1
        [~,DateStrings_B] = xlsread('Tr','Sheet1','A2 : A963'); % 309: 1978.1  273: 1975.1
        Data_1y_b =  xlsread('Tr','Sheet1','B2 : B963'); 
        Data_1y_b=Data_1y_b/100;
        dates_B = datetime(DateStrings_B); %날짜를 매트랩이 읽을수 있는 date time으로 읽어들이기
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
        Data_iniARM_5y =  xlsread('FRM_ARM','Sheet1','C62 : C230'); %initial rate은 Freddie제공한 데이터 사용
        Data_marginARM_5y =  xlsread('FRM_ARM','Sheet1','D62 : D230'); %margin은 Freddie제공한 데이터 사용
        Data_marginARM_5y = Data_marginARM_5y / 100;
        Data_iniARM_5y =Data_iniARM_5y/100 ;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Input ARM 1y initial rate data %%%%%%%%%%%%%%%
        Data_iniARM_1y =  xlsread('FRM_ARM','Sheet1','E62 : E230'); %initial rate은 Freddie제공한 데이터 사용 (2015년 이후는 5/1ARM에서 평균spread를 빼주어서 추정한 값이다)
        Data_marginARM_1y =  xlsread('FRM_ARM','Sheet1','F62 : F230'); %margin은 Freddie제공한 데이터 사용
        Data_marginARM_1y = Data_marginARM_1y / 100;
        Data_iniARM_1y =Data_iniARM_1y/100 ;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Input ARM 3y initial rate data %%%%%%%%%%%%%%%
        Data_iniARM_3y =  xlsread('FRM_ARM','Sheet1','G62 : G230'); %initial rate은 Freddie제공한 데이터 사용 (2015년 이후는 5/1ARM에서 평균spread를 빼주어서 추정한 값이다)
        Data_marginARM_3y =  xlsread('FRM_ARM','Sheet1','H62 : H230'); %margin은 Freddie제공한 데이터 사용
        Data_marginARM_3y = Data_marginARM_3y / 100;
        Data_iniARM_3y =Data_iniARM_3y/100 ;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


        if fixperiod ==1  %2015년 까지만 사용 (out of sample forecasting에서는 쓸수 없다)
            Data_iniARM = Data_iniARM_1y;
            Data_marginARM = Data_marginARM_1y ;
        end

        if fixperiod ==3  %2015년 까지만 사용 (out of sample forecasting에서는 쓸수 없다)
            Data_iniARM = Data_iniARM_3y;
            Data_marginARM = Data_marginARM_3y ;
        end

        if fixperiod ==5  %2015년 까지만 사용 (out of sample forecasting에서는 쓸수 없다)
            Data_iniARM = Data_iniARM_5y;
            Data_marginARM = Data_marginARM_5y ;
        end

        ini_cap=0.02;  %initial cap   %바뀌었음~!!!! 이전에는 0.03
        anu_cap=0.02; % annual cap
        life_cap=0.05; % life time cap
        life_cap_rate_data = Data_iniARM + life_cap; % index 최대한도  이거 순서가 여기가 아니다~!!!!!!! 차라리 f3코드를 참조할것 

        moving_start = find(dates_A=='2005-1-1');  % 변경시 주의~!!! '2008-1-1'  '2010-1-1'
        moving_start_B = find(dates_B=='2005-1-1');  %
        history_B = moving_start_B - lookback*12;
        moving_end = find(dates_A=='2010-1-1');  % '2010-1-1' 2011-1-1' '2010-12-1'(최대) 현재는 8년주기임으로 2011년이 max임. 2011+8=2019년이여서.. 4년주기이면 2015+4=2019
        moving_end_B= moving_start_B + (moving_end - moving_start) ;


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Moving window period %%%%%%%%%%%%%%%%%%%%%%%%%
        an_itotal_avg2=[];  %현 start point에서 i번 시뮬레이션 ARM_ante 관련 값들 평균  
        po_ARM_total2=[];  %현 start point에서 i번 시뮬레이션 ARM_ante 관련 값들 모두 
        benefitante = [];  %  ex_ante선택과 ex_post선택을 비교하여 ex_ante선택의 benefit을 구함
        vasicek_coeff_hist=[]; %vasicek parameter 저장
        FRM_pmt_total=[];  

        j=1;        %cell column이 start point움직일때마다 움직인다. 
        a1=0;   % moving window를 하나씩 옮겨주는 역활

        for start_point= moving_start : moving_end  % moving window roop 시작  (시작일은 1월로 해야 함. 만약 2월로 할려면 추정에 쓰는 history데이터도 2월부터 시작해야 한다) 
            yearly_string = dates_A( start_point :12 : start_point + (H)*12 - 1 ); % 여기서 구한 값은 vasicek에서 그림 그릴때 x축 날짜 표시할때 사용한다. 주택 구매일의 short rate을 그해 대표하는 rate으로 하고 
                                                                                 % maturity day까지 해당 월을 매해 대표하는 rate으로 지정

            Discountrate = Data_7y (start_point);   % NPV 할인율 
            margin_rate = Data_marginARM (start_point);    %해당년도 ARM margin율
            %%% FRM %%%%%%%%%%%%%%%%%%%%%%
            long_rate =Data_FRMrate; 
            FRM_rate=long_rate(start_point) ;    % FRM 계산시 사용하는 이자율 

            [FRM_i] =fn_FRM( FRM_rate, loan, H, T );    % fn_FRM without refinancing option

            FRM_pmt = FRM_i(1,3);    %refinanace option을 쓸려면 여기를  FRM_pmt = FRM_i(:,3) 로 바꾸어야 한다. 
            FRM_pmt_total(end+1,1) = FRM_pmt ; 
            FRM_endvalue_H = FRM_i(H*12,6); 

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            %%% ARM Post %%%%%%%%%%%%%%%%%
            initial_rate = Data_iniARM(start_point);  %start point에 따라 initial rate이 바뀐다. initial rate은 Freddie제공한 데이터 사용
            life_cap_rate = life_cap_rate_data(start_point);
            po_short_rate=Data_1y( start_point :12: start_point + H*12 - 1 ); %거래시작일이 포함된 월이 해당년도를 대표하는 short rate이 되고, 다음 해도 똑같이 해당 월이 해당 년도의 short rate이 된다.
            [po_ARM_total] = fn_ARM_POST_6(po_short_rate, T, H, loan, fixperiod, margin_rate, initial_rate, ini_cap,  anu_cap, life_cap_rate, FRM_pmt, FRM_rate, FRM_endvalue_H, Discountrate); % fn_post
            po_ARM_total2(end+1,:) = [ po_ARM_total ];   %npv_all, shock1, shock2, AVG_size_shock, risk_index, risk_ARM, ARM_IRR
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            %%% simulation interest rate %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            history_data=Data_1y_b(history_B+a1 : 12 : moving_start_B+a1) ; 
            [X, obj, t, short_trend, vasicek_coeff] = fn_shortrate6_nova_HP(history_data, H);  %fn_interest simulation 초기작업 (interest_simulation_initial2) 
            vasicek_coeff_hist(end+1,:) = vasicek_coeff ;  %vasicek coefficient 정리
            for i=1:people % cycle of same routine(같은 계약일자에 몇명의 사람이 선택할것인지 설정한다, 100이면 100명의 사람이 시뮬레이션 결과를 통해 선택한 값을 반환한다)

            %%% ARM ante     
            [an_itotal_avg] = fn_ARM_ante_11(obj, X, t, T, H, loan, fixperiod, margin_rate, initial_rate, ini_cap,  anu_cap, life_cap_rate, FRM_pmt, FRM_rate, yearly_string, FRM_endvalue_H, Discountrate, n_intsimul, po_short_rate,short_trend, vasicek_coeff); 
            an_itotal_avg2{i,j} = [ an_itotal_avg ]; % npv_all, shock1, shock2, AVG_size_shock, risk_index, risk_ARM, ARM_IRR
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            end  % i cycle end   

            j=j+1;  %cell column이 start point움직일때마다 움직인다.  
            a1=a1+1;  % moving window임으로 cycle도 하나씩 증가시킨다.    
        end   % moving window roop종료
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%
        Eshock_an_nosa=[];

        for ii=1:size(an_itotal_avg2, 1)  %사이클수

            for jj=1:size(an_itotal_avg2, 2)  %
               Eshock_an_nosa(ii,jj)=an_itotal_avg2{ii,jj}(14);
            end

        end

        Eshock_an_nosa=mean(Eshock_an_nosa',2);
        %%
        Eshock_an_sa=[];

        for ii=1:size(an_itotal_avg2, 1)  %사이클수

            for jj=1:size(an_itotal_avg2, 2)  %
               Eshock_an_sa(ii,jj)=an_itotal_avg2{ii,jj}(15);
            end

        end

        Eshock_an_sa=mean(Eshock_an_sa',2);
        %%
        Efrmcost_an=[];

        for ii=1:size(an_itotal_avg2, 1)  %사이클수

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
        people = 1  %원래는 100
        n_intsimul = 10 % 원래는 1000
        fixperiod = 1   % 5years Hybrid ARM의 경우 여기서 fixed rate을 적용할 기간을 선정한다. 1/1(사실상 그냥 ARM)의 경우 '1'을 대입하면 된다. 
        lookback = 10  %원래는 10y, history 기간을 몇년으로 잡을 것인가 , HP필터에서 트랜드로 앞에 10개 데이터로 그대로 
        loan =400000    % total loan amount

        %%% Input 1y short interest rate data %%%%%%%%%%%%
        [~,DateStrings_A] = xlsread('Tr','Sheet1','A422 : A963'); 
        Data_1y =  xlsread('Tr','Sheet1','B422 : B590'); 
        Data_1y=Data_1y/100;
        dates_A = datetime(DateStrings_A); %날짜를 매트랩이 읽을수 있는 date time으로 읽어들이기
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Input 1y old_short interest rate data %%%%%%%%%%%%
        % [~,DateStrings_A] = xlsread('Treasury_Constant_Maturity_Rate','5y_month','A72 : A240'); %12:2000.1, 72:2005.1,   191:2015.1,  240:2019.1
        [~,DateStrings_B] = xlsread('Tr','Sheet1','A2 : A963'); % 309: 1978.1  273: 1975.1
        Data_1y_b =  xlsread('Tr','Sheet1','B2 : B963'); 
        Data_1y_b=Data_1y_b/100;
        dates_B = datetime(DateStrings_B); %날짜를 매트랩이 읽을수 있는 date time으로 읽어들이기
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
        Data_iniARM_5y =  xlsread('FRM_ARM','Sheet1','C62 : C230'); %initial rate은 Freddie제공한 데이터 사용
        Data_marginARM_5y =  xlsread('FRM_ARM','Sheet1','D62 : D230'); %margin은 Freddie제공한 데이터 사용
        Data_marginARM_5y = Data_marginARM_5y / 100;
        Data_iniARM_5y =Data_iniARM_5y/100 ;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Input ARM 1y initial rate data %%%%%%%%%%%%%%%
        Data_iniARM_1y =  xlsread('FRM_ARM','Sheet1','E62 : E230'); %initial rate은 Freddie제공한 데이터 사용 (2015년 이후는 5/1ARM에서 평균spread를 빼주어서 추정한 값이다)
        Data_marginARM_1y =  xlsread('FRM_ARM','Sheet1','F62 : F230'); %margin은 Freddie제공한 데이터 사용
        Data_marginARM_1y = Data_marginARM_1y / 100;
        Data_iniARM_1y =Data_iniARM_1y/100 ;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%% Input ARM 3y initial rate data %%%%%%%%%%%%%%%
        Data_iniARM_3y =  xlsread('FRM_ARM','Sheet1','G62 : G230'); %initial rate은 Freddie제공한 데이터 사용 (2015년 이후는 5/1ARM에서 평균spread를 빼주어서 추정한 값이다)
        Data_marginARM_3y =  xlsread('FRM_ARM','Sheet1','H62 : H230'); %margin은 Freddie제공한 데이터 사용
        Data_marginARM_3y = Data_marginARM_3y / 100;
        Data_iniARM_3y =Data_iniARM_3y/100 ;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


        if fixperiod ==1  %2015년 까지만 사용 (out of sample forecasting에서는 쓸수 없다)
            Data_iniARM = Data_iniARM_1y;
            Data_marginARM = Data_marginARM_1y ;
        end

        if fixperiod ==3  %2015년 까지만 사용 (out of sample forecasting에서는 쓸수 없다)
            Data_iniARM = Data_iniARM_3y;
            Data_marginARM = Data_marginARM_3y ;
        end

        if fixperiod ==5  %2015년 까지만 사용 (out of sample forecasting에서는 쓸수 없다)
            Data_iniARM = Data_iniARM_5y;
            Data_marginARM = Data_marginARM_5y ;
        end

        ini_cap=0.02;  %initial cap   %바뀌었음~!!!! 이전에는 0.03
        anu_cap=0.02; % annual cap
        life_cap=0.05; % life time cap
        life_cap_rate_data = Data_iniARM + life_cap; % index 최대한도  이거 순서가 여기가 아니다~!!!!!!! 차라리 f3코드를 참조할것 

        moving_start = find(dates_A=='2005-1-1');  % 변경시 주의~!!! '2008-1-1'  '2010-1-1'
        moving_start_B = find(dates_B=='2005-1-1');  %
        history_B = moving_start_B - lookback*12;
        moving_end = find(dates_A=='2010-1-1');  % '2010-1-1' 2011-1-1' '2010-12-1'(최대) 현재는 8년주기임으로 2011년이 max임. 2011+8=2019년이여서.. 4년주기이면 2015+4=2019
        moving_end_B= moving_start_B + (moving_end - moving_start) ;

        %%% Moving window period %%%%%%%%%%%%%%%%%%%%%%%%%
        an_itotal_avg2=[];  %현 start point에서 i번 시뮬레이션 ARM_ante 관련 값들 평균  
        po_ARM_total2=[];  %현 start point에서 i번 시뮬레이션 ARM_ante 관련 값들 모두 
        benefitante = [];  %  ex_ante선택과 ex_post선택을 비교하여 ex_ante선택의 benefit을 구함
        po_NPV=[]; %po_npv값을 저장하여 뒤에 회귀식에서 사용 Present value of FRM-ARM payment
        po_NPV2=[]; %FRM cost with saving이 저장
        vasicek_coeff_hist=[]; %vasicek parameter 저장

        j=1;        %cell column이 start point움직일때마다 움직인다. 
        a1=0;   % moving window를 하나씩 옮겨주는 역활

        for start_point= moving_start : moving_end  % moving window roop 시작  (시작일은 1월로 해야 함. 만약 2월로 할려면 추정에 쓰는 history데이터도 2월부터 시작해야 한다) 
            yearly_string = dates_A( start_point :12: start_point + (H)*12 - 1 ); % 여기서 구한 값은 vasicek에서 그림 그릴때 x축 날짜 표시할때 사용한다. 주택 구매일의 short rate을 그해 대표하는 rate으로 하고 
                                                                                 % maturity day까지 해당 월을 매해 대표하는 rate으로 지정

            Discountrate = Data_7y (start_point);   % NPV 할인율 
            margin_rate = Data_marginARM (start_point);    %해당년도 ARM margin율
            %%% FRM %%%%%%%%%%%%%%%%%%%%%%
            long_rate =Data_FRMrate; 
            FRM_rate=long_rate(start_point) ;    % FRM 계산시 사용하는 이자율 

            po_long_rate = long_rate(start_point : start_point + (H-1)*12-1) ;   %refinancing하면서 1년마다가 아닌 매개월마다 데이터가 필요. (매개월 마다 rate을 비교한다)
            %     [FRM_i] =fn_FRM( FRM_rate, loan, H, T );    % fn_FRM without refinancing option

            [FRM_i] = fn_FRM_refinance(FRM_rate, loan, H, T, po_long_rate );

            %주의 refinancing option을 하면 FRM_pmt가 하나의 값이 아닌 seriese가 된다. 
            %%%%조심~!  FRM 리파이넨싱 옵션 확인하고 돌릴것~!!!!!!
            %%% FRM refinancing option  %이옵션을 사용하면 shock구하는 것부터 해서 FRM_pmt를 단일값으로 쓰던것을 백터로 다시 다 전환해 주어야 한다. 
        %     po_long_rate=long_rate( start_point: end ); % (1) 월별로 FRM rate비교 : 
        %     [FRM_i] =fn_FRM_refinance1( FRM_rate, loan, H, T, po_long_rate );    % (1) 월별로 FRM rate비교: 함수 쓸때 마지막 날짜는 일년 이전 데이터를 사용해야 한다. 데이터 수가 모자란다. fn_FRM_refinancing    
        %     po_long_rate=long_rate( start_point:12: end ); % (2) year별로 FRM rate비교 (계약날짜의 FRMrate을 해당년도의 대표 rate으로 선정하여 비교한다. 
        %     [FRM_i] =fn_FRM_refinance2( FRM_rate, loan, H, T, po_long_rate );    % (2) year별로 FRM rate비교: fn_FRM_refinancing
            %%%%%%%%%

            FRM_pmt = FRM_i(:,3);    %refinanace option을 쓸려면 여기를  FRM_pmt = FRM_i(:,3) 로 바꾸어야 한다. 
            FRM_endvalue_H = FRM_i(H*12,6); 
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            %%% ARM Post %%%%%%%%%%%%%%%%%
            initial_rate = Data_iniARM(start_point);  %start point에 따라 initial rate이 바뀐다. initial rate은 Freddie제공한 데이터 사용
            life_cap_rate = life_cap_rate_data(start_point);
            po_short_rate=Data_1y( start_point :12: start_point + H*12 - 1 ); %거래시작일이 포함된 월이 해당년도를 대표하는 short rate이 되고, 다음 해도 똑같이 해당 월이 해당 년도의 short rate이 된다.
            [po_ARM_total] = fn_ARM_POST_refin_6(po_short_rate, T, H, loan, fixperiod, margin_rate, initial_rate, ini_cap,  anu_cap, life_cap_rate, FRM_pmt, FRM_endvalue_H, Discountrate); % fn_post
            po_ARM_total2(end+1,:) = [ po_ARM_total ];   %npv_all, shock1, shock2, AVG_size_shock, risk_index, risk_ARM, ARM_IRR
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            %%% simulation interest rate %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            history_data=Data_1y_b(history_B+a1 : 12 : moving_start_B+a1) ; 
            [X, obj, t, short_trend, vasicek_coeff] = fn_shortrate6_nova_HP(history_data, H);  %fn_interest simulation 초기작업 (interest_simulation_initial2) 
            vasicek_coeff_hist(end+1,:) = vasicek_coeff ;  %vasicek coefficient 정리
            for i=1:people % cycle of same routine(같은 계약일자에 몇명의 사람이 선택할것인지 설정한다, 100이면 100명의 사람이 시뮬레이션 결과를 통해 선택한 값을 반환한다)

            %%% ARM ante     
            [an_itotal_avg] = fn_ARM_ante_refin_11(obj, X, t, T, H, loan, fixperiod, margin_rate, initial_rate, ini_cap,  anu_cap, life_cap_rate, FRM_pmt, yearly_string, FRM_endvalue_H, Discountrate, n_intsimul, po_short_rate,short_trend, vasicek_coeff); 
            an_itotal_avg2{i,j} = [ an_itotal_avg ]; % npv_all, shock1, shock2, AVG_size_shock, risk_index, risk_ARM, ARM_IRR
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            end  % i cycle end   

            j=j+1;  %cell column이 start point움직일때마다 움직인다.  
            a1=a1+1;  % moving window임으로 cycle도 하나씩 증가시킨다.    
        end   % moving window roop종료
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%
        Eshock_an_nosa=[];

        for ii=1:size(an_itotal_avg2, 1)  %사이클수

            for jj=1:size(an_itotal_avg2, 2)  %
               Eshock_an_nosa(ii,jj)=an_itotal_avg2{ii,jj}(14);
            end

        end

        Eshock_an_nosa=mean(Eshock_an_nosa',2);
        %%
        Eshock_an_sa=[];

        for ii=1:size(an_itotal_avg2, 1)  %사이클수

            for jj=1:size(an_itotal_avg2, 2)  %
               Eshock_an_sa(ii,jj)=an_itotal_avg2{ii,jj}(15);
            end

        end

        Eshock_an_sa=mean(Eshock_an_sa',2);
        %%
        Efrmcost_an=[];

        for ii=1:size(an_itotal_avg2, 1)  %사이클수

            for jj=1:size(an_itotal_avg2, 2)  %
               Efrmcost_an(ii,jj)=an_itotal_avg2{ii,jj}(16);
            end

        end

        Efrmcost_an=mean(Efrmcost_an',2);

        save('v20_refin_40_f1')
    end
end

