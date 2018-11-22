function [annotations] = loadAnnotations(filename)
%LOADANNOTATIONS load annotations from a xml file. xml structure should follow 
% shhs xml files. This is, events should be annotated following the structure
% CMPStudyConfig.ScoredEvents.ScoredEvent
%   filename    complete file name (with path) 
%   annotations struct with a field for each event type. Field names are the 
%               ones used in the xml files, without white spaces.
annotations = [];
DOM_object = xmlread(filename);
xml = parseXmlFile(DOM_object);
scoredEventCell = xml.CMPStudyConfig.ScoredEvents.ScoredEvent;
totalEvents = length(scoredEventCell);
for i = 1:totalEvents
    currentEvent = scoredEventCell{i};
    name = regexprep(currentEvent.Name, '[ ()]', '');
    if isfield(annotations, name)
        last = length(annotations.(name));
    else
        last = 0;
    end
    annotations.(name)(last + 1).start = str2double(currentEvent.Start);
    annotations.(name)(last + 1).duration = str2double(currentEvent.Duration);
end


function xmlParsed = parseXmlFile(node)
xmlParsed = struct();
childs = node.getChildNodes;
numChilds = childs.getLength;
for i = 1:numChilds
    child = childs.item(i - 1);
    if child.getNodeType == 3
        xmlParsed = char(child.getTextContent);
    else
        name = char(child.getNodeName);
        if isfield(xmlParsed, name)
            if ~iscell(xmlParsed.(name))            
               tmp = xmlParsed.(name);
               xmlParsed.(name) = cell(1);
               xmlParsed.(name){1} = tmp;
            end
            last = length(xmlParsed.(name));
            xmlParsed.(name){last + 1} = parseXmlFile(child);
        else
            xmlParsed.(name)= parseXmlFile(child);
        end
    end
end

