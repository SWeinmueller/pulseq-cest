classdef EventLibrary < handle
    % EventLibrary   Maintain a list of events.
    %
    % The class is used by the Sequence class to store events of an MRI 
    % sequence defined using the Pulseq file format.
    %   See http://pulseq.github.io/
    %
    % This class is designed for *performance* so some functions can be
    % compiled to mex files using MATLAB's code generation. A parallel list
    % of IDs, data, and meta information is maintained to maximise search
    % speed.
    %
    % Sequence Properties:
    %    keys - A list of event IDs
    %    data - A struct array with field 'array' to store data of varying
    %           lengths, remaining compatible with codegen.
    %    lengths - Corresponding lengths of the data arrays
    %    type - Type to distinguish events in the same class (e.g.
    %           trapezoids and arbitrary gradients)
    %
    % Sequence Methods:
    %    find - Find an event in the library
    %    insert - Add a new event to the library
    %
    % See also   mr.Sequence
    %
    % Kelvin Layton <kelvin.layton@uniklinik-freiburg.de>
    % Stefan Kroboth <stefan.kroboth@uniklinik-freiburg.de>
    % Maxim Zaitsev <maxim.zaitsev@uniklinik-freiburg.de>
    
    properties
        keys;
        data;
        lengths;
        type;
        keymap;
    end
    
    methods
        function obj = EventLibrary()
            obj.keys = zeros(1,0);
            obj.data = struct('array',{});
            obj.lengths = zeros(1,0);
            obj.type = char(zeros(1,0));
            obj.keymap = containers.Map('KeyType', 'char', 'ValueType', 'double'); 
        end
        
        function [id, found] = find(obj, data)
            %find Lookup a data structure in the given library.
            %   [id,found]=find(lib,data) Return the index of the data in
            %   the library. If the data does not exist in the library then
            %   the index for the next new entry is returned.
            %
            %   The data is a 1xN array with event-specific data.
            %
            %   See also  insert mr.Sequence.addBlock
            
            % use map index for faster searches
            % matlab is extremely limited with regard to advanced contasiners
            % we therefore are forced to use hashed map and convert data to a
            % string
            data_string = sprintf('%.6g ', data); % precision can be discussed
            % containers.Map does not have a proper find function so we use direct
            % access and catch the possible error
            try
                id = obj.keymap(data_string(1:end-1));
                found = true;
            catch 
                if isempty(obj.keys)
                    id = 1;
                else
                    id = max(obj.keys) + 1;
                end
                found = false;
            end
        end
        
        function [id, found] = find_or_insert(obj, data, type)
            %find Lookup a data structure in the given library.
            %   [id,found]=find_or_insert(lib,data) Return the index of the data in
            %   the library. If the data does not exist in the library it
            %   is inserted right away
            %
            %   The data is a 1xN array with event-specific data.
            %
            %   See also  insert mr.Sequence.addBlock
            
            % use map index for faster searches
            % matlab is extremely limited with regard to advanced contasiners
            % we therefore are forced to use hashed map and convert data to a
            % string
            data_string = sprintf('%.6g ', data); % precision can be discussed
            % containers.Map does not have a proper find function so we use direct
            % access and catch the possible error
            try
                id = obj.keymap(data_string(1:end-1));
                found = true;
            catch 
                if isempty(obj.keys)
                    id = 1;
                else
                    id = max(obj.keys) + 1;
                end
                found = false;
                % insert
                obj.keys(id) = id;
                obj.data(id).array = data;
                obj.lengths(id) = length(data);
                obj.keymap(data_string(1:end-1)) = id;
                if nargin>2
                    obj.type(id) = type;
                end
            end
        end
        
        function insert(obj, id, data, type)
            %insert Add event to library
            % 
            % See also find
            
            obj.keys(id) = id;
            obj.data(id).array = data;
            obj.lengths(id) = length(data);
            
            % use map index for faster searches
            % matlab is extremely limited with regard to advanced containers
            % we therefore are forced to use hashed map and convert data to a
            % string
            data_string=sprintf('%.6g ', data);
            obj.keymap(data_string(1:end-1)) = id;
            if nargin>3
                obj.type(id) = type;
            end
        end
        
        function update(obj, id, data, type)
            if length(obj.keys)>=id
                data_string=sprintf('%.6g ', obj.data(id).array); % see EventLibrary.insert()
                obj.keymap.remove(data_string(1:end-1));
            end
            if nargin>3
                insert(obj, id, data, type);
            else
                insert(obj, id, data)
            end
        end
        
        function update_data(obj, id, old_data, new_data, type)
            %[id, found] = find(obj, old_data);
            %if found
                if nargin>3
                    update(obj, id, new_data, type);
                else
                    update(obj, id, new_data)
                end
            %else
            %    if nargin>3
            %        insert(obj, id, new_data, type);
            %    else
            %        insert(obj, id, new_data)
            %    end
            %end
        end
            
        function out = get(obj, id)
            %get Get element from library by key
            %
            % See also find
            out = struct;
            out.key = obj.keys(id);
            out.data = obj.data(id).array;
            out.length = obj.lengths(id);
            out.type = obj.type(id);
        end
        
    end
       
end

