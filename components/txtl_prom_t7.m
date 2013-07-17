% txtl_prom_t7.m - promoter information for T7 promoter
% ZT June 2013
%
% This file contains a description of the standard p70 promoter.
% Calling the function txtl_prom_p70() will set up the reactions for
% transcription with the measured binding rates and transription rates.


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

function varargout = txtl_prom_t7(mode, tube, dna, rna, varargin)

    % Create strings for reactants and products
    DNA = ['[' dna.Name ']'];		% DNA species name for reactions
    RNA = ['[' rna.Name ']'];		% RNA species name for reactions
    RNAP = 'protein t7RNAP';			% RNA polymerase name for reactions
    RNAPbound = ['protein t7RNAP:' dna.Name];	% Name of bound complex
    
    % importing the corresponding parameters
    paramObj = txtl_component_config('t7prom');

%%%%%%%%%%%%%%%%%%% DRIVER MODE: Setup Species %%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(mode.add_dna_driver, 'Setup Species')
    
    promoterData = varargin{1};
    defaultBasePairs = {'t7','junk','thio';...
        paramObj.Promoter_Length,paramObj.Junk_Length,paramObj.Thio_Length};
    promoterData = txtl_setup_default_basepair_length(tube,promoterData,...
        defaultBasePairs);
    
    varargout{1} = promoterData;
    
    coreSpecies = {RNAP,RNAPbound};
    % empty cellarray for amount => zero amount
    txtl_addspecies(tube, coreSpecies, cell(1,size(coreSpecies,2)), 'Internal');
    
    %
    % Now put in the reactions for the utilization of NTPs
    % Use an enzymatic reaction to proper rate limiting
    % 
    txtl_transcription(mode, tube, dna, rna, RNAP, RNAPbound);

%%%%%%%%%%%%%%%%%%% DRIVER MODE: Setup Reactions %%%%%%%%%%%%%%%%%%%%%%%%%%     
elseif strcmp(mode.add_dna_driver, 'Setup Reactions')
    
    % Parameters that describe this promoter
    parameters = {'TXTL_t7RNAPbound_F',paramObj.RNAPbound_Forward;...
                  'TXTL_t7RNAPbound_R',paramObj.RNAPbound_Reverse};
    % Set up binding reaction
    txtl_addreaction(tube,[DNA ' + ' RNAP ' <-> [' RNAPbound ']'],...
        'MassAction',parameters);
    %
    % Now put in the reactions for the utilization of NTPs
    % Use an enzymatic reaction to proper rate limiting
    % 
    txtl_transcription(mode, tube, dna, rna, RNAP, RNAPbound);

%%%%%%%%%%%%%%%%%%% DRIVER MODE: error handling %%%%%%%%%%%%%%%%%%%%%%%%%%%    
else 
    error('txtltoolbox:txtl_prom_t7:undefinedmode', ...
      'The possible modes are ''Setup Species'' and ''Setup Reactions''.');
end 

% Automatically use MATLAB mode in Emacs (keep at end of file)
% Local variables:
% mode: matlab
% End:
