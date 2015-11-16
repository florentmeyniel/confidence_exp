function value = default_arguments(argument_list, name, default)

isdefault = 1;

for i = 1:length(argument_list)
    if strcmp(argument_list{i}, name)
        value = argument_list{i+1};
        isdefault = 0;
    end
end

if isdefault
    if nargin == 2
        error('no default argument was provided for %s', name)
    else
        value = default;
    end
end

