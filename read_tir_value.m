function val = read_tir_value(filename, key)

    fid = fopen(filename, 'r');
    if fid == -1
        error('Nao foi possivel abrir o ficheiro: %s', filename);
    end

    val = [];
    while ~feof(fid)
        line = strtrim(fgetl(fid));

        if isempty(line)
            continue;
        end

        % ignora comentarios simples
        if startsWith(line, '!')
            continue;
        end

        % procurar "KEY = valor"
        expr = ['^\s*' regexptranslate('escape', key) '\s*=\s*(.+?)\s*$'];
        tok = regexp(line, expr, 'tokens', 'once');

        if ~isempty(tok)
            raw = strtrim(tok{1});
            raw = strrep(raw, '''', '');
            raw = strrep(raw, '"', '');

            num = str2double(raw);
            if ~isnan(num)
                val = num;
            else
                val = raw;
            end

            fclose(fid);
            return;
        end
    end

    fclose(fid);
    error('Chave "%s" nao encontrada no ficheiro %s.', key, filename);
end