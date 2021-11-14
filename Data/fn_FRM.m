function [FRM_i] =fn_FRM( FRM_rate, loan, H, T)

%     FRM_rate=0.045 ; %¿¢¼¿ ¿¬½À¿ë ¿¢¼¿ ¿¬½À¿ë ¿¢¼¿ ¿¬½À¿ë ¿¢¼¿ ¿¬½À¿ë ¿¢¼¿ ¿¬½À¿ë
%     T=30 ;   %¿¢¼¿ ¿¹Á¦ Å×½ºÆ®¿ë ¿¢¼¿ ¿¬½À¿ë ¿¢¼¿ ¿¬½À¿ë ¿¢¼¿ ¿¬½À¿ë ¿¢¼¿ ¿¬½À¿ë 
    
    FRM_begin_bal=loan;  %FRM beginning balance
    FRM_pmt = payper(FRM_rate/12, T*12, loan);  %FRM payment
    FRM_r_pmt=[];  %FRM interest payment
    FRM_prin_pmt=[];  %FRM principal payment
    FRM_ending_bal=[];   %FRM ending balance
    
    for mo=1:T*12 
    FRM_r_pmt(end+1,1) = FRM_begin_bal(mo) * FRM_rate /12 ;  %annualizedµÈ ÀÌÀÚÀ²Àº 12¸¦ ³ª´©°í ÀÌ¹Ì monthly rateÀÌ¸é ±×³É ¾²¸é µÈ´Ù. 
    FRM_prin_pmt(end+1,1) = FRM_pmt - FRM_r_pmt(mo) ;
    FRM_ending_bal(end+1,1) =  FRM_begin_bal(mo) - FRM_prin_pmt(mo)  ;
    FRM_begin_bal(end+1,1) = FRM_ending_bal(mo) ;
    end    
    
    FRM_begin_bal = FRM_begin_bal(1:end-1,1) ;
    FRM_pmt = ones( T*12, 1 ) * FRM_pmt;
    FRM_i = [ [1:T*12]', FRM_begin_bal, FRM_pmt, FRM_r_pmt, FRM_prin_pmt, FRM_ending_bal];
    
end
