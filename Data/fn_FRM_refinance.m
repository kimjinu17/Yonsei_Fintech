function [FRM_i] =fn_FRM_refinance(FRM_rate, loan, H, T, po_long_rate)

    FRM_begin_bal=loan;  %FRM beginning balance
%     FRM_pmt = payper(FRM_rate/12, T*12, loan);  %FRM payment
    FRM_r_pmt=[];  %FRM interest payment
    FRM_prin_pmt=[];  %FRM principal payment
    FRM_ending_bal=[];   %FRM ending balance
    FRM_rate_total=[];
    FRM_pmt_all=[];
    %%% refinancing
       
    mo=1 ; 
    FRM_rate = po_long_rate(mo);  %initial��
    
    while mo <= (H-1)*12 %�켱 9���� holding�Ⱓ���� refinancing�� ���ɴ�. ������ 10��°�� ���� FRM rate�� �����ϴ� ���̱� ������ ���� ����Ѵ�. (���� ���⼭ 9�������� refinancing�� �ϸ� �Ѿ�⵵ �Ѵ�)
        
         %FRM payment
       if FRM_rate < po_long_rate(mo) + 0.01 % 1% �̸����� �������� ���� FRM rate���� �׳� ���Ѵ�. 
            FRM_pmt = payper(FRM_rate/12, T*12-mo, FRM_begin_bal(end) );
            FRM_rate_total(end+1,1) = FRM_rate ; 
            FRM_r_pmt(end+1,1) = FRM_begin_bal(mo) * FRM_rate /12 ;  %annualized�� �������� 12�� ������ �̹� monthly rate�̸� �׳� ���� �ȴ�. 
            FRM_prin_pmt(end+1,1) = FRM_pmt - FRM_r_pmt(mo) ;
            FRM_ending_bal(end+1,1) =  FRM_begin_bal(mo) - FRM_prin_pmt(mo)  ;
            FRM_begin_bal(end+1,1) = FRM_ending_bal(mo) ;
            FRM_pmt_all(end+1,1 ) = FRM_pmt ;
            mo=mo+1 ;   
        
       else if FRM_rate >= po_long_rate(mo) + 0.01 &&  mo <= 12  %ó�����۽� (12���� �̸�) FRMrate�� �۾Ƶ� ��ȯ�� �Ұ��ϴ�. �� ������ ������ if�� �´� ������ ã�� ���� ���ѷ����� ���� (�Ʒ� else if�� ��Ȯ�� ������ ���ϸ� ��ü�� Ŀ���Ѵ�). 
            FRM_pmt = payper(FRM_rate/12, T*12-mo, FRM_begin_bal(end) );
            FRM_rate_total(end+1,1) = FRM_rate ; 
            FRM_r_pmt(end+1,1) = FRM_begin_bal(mo) * FRM_rate /12 ;  %annualized�� �������� 12�� ������ �̹� monthly rate�̸� �׳� ���� �ȴ�. 
            FRM_prin_pmt(end+1,1) = FRM_pmt - FRM_r_pmt(mo) ;
            FRM_ending_bal(end+1,1) =  FRM_begin_bal(mo) - FRM_prin_pmt(mo)  ;
            FRM_begin_bal(end+1,1) = FRM_ending_bal(mo) ;
            FRM_pmt_all(end+1,1 ) = FRM_pmt ;
            mo=mo+1 ; 
            
        else if FRM_rate >= po_long_rate(mo) + 0.01 &&  mo > 12 % ���� 1�������� 1%�̻� �������� refinancing�� �̵��̴�.�׷��� holding period���� 12������ �� �̸��� ��¥������ refinancing�Ҹ��� ���ڷ� ����Ѵ�. 
            FRM_rate = po_long_rate(mo) ; 
            FRM_rate_total(end+1,1) = FRM_rate ;
            mo3=mo ; 
            FRM_pmt = payper(FRM_rate/12, T*12-mo3, FRM_begin_bal(end) );  %FRM payment
            FRM_r_pmt(end+1,1) = FRM_begin_bal(mo3) * FRM_rate /12 ;  % annualized�� �������� 12�� ������ �̹� monthly rate�̸� �׳� ���� �ȴ�. 
            FRM_prin_pmt(end+1,1) = FRM_pmt - FRM_r_pmt(mo3) ;
            FRM_ending_bal(end+1,1) =  FRM_begin_bal(mo3) - FRM_prin_pmt(mo3)  ;
            FRM_begin_bal(end+1,1) = FRM_ending_bal(mo3) ;
            FRM_pmt_all(end+1,1 ) = FRM_pmt + 4500 ; % ������ ������ ��� �Ʒ� for���� ���� ������ ���ߴ�. refinancing cost 4500$  �뷫 1�⵿�� 40���޷��� 1% ������ �ݾ׿����� �������� ����. �̿� 4000�޷��� ���� ����� ������ �־� 4500�޷���(�赿�ű���������)
            
            for mo2=1:11 %�ش� refinace�� rate���� ������ 1���� �ǹ� ��������� ������ ó�� 1������ ��� ������ �������� �Ʒ� 11���� ���� ����. �Ʒ� for������ ���������� �ش� rate���θ� �ش� ���� FRM rate�� �񱳾��� ������. 
            mo3=mo+mo2 ; 
            FRM_rate_total(end+1,1) = FRM_rate ;
            FRM_pmt = payper(FRM_rate/12, T*12-mo3, FRM_begin_bal(end) );  %FRM payment
            FRM_r_pmt(end+1,1) = FRM_begin_bal(mo3) * FRM_rate /12 ;  % annualized�� �������� 12�� ������ �̹� monthly rate�̸� �׳� ���� �ȴ�. 
            FRM_prin_pmt(end+1,1) = FRM_pmt - FRM_r_pmt(mo3) ;
            FRM_ending_bal(end+1,1) =  FRM_begin_bal(mo3) - FRM_prin_pmt(mo3)  ;
            FRM_begin_bal(end+1,1) = FRM_ending_bal(mo3) ;
            FRM_pmt_all(end+1,1 ) = FRM_pmt ; 
            end
       
            mo = mo3 +1; 
            end
           end
       end
                  
    end
    
    
    %���⼭�� ������ 12������ ���� FRM payment�� �����Ѵ�. �ٸ� ������ refinancing�� ������ 24��������
    %13�����̳����� ����ȴٸ� �̸� ���� �����Ͽ��� ������ ������ ���� �ΰ��� ���ǹ����� �����Ѵ�. 
    
    if mo == length(FRM_rate_total)+1  %���� FRM �����̳����� �̹� �Ϸ� �ϰ� ���� �ݸ��� �� �������� �ʴ»�Ȳ
    
        for mo2=0:11 
            mo3=mo+mo2;   
            FRM_rate_total(end+1,1) = FRM_rate ;
            FRM_pmt = payper(FRM_rate/12, T*12-mo3, FRM_begin_bal(end) );  %FRM payment
            FRM_r_pmt(end+1,1) = FRM_begin_bal(mo3) * FRM_rate /12 ;  % annualized�� �������� 12�� ������ �̹� monthly rate�̸� �׳� ���� �ȴ�. 
            FRM_prin_pmt(end+1,1) = FRM_pmt - FRM_r_pmt(mo3) ;
            FRM_ending_bal(end+1,1) =  FRM_begin_bal(mo3) - FRM_prin_pmt(mo3)  ;
            FRM_begin_bal(end+1,1) = FRM_ending_bal(mo3) ;
            FRM_pmt_all(end+1,1 ) = FRM_pmt ; %
        end
       
    else if mo-1 < length(FRM_rate_total)  %���� FRM �����̳����� ������ 12���� �������� �̹� ����� ��Ȳ�̰� ������ ��������ŭ �� ���� �ϴ� ��Ȳ
        mo=length(FRM_rate); %mo�� FRM_rateũ�⸸ŭ ��ȯ�Ѵ�. 
        for mo2=1:H*12-length(FRM_rate) %��ü 120������ �̹� refinancing���� ����� 12���� ��ŭ�� ���ϰ� ������ �������� ���
            mo3=mo+mo2;   
            FRM_rate_total(end+1,1) = FRM_rate ;
            FRM_pmt = payper(FRM_rate/12, T*12-mo3, FRM_begin_bal(end) );  %FRM payment
            FRM_r_pmt(end+1,1) = FRM_begin_bal(mo3) * FRM_rate /12 ;  % annualized�� �������� 12�� ������ �̹� monthly rate�̸� �׳� ���� �ȴ�. 
            FRM_prin_pmt(end+1,1) = FRM_pmt - FRM_r_pmt(mo3) ;
            FRM_ending_bal(end+1,1) =  FRM_begin_bal(mo3) - FRM_prin_pmt(mo3)  ;
            FRM_begin_bal(end+1,1) = FRM_ending_bal(mo3) ;
            FRM_pmt_all(end+1,1 ) = FRM_pmt ; %   
        end
        end
        
        
    end
    
    
    FRM_begin_bal = FRM_begin_bal(1:end-1,1) ;    
    FRM_i = [ [1:H*12]', FRM_begin_bal, FRM_pmt_all, FRM_r_pmt, FRM_prin_pmt, FRM_ending_bal, FRM_rate_total];
        
    
end

