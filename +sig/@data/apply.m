% SIG.DATA.APPLY
%
% Copyright (C) 2014, 2017-2018 Olivier Lartillot
%
% All rights reserved.
% License: New BSD License. See full text of the license in LICENSE.txt in
% the main folder of the MiningSuite distribution.

function [obj,varargout] = apply(obj,func,argin,dimfunc,maxdimfunc,type)
    if nargin<5
        maxdimfunc = Inf;
    end

    if nargin<6
        type = '()';
    end
    
    if obj.layers == 2
        obji = obj;
        obji.layers = 1;
        argini = argin;
        for i = 1:length(obj.content)
            obji.content = obj.content{i};
            for j = 1:length(argin)
                if iscell(argin{j})
                    argini{j} = argin{j}{i};
                end
            end
            if nargout == 0
                apply(obji,func,argini,dimfunc,maxdimfunc,type);
            else
                obj.content{i} = apply(obji,func,argini,dimfunc,maxdimfunc,type);
            end
        end
        return
    end
    
    mindimfunc = length(dimfunc);
    multioutput = 0;
    
    data = obj.content;
    if isempty(data)
        return
    end
    dimdata = size(data);
    ndimdata = length(dimdata);
    ordim = zeros(1,ndimdata);
    if isinf(maxdimfunc)
        maxdimfunc = min(maxdimfunc,ndimdata);
    end
    
    for i = 1:length(dimfunc)
        foundim = obj.whichdim(dimfunc{i});
        if isempty(foundim)
            ndimdata = ndimdata+1;
            foundim = ndimdata;
            obj.dims{foundim} = dimfunc{i};
        end
        ordim(i) = foundim;
        dimdata(foundim) = 0;
    end

    [sortedim bestdim] = sort(dimdata,'descend');
    notherdims = ndimdata-length(dimfunc);
    if notherdims
        ordim(length(dimfunc)+1:ndimdata) = bestdim(1:notherdims);
    end
    
    data = permute(data,ordim);
    dimdata = dimdata(ordim);

    start = cell(1,ndimdata);
    for i = 1:maxdimfunc
        start{i} = ':';
    end
    oldtype = '()';
    args = recurse(data,start,maxdimfunc+1,ndimdata,{},oldtype);
    argsin = {};
    for i = 1:length(argin)
        if isa(argin{i},'sig.data')
            argin{i} = argin{i}.content;
            argin{i} = permute(argin{i},ordim);
            oldtype = '()';
            argsin{i} = recurse(argin{i},start,maxdimfunc+1,ndimdata,{},...
                                oldtype);
        end
    end
    
    for i = 1:length(args)
        olddatai = subsref(data,args{i});
        
        argini = argin;
        for j = 1:min(length(argin),length(argsin))
            argini{j} = subsref(argini{j},argsin{j}{i});
        end
        
        f = find(strcmp('index',argin));
        if f
            argini{f} = i;
        end
                
        f = find(strcmp('self',argin));
        if f
            argini{f} = olddatai;
        else
            argini = [{olddatai} argini];
        end
        
        if nargout == 0
            func(argini{:});
        elseif nargout == 1
            newdatai = func(argini{:});
        elseif nargout == 2
            [newdatai varargout{1}] = func(argini{:});
        elseif nargout == 3
            [newdatai varargout{1} varargout{2}] = ...
                func(argini{:});
        elseif nargout == 4
            [newdatai varargout{1} varargout{2} varargout{3}] = ...
                func(argini{:});
        elseif nargout == 5
            [newdatai varargout{1} varargout{2} varargout{3} ...
                varargout{4}] = func(argini{:});
        else
            error('sig.data.apply: Full reconstruction not implemented yet.');
        end

        if nargout
            if i == 1
                if strcmp(type,'{}')
                    dimdata(~dimdata) = 1;
                    newdata = cell(dimdata);
                    for j = 1:maxdimfunc
                        start{j} = 1;
                    end
                    newargs = recurse(data,start,maxdimfunc+1,ndimdata,{},'{}');

                    if iscell(newdatai)
                        maindata = newdata;
                        newdata = cell(1,length(newdatai));
                        multioutput = 1;
                        for j = 1:length(newdatai)
                            newdata{j} = maindata;
                        end
                    end

                elseif ~isequal(size(olddatai),size(newdatai)) && ndimdata>maxdimfunc
                    extradims = sortedim((maxdimfunc+1:ndimdata)-mindimfunc);
                    if ismatrix(newdatai) && size(newdatai,2) == 1
                        newdata = zeros([length(newdatai),extradims]);
                    else
                        newdata = zeros([size(newdatai),extradims]);
                    end
                    if strcmp(type,args{1}.type)
                        newargs = args;
                    else
                        newargs = recurse(data,start,maxdimfunc+1,ndimdata,{},type);
                    end                

                else
                    newdata = newdatai; %data;
                    if strcmp(type,args{1}.type)
                        newargs = args;
                    else
                        newargs = recurse(data,start,maxdimfunc+1,ndimdata,{},type);
                    end   
                end


            end
        
            if iscell(newdatai)
                for j = 1:length(newdatai)
                    newdata{j} = subsasgn(newdata{j},newargs{i},newdatai{j});
                end
            else
                newdata = subsasgn(newdata,newargs{i},newdatai);
            end
        else
            newdata = [];
        end
    end

    if nargout
        if iscell(newdatai)
            for j = 1:length(newdatai)
                newdata{j} = ipermute(newdata{j},ordim);
            end
        else
            newdata = ipermute(newdata,ordim);
        end
    end
    obj.content = newdata;
    obj.multioutput = multioutput;
end


function args = recurse(data,current,d,ndim,args,type)
    if d > ndim
        args{end+1} = substruct(type,current);
    else
        for i = 1:size(data,d)
            current{d} = i;
            args = recurse(data,current,d+1,ndim,args,type);
        end
    end
end