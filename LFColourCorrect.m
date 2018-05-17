% LFColourCorrect - applies a colour correction matrix, balance vector, and gamma, called by LFUtilDecodeLytroFolder
%
% Usage: 
%     LF = LFColourCorrect( LF, ColMatrix, ColBalance, Gamma, DoAWB )
% 
% This implementation deals with saturated input pixels by aggressively saturating output pixels.
%
% Inputs :
% 
%     LF : a light field or image to colour correct. It should be a floating point array, and
%          may be of any dimensinality so long as the last dimension has length 3. For example, a 2D
%          image of size [Nl,Nk,3], a 4D image of size [Nj,Ni,Nl,Nk,3], and a 1D list of size [N,3]
%          are all valid.
%
%    ColMatrix : a 3x3 colour conversion matrix. This can be built from the metadata provided
%                with Lytro imagery using the command:
%                     ColMatrix = reshape(cell2mat(LFMetadata.image.color.ccmRgbToSrgbArray), 3,3);
%                as demonstrated in LFUtilDecodeLytroFolder.
% 
%    ColBalance : 3-element vector containing a multiplicative colour balance.
% 
%    Gamma : rudimentary gamma correction is applied of the form LF = LF.^Gamma.
%
%    DoAWB : Controls whether automatic white balance is applied (default=false).
%
% Outputs : 
% 
%     LF, of the same dimensionality as the input.
% 
% 
% See also: LFHistEqualize, LFUtilDecodeLytroFolder

% Part of LF Toolbox xxxVersionTagxxx
% Copyright (c) 2013-2015 Donald G. Dansereau

function LF = LFColourCorrect(LF, ColMatrix, ColBalance, Gamma, DoAWB)

% Flag indicating the automatic white balancing should be set to false as
% default to maintain the original behavior
if nargin <= 4
    DoAWB = false;
end

LFSize = size(LF);

% Flatten input to a flat list of RGB triplets
NDims = numel(LFSize);
c1 = ceil(LFSize(1)/2);
c2 = ceil(LFSize(2)/2);
c_slice = squeeze(LF(c1,c2,:,:,:));
c_slice = reshape(c_slice, [prod(LFSize(3:NDims-1)), 3]);
LF = reshape(LF, [prod(LFSize(1:NDims-1)), 3]);

LF = bsxfun(@times, LF, ColBalance);
LF = LF * ColMatrix;

% Unflatten result
LF = reshape(LF, [LFSize(1:NDims-1),3]);

% Saturating eliminates some issues with clipped pixels, but is aggressive and loses information
% todo[optimization]: find a better approach to dealing with saturated pixels
SaturationLevel = ColBalance*ColMatrix;
SaturationLevel = min(SaturationLevel);
LF = min(SaturationLevel,max(0,LF)) ./ SaturationLevel; 

% Apply gamma
LF = LF .^ Gamma;

% Apply AWB
if(DoAWB)
	LF = LFAWB(c_slice,LF,'cat',0.35,10000);
end
