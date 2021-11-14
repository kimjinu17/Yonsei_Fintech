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
    FRM_rate = po_long_rate(mo);  %initial값
    
    while mo <= (H-1)*12 %우선 9년의 holding기간동안 refinancing을 살핀다. 마지막 10년째는 기존 FRM rate을 유지하는 쪽이기 때문에 따로 고려한다. (물론 여기서 9년쯔음에 refinancing을 하면 넘어가기도 한다)
        
         %FRM payment
       if FRM_rate < po_long_rate(mo) + 0.01 % 1% 미만으로 내려가면 현재 FRM rate으로 그냥 구한다. 
            FRM_pmt = payper(FRM_rate/12, T*12-mo, FRM_begin_bal(end) );
            FRM_rate_total(end+1,1) = FRM_rate ; 
            FRM_r_pmt(end+1,1) = FRM_begin_bal(mo) * FRM_rate /12 ;  %annualized된 이자율은 12를 나누고 이미 monthly rate이면 그냥 쓰면 된다. 
            FRM_prin_pmt(end+1,1) = FRM_pmt - FRM_r_pmt(mo) ;
            FRM_ending_bal(end+1,1) =  FRM_begin_bal(mo) - FRM_prin_pmt(mo)  ;
            FRM_begin_bal(end+1,1) = FRM_ending_bal(mo) ;
            FRM_pmt_all(end+1,1 ) = FRM_pmt ;
            mo=mo+1 ;   
        
       else if FRM_rate >= po_long_rate(mo) + 0.01 &&  mo <= 12  %처음시작시 (12개월 미만) FRMrate이 작아도 변환이 불가하다. 이 조건이 없으면 if에 맞는 조건을 찾지 못해 무한루프를 돈다 (아래 else if랑 정확히 조건을 합하면 전체를 커버한다). 
            FRM_pmt = payper(FRM_rate/12, T*12-mo, FRM_begin_bal(end) );
            FRM_rate_total(end+1,1) = FRM_rate ; 
            FRM_r_pmt(end+1,1) = FRM_begin_bal(mo) * FRM_rate /12 ;  %annualized된 이자율은 12를 나누고 이미 monthly rate이면 그냥 쓰면 된다. 
            FRM_prin_pmt(end+1,1) = FRM_pmt - FRM_r_pmt(mo) ;
            FRM_ending_bal(end+1,1) =  FRM_begin_bal(mo) - FRM_prin_pmt(mo)  ;
            FRM_begin_bal(end+1,1) = FRM_ending_bal(mo) ;
            FRM_pmt_all(end+1,1 ) = FRM_pmt ;
            mo=mo+1 ; 
            
        else if FRM_rate >= po_long_rate(mo) + 0.01 &&  mo > 12 % 만기 1년전까지 1%이상 떨어지면 refinancing이 이득이다.그래서 holding period에서 12개월을 뺀 미만의 날짜까지만 refinancing할만한 일자로 고려한다. 
            FRM_rate = po_long_rate(mo) ; 
            FRM_rate_total(end+1,1) = FRM_rate ;
            mo3=mo ; 
            FRM_pmt = payper(FRM_rate/12, T*12-mo3, FRM_begin_bal(end) );  %FRM payment
            FRM_r_pmt(end+1,1) = FRM_begin_bal(mo3) * FRM_rate /12 ;  % annualized된 이자율은 12를 나누고 이미 monthly rate이면 그냥 쓰면 된다. 
            FRM_prin_pmt(end+1,1) = FRM_pmt - FRM_r_pmt(mo3) ;
            FRM_ending_bal(end+1,1) =  FRM_begin_bal(mo3) - FRM_prin_pmt(mo3)  ;
            FRM_begin_bal(end+1,1) = FRM_ending_bal(mo3) ;
            FRM_pmt_all(end+1,1 ) = FRM_pmt + 4500 ; % 이조건 때문에 사실 아래 for문에 같이 넣지를 못했다. refinancing cost 4500$  대략 1년동안 40만달러를 1% 할인한 금액에대한 보상으로 여김. 이에 4000달러에 여러 보험료 지급이 있어 4500달러로(김동신교수님제안)
            
            for mo2=1:11 %해당 refinace한 rate으로 무조건 1년은 의무 계약임으로 위에서 처음 1개월은 고려 했으니 나머지는 아래 11개월 동안 진행. 아래 for문으로 강제적으로 해당 rate으로만 해당 월의 FRM rate과 비교없이 돌린다. 
            mo3=mo+mo2 ; 
            FRM_rate_total(end+1,1) = FRM_rate ;
            FRM_pmt = payper(FRM_rate/12, T*12-mo3, FRM_begin_bal(end) );  %FRM payment
            FRM_r_pmt(end+1,1) = FRM_begin_bal(mo3) * FRM_rate /12 ;  % annualized된 이자율은 12를 나누고 이미 monthly rate이면 그냥 쓰면 된다. 
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
    
    
    %여기서는 마지막 12개월에 대한 FRM payment를 정리한다. 다만 위에서 refinancing이 마지막 24개월에서
    %13개월이내에서 진행된다면 이를 따로 정리하여야 함으로 다음과 같은 두가지 조건문으로 정리한다. 
    
    if mo == length(FRM_rate_total)+1  %만약 FRM 리파이낸싱이 이미 완료 하고 따히 금리가 더 떨어지지 않는상황
    
        for mo2=0:11 
            mo3=mo+mo2;   
            FRM_rate_total(end+1,1) = FRM_rate ;
            FRM_pmt = payper(FRM_rate/12, T*12-mo3, FRM_begin_bal(end) );  %FRM payment
            FRM_r_pmt(end+1,1) = FRM_begin_bal(mo3) * FRM_rate /12 ;  % annualized된 이자율은 12를 나누고 이미 monthly rate이면 그냥 쓰면 된다. 
            FRM_prin_pmt(end+1,1) = FRM_pmt - FRM_r_pmt(mo3) ;
            FRM_ending_bal(end+1,1) =  FRM_begin_bal(mo3) - FRM_prin_pmt(mo3)  ;
            FRM_begin_bal(end+1,1) = FRM_ending_bal(mo3) ;
            FRM_pmt_all(end+1,1 ) = FRM_pmt ; %
        end
       
    else if mo-1 < length(FRM_rate_total)  %만약 FRM 리파이낸싱이 마지막 12개월 내에서도 이미 진행된 상황이고 나머지 개월수만큼 더 내야 하는 상황
        mo=length(FRM_rate); %mo를 FRM_rate크기만큼 반환한다. 
        for mo2=1:H*12-length(FRM_rate) %전체 120개월중 이미 refinancing으로 진행된 12개월 만큼을 제하고 나머지 개월수만 계산
            mo3=mo+mo2;   
            FRM_rate_total(end+1,1) = FRM_rate ;
            FRM_pmt = payper(FRM_rate/12, T*12-mo3, FRM_begin_bal(end) );  %FRM payment
            FRM_r_pmt(end+1,1) = FRM_begin_bal(mo3) * FRM_rate /12 ;  % annualized된 이자율은 12를 나누고 이미 monthly rate이면 그냥 쓰면 된다. 
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

