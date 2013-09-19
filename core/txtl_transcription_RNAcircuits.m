% txtl_transcription.m - sigma factor independent implementation for gene
% transcription in the TXTL system
% RMM, 9 Sep 2012
%
% It can be called by promoter files that need to
% set up the approriate transcription reactions.

% Written by Richard Murray, 9 Sep 2012
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

function txtl_transcription_RNAcircuits(mode, varargin)
tube = varargin{1};
dna = varargin{2};
rna = varargin{3};
RNAP = varargin{4};
RNAPbound = varargin{5};

%%%%%%%%%%%%%%%%%%% DRIVER MODE: Setup Species %%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(mode.add_dna_driver, 'Setup Species')
    if ~mode.utr_attenuator_flag
        if nargin < 6
            error('the number of argument should be at least 6, not %d',nargin);
        elseif nargin > 6
            extraSpecies = varargin{6};
            coreSpecies = {'NTP',RNAPbound,['NTP:' RNAPbound],RNAP,extraSpecies{:}};
        else
            coreSpecies = {'NTP',RNAPbound,['NTP:' RNAPbound],RNAP};
        end
    else
        if nargin == 9
            prom_spec = varargin{6};
            rbs_spec = varargin{7};
            gene_spec = varargin{8};
            coreSpecies = txtl_tx_cascade(mode, tube, dna, rna, RNAP, RNAPbound, prom_spec, rbs_spec, gene_spec);
        else
            error('the number of argument should be at 9, not %d',nargin);
        end
    end
    
    
    % empty cellarray for amount => zero amount
    txtl_addspecies(tube, coreSpecies, cell(1,size(coreSpecies,2)), 'Internal');
    
    %%%%%%%%%%%%%%%%%%% DRIVER MODE: Setup Reactions %%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode.add_dna_driver,'Setup Reactions')
    if ~mode.utr_attenuator_flag
        if nargin < 6
            error('the number of argument should be at least 6, not %d',nargin);
        elseif nargin > 6
            extraSpecies = varargin{6};
            % processing the extraSpecies
            extraStr = extraSpecies{1};
            for k=2:size(extraSpecies,1)
                extraStr = [extraStr '+' extraSpecies{k}];
            end
            transcriptionEq = ...
                ['[NTP:' RNAPbound '] -> ' dna.Name ' + ' rna.Name ' + ' RNAP ' + ' extraStr];
        else
            transcriptionEq = ...
                ['[NTP:' RNAPbound '] -> ' dna.Name ' + ' rna.Name ' + ' RNAP];
        end
        ktxExpression =  strrep(tube.Userdata.ReactionConfig.Transcription_Rate,...
            'RNA_Length','rna.UserData');
        ktx = eval(ktxExpression);
        % parameter values
        NTPparameters = {'TXTL_NTP_RNAP_F', tube.UserData.ReactionConfig.NTP_Forward;
            'TXTL_NTP_RNAP_R', tube.UserData.ReactionConfig.NTP_Reverse};
    else
        if nargin == 9
            prom_spec = varargin{6};
            rbs_spec = varargin{7};
            gene_spec = varargin{8};
            txtl_tx_cascade(mode, tube, dna, rna, RNAP, RNAPbound, prom_spec, rbs_spec, gene_spec);
        else
            error('the number of argument should be at 9, not %d',nargin);
        end
        
    end
    
    % NTP consumption models
    if tube.UserData.ReactionConfig.NTPmodel == 1
        % Compute the number of NTPs required, in 100 NTP blocks
        ntpcnt = ceil(rna.UserData/100);	% get number of NTP blocks
        if (ntpcnt == 0)
            ntpstr = '';
        else
            ntpstr = int2str(ntpcnt);
        end
        
        txtl_addreaction(tube,['[' RNAPbound '] + ' ntpstr ' NTP <-> [NTP:' RNAPbound ']'],...
            'MassAction',NTPparameters);
    else
        if ~mode.utr_attenuator_flag
            % to deal with stiffness due to high reaction-order
            txtl_addreaction(tube,['[' RNAPbound '] + NTP <-> [NTP:' RNAPbound ']'],...
                'MassAction',NTPparameters);
            
            %dummy raction
            ntpcnt = ceil(rna.UserData/100);	% get number of NTP blocks
            NTPConsumptionRate = {'TXTL_NTP_consumption',(ntpcnt-1)*ktx};
            
            txtl_addreaction(tube,['[NTP:' RNAPbound '] -> ' dna.Name ' +  ' RNAP],...
                'MassAction',NTPConsumptionRate);
        end
    end
    
    % transcription and att-anti reactions
    if ~mode.utr_attenuator_flag
        txtl_addreaction(tube,transcriptionEq,'MassAction',{'TXTL_transcription_rate1',ktx});          
    end
    
%%%%%%%%%%%%%%%%%%% DRIVER MODE: error handling %%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    error('txtltoolbox:txtl_transcription:undefinedmode', ...
        'The possible modes are ''Setup Species'' and ''Setup Reactions''.');
end




% Automatically use MATLAB mode in Emacs (keep at end of file)
% Local variables:
% mode: matlab
% End:
% Parameters describing the enzymatic process