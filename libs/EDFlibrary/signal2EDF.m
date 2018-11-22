function statusok = signal2EDF(signal, sr, patId, recId, sname, startdate, starttime, Pmin, Pmax, Dmin, Dmax, units, prefiltering, filename)

fid = fopen(filename, 'w', 'ieee-le');

if (fid == -1)
    disp('Error creating output file');
    return;
end

general_header_size = 256; %bytes
one_signal_header_size = 256; %bytes

% Write edf

% FIXED HEADER
header.version = 0;
header.local_patient_identification = patId;
header.local_recording_identification = recId;
header.startdate_recording = startdate;
header.starttime_recording = starttime;
header.num_signals = 1;
header.num_bytes_header = general_header_size + one_signal_header_size;
header.reserved = '';
header.duration_data_record = 1;
header.num_data_records = ceil(length(signal) / sr);

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
header.signals_info(1).label = sname;
header.signals_info(1).transducer_type = '';
header.signals_info(1).physical_dimension = units;
header.signals_info(1).physical_min = Pmin;
header.signals_info(1).physical_max = Pmax;
header.signals_info(1).digital_min = Dmin;
header.signals_info(1).digital_max = Dmax;
header.signals_info(1).prefiltering = prefiltering;
header.signals_info(1).num_samples_datarecord = sr;
header.signals_info(1).reserved = '';

fprintf(fid, '%-16s', header.signals_info(1).label);
fprintf(fid, '%-80s', header.signals_info(1).transducer_type);
fprintf(fid, '%-8s', header.signals_info(1).physical_dimension);
fprintf(fid, trimAndFillWithBlanks(num2str(header.signals_info(1).physical_min), 8));
fprintf(fid, trimAndFillWithBlanks(num2str(header.signals_info(1).physical_max), 8));
fprintf(fid, trimAndFillWithBlanks(num2str(header.signals_info(1).digital_min), 8));
fprintf(fid, trimAndFillWithBlanks(num2str(header.signals_info(1).digital_max), 8));
fprintf(fid, '%-80s', header.signals_info(1).prefiltering);
fprintf(fid, trimAndFillWithBlanks(num2str(header.signals_info(1).num_samples_datarecord), 8));
fprintf(fid, '%-32s', header.signals_info(1).reserved);

% DATA WRITING
signalIndex = 1;
numRecords2write = header.num_data_records; %for the moment we trust header information and write the full signal
%record_size = header.signals_info(signalIndex).num_samples_datarecord;

header_length = general_header_size + header.num_signals * one_signal_header_size;
current_position = ftell(fid); % in bytes

if ne(header_length, current_position)
    disp('something wrong could be happening');
end

bytes_full_data_record = 2 * sum([header.signals_info.num_samples_datarecord]);

% Positioning on the begining of the selected file
startRec = 0;
%fseek(fid, header_length + (bytes_full_data_record * startRec), 'bof');

logConversion = strcmp(header.signals_info(signalIndex).physical_dimension', 'Filtered');
if logConversion
    % Parse prefiltering to set this values
    tokens = textscan(header.signals_info(signalIndex).prefiltering, 'sign*LN[sign*(at %.1fHz)/(%.5f)]/(%.5f)(Kemp:J Sleep Res 1998-supp2:132)');
    if isempty(tokens{2})
        disp('Warning: assigned default values to logConversion');
        LogFloatY0 = 0.0001; % default value
    else
        LogFloatY0 = tokens{2};
    end
    if isempty(tokens{3})
        disp('Warning: assigned default values to logConversion');
        LogFloatA = 0.001; % default value
    else
        LogFloatA = tokens{3};
    end
    
    % Actual writing
    data = Dmin + (Dmax - Dmin) * (LogFloatVector(signal, LogFloatY0, LogFloatA) - Pmin)/(Pmax - Pmin);
else
    data = Dmin + (Dmax - Dmin) * (signal - Pmin)/(Pmax - Pmin);
end
data = typecast(int16(data), 'uint16'); % From double to 16bit unsigned integers

fwrite(fid, data, 'uint16');
statusok = (fclose(fid) == 0);
