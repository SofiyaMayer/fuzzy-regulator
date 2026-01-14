clc; clear; close all;
global roadX roadY roadAnglesCum roadDistancesCum

% 1. Inicializace prostředí
run('genXY2a.m'); 
model = 'vehicleOnTrack_v7_2020b';
fisFile = 'vehicleControllerV6b.fis';

if ~bdIsLoaded(model), load_system(model); end

% 2. Baseline Test
fprintf('--- KROK 1: Testuji Baseline ---\n');
baselineCost = calculate_fitness([1, 1, 1], fisFile, model);
fprintf('Baseline Fitness: %.4f\n\n', baselineCost);

% 3. GA Setup - Agresivnější nastavení
nVars = 3; 
lb = [0.5, 0.5, 0.5]; % Rozšířené meze
ub = [2.0, 2.0, 2.0];

% Počáteční populace - Baseline + náhodné okolí
initial_pop = [ones(1, 3); 0.9+0.2*rand(14, 3)]; 

opts = optimoptions('ga', ...
    'PopulationSize', 40, ...            % Větší populace
    'MaxGenerations', 30, ...            % Více času na učení
    'InitialPopulationMatrix', initial_pop, ...
    'EliteCount', 2, ...                 % Méně elitářství pro více inovace
    'CrossoverFraction', 0.7, ...
    'CrossoverFcn', @crossoverintermediate, ... % Hladší křížení pro spojité proměnné
    'MutationFcn', {@mutationgaussian, 0.2, 1.0}, ... % SILNĚJŠÍ mutace (Scale=0.2)
    'PlotFcn', {@gaplotbestf, @gaplotdistance}, ... % Sledujte "Distance" - nesmí být 0!
    'Display', 'iter');

% 4. Spuštění GA
fprintf('--- KROK 2: Optimalizace ---\n');
[bestParams, bestFitness] = ga(@(x) calculate_fitness(x, fisFile, model), ...
    nVars, [], [], [], [], lb, ub, [], opts);

% 5. Výsledky a uložení
fprintf('\n--- KROK 3: Hotovo ---\n');
fprintf('Původní: %.2f | Nové: %.2f | Zlepšení: %.2f %%\n', ...
    baselineCost, bestFitness, ((baselineCost - bestFitness)/baselineCost)*100);

% Finální zápis (beze změn v logice zápisu)
finalFIS = readfis(fisFile);
for i = 1:min(numel(finalFIS.Inputs), 2)
    finalFIS.Inputs(i).Range = finalFIS.Inputs(i).Range * bestParams(i);
    for m = 1:numel(finalFIS.Inputs(i).MembershipFunctions)
        finalFIS.Inputs(i).MembershipFunctions(m).Parameters = ...
            finalFIS.Inputs(i).MembershipFunctions(m).Parameters * bestParams(i);
    end
end
finalFIS.Outputs(1).Range = finalFIS.Outputs(1).Range * bestParams(3);
for m = 1:numel(finalFIS.Outputs(1).MembershipFunctions)
    finalFIS.Outputs(1).MembershipFunctions(m).Parameters = ...
        finalFIS.Outputs(1).MembershipFunctions(m).Parameters * bestParams(3);
end
writefis(finalFIS, 'vehicleController_Optimized.fis');