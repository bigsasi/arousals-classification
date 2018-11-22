function [edfFile] = loadFile(filename)
%LOADSIGNAL load data from edf file, returning the all the data contained
% in the file
%   filename    INPUT file to read signal from
%   edfFile     OUTPUT parsed file info
%       .header EDF file header (info about the polysomnography
%           .version
%           .local_patient_identification
%           .local_recording_identification
%           .starttime_recording
%           .startdate_recording
%           .num_bytes_header
%           .reserved
%           .num_data_records
%           .duration_data_records
%           .num_signals
%           .signals_info (== .signal.header)
%       .signal         struct for each of the signals in the edf file
%           .header     signal info
%               .label
%               .transducter_type
%               .physical_dimension
%               .physical_min
%               .physical_max
%               .digital_min
%               .digital_max
%               .prefiltering
%               .num_samples_data_record
%               .sample_rate
%               .signalOffset
%               .reserved
%           .raw        raw signal as readed from the edf file
%           .filtered   filtered signal, if any
    header = EDFreadHeader(filename);
    edfFile.header = header;
    edfFile.signal = cell(1, header.num_signals);
    for i = 1:header.num_signals
        edfFile.signal{i}.header = header.signals_info(i);
        signal = EDFreadSignal(filename, i, [], []);
        edfFile.signal{i}.raw = signal;
    end
end

