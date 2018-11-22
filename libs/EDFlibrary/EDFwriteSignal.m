function statusok = EDFwriteSignal(header, signal, filename, logConversion)

fid = fopen(filename, 'r+', 'ieee-le');

if (fid == -1)
    disp('Error creating output file');
    return;
end

general_header_size = 256; %bytes
one_signal_header_size = 256; %bytes

% Write edf

% FIXED HEADER
fprintf(fid, trimAndFillWithBlanks(num2str(header.version), 8));   % version
fprintf(fid, '%-80s', header.local_patient_identification);
fprintf(fid, '%-80s', header.local_recording_identification);
fprintf(fid, '%-8s', header.startdate_recording);
fprintf(fid, '%-8s', header.starttime_recording);
actualHeaderBytes = general_header_size + one_signal_header_size*header.num_signals;
if (ne(actualHeaderBytes, header.num_bytes_header))
    disp('EDFwriteSignal: Warning, num_bytes_header does not match the actual number of header bytes. Fixed!');
end
fprintf(fid, trimAndFillWithBlanks(num2str(actualHeaderBytes), 8));
fprintf(fid, '%-44s', header.reserved);
fprintf(fid, trimAndFillWithBlanks(num2str(header.num_data_records), 8));
fprintf(fid, trimAndFillWithBlanks(num2str(header.duration_data_record), 8));
fprintf(fid, trimAndFillWithBlanks(num2str(header.num_signals), 4));

% SIGNAL DEPENDENT HEADER
ns = header.num_signals;
for k = 1:ns
    fprintf(fid, '%-16s', header.signals_info(k).label);
end
for k = 1:ns
    fprintf(fid, '%-80s', header.signals_info(k).transducer_type);
end
for k = 1:ns
    fprintf(fid, '%-8s', header.signals_info(k).physical_dimension);
end
for k = 1:ns
    fprintf(fid, trimAndFillWithBlanks(num2str(header.signals_info(k).physical_min), 8));
end
for k = 1:ns
    fprintf(fid, trimAndFillWithBlanks(num2str(header.signals_info(k).physical_max), 8));
end
for k = 1:ns
    fprintf(fid, trimAndFillWithBlanks(num2str(header.signals_info(k).digital_min), 8));
end
for k = 1:ns
    fprintf(fid, trimAndFillWithBlanks(num2str(header.signals_info(k).digital_max), 8));
end
for k = 1:ns
    fprintf(fid, '%-80s', header.signals_info(k).prefiltering);
end
signalOffsets = zeros(1, ns); % In bytes
for k = 1:ns
    fprintf(fid, trimAndFillWithBlanks(num2str(header.signals_info(k).num_samples_datarecord), 8));
    if (k > 1)
        signalOffsets(k) = signalOffsets(k - 1) + 2 * header.signals_info(k - 1).num_samples_datarecord;
    end
end
for k = 1:ns
    fprintf(fid, '%-32s', header.signals_info(k).reserved);
end

% DATA WRITING
signalIndex = 1;
numRecords2write = header.num_data_records; %for the moment we trust header information and write the full signal
record_size = header.signals_info(signalIndex).num_samples_datarecord;

header_length = general_header_size + ns * one_signal_header_size;
current_position = ftell(fid); % in bytes

if ne(header_length, current_position)
    disp('something wrong could be happening');
end

bytes_full_data_record = 2 * sum([header.signals_info.num_samples_datarecord]);

% Positioning on the begining of the selected file
startRec = 0;
if ne(signalIndex, 1)
    fseek(fid, header_length + (bytes_full_data_record * startRec) + signalOffsets(signalIndex), 'bof');
end

Pmin = header.signals_info(signalIndex).physical_min;
Pmax = header.signals_info(signalIndex).physical_max;
Dmin = header.signals_info(signalIndex).digital_min;
Dmax = header.signals_info(signalIndex).digital_max;

LogFloatA = 0.001;
LogFloatY0 = 0.0001;

if logConversion
    data = Dmin + (Dmax - Dmin) * (LogFloatVector(double(signal), LogFloatY0, LogFloatA) - Pmin)/(Pmax - Pmin);
else
    data = Dmin + (Dmax - Dmin) * (double(signal) - Pmin)/(Pmax - Pmin);
end

% PreCD: Data is in A2 complement format and each column in data is a different signal
for k = 1:numRecords2write
    current_pos = ftell(fid);
    fwrite(fid, data((k-1)*record_size+1:k*record_size));
    next_pos = current_pos + bytes_full_data_record - 2 * record_size;
    fseek(fid, next_pos, 'bof');
end
%fwrite(fid, data, 'int16');
fclose(fid);

%data = typecast(data, 'int16'); % From two's complement to signed integers
