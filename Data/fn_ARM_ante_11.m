
function [itotal_avg] =fn_ARM_ante_robust_11(obj, X, t, T, H, loan, fixperiod, margin_rate, initial_rate, ini_cap,  anu_cap, life_cap_rate, FRM_pmt, FRM_rate, yearly , FRM_endvalue_H, Discountrate, n_intsimul, po_short_rate, short_trend, vasicek_coeff);
   H_varsicek = H-1;
   npv_all=[];  %Net present value of ARM ante
   ARM_IRR=[]; %IRR
   shock1=[]; %Shock1 : ARM(ante) payment가 FRM payment보다 높은 횟수
   shock2=[]; %Shock2 : Saving이 0보다 작고 ARM(ante) payment가 FRM payment보다 높은 횟수
   AVG_size_shock1= []; %average size of the shock (no saving)
   AVG_size_shock2= []; %average size of the shock (saving)
   AVG_size_shock12= [];
   AVG_size_shock22= [];
   risk_index =[] ; %  short_rate(ante)의 STD 
   risk_ARM = [] ; % contract rate(ante)의 STD
   an_short_rate1_figure=[]; % short rate을 Vasicek으로 추정한 값들을 모아 두었다가 그림으로 그려볼 때 사용
   AVG_size_shock3=[];
   error=[];
   npv_all2=[]; %FRM cost with saving 저장되는곳. (ex-ante)
   
   Eshock_sa=[]; 
   Efrmcost_sa=[];

   Eshock_nosa=[];
   Efrmcost=[];

    
    for nTrials = 1: n_intsimul;  %몇번의 inerest path를 만들것인지 결정(즉 몇번 시뮬레이션한 결과를 구매자가 보고 판단할것인지 결정한다. 1000번이면 1000번 시뮬레이션한 결과를 토대로 평균한 NPV값으로 모기지론을 선택.
           
    short_cycle1 = X(1);  %초기값 대입
    short_cycle2 = [];
    short_cycle2(end+1,1) = short_cycle1 ; % 최종 이자율이 축적되는 곳
    
    for i= 1: H_varsicek
                  
        drate1 = vasicek_coeff(1)*( vasicek_coeff(2) - short_cycle1 )+ vasicek_coeff(3) * normrnd(0,1);   %vasicek식
        short_cycle1=drate1+short_cycle1;  %drt에다가 이전 rt를 더하여 현재 rt값을 구함
        short_cycle2(end+1,1) = short_cycle1;  
    
    end
    
    short_trend_adj = short_trend - short_trend(1) + short_trend(end) ;
    short_rate= short_cycle2 + short_trend_adj(1:H); %H만큰 더해줘도 상관없는것이 우선 lookback이 10년이면 10개 데이터만 forecast하기 때문에 마침 H가 10년이어서 가져다 쓴것일뿐이다. 
   
    an_short_rate1_figure(:,end+1) = short_rate ;  %short rate path 그림으로 볼때 확인
        
        
    %%% (매트랩코드 제공) ex-ante short rate  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     short_cycle = obj.interpolate(t, X(:,:,ones(1,1)), 'Times',[obj.StartTime  H_varsicek], 'Refine', true);   %  T가 T_varsicek인 T-1로 되어있었는데 시뮬레이션 가이드는 이렇게 되어 있지 않음. 처음은 obj.StartState로 시작하면서 마지막은 average값으로 끝나는 3차원 행렬만들기
%     [t,ii] = sort(t); 
%     short_cycle = squeeze(short_cycle); 
%     short_cycle = short_cycle(ii);  % interpolation순서를 시간순으로 재 정리 
    

% % %     short_rate ( find ( short_rate <0 ) ) = 0.001 ;  % liquidity trap: 만약 마이너스 이자율이 예측되면 0.001을 넣는다.
    
    %%% ARM_ante %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ARM_pmt = [];  % ARM(ante) payment
    ending_bal = [];  %ARM(ante) ending balance
    Indexed_rate = [];   %ARM(ante) indexted rate = margin rate + 1y TB
    contract_rate = [] ;  
    annual_cap_rate=0;  %ARM(ante) annual cap rate
    
    if fixperiod>1 %fixperiod가 2년보다 큰 경우만 적용. 
        for a1=2:fixperiod;   %annual cap rate의 경우 처음 년도는 사용하지 않고 2번째 년도부터 사용되며 모두 annual cap + contract rate(작년)이다. 
        annual_cap_rate(end+1,1) = initial_rate + anu_cap ; 
        end
    end
    
    begin_bal=loan ;
    remain_term=T*12 ;
 
     
    for ye=1:H    % 'mo' is year order        
                
        if ye <= fixperiod 
            Indexed_rate(end+1,1) = margin_rate + short_rate (ye);
            %an_annual_cap_rate는 위에서 초기fixed구간을 미리 구해 놓음.
            contract_rate(end+1,1) =  initial_rate;
        else if ye == fixperiod+1 ;  %이때만 다로 살피는 이유는 다른건 다 동일한 조건인데 annual cap rate이 여기서만 initial cap을 적용함. 이후부터는 annual cap적용 
            Indexed_rate(end+1,1) = margin_rate + short_rate (ye) ;
            annual_cap_rate(end+1,1) =  ini_cap + contract_rate(ye-1) ;  %initial cap 적용
            contract_rate(end+1,1) =  min( [Indexed_rate(ye), annual_cap_rate(ye), life_cap_rate] );
            else
                Indexed_rate(end+1,1) = margin_rate + short_rate (ye) ;
                annual_cap_rate(end+1,1) = anu_cap + contract_rate(ye-1);  %annual cap 적용
                contract_rate(end+1,1) =  min( [Indexed_rate(ye), annual_cap_rate(ye), life_cap_rate] );         
            end
        end
        ARM_pmt(end+1,1) = payper(contract_rate(ye)/12, remain_term , begin_bal(ye) );
        ending_bal(end+1,1) = fvfix(contract_rate(ye)/12, 12, -ARM_pmt(ye), begin_bal(ye) ) ;
        begin_bal(end+1,1) = ending_bal(ye) ; %다음날짜 beginning balance를 미리 업데이트 해준다.
        remain_term = remain_term-12 ;
    end
    begin_bal = begin_bal(1:end-1,1) ;   %begin_bal의 경우 for문 마지막에 그다음 내용을 미리 입력해서 다른 변수보다 한개 더 많기 때문에 하나를 없애 줘야 한다. 
%     ARM_pmt_total=sum(ARM_pmt.*12);    
    
    ARM_i=[ [1:H]', short_rate, Indexed_rate, annual_cap_rate, contract_rate, begin_bal,ARM_pmt, ending_bal];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% ARM pmt, rate  등 monthly %%%%%%%%
    %%% ARM pmt monthly
    ARM_pmt_monthly=[];  %위에서 yearly로 구한 ARM payment를 FRM과 매달 net cash flow를 구하기 위해 매해 같은 값을 12개월씩 추가하여 만듬      
        for a1=1:H 
            for a2=1:12
                ARM_pmt_monthly(end+1,1) = ARM_pmt(a1);
            end
        end
    %%% ARM contract rate monthly        
    contract_rate_mo=[];  %위에서 yearly로 구한 ARM contract rate를 monthly로 구하기 위해 매해 같은 값을 12개월씩 추가하여 만듬
        for a1=1:H 
            for a2=1:12
                contract_rate_mo(end+1,1) =  contract_rate(a1)/12;
            end
        end
    %%% ARM indexed rate monthly        
   Indexed_rate_mo=[];  %위에서 yearly로 구한 ARM inedexed rate를 monthly로 구하기 위해 매해 같은 값을 12개월씩 추가하여 만듬
        for a1=1:H 
            for a2=1:12
                Indexed_rate_mo(end+1,1) =  Indexed_rate(a1)/12;
            end
        end
        
    %%% ARM end balance monthly
    begin_bal_monthly=loan;
    ending_bal_monthly=[];
    interest_pmt=[]; 
    principal_pmt=[];
    
    for a1=1:H*12
       interest_pmt(end+1,1) = begin_bal_monthly(a1) * contract_rate_mo(a1) ;
       principal_pmt(end+1,1) = ARM_pmt_monthly(a1) - interest_pmt(a1) ;
       ending_bal_monthly(end+1,1) =  begin_bal_monthly(a1) - principal_pmt(a1) ;
       begin_bal_monthly(end+1,1) = ending_bal_monthly (a1) ; 
    end 
    
    begin_bal_monthly=begin_bal_monthly(1:H*12,1);
    arm_monthly=[[1:H*12]' Indexed_rate_mo contract_rate_mo begin_bal_monthly ARM_pmt_monthly interest_pmt principal_pmt ending_bal_monthly ];   % NPV는 monthly로 비교해야 함으로 구한다. 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%% cash flow monthly 도출      
    ARM_endvalue_H = ending_bal_monthly(H*12);
    cashflow_net=[];  %NPV구할때 사용  % 기존 알고리즘에서는 이 부분을 실수로 안넣어서 이제까지 구한 NPV는 2008년에 구한 cashflow부터 계속 누적된 cashnet을 구했었다.....
    
    for a1 = 1:H *12
    
        if a1 < H*12
        cashflow_net(end+1,1) = FRM_pmt-ARM_pmt_monthly(a1) ;  %NPV구하기 위한 net cashflow 값을 미리 구함
        else
        cashflow_net(end+1,1) = (FRM_pmt + FRM_endvalue_H) - (ARM_pmt_monthly(a1) + ARM_endvalue_H);
        end
        
    end
 
    %%% ARM_cashflow monthly 도출   
    ARM_cashflow_mo=[]; %IRR구하기 위해 ARM의 holding period 구간 cash flow작성.
    for a1 = 1:H *12
    
        if a1 == 1
        ARM_cashflow_mo(end+1,1) = loan - ARM_pmt_monthly(a1) ;  %NPV 구하기 위한 net값을 미리 구함

        elseif a1 < H*12
        ARM_cashflow_mo(end+1,1) = - ARM_pmt_monthly(a1) ;  %NPV 구하기 위한 net값을 미리 구함
                   
        else %a3 == H*12
        ARM_cashflow_mo(end+1,1) =  - ( ARM_pmt_monthly(a1) + ARM_endvalue_H ) ;
   
        end  
    end
    
    %%% i번째 ARM, FRM_pmt 결과 도출, NPV, IRR 등 정리 (H기간동안 정리)  %%%%%    
    npv_all(end+1,1) = pvvar(cashflow_net, Discountrate/12 );     %할인율로 FRM_rate을 쓰는게 맞는지 꼭 확인~!!! (고칠것~!!!!!!)
    ARM_IRR(end+1,1) = irr(ARM_cashflow_mo);   %오류가 자꾸 생김... inf값이 잇다는데..
    
    %%% ith shock 1 (NO saving, ARM pmt가 FRM보다 높으면 카운트 한다.)
    shock1(end+1,1) = length ( find (ARM_pmt(1:H) > FRM_pmt) ) / H ;  % ARM payment가 FRM payment보다 많을때 그 횟수를 체트한다. normalize하기 위해 H를 나눠준다. 월별로 
    
    
    %%% ith shock 2 (Saving option)
    %FRM과 ARM의 차를 saving으로 간주하고 이 금액만큼을 계속 저축해둔다고 가정했을때 만약 ARM>FRM payment인
    %순간에 저축한 금액에서 착출하고, 더이상 착출이 어려운 시점을 shock으로 간주한다. 
    numberofshock=0;
    saving=0;
        for mo=1: H*12
        saving = saving + ( FRM_pmt - ARM_pmt_monthly(mo) );
        
            if saving <0;
                saving =0;
            end
            
            if ARM_pmt_monthly(mo) > FRM_pmt && saving == 0
                numberofshock = numberofshock+1 ;
            end
            
        end
    shock2(end+1,1) = numberofshock / (H*12);  %이건 매달 비교한것임으로 H에 12를 곱하여 monthly로 확인
    
    %%% ith AVG size of the shock
    % payment shock size1
%     AVG_size_shock1(end+1,1) = mean(ARM_pmt)/FRM_pmt-1;  

    pmtshock1=[];
    
    for ii2=1:H
    
    pmtshock1(end+1,1) = max( [ARM_pmt(ii2) - FRM_pmt,0] );
                
    end
     
    AVG_size_shock1(end+1,1) = mean(pmtshock1)/FRM_pmt -1 ; %saving 을 고려 안한 shock size
    AVG_size_shock12(end+1,1) = mean(pmtshock1)/FRM_pmt ;
    
    % payment shock size2
    
    pmtshock2=[];
    saving=0;
    
       for mo=1: H *12
        saving = saving + ( FRM_pmt - ARM_pmt_monthly(mo) );
        
            if saving > 0 
               pmtshock2(end+1,1) = 0 ;
             
            else
              pmtshock2(end+1,1) = -saving;   %개선된 부분 (이전에는 saving을 고려하지 않고 그냥 FRM_pmt - ARM_pmt만 해서 마지막 남은 saving효과가 감쇄 됬다. 
              saving =0;
            end
            
        end
       
    AVG_size_shock2(end+1,1) = mean(pmtshock2)/FRM_pmt -1 ;  %saving 을 고려한 shock size
    AVG_size_shock22(end+1,1) = mean(pmtshock2)/FRM_pmt;   %제대로 구함
    
    %틀린거 %%%%
    pmtshock3=[];
    saving=0;
    
       for mo=1: H *12
        saving = saving + ( FRM_pmt - ARM_pmt_monthly(mo) );
        
            if saving > 0 
               pmtshock3(end+1,1) = 0 ;
            end
            
            if saving <0;
                saving =0;
            end
            
            if ARM_pmt_monthly(mo) > FRM_pmt && saving == 0
                pmtshock3(end+1,1) = ARM_pmt_monthly(mo) - FRM_pmt;
            end
            if ARM_pmt_monthly(mo) <= FRM_pmt && saving == 0       %추가된 부분 %추가된 부분 %추가된 부분 %추가된 부분 %추가된 부분 %추가된 부분 %추가된 부분 %추가된 부분
                pmtshock3(end+1,1) = 0;
            end 

       end
       
    AVG_size_shock3(end+1,1) = mean(pmtshock3)/FRM_pmt;      %틀린거 
    error(end+1,1)=AVG_size_shock3(end)-AVG_size_shock22(end);
    
        
    %% ith risk 
    risk_index(end+1,1) = std( short_rate(1:H)  ) ;
    risk_ARM(end+1,1) = std( contract_rate_mo(1:H*12)  ) ;     
    
    %% FRM cost with saving

    saving=0;
    cashflow_net2=[];
      for mo=1: H *12-1
        saving = saving + ( FRM_pmt - ARM_pmt_monthly(mo) );
                
            if saving > 0 
              cashflow_net2(end+1,1) = 0  ; %사실상 ARM pmt에다가 차액 만큼을 saving으로 지불했기 때문에 net cash는 0이 된다. 
              
            else
              cashflow_net2(end+1,1) = saving ; % saving이 여기서는 마이너스인데 ARM pmt가 FRM pmt에다가 saving도 초과한 값임으로.  
              saving =0;
            end
            
      end

      mo= H *12;
      cashflow_net2(end+1,1) =  (FRM_pmt + FRM_endvalue_H) - (ARM_pmt_monthly(mo) + ARM_endvalue_H) + saving;  %아마 여기서 saving이 꽤 쌓여 있어 FRM cost를 증가 시킨다. 
      npv_all2(end+1,1) = pvvar(cashflow_net2, Discountrate/12 );  %FRM cost with saving
    
    
      
    %%  E(shock) non saving 8/20버젼  
    
    Eshock1=[];
    
    for ii2=1:H
    
    Eshock1(end+1,1) = max( [ARM_pmt(ii2) - FRM_pmt,0] )/FRM_pmt *100;  % 퍼센티지로 구함
                
    end
     
    Eshock_nosa(end+1,1) = mean( Eshock1 );
        
    %%  E(shock) saving 8/20버젼  
    Eshock2=[];
    saving=0;
    
      for mo=1: H *12
        saving = saving + ( FRM_pmt - ARM_pmt_monthly(mo) );
        
            if saving > 0 
              Eshock2(end+1,1) = 0 ;
            
            else
              Eshock2(end+1,1) = -saving / FRM_pmt *100;  
              saving =0;
            end
            
       end

    Eshock_sa(end+1,1) = mean( Eshock2 );
 
    %% E(FRM cost) non saving 8/20버젼  
    
    Efrmcost(end+1,1) = mean( cashflow_net./FRM_pmt *100 ) ;
            
    %% E(FRM cost) saving 8/20버젼  
    
%     Efrmcost_sa(end+1,1) = mean( cashflow_net2./FRM_pmt *100 ) ;   
      
      
      
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end   % nTrials roop종료 
  
    
    %%% i=1-100 까지 NPV, IRR, shock1,2 등 값들 정리.%%%%%%%%%%%%%%%%%%%%%%% 
    itotal = [npv_all, shock1, shock2, AVG_size_shock1, risk_index, risk_ARM, ARM_IRR, AVG_size_shock2, AVG_size_shock12, AVG_size_shock22, AVG_size_shock3, error, npv_all2, Eshock_nosa, Eshock_sa, Efrmcost];    
    itotal_avg = mean(itotal,1) ; % an_npv_year, an_shock1_year, an_shock2_year, an_risk_index_year, an_risk_ARM_year, an_ARM_IRR_year
    
        
end
