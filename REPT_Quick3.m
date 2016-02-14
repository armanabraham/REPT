function probs = Rapid2_Quick3(params,x)

% Rapid2_Quick3
% 
% Design matrix for QUICK (Weibull) function including lapse rate.
% Returns vector of probabilites corresponding to vector of
% x-values for the three "params". 
% "n" is the no. of observations at each x-value.
%
% - Input arguments 
%   params - parameters for calculating Weibull function
%   x - an array of x values for which Weibull should be calculated
%
% - Output arguments
%   probs - array with Weibull function values
%
% - Example
%   probabilities = Rapid2_Quick3(weibullParams, xValues)
%   
% - Development
%   25.10.99 Colin Clifford: Implemented
%   28.02.03, Colin Cliford: modified
%   01.09.10, Arman: added more comments
%
% - Download page
%   http://www.psych.usyd.edu.au/tmslab/rapid2andrept.html

probs = (1-params(3))*(1 - exp(-((x./params(1)).^params(2)))); %+params(3);
