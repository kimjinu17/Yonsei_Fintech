
function [X, obj, t, short_trend, vasicek_coeff] =fn_shortrate6_nova_HP( history_data, H)
H_varsicek = H-1;
%%% (매트랩코드 제공) Vasicek model%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[short_trend,short_cycle] = hpfilter(history_data,100);  %yearly에서는 smoothing parameter 100 대입


regressors = [ones(length(short_cycle) - 1, 1) short_cycle(1:end-1)];  %(상수항 , 독립변수값) 독립변수는 금리이고 1을 빼준건, 종속변수가 return형식이어서 마지막값이 빠진다. 
[coefficients, intervals, residuals] = regress(diff(short_cycle), regressors);  %(종속변수, 독립변수)
dt    = 1;  % time increment = 1 year /
speed = -coefficients(2)/dt;  %coefficients(1):상수항(알파), coefficients(2): 베타.
level = -coefficients(1)/coefficients(2); 
sigma =  std(residuals)/sqrt(dt);

vasicek_coeff = [speed, level, sigma];

obj = hwv(speed, level, sigma, 'StartState', short_cycle(end));  %Hull-White/Vasicek Gaussian Diffusion model.
                                                                    %Create and displays hwv objects, which derive from the sdemrd 
                                                                    %(SDE with drift rate expressed in mean-reverting form) class.
                                                                    %Startstate 는 현재추정에 사용된 가장 마지막 데이터를 초기값으로 하고 마지막값은 나중에 기댓값으로 정한다. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% power of two algorithm의 순서 입력 %%%%%%%%%%%%%%%%%%%%%

%%%%(매트랩코드 제공)  2 power algorithm 사용시 아래 코드 추가 %%%%%
% times  = (1:H_varsicek)';
% t      = NaN(length(times) + 1, 1);  %interepolation 순서 넣음
% t(1)   = obj.StartTime;  %첫번째에는 0번을 기입
% t(2)   = H_varsicek;  %2번째에는 만기가 되는 순차를 넣음
% delta  = H_varsicek;
% jMax   = 1;
% iCount = 3;  %interest rate 이 3month interval을 갖는다고 가정하는 듯

% for k = 1:log2(H_varsicek)  % 여기서는 t에 앞으로 power of two algorithm을 하기위해 interpolation 순서를 정한다. 
%     i = delta / 2;
%     for j = 1:jMax
%         t(iCount) = times(i);
%         i         = i + delta;
%         iCount    = iCount + 1;
%     end
%     jMax  = 2 * jMax;
%     delta = delta / 2;
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% t=[0;10;4;8;2;6;1;3;5;7;9];
t=[0;9;4;8;2;6;1;3;5;7] ;

%%%%%%%%%%%%%%%%%%%%%%%%% 2 power algorithm 그림 그릴려면 아래 코드 추가 %%%%%
% stem(1:length(t), t, 'filled')
% xlabel('Index'), ylabel('Interpolation Time (Days)')
% title ('Sampling Scheme for the Power-of-Two Algorithm')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

average = obj.StartState * exp(-speed * H_varsicek) + level * (1 - exp(-speed * H_varsicek)); %(매트랩코드 제공)  Average of short rate at T from Vasicek model.  mean of dX_T ->자세한건 위키피디아에 공식으로 나와 있음  
                   
% % % % % % % %    
X       = [obj.StartState ; average] ;   % interpolation값으로 최초값인 initial and end value를 기입



end
