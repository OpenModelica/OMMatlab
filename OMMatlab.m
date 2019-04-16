classdef OMMatlab < handle
    properties
        context
        requester
        portfile
        filename
        modelname
        xmlfile
        resultfile=''
        simulationoptions=struct
        quantitieslist=struct
        parameterlist=struct
        continuouslist=struct
        inputlist=struct
        outputlist=struct
        mappednames=struct
        %fileid
    end
    methods
        function obj = OMMatlab()
            randomstring = char(97 + floor(26 .* rand(10,1)))';
            if ispc
                omhome = getenv('OPENMODELICAHOME');
                omhomepath = replace(fullfile(omhome,'bin','omc.exe'),'\','/');
                % add omhome to path environment variabel
                path1 = getenv('PATH');
                path1 = [path1 omhome];
                setenv('PATH', path1);
                
                %cmd ="START /b "+omhomepath +" --interactive=zmq +z=matlab."+randomstring;
                cmd = ['START /b',' ',omhomepath,' --interactive=zmq +z=matlab.',randomstring];
                portfile = strcat('openmodelica.port.matlab.',randomstring);
            else
                if ismac && system("which omc") ~= 0
                    cmd =['/opt/openmodelica/bin/omc --interactive=zmq -z=matlab.',randomstring,' &'];
                else
                    cmd =['omc --interactive=zmq -z=matlab.',randomstring,' &'];
                end
                portfile = strcat('openmodelica.',getenv('USER'),'.port.matlab.',randomstring);
            end
            system(cmd);
            %pause(0.2);
            obj.portfile = replace(fullfile(tempdir,portfile),'\','/');
            while true
                pause(0.01);
                if(isfile(obj.portfile))
                    filedata=fileread(obj.portfile);
                    break;
                end
            end
            import org.zeromq.*
            obj.context=ZMQ.context(1);
            obj.requester =obj.context.socket(ZMQ.REQ);
            %obj.portfile=replace(fullfile(tempdir,portfile),'\','/');
            %obj.fileid=fileread(obj.portfile);
            obj.requester.connect(filedata);
        end
        
        function reply = sendExpression(obj,expr)
            obj.requester.send(expr,0);
            reply=obj.requester.recvStr(0);
        end
        
        function ModelicaSystem(obj,filename,modelname,libraries)
            if (nargin < 2)
                error('Not enough arguments, filename and classname is required');
            end
            
            if ~exist(filename, 'file')
                msg=filename +" does not exist";
                error(msg);
                return;
            end
            filepath = replace(filename,'\','/');
            %disp(filepath);
            loadfilemsg=obj.sendExpression("loadFile( """+ filepath +""")");
            %disp(loadfilemsg);
            if (eval(loadfilemsg)==false)
                disp(obj.sendExpression("getErrorString()"));
                return;
            end
            % check for libraries
            if exist('libraries', 'var')
                %disp("library given");
                for n=1:length(libraries)
                    %disp("loop libraries:" + libraries{n});
                    if(isfile(libraries{n}))
                        libmsg = obj.sendExpression("loadFile( """+ libraries{n} +""")");
                    else
                        libmsg = obj.sendExpression("loadModel("+ libraries{n} +")");
                    end
                    %disp(libmsg);
                    if (eval(libmsg)==false)
                        disp(obj.sendExpression("getErrorString()"));
                        return;
                    end
                end
            else
                %disp("library not given");
            end
            obj.filename = filename;
            obj.modelname = modelname;
            BuildModelicaModel(obj)
%             buildModelResult=obj.sendExpression("buildModel("+ modelname +")");
%             r2=split(erase(string(buildModelResult),["{","}",""""]),",");
%             %disp(r2);
%             if(isempty(r2{1}))
%                 disp(obj.sendExpression("getErrorString()"));
%                 return;
%             end
%             xmlpath =strcat(pwd,'\',r2{2});
%             obj.xmlfile = replace(xmlpath,'\','/');
%             xmlparse(obj);
        end
        
        function BuildModelicaModel(obj)
            buildModelResult=obj.sendExpression("buildModel("+ obj.modelname +")");
            r2=split(erase(string(buildModelResult),["{","}",""""]),",");
            %disp(r2);
            if(isempty(r2{1}))
                disp(obj.sendExpression("getErrorString()"));
                return;
            end
            xmlpath =strcat(pwd,'\',r2{2});
            obj.xmlfile = replace(xmlpath,'\','/');
            xmlparse(obj);
        end
        
        function xmlparse(obj)
            if isfile(obj.xmlfile)
                xDoc=xmlread(obj.xmlfile);
                % DefaultExperiment %
                allexperimentitems = xDoc.getElementsByTagName('DefaultExperiment');
                obj.simulationoptions.('startTime') = char(allexperimentitems.item(0).getAttribute('startTime'));
                obj.simulationoptions.('stopTime') = char(allexperimentitems.item(0).getAttribute('stopTime'));
                obj.simulationoptions.('stepSize') = char(allexperimentitems.item(0).getAttribute('stepSize'));
                obj.simulationoptions.('tolerance') = char(allexperimentitems.item(0).getAttribute('tolerance'));
                obj.simulationoptions.('solver') = char(allexperimentitems.item(0).getAttribute('solver'));
                
                % ScalarVariables %
                allvaritem = xDoc.getElementsByTagName('ScalarVariable');
                for k = 0:allvaritem.getLength-1
                    name=char(allvaritem.item(k).getAttribute('name'));
                    changeable=char(allvaritem.item(k).getAttribute('isValueChangeable'));
                    description=char(allvaritem.item(k).getAttribute('description'));
                    variability=char(allvaritem.item(k).getAttribute('variability'));
                    causality =char(allvaritem.item(k).getAttribute('causality'));
                    alias=char(allvaritem.item(k).getAttribute('alias'));
                    aliasVariable=char(allvaritem.item(k).getAttribute('aliasVariable'));
                    obj.quantitieslist(k+1).('name')=name;
                    obj.quantitieslist(k+1).('changeable')=changeable;
                    obj.quantitieslist(k+1).('description')=description;
                    obj.quantitieslist(k+1).('variability')=variability;
                    obj.quantitieslist(k+1).('causality')=causality;
                    obj.quantitieslist(k+1).('alias')=alias;
                    obj.quantitieslist(k+1).('aliasVariable')=aliasVariable;
                    sub = allvaritem.item(k).getElementsByTagName('Real');
                    try
                        value = char(sub.item(0).getAttribute('start'));
                    catch
                        value = '';
                    end
                    obj.quantitieslist(k+1).('value') = value;
                    
                    % check for variability parameter and add to parameter list
                    if(strcmp(variability,'parameter'))
                        try
                            obj.parameterlist.(name) = value;
                        catch ME
                            createvalidnames(obj,name,value,"parameter");
                        end
                    end
                    % check for variability continuous and add to continuous list
                    if(strcmp(variability,'continuous'))
                        try
                            obj.continuouslist.(name) = value;
                        catch ME
                            createvalidnames(obj,name,value,"continuous");
                        end
                    end
                    
                    % check for causality input and add to input list
                    if(strcmp(causality,'input'))
                        try
                            obj.inputlist.(name) = value;
                        catch ME
                            createvalidnames(obj,name,value,"input");
                        end
                    end
                    % check for causality output and add to output list
                    if(strcmp(causality,'output'))
                        try
                            obj.outputlist.(name) = value;
                        catch ME
                            createvalidnames(obj,name,value,"output");
                        end
                    end                   
                end
            else
                msg="xmlfile is not generated";
                error(msg);
                return;
            end            
        end
                
        function result= getQuantities(obj,args)
            if exist('args', 'var')
                tmpresult=[];
                for n=1:length(args)
                    for q=1:length(obj.quantitieslist)
                        if(strcmp(obj.quantitieslist(q).name,args(n)))
                            tmpresult=[tmpresult;obj.quantitieslist(q)];
                        end
                    end
                end
                result=struct2table(tmpresult,'AsArray',true);
            else
                result=struct2table(obj.quantitieslist,'AsArray',true);
            end
            return;
        end
        
        function result = getParameters(obj,args)
            if exist('args', 'var')
                param=strings(1,length(args));
                for n=1:length(args)
                    param(n) = obj.parameterlist.(args(n));
                end
                result = param;
            else
                result = obj.parameterlist;
            end
            return;
        end
        
        function result = getInputs(obj,args)
            if exist('args', 'var')
                inputs=strings(1,length(args));
                for n=1:length(args)
                    inputs(n) = obj.inputlist.(args(n));
                end
                result = inputs;
            else
                result = obj.inputlist;
            end
            return;
        end
        
        function result = getOutputs(obj,args)
            if exist('args', 'var')
                outputs=strings(1,length(args));
                for n=1:length(args)
                    outputs(n) = obj.outputlist.(args(n));
                end
                result = outputs;
            else
                result = obj.outputlist;
            end
            return;
        end
        
        function result = getContinuous(obj,args)
            if exist('args', 'var')
                continuous=strings(1,length(args));
                for n=1:length(args)
                    continuous(n) = obj.outputlist.(args(n));
                end
                result = continuous;
            else
                result = obj.continuouslist;
            end
            return;
        end
        
        function result = getSimulationOptions(obj,args)
            if exist('args', 'var')
                simoptions=strings(1,length(args));
                for n=1:length(args)
                    simoptions(n) = obj.simulationoptions.(args(n));
                end
                result = simoptions;
            else
                result = obj.simulationoptions;
            end
            return;
        end
        
        function simulate(obj)
            if(isfile(obj.xmlfile))
                if (ispc)
                    getexefile = replace(fullfile(pwd,[char(obj.modelname),'.exe']),'\','/');
                    %disp(getexefile)
                else
                    getexefile = replace(fullfile(pwd,char(obj.modelname)),'\','/');
                end
                system(getexefile);
                obj.resultfile=replace(fullfile(pwd,[char(obj.modelname),'_res.mat']),'\','/');
            else
                disp("Model cannot be Simulated:")
            end
        end
        
        function result = getSolutions(obj,args)
            if(isfile(obj.resultfile))
                if exist('args', 'var')
                    tmp1=strjoin(cellstr(args),',');
                    tmp2=['{',tmp1,'}'];
                    %disp(tmp2)
                    simresult=obj.sendExpression("readSimulationResult(""" + obj.resultfile + ""","+tmp2+")");
                    data=eval(simresult);
                    %disp("size is:" +length(data));
                    % create an empty cell array of fixed length
                    finalresults={length(data)};
                    for n=1:length(data)
                        %disp("loop val:" + n);
                        finalresults{n} = cell2mat(data{1,n});
                    end
                    result = finalresults;
                else
                    tmp1=obj.sendExpression("readSimulationResultVars(""" + obj.resultfile + """)");
                    tmp2=eval(tmp1);
                    tmp3=strings(1,length(tmp2));
                    for i=1:length(tmp2)
                        tmp3(i)=tmp2{i};
                    end
                    result = tmp3;
                end
                return;
            else
                disp("Model not Simulated, Simulate the model to get the results")
                return;
            end
        end
        
        % function which creates valid field name as matlab
        % does not allow der(h) to be a valid name, also map
        % the changed names to mappednames struct, inorder to
        % keep track of the original names as it is needed to query
        % simulation results
        function createvalidnames(obj,name,value,structname)
            tmpname=matlab.lang.makeValidName(name);
            obj.mappednames.(tmpname)= name;
            if(strcmp(structname,'continuous'))
                obj.continuouslist.(tmpname)= value;
            end
            if(strcmp(structname,'parameter'))
                obj.parameterlist.(tmpname)= value;
            end
            if(strcmp(structname,'input'))
                obj.inputlist.(tmpname)= value;
            end
            if(strcmp(structname,'output'))
                obj.outputlist.(tmpname)= value;
            end
        end
        
        
        function delete(obj)
            delete(obj.portfile);
            obj.requester.close();
            delete(obj);
        end
    end
end
