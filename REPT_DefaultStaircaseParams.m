function [success, staircaseParams] = REPT_DefaultStaircaseParams

% Assign default staircase parameters 

% --- Implementation 
% 16.10.08, Arman
% 20.11.08, Arman: changed default parameters for the staircase to be more
% optimal for the phosphene threshold identification
% 18.06.10, Arman: changed xlevels and alevels from 30 to 31 for ease of
% specifying the pulse intensity range in even numbers, such as from 40 -
% 70, which includes 31 integer numbers. 

% --- Input arguments
% None

% --- Output arguments 
% success - 0 if something goes wrong, 1 if the function execution succeeded
% staircaseParams - default staircase parameters as a structure 

% --- Example 
% [success, staircaseParams] = REPT_DefaultStaircaseParams

% --- Let's start

success = 0; 

staircaseParams.xlevels = 31; 
staircaseParams.xstep = 10^.005; %10^.05
staircaseParams.xmin = .05;

staircaseParams.alevels = 31; 
staircaseParams.astep = 10^.005; %10^.05;
staircaseParams.amin = .05;

staircaseParams.blevels = 90; 
staircaseParams.bstep = 0.25;
staircaseParams.bbase = .5;

success = 1; 
