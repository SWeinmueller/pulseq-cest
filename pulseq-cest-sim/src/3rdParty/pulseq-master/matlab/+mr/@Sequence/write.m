function write(obj,filename)
%WRITE Write sequence to file.
%   WRITE(seqObj, filename) Write the sequence data to the given
%   filename using the open file format for MR sequences.
%
%   Examples:
%   Write the sequence file to the my_sequences directory
%
%       write(seqObj,'my_sequences/gre.seq')
%
% See also  read

fid=fopen(filename, 'w');
assert(fid ~= -1, 'Cannot open file: %s', filename);
fprintf(fid, '# Pulseq sequence file\n');
fprintf(fid, '# Created by MATLAB mr toolbox\n\n');

fprintf(fid, '[VERSION]\n');
fprintf(fid, 'major %s\n', num2str(obj.version_major));
fprintf(fid, 'minor %s\n', num2str(obj.version_minor));
fprintf(fid, 'revision %s\n', num2str(obj.version_revision));
fprintf(fid, '\n');

if ~isempty(obj.definitions)
    fprintf(fid, '[DEFINITIONS]\n');
    keys = obj.definitions.keys;
    values = obj.definitions.values;
    for i=1:length(keys)
        fprintf(fid, '%s ', keys{i});
        if (ischar(values{i}))
            fprintf(fid, '%s ', values{i});
        else
            fprintf(fid, '%g ', values{i});
        end
        fprintf(fid, '\n');
    end
	fprintf(fid, '\n');
end

fprintf(fid, '# Format of blocks:\n');
fprintf(fid, '#  #  D RF  GX  GY  GZ ADC EXT\n');
fprintf(fid, '[BLOCKS]\n');
idFormatWidth = length(num2str(length(obj.blockEvents)));
idFormatStr = ['%' num2str(idFormatWidth) 'd'];
for i = 1:length(obj.blockEvents)
    %fprintf(fid,[idFormatStr ' %2d %2d %3d %3d %3d %2d 0\n'],[i obj.blockEvents(i,:)]);
    %fprintf(fid,[idFormatStr ' %2d %2d %3d %3d %3d %2d 0\n'],[i obj.blockEvents{i}]);
    fprintf(fid,[idFormatStr ' %2d %2d %3d %3d %3d %2d %2d\n'], ...
            [i obj.blockEvents{i}]); 
end
fprintf(fid, '\n');

if ~isempty(obj.rfLibrary.keys)
    fprintf(fid, '# Format of RF events:\n');
    fprintf(fid, '# id amplitude mag_id phase_id delay freq phase\n');
    fprintf(fid, '# ..        Hz   ....     ....    us   Hz   rad\n');
    fprintf(fid, '[RF]\n');
    keys = obj.rfLibrary.keys;
    for k = keys
        libData1 = obj.rfLibrary.data(k).array(1:3);
        libData2 = obj.rfLibrary.data(k).array(5:6);
        delay = round(obj.rfLibrary.data(k).array(4)*1e6);
        fprintf(fid, '%d %12g %d %d %g %g %g\n', [k libData1 delay ...
                                                  libData2]);
    end
    fprintf(fid, '\n');
end

arbGradMask = obj.gradLibrary.type == 'g';
trapGradMask = obj.gradLibrary.type == 't';

if any(arbGradMask)
    fprintf(fid, '# Format of arbitrary gradients:\n');
    fprintf(fid, '# id amplitude shape_id delay\n');
    fprintf(fid, '# ..      Hz/m     ....    us\n');
    fprintf(fid, '[GRADIENTS]\n');
    keys = obj.gradLibrary.keys;
    for k = keys(arbGradMask)
        fprintf(fid, '%d %12g %d %d\n', ...
                [k obj.gradLibrary.data(k).array(1:2) ...
                 round(obj.gradLibrary.data(k).array(3)*1e6)]);
    end
    fprintf(fid, '\n');
end

if any(trapGradMask)
    fprintf(fid, '# Format of trapezoid gradients:\n');
    fprintf(fid, '# id amplitude rise flat fall delay\n');
    fprintf(fid, '# ..      Hz/m   us   us   us    us\n');
    fprintf(fid, '[TRAP]\n');
    keys = obj.gradLibrary.keys;
    for k = keys(trapGradMask)
        data = obj.gradLibrary.data(k).array;
        data(2:end) = round(1e6*data(2:end));
        fprintf(fid, '%2d %12g %3d %4d %3d %3d\n', [k data]);
    end
    fprintf(fid, '\n');
end

if ~isempty(obj.adcLibrary.keys)
    fprintf(fid, '# Format of ADC events:\n');
    fprintf(fid, '# id num dwell delay freq phase\n');
    fprintf(fid, '# ..  ..    ns    us   Hz   rad\n');
    fprintf(fid, '[ADC]\n');
    keys = obj.adcLibrary.keys;
    for k = keys
        data = obj.adcLibrary.data(k).array(1:5).*[1 1e9 1e6 1 1];
        fprintf(fid, '%d %d %.0f %.0f %g %g\n', [k data]);
    end
    fprintf(fid, '\n');
end

if ~isempty(obj.delayLibrary.keys)
    fprintf(fid, '# Format of delays:\n');
    fprintf(fid, '# id delay (us)\n');
    fprintf(fid, '[DELAYS]\n');
    keys = obj.delayLibrary.keys;
    for k = keys
        fprintf(fid, '%d %d\n', ...
                [k round(1e6*obj.delayLibrary.data(k).array)]);
    end
    fprintf(fid, '\n');
end

if ~isempty(obj.extensionLibrary.keys)
    fprintf(fid, '# Format of extension lists:\n');
    fprintf(fid, '# id type ref next_id\n');
    fprintf(fid, '# next_id of 0 terminates the list\n');
    fprintf(fid, '# Extension list is followed by extension specifications\n');
    fprintf(fid, '[EXTENSIONS]\n');
    keys = obj.extensionLibrary.keys;
    for k = keys
        fprintf(fid, '%d %d %d %d\n', ...
                [k round(obj.extensionLibrary.data(k).array)]);
    end
    fprintf(fid, '\n');
end

if ~isempty(obj.trigLibrary.keys)
    fprintf(fid, '# Extension specification for digital output and input triggers:\n');
    fprintf(fid, '# id type channel delay (us) duration (us)\n');
    fprintf(fid, 'extension TRIGGERS 1\n'); % fixme: extension ID 1 is hardcoded here for triggers
    keys = obj.trigLibrary.keys;
    for k = keys
        fprintf(fid, '%d %d %d %d %d\n', ...
                [k round(obj.trigLibrary.data(k).array.*[1 1 1e6 1e6])]); 
    end
    fprintf(fid, '\n');
end

if ~isempty(obj.shapeLibrary.keys)
    fprintf(fid, '# Sequence Shapes\n');
    fprintf(fid, '[SHAPES]\n\n');
    keys = obj.shapeLibrary.keys;
    for k = keys
        shape_dat = obj.shapeLibrary.data(k).array;
        fprintf(fid, 'shape_id %d\n', k);
        fprintf(fid, 'num_samples %d\n', shape_dat(1));
        fprintf(fid, '%.9g\n', shape_dat(2:end));
        fprintf(fid, '\n');
    end
end

fclose(fid);
end
