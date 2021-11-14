
function [X, obj, t, short_trend, vasicek_coeff] =fn_shortrate6_nova_HP( history_data, H)
H_varsicek = H-1;
%%% (��Ʈ���ڵ� ����) Vasicek model%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[short_trend,short_cycle] = hpfilter(history_data,100);  %yearly������ smoothing parameter 100 ����


regressors = [ones(length(short_cycle) - 1, 1) short_cycle(1:end-1)];  %(����� , ����������) ���������� �ݸ��̰� 1�� ���ذ�, ���Ӻ����� return�����̾ ���������� ������. 
[coefficients, intervals, residuals] = regress(diff(short_cycle), regressors);  %(���Ӻ���, ��������)
dt    = 1;  % time increment = 1 year /
speed = -coefficients(2)/dt;  %coefficients(1):�����(����), coefficients(2): ��Ÿ.
level = -coefficients(1)/coefficients(2); 
sigma =  std(residuals)/sqrt(dt);

vasicek_coeff = [speed, level, sigma];

obj = hwv(speed, level, sigma, 'StartState', short_cycle(end));  %Hull-White/Vasicek Gaussian Diffusion model.
                                                                    %Create and displays hwv objects, which derive from the sdemrd 
                                                                    %(SDE with drift rate expressed in mean-reverting form) class.
                                                                    %Startstate �� ���������� ���� ���� ������ �����͸� �ʱⰪ���� �ϰ� ���������� ���߿� ������� ���Ѵ�. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% power of two algorithm�� ���� �Է� %%%%%%%%%%%%%%%%%%%%%

%%%%(��Ʈ���ڵ� ����)  2 power algorithm ���� �Ʒ� �ڵ� �߰� %%%%%
% times  = (1:H_varsicek)';
% t      = NaN(length(times) + 1, 1);  %interepolation ���� ����
% t(1)   = obj.StartTime;  %ù��°���� 0���� ����
% t(2)   = H_varsicek;  %2��°���� ���Ⱑ �Ǵ� ������ ����
% delta  = H_varsicek;
% jMax   = 1;
% iCount = 3;  %interest rate �� 3month interval�� ���´ٰ� �����ϴ� ��

% for k = 1:log2(H_varsicek)  % ���⼭�� t�� ������ power of two algorithm�� �ϱ����� interpolation ������ ���Ѵ�. 
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

%%%%%%%%%%%%%%%%%%%%%%%%% 2 power algorithm �׸� �׸����� �Ʒ� �ڵ� �߰� %%%%%
% stem(1:length(t), t, 'filled')
% xlabel('Index'), ylabel('Interpolation Time (Days)')
% title ('Sampling Scheme for the Power-of-Two Algorithm')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

average = obj.StartState * exp(-speed * H_varsicek) + level * (1 - exp(-speed * H_varsicek)); %(��Ʈ���ڵ� ����)  Average of short rate at T from Vasicek model.  mean of dX_T ->�ڼ��Ѱ� ��Ű�ǵ�ƿ� �������� ���� ����  
                   
% % % % % % % %    
X       = [obj.StartState ; average] ;   % interpolation������ ���ʰ��� initial and end value�� ����



end
