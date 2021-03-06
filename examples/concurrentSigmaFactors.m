%% clean up

clear variables
close all
clc

%% simple circuit with 2 genes

% Set up the standard TXTL tubes
tube1 = txtl_extract('E30VNPRL');
tube2 = txtl_buffer('E30VNPRL');

% Set up a tube that will contain our DNA
tube3 = txtl_newtube('circuit');
dna_sigma28 = txtl_add_dna(tube3, 'p70(50)', 'rbs(20)', 'sigma28(600)', 4, 'linear');
dna_deGFP =   txtl_add_dna(tube3, 'p70(50)', 'rbs(20)', 'deGFP(1000)', 4, 'linear');
dna_gamS =    txtl_add_dna(tube3, 'p70(50)', 'rbs(20)', 'gamS(1000)', 1, 'plasmid');


tube4 = txtl_newtube('no_s28_circuit');
dna_sigma28 = txtl_add_dna(tube4, 'p70(50)', 'rbs(20)', 'sigma28(600)', 0.4, 'linear');
dna_deGFP =   txtl_add_dna(tube4, 'p70(50)', 'rbs(20)', 'deGFP(1000)', 4, 'linear');
dna_gamS =    txtl_add_dna(tube4, 'p70(50)', 'rbs(20)', 'gamS(1000)', 1, 'plasmid');

tube5 = txtl_newtube('no_s28_circuit');
dna_sigma28 = txtl_add_dna(tube5, 'p70(50)', 'rbs(20)', 'sigma28(600)', 1, 'linear');
dna_deGFP =   txtl_add_dna(tube5, 'p70(50)', 'rbs(20)', 'deGFP(1000)', 4, 'linear');
dna_gamS =    txtl_add_dna(tube5, 'p70(50)', 'rbs(20)', 'gamS(1000)', 1, 'plasmid');

% Mix the contents of the individual tubes and add some inducer
well_a1 = txtl_combine([tube1, tube2, tube3]);
well_b1 = txtl_combine([tube1, tube2, tube4]);
well_c1 = txtl_combine([tube1, tube2, tube5]);

%% Run a simulation

% 1st run
tic
simData = txtl_runsim(well_a1, 9*60*60);
toc
t_ode = simData.Time;
x_ode = simData.Data;

tic
simData_nos28 = txtl_runsim(well_b1, 9*60*60);
toc
t_ode_b1 = simData_nos28.Time;
x_ode_b1 = simData_nos28.Data;

tic
simData_c1 = txtl_runsim(well_c1, 9*60*60);
toc
t_ode_c1 = simData_c1.Time;
x_ode_c1 = simData_c1.Data;

%% plot the result


dataGroups = txtl_getDefaultPlotDataStruct();
dataGroups(2).SpeciesToPlot   = {'protein deGFP*'};

txtl_plot(t_ode,x_ode,well_a1,dataGroups)
txtl_plot(t_ode_b1,x_ode_b1,well_b1,dataGroups)

%%

figure(5)
hold on
plot(t_ode/60,x_ode(:,findspecies(well_b1,'RNAP')),'b*')
plot(t_ode/60,x_ode(:,findspecies(well_b1,'RNAP28')),'r*')
plot(t_ode/60,x_ode(:,findspecies(well_b1,'RNAP70')),'g*')
xlabel('Time [min]');
ylabel('Concentration [nM]');
title('Sigma factors - Simulation')
axis([0 100 0 110])
hold off
legend('free RNAP','RNAP28','RNAP70')

figure(6)
hold on
plot(t_ode/60,x_ode(:,findspecies(well_a1,'protein deGFP*')),'r*')

plot(t_ode_c1/60,x_ode_c1(:,findspecies(well_c1,'protein deGFP*')),'b*')
plot(t_ode_b1/60,x_ode_b1(:,findspecies(well_b1,'protein deGFP*')),'g*')
legend('4nM \sigma70 - p28','1nM \sigma70 - p28','0.4nM \sigma70 - p28')
xlabel('Time [min]');
ylabel('Concentration [nM]');
title('deGFP expression with presence of competing \sigma28 factor - Simulation')
hold off



