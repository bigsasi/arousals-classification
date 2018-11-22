function annotations = EDFreadAnnotations(filename, doSkipTimeKeep)

% Skips 'Time-keep' annotations
if isempty(doSkipTimeKeep)
    doSkipTimeKeep = 0;
end

general_header_size = 256; %bytes
one_signal_header_size = 256; %bytes

header = EDFreadHeader(filename);

fid = fopen(filename);

if (fid == -1)
    disp('Error opening the file');
    return;
end

bytes_full_data_record = 2 * sum([header.signals_info.num_samples_datarecord]);
header_length = general_header_size + header.num_signals * one_signal_header_size;

% Set the pointer to the annotations signal
signalIndex = header.num_signals;

if not(strcmpi(header.signals_info(signalIndex).label', 'EDF Annotations '))
    disp('Error: Not annotation signals was found in the file');
    return;
end

% Positioning on the begining of the selected file
fseek(fid, header_length + header.signals_info(signalIndex).signalOffset, 'bof');

record_size = header.signals_info(signalIndex).num_samples_datarecord;

% We will read all the annotations
numRecords2read = header.num_data_records;

% Data reading
data = fread(fid, record_size*numRecords2read, strcat(num2str(record_size),'*uint16=>uint16'), bytes_full_data_record - 2*record_size);
fclose(fid);

data = typecast(data, 'uint8'); % From two's complement to 1-byte US-ASCII characters

%eventsall = typecast(int16(eventstmp(:,i)),'uint8')';
header.events.TYP = [];
header.events.POS = [];
header.events.DUR = [];
header.events.OFF = [];
eventsall = data;
tmp = find(eventsall == 20); % ASCII '20' separates each annotation after the time stamp (onset+duration)
% Detection of 'end of TAL': ASCII '20' followed by ASCII '0'. Each TAL may contain several annotations, and the last one finishes with this combination
% Note: Each TAL shares time_stamp and duration. Several TALS can be
%       included in the same block, but the first one contains an empty
%       annotation that indicates the time_stamp of the block itself.
numberTALends = tmp(eventsall(tmp+1) == 0); 
eventsall(eventsall == 32) = 95; % Blank spaces (32) are substituted by underscores? (95 -> _)

annotations.start = [];
annotations.duration = [];
annotations.label = [];
annotations.offset = [];
for k = 1:length(numberTALends)
    if (k == 1)
        tal = eventsall(1:numberTALends(1));
    else
        tal = eventsall(numberTALends(k-1)+2:numberTALends(k));
    end
   % Find offset and duration
   sep = find(tal == 20);
   indxDur = find(tal == 21);
   if isempty(indxDur)
       dur = 0;
       offset = str2double(native2unicode(tal(1:sep(1)-1)));
   else
       dur = str2double(native2unicode(tal(indxDur(1)+1:sep(1)-1)));
       offset = str2double(native2unicode(tal(1:indxDur(1)-1)));
   end
   % Read annotations
   for k1 = 1:length(sep)-1
       tmp = native2unicode(tal(sep(k1)+1:sep(k1+1)-1));
       if length(tmp) == 0
           annotations.label = [annotations.label, {'Time-keep'}];
       else
           %annotations.label = [annotations.label, textscan(tmp, '%s')];
           annotations.label = [annotations.label, {sprintf('%s', tmp)}];
       end
       annotations.start = [annotations.start, offset]; % TODO, add to startdate time
       annotations.offset = [annotations.offset, offset];
       annotations.duration = [annotations.duration, dur];
   end
end

if doSkipTimeKeep
    indxTimeKeep = strcmpi(annotations.label, 'Time-keep');
    annotations.start(indxTimeKeep) = [];
    annotations.offset(indxTimeKeep) = [];
    annotations.duration(indxTimeKeep) = [];
    annotations.label(indxTimeKeep) = [];
end

disp('Finished');