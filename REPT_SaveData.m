function success = REPT_SaveData(fileName, responses, threshold, duration);

success = 0;

fileHandle = fopen(fileName', 'a');

fprintf(fileHandle, '%s\n', '------------------------------------------');
dateTime = fix(clock);
date = ['Collection date (dd-mm-yyyy):   ', num2str(dateTime(3)), '-', num2str(dateTime(2)), '-', num2str(dateTime(1))];
time = ['Collection time:   ', num2str(dateTime(4)), ':', num2str(dateTime(5))];

fprintf(fileHandle, '%s\n', date);
fprintf(fileHandle, '%s\n', time);
fprintf(fileHandle, '\n');

nResponses = length(responses(:,1));
fprintf(fileHandle, '%s\n', '    Trial  PowerLevel  Response');
for ixResponse = 1:nResponses
    fprintf(fileHandle, '%9.0f', responses(ixResponse, :));
    fprintf(fileHandle, '\n');
end

durationLine = ['REPT duration:  ', num2str(duration), ' sec'];
thresholdLine1 = ['Estimated threshold (at 60%):  ', num2str(threshold(1)), '%'];
thresholdLine2 = ['Estimated threshold (at 50%):  ', num2str(threshold(2)), '%'];

fprintf(fileHandle, '%s\n', durationLine);
fprintf(fileHandle, '%s\n', thresholdLine1);
fprintf(fileHandle, '%s\n', thresholdLine2);

fprintf(fileHandle, '%s\n', '------------------------------------------');
fprintf(fileHandle, '\n');

fclose(fileHandle);
success = 1;

