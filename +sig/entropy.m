% SIG.ENTROPY
%
% Copyright (C) 2017-2018 Olivier Lartillot
% Copyright (C) 2007-2009 Olivier Lartillot & University of Jyvaskyla
%
% All rights reserved.
% License: New BSD License. See full text of the license in LICENSE.txt in
% the main folder of the MiningSuite distribution.

function varargout = entropy(varargin)
    varargout = sig.operate('sig','entropy',...
                            initoptions,@init,@main,@after,varargin);
end


%%
function options = initoptions
    options = sig.Signal.signaloptions('FrameAuto',.05,.5);
    
        center.key = 'Center';
        center.type = 'Boolean';
        center.default = 0;
    options.center = center;
end


%%
function [x,type] = init(x,option)
    if x.istype('sig.Signal')
        if option.frame
            x = sig.frame(x,'FrameSize',option.fsize.value,option.fsize.unit,...
                          'FrameHop',option.fhop.value,option.fhop.unit);
        end
        x = sig.spectrum(x);   
    end
    type = 'sig.Signal';
end


function out = main(in,option)
    x = in{1};
    if ~strcmpi(x.yname,'Entropy')
        res = sig.compute(@routine,x.Ydata,option);
        x = sig.Signal(res,'Name','Entropy',...
                       'Srate',x.Srate,'Sstart',x.Sstart,'Send',x.Send,...
                       'Ssize',x.Ssize,'FbChannels',x.fbchannels);
    end
    out = {x};
end


function out = routine(d,option)
    e = d.apply(@algo,{option},{'element'},1);
    out = {e};
end


function y = algo(d,option)
    if option.center
        d = d-mean(d);
    end
    
    % Negative data is trimmed:
    d(d<0) = 0;
    
    % Data is normalized such that the sum is equal to 1.
    d = d./sum(d);
    
    % Actual computation of entropy
    y = -sum(d.*log(d + 1e-12))./log(size(d,1));
end


function x = after(x,option)
end