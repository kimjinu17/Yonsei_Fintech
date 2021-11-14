function [po_ARM_total] = fn_ARM_POST_refin_6(short_rate, T, H, loan, fixperiod, margin_rate, initial_rate, ini_cap,  anu_cap, life_cap_rate, FRM_pmt, FRM_endvalue_H, Discountrate);
    
   %%% ARM_ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   ARM_pmt = [];  % ARM(ante) payment
   ending_bal = [];  %ARM(ante) ending balance
   Indexed_rate = [];   %ARM(ante) indexted rate = margin rate + 1y TB
   contract_rate = [] ;  
   annual_cap_rate=0;  %ARM(ante) annual cap rate
    pmtshock3=[];
    
    if fixperiod>1 %fixperiod�� 2�⺸�� ū ��츸 ����. 
        for a1=2:fixperiod;   %annual cap rate�� ��� ó�� �⵵�� ������� �ʰ� 2��° �⵵���� ���Ǹ� ��� annual cap + contract rate(�۳�)�̴�.fixed period������ ���� ���̴�.
        annual_cap_rate(end+1,1) = initial_rate + anu_cap ; 
        end
    end
    
    begin_bal=loan ;
    remain_term=T*12 ;

    
    for ye=1:H    %'ye' is year order  %���⼭ ���Ѱ� H period���ȸ� ���Ѵ�. T�Ⱓ���� �ٱ��ҷ��� �ܱ�ݸ� ���� �����Ͱ� ���ڶ� ���Ҽ� ����.        
                
        if ye <= fixperiod 
            Indexed_rate(end+1,1) = margin_rate + short_rate (ye);
            %an_annual_cap_rate�� ������ �ʱ�fixed������ �̸� ���� ����.
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
        begin_bal(end+1,1) = ending_bal(ye) ;   %������¥ beginning balance�� �̸� ������Ʈ ���ش�.
        remain_term = remain_term-12 ;
    end
    begin_bal = begin_bal(1:end-1,1) ;   %begin_bal�� ��� for�� �������� �� ���� ������ �̸� �Է��ؼ� �ٸ� �������� �Ѱ� �� ���� ������ �ϳ��� ���� ��� �Ѵ�. 
%     po_ARM_pmt_total=sum(ARM_pmt.*12);    
    
    po_ARM_i=[ [1:H]', short_rate, Indexed_rate, annual_cap_rate, contract_rate, begin_bal,ARM_pmt, ending_bal];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    %%%%% ante ARM�� ���� �κ� ����    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
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
    ARM_mo = [ [1:H*12]' Indexed_rate_mo contract_rate_mo begin_bal_monthly ARM_pmt_monthly interest_pmt principal_pmt ending_bal_monthly ];   % NPV�� monthly�� ���ؾ� ������ ���Ѵ�. 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%% cash flow monthly ����      
    cashflow_net=[];  %NPV���Ҷ� ���
    ARM_endvalue_H = ending_bal_monthly(H*12);  %12���� ���� pmt�� pmt�� ������ ������ valance�� �� �����ϰ� pay off
    
    for a1 = 1:H *12
    
        if a1 < H*12
        cashflow_net(end+1,1) = FRM_pmt(a1)-ARM_pmt_monthly(a1) ;  %NPV���ϱ� ���� net cashflow ���� �̸� ����
        else
        cashflow_net(end+1,1) = (FRM_pmt(a1) + FRM_endvalue_H) - (ARM_pmt_monthly(a1) + ARM_endvalue_H);
        end
        
    end
 
    %%% ARM_cashflow monthly ����   
    ARM_cashflow_mo=[]; %IRR���ϱ� ���� ARM�� holding period ���� cash flow�ۼ�.
    for a1 = 1:H *12
    
        if a1 == 1
        ARM_cashflow_mo(end+1,1) = loan - ARM_pmt_monthly(a1) ;  %NPV ���ϱ� ���� net���� �̸� ����

        elseif a1 < H*12
        ARM_cashflow_mo(end+1,1) = - ARM_pmt_monthly(a1) ;  %NPV ���ϱ� ���� net���� �̸� ����
                   
        else %a1 == H*12
        ARM_cashflow_mo(end+1,1) =  - ( ARM_pmt_monthly(a1) + ARM_endvalue_H ) ;
   
        end  
    end
    %%% i��° ARM, FRM_pmt ��� ����, NPV, IRR �� ���� (H�Ⱓ���� ����)  %%%%%    
    npv_all = pvvar(cashflow_net, Discountrate/12 );     %�������� FRM_rate�� ���°� �´��� �� Ȯ��~!!! (��ĥ��~!!!!!!)
    ARM_IRR = irr(ARM_cashflow_mo);   
    
    %%% ith shock 1 (No Saving option)
    shock1=1; 
    for mo=1: H *12
    
         if ARM_pmt_monthly(mo) > FRM_pmt(mo)  %FRMpmt�� ���������� ��ȯ
             shock1 = shock1+1;
         end
%          shock1 = length ( find (ARM_pmt(1:H) > FRM_pmt) ) / H ;  % ARM payment�� FRM payment���� ������ �� Ƚ���� üƮ�Ѵ�. normalize�ϱ� ���� H�� �����ش�. ������ 
                                                                       % ���� �ʴ� ������ ������ ���� �⵵���� ���� payment�� ����Ǳ⶧���̴�. �� �⵵ ���� ���ص� �����ϱ� ����
     end
     shock1 = shock1 / (H*12) ;
     
    %%% ith shock 2 (Saving option)
    %FRM�� ARM�� ���� saving���� �����ϰ� �� �ݾ׸�ŭ�� ��� �����صдٰ� ���������� ���� ARM>FRM payment��
    %������ ������ �ݾ׿��� �����ϰ�, ���̻� ������ ����� ������ shock���� �����Ѵ�. 
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
    shock2 = numberofshock / (H*12);  %�̰� �Ŵ� ���Ѱ������� H�� 12�� ���Ͽ� monthly�� Ȯ��
         
    
    %%% ith AVG size of the shock 3 (Saving option)
%     AVG_size_shock = mean(ARM_pmt)/FRM_pmt - 1;
    % payment shock size1
    pmtshock1=[];
    
    for mo=1: H *12
    
    pmtshock1(end+1,1) = max( [ARM_pmt_monthly(mo) - FRM_pmt(mo),0] );
                
    end
     
    AVG_size_shock1 = mean(pmtshock1)/mean(FRM_pmt) -1 ; %�߸����Ѱ�  saving �� ��� ���� shock size
    AVG_size_shock12 = mean(pmtshock1)/mean(FRM_pmt);   %�̰ɷ� ���
    % payment shock size2  
    pmtshock2=[];
    saving=0;
    
       for mo=1: H *12
        saving = saving + ( FRM_pmt(mo) - ARM_pmt_monthly(mo) );
        
            if saving > 0 
               pmtshock2(end+1,1) = 0 ;
            
            else
              pmtshock2(end+1,1) = -saving;   %������ �κ� (�������� saving�� ������� �ʰ� �׳� FRM_pmt - ARM_pmt�� �ؼ� ������ ���� savingȿ���� ���� ���. 
              saving =0;
            end
            
        end

    AVG_size_shock2 = mean(pmtshock2)/mean(FRM_pmt) -1 ;  %�߸����Ѱ� saving �� ����� shock size
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
                        
            if ARM_pmt_monthly(mo) <= FRM_pmt(mo) && saving == 0       %�߰��� �κ� %�߰��� �κ� %�߰��� �κ� %�߰��� �κ� %�߰��� �κ� %�߰��� �κ� %�߰��� �κ� %�߰��� �κ�
                pmtshock3(end+1,1) = 0;
            end 

       end
       
    AVG_size_shock3 = mean(pmtshock3)/ mean(FRM_pmt);      %Ʋ����  
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
              cashflow_net2(end+1,1) = 0  ; %��ǻ� ARM pmt���ٰ� ���� ��ŭ�� saving���� �����߱� ������ net cash�� 0�� �ȴ�. 
              
            else
              cashflow_net2(end+1,1) = saving ; % saving�� ���⼭�� ���̳ʽ��ε� ARM pmt�� FRM pmt���ٰ� saving�� �ʰ��� ��������.  
              saving =0;
            end
            
      end

      mo= H *12;
      cashflow_net2(end+1,1) =  (FRM_pmt(mo) + FRM_endvalue_H) - (ARM_pmt_monthly(mo) + ARM_endvalue_H) + saving;  %�Ƹ� ���⼭ saving�� �� �׿� �־� FRM cost�� ���� ��Ų��. 
      npv_all2 = pvvar(cashflow_net2, Discountrate/12 );  %FRM cost with saving

    
    
    %%%%% ante ARM�� ���� �κ� ��    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%  E(shock) non saving 8/20����  
    
    Eshock1=[];
    
    for mo=1: H *12
    
    Eshock1(end+1,1) = max( [ARM_pmt_monthly(mo) - FRM_pmt(mo),0] )/FRM_pmt(mo) *100;  % �ۼ�Ƽ���� ����
                
    end
     
    Eshock_nosa = mean( Eshock1 );
        
    %%  E(shock) saving 8/20����  
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
      
    %% E(FRM cost) non saving 8/20����  
    
    
    Efrmcost=[];  %NPV���Ҷ� ���
        
    for mo = 1:H *12
    
        if mo < H*12
        Efrmcost(end+1,1) = ( FRM_pmt(mo)-ARM_pmt_monthly(mo) ) /  FRM_pmt(mo) * 100;  %NPV���ϱ� ���� net cashflow ���� �̸� ����
        else
        Efrmcost(end+1,1) = ( (FRM_pmt(mo) + FRM_endvalue_H) - (ARM_pmt_monthly(mo) + ARM_endvalue_H) ) / FRM_pmt(mo) * 100 ;
        end
        
    end
    
    
    Efrmcost = mean( Efrmcost )  ; %PV�� ��� discount���̶� �ִµ� �̰� �׳� ����̿��� sa, non sa�� ���̰� ����. 
        
    
    
    %%% i=1-1000 ���� NPV, IRR, shock1,2 �� ���� ����.%%%%%%%%%%%%%%%%%%%%%% 
    po_ARM_total = [npv_all, shock1, shock2, AVG_size_shock1, risk_index, risk_ARM, ARM_IRR, AVG_size_shock2, AVG_size_shock12, AVG_size_shock22, AVG_size_shock3, error, npv_all2, Eshock_nosa, Eshock_sa, Efrmcost ];    %8��°�� saving�ɼ��� �� pmt size�� �־���. 
    
 
    
    
end