function parameters = get_excel_value()

    folder = "parameters";

    excelFile = fullfile(folder, "inputs.xlsx");
    cacheFile = fullfile(folder, "parameters.mat");

    if ~isfolder(folder)
        error("The folder '%s' was not found.", folder);
    end

    if ~isfile(excelFile)
        error("The file '%s' was not found.", excelFile);
    end

    excelInfo = dir(excelFile);

    excelStamp = excelInfo.datenum;
    excelBytes = excelInfo.bytes;

    if isfile(cacheFile)
        S = load(cacheFile);

        if isfield(S, "parameters") && ...
           isfield(S, "excelStamp") && ...
           isfield(S, "excelBytes") && ...
           S.excelStamp == excelStamp && ...
           S.excelBytes == excelBytes

            parameters = S.parameters;
            disp("Using saved parameters.");
            return;
        end
    end

    disp("Excel changed or cache missing. Reading inputs.xlsx...");

    C = readcell(excelFile);

    parameters.v_kmh = readValue(C, "v_kmh");
    parameters.g     = readValue(C, "g");
    parameters.wb    = readValue(C, "wb");
    parameters.wd    = readValue(C, "wd");
    parameters.h_cg  = readValue(C, "h_cg");
    parameters.t_f   = readValue(C, "t_f");
    parameters.t_r   = readValue(C, "t_r");

    parameters.k_f  = readValue(C, "k_f");
    parameters.k_r  = readValue(C, "k_r");
    parameters.ir_f = readValue(C, "ir_f");
    parameters.ir_r = readValue(C, "ir_r");

    parameters.arb_f    = readValue(C, "arb_f");
    parameters.arb_r    = readValue(C, "arb_r");
    parameters.arb_l_f  = readValue(C, "arb_l_f");
    parameters.arb_l_r  = readValue(C, "arb_l_r");
    parameters.arb_ir_f = readValue(C, "arb_ir_f");
    parameters.arb_ir_r = readValue(C, "arb_ir_r");

    parameters.rc_f = readValue(C, "rc_f");
    parameters.rc_r = readValue(C, "rc_r");

    parameters.ws  = readValue(C, "ws");
    parameters.wuf = readValue(C, "wuf");
    parameters.wur = readValue(C, "wur");

    parameters.gamma_fl = readValue(C, "gamma_fl");
    parameters.gamma_fr = readValue(C, "gamma_fr");
    parameters.gamma_rl = readValue(C, "gamma_rl");
    parameters.gamma_rr = readValue(C, "gamma_rr");

    parameters.tau_fl = readValue(C, "tau_fl");
    parameters.tau_fr = readValue(C, "tau_fr");
    parameters.tau_rl = readValue(C, "tau_rl");
    parameters.tau_rr = readValue(C, "tau_rr");

    parameters.vs_step = readValue(C, "vs");
    parameters.si_step = readValue(C, "si");

    parameters.gamma_f_min = readValue(C, "gamma_f_min");
    parameters.gamma_f_max = readValue(C, "gamma_f_max");
    parameters.gamma_r_min = readValue(C, "gamma_r_min");
    parameters.gamma_r_max = readValue(C, "gamma_r_max");
    parameters.gamma_step  = readValue(C, "gamma_step");

    parameters.tau_f_min = readValue(C, "tau_f_min");
    parameters.tau_f_max = readValue(C, "tau_f_max");
    parameters.tau_r_min = readValue(C, "tau_r_min");
    parameters.tau_r_max = readValue(C, "tau_r_max");
    parameters.tau_step  = readValue(C, "tau_step");

    parameters.do_search = readValue(C, "do_search");

    save(cacheFile, "parameters", "excelStamp", "excelBytes");

end


function val = readValue(C, name)

    [row, col] = find(strcmpi(string(C), name), 1);

    if isempty(row)
        error("Parameter '%s' was not found in Excel.", name);
    end

    if col + 1 > size(C, 2)
        error("Parameter '%s' exists, but there is no value to its right.", name);
    end

    val = C{row, col + 1};

    if isempty(val)
        error("Parameter '%s' exists, but the value to its right is empty.", name);
    end

    if isstring(val) || ischar(val)
        val_str = strtrim(string(val));

        if strlength(val_str) == 0 || any(ismissing(val_str))
            error("Parameter '%s' exists, but the value to its right is empty.", name);
        end

        val_str = replace(val_str, ",", ".");
        val_num = str2double(val_str);

        if ~isnan(val_num)
            val = val_num;
        else
            val = val_str;
        end

    elseif isnumeric(val)
        if any(isnan(val), "all")
            error("Parameter '%s' exists, but the value to its right is NaN.", name);
        end

    elseif ismissing(val)
        error("Parameter '%s' exists, but the value to its right is missing.", name);
    end

end