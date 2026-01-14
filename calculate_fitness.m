function cost = calculate_fitness(params, fisFileName, modelName)
    try
        % 1. Načtení a úprava FIS
        fis = readfis(fisFileName);
        
        % Škálování (jen základní násobení rozsahů)
        fis.Inputs(1).Range = fis.Inputs(1).Range * params(1);
        % ... (zde případně úprava MF parametrů, pokud je třeba)
        fis.Outputs(1).Range = fis.Outputs(1).Range * params(3);
        
        % 2. PROPOJENÍ: Vložíme FIS přímo do "batohu" (Model Workspace) modelu
        hws = get_param(modelName, 'ModelWorkspace');
        assignin(hws, 'fis_active', fis); 
        
        % 3. SIMULACE
        % Simulink teď automaticky použije 'fis_active' z Model Workspace
        out = sim(modelName, 'CaptureErrors', 'on', 'FastRestart', 'off');
        
        % 4. VÝSLEDEK (Zjednodušený výpočet)
        distTS = out.find('DistCar');
        if isempty(distTS), cost = 1e5; return; end
        
        y = double(distTS.Data);
        cost = sqrt(mean(y.^2)) * 100 + (max(abs(y)) * 50);
        
    catch
        cost = 1e5; % Pokud se něco pokazí, vrátíme vysoké číslo
    end
end