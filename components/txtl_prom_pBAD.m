% txtl_prom_pBAD.m - promoter information for pBAD promoter
% Zoltan Tuza, Oct 2012
%
% This file contains a description of the p28 and ptet combinatorial promoter.
% Calling the function txtl_prom_pBAD() will set up the reactions for
% transcription with the measured binding rates and transription rates.
%
%

% Written by Zoltan Tuza, Oct 2012
%
% Copyright (c) 2012 by California Institute of Technology
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
%
%   1. Redistributions of source code must retain the above copyright
%      notice, this list of conditions and the following disclaimer.
%
%   2. Redistributions in binary form must reproduce the above copyright
%      notice, this list of conditions and the following disclaimer in the
%      documentation and/or other materials provided with the distribution.
%
%   3. The name of the author may not be used to endorse or promote products
%      derived from this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
% IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
% INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
% (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
% HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
% STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
% IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.

function varargout= txtl_prom_pBAD(mode, tube, dna, rna, varargin)

% Create strings for reactants and products
DNA = ['[' dna.Name ']'];		% DNA species name for reactions
RNA = ['[' rna.Name ']'];		% RNA species name for reactions
RNAP = 'RNAP70';			% RNA polymerase name for reactions
RNAPbound = ['RNAP70:' dna.Name];
P1 = 'protein sigma70';

% importing the corresponding parameters
paramObj = txtl_component_config('pBAD');

%%%%%%%%%%%%%%%%%%% DRIVER MODE: Setup Species %%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(mode.add_dna_driver, 'Setup Species')
    
    promoterData = varargin{1};
    if nargin==8
        prom_spec = varargin{2};
        rbs_spec = varargin{3};
        gene_spec = varargin{4};
    elseif nargin~=5
        error('the number of argument should be 5 or 8, not %d',nargin);
    end
    defaultBasePairs = {'pBAD','junk','thio';150,500,0};
    promoterData = txtl_setup_default_basepair_length(tube,promoterData,...
        defaultBasePairs);
    
    varargout{1} = promoterData;
    
    coreSpecies = {RNAP,RNAPbound,P1};
    txtl_addspecies(tube, coreSpecies, cell(1,size(coreSpecies,2)), 'Internal');
    
    %%%%%%%%%%%%%%%%%%% DRIVER MODE: Setup Reactions %%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode.add_dna_driver,'Setup Reactions')
    listOfSpecies = varargin{1};
    if nargin==8
        prom_spec = varargin{2};
        rbs_spec = varargin{3};
        gene_spec = varargin{4};
    elseif nargin~=5
        error('the number of argument should be 5 or 8, not %d',nargin);
    end
    % Parameters that describe this promoter (this is where the variation
    % in the promoter strength comes in.
    parameters = {'TXTL_PBAD_RNAPbound_F',paramObj.RNAPbound_Forward;...
        'TXTL_PBAD_RNAPbound_R',paramObj.RNAPbound_Reverse};
    % Set up binding reaction
    txtl_addreaction(tube,[DNA ' + ' RNAP ' <-> [' RNAPbound ']'],...
        'MassAction',parameters);
    
    p = regexp(listOfSpecies,'^arabinose:protein AraC(-lva)?$', 'match');
    activatedProtein = vertcat(p{:});
    
    for k = 1:size(activatedProtein,1)
        txtl_addreaction(tube, ...
            [dna.Name ' + ' activatedProtein{k} ' <-> [' dna.Name ':' activatedProtein{k} ']' ],...
            'MassAction',{'TXTL_PBAD_TFBIND_F',paramObj.activation_F;...
            'TXTL_PBAD_TFBIND_R',paramObj.activation_R});
        
        txtl_addreaction(tube, ...
            [RNAPbound ' + ' activatedProtein{k} ' <-> [' RNAPbound ':' activatedProtein{k} ']' ],...
            'MassAction',{'TXTL_PBAD_TFBIND_F',paramObj.activation_F;...
            'TXTL_PBAD_TFBIND_R',paramObj.activation_R});
        
        txtl_addreaction(tube, ...
            [dna.Name ':' activatedProtein{k} ' + ' RNAP ' <-> [' RNAPbound ':' activatedProtein{k} ']' ],...
            'MassAction',{'TXTL_PBAD_TFRNAPbound_F',paramObj.RNAPbound_Forward_actv;...
            'TXTL_PBAD_TFRNAPbound_R',paramObj.RNAPbound_Reverse_actv});
        
        if mode.utr_attenuator_flag
            mode.add_dna_driver = 'Setup Species';
            txtl_transcription_RNAcircuits(mode, tube, dna, rna, RNAP,RNAPbound, prom_spec, rbs_spec, gene_spec );
            txtl_transcription_RNAcircuits(mode, tube, dna, rna, RNAP, [RNAPbound ':' activatedProtein{k} ],prom_spec, rbs_spec, gene_spec,{activatedProtein{k} } );
            mode.add_dna_driver = 'Setup Reactions';
            txtl_transcription_RNAcircuits(mode, tube, dna, rna, RNAP,RNAPbound, prom_spec, rbs_spec, gene_spec );
            txtl_transcription_RNAcircuits(mode, tube, dna, rna, RNAP, [RNAPbound ':' activatedProtein{k} ],prom_spec, rbs_spec, gene_spec,{activatedProtein{k}} );
        else
            mode.add_dna_driver = 'Setup Species';
            txtl_transcription(mode, tube, dna, rna, RNAP,RNAPbound);
            txtl_transcription(mode, tube, dna, rna, RNAP,[RNAPbound ':' activatedProtein{k} ],{activatedProtein{k}});
            mode.add_dna_driver = 'Setup Reactions';
            txtl_transcription(mode, tube, dna, rna, RNAP,RNAPbound);
            txtl_transcription(mode, tube, dna, rna, RNAP,[RNAPbound ':' activatedProtein{k} ],{activatedProtein{k}});
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%% DRIVER MODE: error handling %%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    error('txtltoolbox:txtl_prom_pBAD:undefinedmode', ...
        'The possible modes are ''Setup Species'' and ''Setup Reactions''.');
end



% Automatically use MATLAB mode in Emacs (keep at end of file)
% Local variables:
% mode: matlab
% End:
