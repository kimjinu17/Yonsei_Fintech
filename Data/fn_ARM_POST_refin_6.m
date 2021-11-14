function [po_ARM_total] = fn_ARM_POST_refin_6(short_rate, T, H, loan, fixperiod, margin_rate, initial_rate, ini_cap,  anu_cap, life_cap_rate, FRM_pmt, FRM_endvalue_H, Discountrate);
    
   %%% ARM_ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   ARM_pmt = [];  % ARM(ante) payment
   ending_bal = [];  %ARM(ante) ending balance
   Indexed_rate = [];   %ARM(ante) indexted rate = margin rate + 1y TB
   contract_rate = [] ;  
   annual_cap_rate=0;  %ARM(ante) annual cap rate
    pmtshock3=[];
    
    if fixperiod>1 %fixperiod가 2년보다 큰 경우만 적용. 
        for a1=2:fixperiod;   %annual cap rate의 경우 처음 년도는 사용하지 않고 2번째 년도부터 사용되며 모두 annual cap + contract rate(작년)이다.fixed period까지는 같은 값이다.
        annual_cap_rate(end+1,1) = initial_rate + anu_cap ; 
        end
    end
    
    begin_bal=loan ;
    remain_term=T*12 ;

    
    for ye=1:H    %'ye' is year order  %여기서 구한건 H period동안만 구한다. T기간까지 다구할려면 단기금리 사후 데이터가 모자라서 구할수 없다.        
                
        if ye <= fixperiod 
            Indexed_rate(end+1,1) = margin_rate + short_rate (ye);
            %an_annual_cap_rate는 위에서 초기fixed구간을 미리 구해 놓음.
            contract_rate(end+1,1) =  initial_rate;
        else if ye== fixperiod+1 ;
            Indexed_rate(end+1,1) = margin_rate + short_rate (ye) ;
            annual_cap_rate(end+1,1) =  ini_cap + contract_rate(ye-1) ;
            contract_rate(end+1,1) =  min( [Indexed_rate(ye), annual_cap_rate(ye), life_cap_rate] );
            else
                Indexed_rate(end+1,1) = margin_rate + short_rate (ye) ;
                annual_cap_rate(end+1,1) = anu_cap + contract_rate(ye-1);
                contract_rate(end+1,1) =  min( [Indexed_rate(ye), annual_cap_rate(ye), life_cap_rate] );         
            end
        end
        ARM_pmt(end+1,1) = payper(contract_rate(ye)/12, remain_term , begin_bal(ye) );
        ending_bal(end+1,1) = fvfix(contract_rate(ye)/12, 12, -ARM_pmt(ye), begin_bal(ye) ) ;
        begin_bal(end+1,1) = ending_bal(ye) ;   %다음날짜 beginning balance를 미리 업데이트 해준다.
        remain_term = remain_term-12 ;
    end
    begin_bal = begin_bal(1:end-1,1) ;   %begin_bal의 경우 for문 마지막에 그 다음 내용을 미리 입력해서 다른 변수보다 한개 더 많기 때문에 하나를 없애 줘야 한다. 
%     po_ARM_pmt_total=sum(ARM_pmt.*12);    
    
    po_ARM_i=[ [1:H]', short_rate, Indexed_rate, annual_cap_rate, contract_rate, begin_bal,ARM_pmt, ending_bal];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    %%%%% ante ARM과 같은 부분 시작    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
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
    ARM_mo = [ [1:H*12]' Indexed_rate_mo contract_rate_mo begin_bal_monthly ARM_pmt_monthly interest_pmt principal_pmt ending_bal_monthly ];   % NPV는 monthly로 비교해야 함으로 구한다. 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%% cash flow monthly 도출      
    cashflow_net=[];  %NPV구할때 사용
    ARM_endvalue_H = ending_bal_monthly(H*12);  %12개월 차에 pmt와 pmt를 제외한 나머지 valance를 다 지불하고 pay off
    
    for a1 = 1:H *12
    
        if a1 < H*12
        cashflow_net(end+1,1) = FRM_pmt(a1)-ARM_pmt_monthly(a1) ;  %NPV구하기 위한 net cashflow 값을 미리 구함
        else
        cashflow_net(end+1,1) = (FRM_pmt(a1) + FRM_endvalue_H) - (ARM_pmt_monthly(a1) + ARM_endvalue_H);
        end
        
    end
 
    %%% ARM_cashflow monthly 도출   
    ARM_cashflow_mo=[]; %IRR구하기 위해 ARM의 holding period 구간 cash flow작성.
    for a1 = 1:H *12
    
        if a1 == 1
        ARM_cashflow_mo(end+1,1) = loan - ARM_pmt_monthly(a1) ;  %NPV 구하기 위한 net값을 미리 구함

        elseif a1 < H*12
        ARM_cashflow_mo(end+1,1) = - ARM_pmt_monthly(a1) ;  %NPV 구하기 위한 net값을 미리 구함
                   
        else %a1 == H*12
        ARM_cashflow_mo(end+1,1) =  - ( ARM_pmt_monthly(a1) + ARM_endvalue_H ) ;
   
        end  
    end
    %%% i번째 ARM, FRM_pmt 결과 도출, NPV, IRR 등 정리 (H기간동안 정리)  %%%%%    
    npv_all = pvvar(cashflow_net, Discountrate/12 );     %할인율로 FRM_rate을 쓰는게 맞는지 꼭 확인~!!! (고칠것~!!!!!!)
    ARM_IRR = irr(ARM_cashflow_mo);   
    
    %%% ith shock 1 (No Saving option)
    shock1=1; 
    for mo=1: H *12
    
         if ARM_pmt_monthly(mo) > FRM_pmt(mo)  %FRMpmt가 벡터임으로 변환
             shock1 = shock1+1;
         end
%          shock1 = length ( find (ARM_pmt(1:H) > FRM_pmt) ) / H ;  % ARM payment가 FRM payment보다 많을때 그 횟수를 체트한다. normalize하기 위해 H를 나눠준다. 월별로 
                                                                       % 보지 않는 이유는 어차피 같은 년도에는 같은 payment가 적용되기때문이다. 즉 년도 별로 비교해도 무관하기 때문
     end
     shock1 = shock1 / (H*12) ;
     
    %%% ith shock 2 (Saving option)
    %FRM과 ARM의 차를 saving으로 간주하고 이 금액만큼을 계속 저축해둔다고 가정했을때 만약 ARM>FRM payment인
    %순간에 저축한 금액에서 착출하고, 더이상 착출이 어려운 시점을 shock으로 간주한다. 
     numberofshock=0;
    saving=0;
        for mo=1: H *12
        saving = saving + ( FRM_pmt(mo) - ARM_pmt_monthly(mo) );
        
            if saving <0;
                saving =0;
            end
            
            if ARM_pmt_monthly(mo) > FRM_pmt(mo) && saving == 0
                numberofshock = numberofshock+1 ;
            end
            
        end
    shock2 = numberofshock / (H*12);  %이건 매달 비교한것임으로 H에 12를 곱하여 monthly로 확인
         
    
    %%% ith AVG size of the shock 3 (Saving option)
%     AVG_size_shock = mean(ARM_pmt)/FRM_pmt - 1;
    % payment shock size1
    pmtshock1=[];
    
    for mo=1: H *12
    
    pmtshock1(end+1,1) = max( [ARM_pmt_monthly(mo) - FRM_pmt(mo),0] );
                
    end
     
    AVG_size_shock1 = mean(pmtshock1)/mean(FRM_pmt) -1 ; %잘못구한것  saving 을 고려 안한 shock size
    AVG_size_shock12 = mean(pmtshock1)/mean(FRM_pmt);   %이걸로 사용
    % payment shock size2  
    pmtshock2=[];
    saving=0;
    
       for mo=1: H *12
        saving = saving + ( FRM_pmt(mo) - ARM_pmt_monthly(mo) );
        
            if saving > 0 
               pmtshock2(end+1,1) = 0 ;
            
            else
              pmtshock2(end+1,1) = -saving;   %개선된 부분 (이전에는 saving을 고려하지 않고 그냥 FRM_pmt - ARM_pmt만 해서 마지막 남은 saving효과가 감쇄 됬다. 
              saving =0;
            end
            
        end

    AVG_size_shock2 = mean(pmtshock2)/mean(FRM_pmt) -1 ;  %잘못구한것 saving 을 고려한 shock size
    AVG_size_shock22 = mean(pmtshock2)/mean(FRM_pmt) ;
    
    
     
       for mo=1: H *12
        saving = saving + ( FRM_pmt(mo) - ARM_pmt_monthly(mo) );
        
            if saving > 0 
               pmtshock3(end+1,1) = 0 ;
            end
            
            if saving <0;
                saving =0;
            end
            
            if ARM_pmt_monthly(mo) > FRM_pmt(mo) && saving == 0
                pmtshock3(end+1,1) = ARM_pmt_monthly(mo) - FRM_pmt(mo);
            end
                        
            if ARM_pmt_monthly(mo) <= FRM_pmt(mo) && saving == 0       %추가된 부분 %추가된 부분 %추가된 부분 %추가된 부분 %추가된 부분 %추가된 부분 %추가된 부분 %추가된 부분
                pmtshock3(end+1,1) = 0;
            end 

       end
       
    AVG_size_shock3 = mean(pmtshock3)/ mean(FRM_pmt);      %틀린거  
    error=AVG_size_shock3-AVG_size_shock22;
    
    
    %%%ith risk 
    risk_index = std( short_rate(1:H)  ) ;
    risk_ARM = std( contract_rate_mo(1:H*12)  ) ;     
    
      %% FRM cost with saving

    saving=0;
    cashflow_net2=[];
      for mo=1: H *12-1
        saving = saving + ( FRM_pmt(mo) - ARM_pmt_monthly(mo) );
                
            if saving > 0 
              cashflow_net2(end+1,1) = 0  ; %사실상 ARM pmt에다가 차액 만큼을 saving으로 지불했기 때문에 net cash는 0이 된다. 
              
            else
              cashflow_net2(end+1,1) = saving ; % saving이 여기서는 마이너스인데 ARM pmt가 FRM pmt에다가 saving도 초과한 값임으로.  
              saving =0;
            end
            
      end

      mo= H *12;
      cashflow_net2(end+1,1) =  (FRM_pmt(mo) + FRM_endvalue_H) - (ARM_pmt_monthly(mo) + ARM_endvalue_H) + saving;  %아마 여기서 saving이 꽤 쌓여 있어 FRM cost를 증가 시킨다. 
      npv_all2 = pvvar(cashflow_net2, Discountrate/12 );  %FRM cost with saving

    
    
    %%%%% ante ARM과 같은 부분 끝    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%  E(shock) non saving 8/20버젼  
    
    Eshock1=[];
    
    for mo=1: H *12
    
    Eshock1(end+1,1) = max( [ARM_pmt_monthly(mo) - FRM_pmt(mo),0] )/FRM_pmt(mo) *100;  % 퍼센티지로 구함
                
    end
     
    Eshock_nosa = mean( Eshock1 );
        
    %%  E(shock) saving 8/20버젼  
    Eshock2=[];
    saving=0;
    
      for mo=1: H *12
        saving = saving + ( FRM_pmt(mo) - ARM_pmt_monthly(mo) );
        
            if saving > 0 
              Eshock2(end+1,1) = 0 ;
            
            else
              Eshock2(end+1,1) = -saving / FRM_pmt(mo) *100;  
              saving =0;
            end
            
       end

    Eshock_sa = mean( Eshock2 );
      
    %% E(FRM cost) non saving 8/20버젼  
    
    
    Efrmcost=[];  %NPV구할때 사용
        
    for mo = 1:H *12
    
        if mo < H*12
        Efrmcost(end+1,1) = ( FRM_pmt(mo)-ARM_pmt_monthly(mo) ) /  FRM_pmt(mo) * 100;  %NPV구하기 위한 net cashflow 값을 미리 구함
        else
        Efrmcost(end+1,1) = ( (FRM_pmt(mo) + FRM_endvalue_H) - (ARM_pmt_monthly(mo) + ARM_endvalue_H) ) / FRM_pmt(mo) * 100 ;
        end
        
    end
    
    
    Efrmcost = mean( Efrmcost )  ; %PV의 경우 discount차이라도 있는데 이건 그냥 평균이여서 sa, non sa의 차이가 없다. 
        
    
    
    %%% i=1-1000 까지 NPV, IRR, shock1,2 등 값들 정리.%%%%%%%%%%%%%%%%%%%%%% 
    po_ARM_total = [npv_all, shock1, shock2, AVG_size_shock1, risk_index, risk_ARM, ARM_IRR, AVG_size_shock2, AVG_size_shock12, AVG_size_shock22, AVG_size_shock3, error, npv_all2, Eshock_nosa, Eshock_sa, Efrmcost ];    %8번째에 saving옵션이 들어간 pmt size를 넣었다. 
    
 
    
    
end