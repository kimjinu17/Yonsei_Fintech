
function [itotal_avg] =fn_ARM_ante_robust_11(obj, X, t, T, H, loan, fixperiod, margin_rate, initial_rate, ini_cap,  anu_cap, life_cap_rate, FRM_pmt, FRM_rate, yearly , FRM_endvalue_H, Discountrate, n_intsimul, po_short_rate, short_trend, vasicek_coeff);
   H_varsicek = H-1;
   npv_all=[];  %Net present value of ARM ante
   ARM_IRR=[]; %IRR
   shock1=[]; %Shock1 : ARM(ante) payment�� FRM payment���� ���� Ƚ��
   shock2=[]; %Shock2 : Saving�� 0���� �۰� ARM(ante) payment�� FRM payment���� ���� Ƚ��
   AVG_size_shock1= []; %average size of the shock (no saving)
   AVG_size_shock2= []; %average size of the shock (saving)
   AVG_size_shock12= [];
   AVG_size_shock22= [];
   risk_index =[] ; %  short_rate(ante)�� STD 
   risk_ARM = [] ; % contract rate(ante)�� STD
   an_short_rate1_figure=[]; % short rate�� Vasicek���� ������ ������ ��� �ξ��ٰ� �׸����� �׷��� �� ���
   AVG_size_shock3=[];
   error=[];
   npv_all2=[]; %FRM cost with saving ����Ǵ°�. (ex-ante)
   
   Eshock_sa=[]; 
   Efrmcost_sa=[];

   Eshock_nosa=[];
   Efrmcost=[];

    
    for nTrials = 1: n_intsimul;  %����� inerest path�� ��������� ����(�� ��� �ùķ��̼��� ����� �����ڰ� ���� �Ǵ��Ұ����� �����Ѵ�. 1000���̸� 1000�� �ùķ��̼��� ����� ���� ����� NPV������ ��������� ����.
           
    short_cycle1 = X(1);  %�ʱⰪ ����
    short_cycle2 = [];
    short_cycle2(end+1,1) = short_cycle1 ; % ���� �������� �����Ǵ� ��
    
    for i= 1: H_varsicek
                  
        drate1 = vasicek_coeff(1)*( vasicek_coeff(2) - short_cycle1 )+ vasicek_coeff(3) * normrnd(0,1);   %vasicek��
        short_cycle1=drate1+short_cycle1;  %drt���ٰ� ���� rt�� ���Ͽ� ���� rt���� ����
        short_cycle2(end+1,1) = short_cycle1;  
    
    end
    
    short_trend_adj = short_trend - short_trend(1) + short_trend(end) ;
    short_rate= short_cycle2 + short_trend_adj(1:H); %H��ū �����൵ ������°��� �켱 lookback�� 10���̸� 10�� �����͸� forecast�ϱ� ������ ��ħ H�� 10���̾ ������ �����ϻ��̴�. 
   
    an_short_rate1_figure(:,end+1) = short_rate ;  %short rate path �׸����� ���� Ȯ��
        
        
    %%% (��Ʈ���ڵ� ����) ex-ante short rate  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     short_cycle = obj.interpolate(t, X(:,:,ones(1,1)), 'Times',[obj.StartTime  H_varsicek], 'Refine', true);   %  T�� T_varsicek�� T-1�� �Ǿ��־��µ� �ùķ��̼� ���̵�� �̷��� �Ǿ� ���� ����. ó���� obj.StartState�� �����ϸ鼭 �������� average������ ������ 3���� ��ĸ����
%     [t,ii] = sort(t); 
%     short_cycle = squeeze(short_cycle); 
%     short_cycle = short_cycle(ii);  % interpolation������ �ð������� �� ���� 
    

% % %     short_rate ( find ( short_rate <0 ) ) = 0.001 ;  % liquidity trap: ���� ���̳ʽ� �������� �����Ǹ� 0.001�� �ִ´�.
    
    %%% ARM_ante %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ARM_pmt = [];  % ARM(ante) payment
    ending_bal = [];  %ARM(ante) ending balance
    Indexed_rate = [];   %ARM(ante) indexted rate = margin rate + 1y TB
    contract_rate = [] ;  
    annual_cap_rate=0;  %ARM(ante) annual cap rate
    
    if fixperiod>1 %fixperiod�� 2�⺸�� ū ��츸 ����. 
        for a1=2:fixperiod;   %annual cap rate�� ��� ó�� �⵵�� ������� �ʰ� 2��° �⵵���� ���Ǹ� ��� annual cap + contract rate(�۳�)�̴�. 
        annual_cap_rate(end+1,1) = initial_rate + anu_cap ; 
        end
    end
    
    begin_bal=loan ;
    remain_term=T*12 ;
 
     
    for ye=1:H    % 'mo' is year order        
                
        if ye <= fixperiod 
            Indexed_rate(end+1,1) = margin_rate + short_rate (ye);
            %an_annual_cap_rate�� ������ �ʱ�fixed������ �̸� ���� ����.
            contract_rate(end+1,1) =  initial_rate;
        else if ye == fixperiod+1 ;  %�̶��� �ٷ� ���Ǵ� ������ �ٸ��� �� ������ �����ε� annual cap rate�� ���⼭�� initial cap�� ������. ���ĺ��ʹ� annual cap���� 
            Indexed_rate(end+1,1) = margin_rate + short_rate (ye) ;
            annual_cap_rate(end+1,1) =  ini_cap + contract_rate(ye-1) ;  %initial cap ����
            contract_rate(end+1,1) =  min( [Indexed_rate(ye), annual_cap_rate(ye), life_cap_rate] );
            else
                Indexed_rate(end+1,1) = margin_rate + short_rate (ye) ;
                annual_cap_rate(end+1,1) = anu_cap + contract_rate(ye-1);  %annual cap ����
                contract_rate(end+1,1) =  min( [Indexed_rate(ye), annual_cap_rate(ye), life_cap_rate] );         
            end
        end
        ARM_pmt(end+1,1) = payper(contract_rate(ye)/12, remain_term , begin_bal(ye) );
        ending_bal(end+1,1) = fvfix(contract_rate(ye)/12, 12, -ARM_pmt(ye), begin_bal(ye) ) ;
        begin_bal(end+1,1) = ending_bal(ye) ; %������¥ beginning balance�� �̸� ������Ʈ ���ش�.
        remain_term = remain_term-12 ;
    end
    begin_bal = begin_bal(1:end-1,1) ;   %begin_bal�� ��� for�� �������� �״��� ������ �̸� �Է��ؼ� �ٸ� �������� �Ѱ� �� ���� ������ �ϳ��� ���� ��� �Ѵ�. 
%     ARM_pmt_total=sum(ARM_pmt.*12);    
    
    ARM_i=[ [1:H]', short_rate, Indexed_rate, annual_cap_rate, contract_rate, begin_bal,ARM_pmt, ending_bal];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% ARM pmt, rate  �� monthly %%%%%%%%
    %%% ARM pmt monthly
    ARM_pmt_monthly=[];  %������ yearly�� ���� ARM payment�� FRM�� �Ŵ� net cash flow�� ���ϱ� ���� ���� ���� ���� 12������ �߰��Ͽ� ����      
        for a1=1:H 
            for a2=1:12
                ARM_pmt_monthly(end+1,1) = ARM_pmt(a1);
            end
        end
    %%% ARM contract rate monthly        
    contract_rate_mo=[];  %������ yearly�� ���� ARM contract rate�� monthly�� ���ϱ� ���� ���� ���� ���� 12������ �߰��Ͽ� ����
        for a1=1:H 
            for a2=1:12
                contract_rate_mo(end+1,1) =  contract_rate(a1)/12;
            end
        end
    %%% ARM indexed rate monthly        
   Indexed_rate_mo=[];  %������ yearly�� ���� ARM inedexed rate�� monthly�� ���ϱ� ���� ���� ���� ���� 12������ �߰��Ͽ� ����
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
    arm_monthly=[[1:H*12]' Indexed_rate_mo contract_rate_mo begin_bal_monthly ARM_pmt_monthly interest_pmt principal_pmt ending_bal_monthly ];   % NPV�� monthly�� ���ؾ� ������ ���Ѵ�. 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%% cash flow monthly ����      
    ARM_endvalue_H = ending_bal_monthly(H*12);
    cashflow_net=[];  %NPV���Ҷ� ���  % ���� �˰��򿡼��� �� �κ��� �Ǽ��� �ȳ־ �������� ���� NPV�� 2008�⿡ ���� cashflow���� ��� ������ cashnet�� ���߾���.....
    
    for a1 = 1:H *12
    
        if a1 < H*12
        cashflow_net(end+1,1) = FRM_pmt-ARM_pmt_monthly(a1) ;  %NPV���ϱ� ���� net cashflow ���� �̸� ����
        else
        cashflow_net(end+1,1) = (FRM_pmt + FRM_endvalue_H) - (ARM_pmt_monthly(a1) + ARM_endvalue_H);
        end
        
    end
 
    %%% ARM_cashflow monthly ����   
    ARM_cashflow_mo=[]; %IRR���ϱ� ���� ARM�� holding period ���� cash flow�ۼ�.
    for a1 = 1:H *12
    
        if a1 == 1
        ARM_cashflow_mo(end+1,1) = loan - ARM_pmt_monthly(a1) ;  %NPV ���ϱ� ���� net���� �̸� ����

        elseif a1 < H*12
        ARM_cashflow_mo(end+1,1) = - ARM_pmt_monthly(a1) ;  %NPV ���ϱ� ���� net���� �̸� ����
                   
        else %a3 == H*12
        ARM_cashflow_mo(end+1,1) =  - ( ARM_pmt_monthly(a1) + ARM_endvalue_H ) ;
   
        end  
    end
    
    %%% i��° ARM, FRM_pmt ��� ����, NPV, IRR �� ���� (H�Ⱓ���� ����)  %%%%%    
    npv_all(end+1,1) = pvvar(cashflow_net, Discountrate/12 );     %�������� FRM_rate�� ���°� �´��� �� Ȯ��~!!! (��ĥ��~!!!!!!)
    ARM_IRR(end+1,1) = irr(ARM_cashflow_mo);   %������ �ڲ� ����... inf���� �մٴµ�..
    
    %%% ith shock 1 (NO saving, ARM pmt�� FRM���� ������ ī��Ʈ �Ѵ�.)
    shock1(end+1,1) = length ( find (ARM_pmt(1:H) > FRM_pmt) ) / H ;  % ARM payment�� FRM payment���� ������ �� Ƚ���� üƮ�Ѵ�. normalize�ϱ� ���� H�� �����ش�. ������ 
    
    
    %%% ith shock 2 (Saving option)
    %FRM�� ARM�� ���� saving���� �����ϰ� �� �ݾ׸�ŭ�� ��� �����صдٰ� ���������� ���� ARM>FRM payment��
    %������ ������ �ݾ׿��� �����ϰ�, ���̻� ������ ����� ������ shock���� �����Ѵ�. 
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
    shock2(end+1,1) = numberofshock / (H*12);  %�̰� �Ŵ� ���Ѱ������� H�� 12�� ���Ͽ� monthly�� Ȯ��
    
    %%% ith AVG size of the shock
    % payment shock size1
%     AVG_size_shock1(end+1,1) = mean(ARM_pmt)/FRM_pmt-1;  

    pmtshock1=[];
    
    for ii2=1:H
    
    pmtshock1(end+1,1) = max( [ARM_pmt(ii2) - FRM_pmt,0] );
                
    end
     
    AVG_size_shock1(end+1,1) = mean(pmtshock1)/FRM_pmt -1 ; %saving �� ��� ���� shock size
    AVG_size_shock12(end+1,1) = mean(pmtshock1)/FRM_pmt ;
    
    % payment shock size2
    
    pmtshock2=[];
    saving=0;
    
       for mo=1: H *12
        saving = saving + ( FRM_pmt - ARM_pmt_monthly(mo) );
        
            if saving > 0 
               pmtshock2(end+1,1) = 0 ;
             
            else
              pmtshock2(end+1,1) = -saving;   %������ �κ� (�������� saving�� ������� �ʰ� �׳� FRM_pmt - ARM_pmt�� �ؼ� ������ ���� savingȿ���� ���� ���. 
              saving =0;
            end
            
        end
       
    AVG_size_shock2(end+1,1) = mean(pmtshock2)/FRM_pmt -1 ;  %saving �� ����� shock size
    AVG_size_shock22(end+1,1) = mean(pmtshock2)/FRM_pmt;   %����� ����
    
    %Ʋ���� %%%%
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
            if ARM_pmt_monthly(mo) <= FRM_pmt && saving == 0       %�߰��� �κ� %�߰��� �κ� %�߰��� �κ� %�߰��� �κ� %�߰��� �κ� %�߰��� �κ� %�߰��� �κ� %�߰��� �κ�
                pmtshock3(end+1,1) = 0;
            end 

       end
       
    AVG_size_shock3(end+1,1) = mean(pmtshock3)/FRM_pmt;      %Ʋ���� 
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
              cashflow_net2(end+1,1) = 0  ; %��ǻ� ARM pmt���ٰ� ���� ��ŭ�� saving���� �����߱� ������ net cash�� 0�� �ȴ�. 
              
            else
              cashflow_net2(end+1,1) = saving ; % saving�� ���⼭�� ���̳ʽ��ε� ARM pmt�� FRM pmt���ٰ� saving�� �ʰ��� ��������.  
              saving =0;
            end
            
      end

      mo= H *12;
      cashflow_net2(end+1,1) =  (FRM_pmt + FRM_endvalue_H) - (ARM_pmt_monthly(mo) + ARM_endvalue_H) + saving;  %�Ƹ� ���⼭ saving�� �� �׿� �־� FRM cost�� ���� ��Ų��. 
      npv_all2(end+1,1) = pvvar(cashflow_net2, Discountrate/12 );  %FRM cost with saving
    
    
      
    %%  E(shock) non saving 8/20����  
    
    Eshock1=[];
    
    for ii2=1:H
    
    Eshock1(end+1,1) = max( [ARM_pmt(ii2) - FRM_pmt,0] )/FRM_pmt *100;  % �ۼ�Ƽ���� ����
                
    end
     
    Eshock_nosa(end+1,1) = mean( Eshock1 );
        
    %%  E(shock) saving 8/20����  
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
 
    %% E(FRM cost) non saving 8/20����  
    
    Efrmcost(end+1,1) = mean( cashflow_net./FRM_pmt *100 ) ;
            
    %% E(FRM cost) saving 8/20����  
    
%     Efrmcost_sa(end+1,1) = mean( cashflow_net2./FRM_pmt *100 ) ;   
      
      
      
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end   % nTrials roop���� 
  
    
    %%% i=1-100 ���� NPV, IRR, shock1,2 �� ���� ����.%%%%%%%%%%%%%%%%%%%%%%% 
    itotal = [npv_all, shock1, shock2, AVG_size_shock1, risk_index, risk_ARM, ARM_IRR, AVG_size_shock2, AVG_size_shock12, AVG_size_shock22, AVG_size_shock3, error, npv_all2, Eshock_nosa, Eshock_sa, Efrmcost];    
    itotal_avg = mean(itotal,1) ; % an_npv_year, an_shock1_year, an_shock2_year, an_risk_index_year, an_risk_ARM_year, an_ARM_IRR_year
    
        
end
