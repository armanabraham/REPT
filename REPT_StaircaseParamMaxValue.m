function maxValue = REPT_StaircaseParamMaxValue(min, step, levels)

% Calculate max value either for x, a or b parameter. 
% 17 Oct 2008, Arman
%
% --- Input arguments
% min - min value of either x, a or b
% step - step of either x, a, or b
% levels - levels of either x, a or b
%
% --- Output arguments 
% maxValue = maximum value that x, a or b parameter can assume


% --- Let's start
allValues = zeros(1, levels);
allValues(1) = min;
for ixValue = 2:levels
    allValues(ixValue) = allValues(ixValue - 1) * step;
end

maxValue = max(allValues);




