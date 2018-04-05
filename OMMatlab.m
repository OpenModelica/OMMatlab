classdef OMMatlab < handle
    properties
        context
        requester
        portfile
        fileid
    end
    methods
        function obj = OMMatlab()
            randomstring = char(97 + floor(26 .* rand(10,1)))';
            if ispc
                omhome = getenv('OPENMODELICAHOME');
                omhomepath = replace(fullfile(omhome,'bin','omc.exe'),'\','/');
                cmd ="START /b "+omhomepath +" --interactive=zmq +z=matlab."+randomstring;
                portfile = strcat('openmodelica.port.matlab.',randomstring);
            else
                if ismac && system("which omc") ~= 0
                  cmd ="/opt/openmodelica/bin/omc --interactive=zmq -z=matlab."+randomstring+" &";
                else
                  cmd ="omc --interactive=zmq -z=matlab."+randomstring+" &";
                end
                portfile = strcat('openmodelica.',getenv('USER'),'.port.matlab.',randomstring);
            end
            system(cmd);
            pause(0.2);
            import org.zeromq.*
            obj.context=ZMQ.context(1);
            obj.requester =obj.context.socket(ZMQ.REQ);
            obj.portfile=replace(fullfile(tempdir,portfile),'\','/');
            obj.fileid=fileread(obj.portfile);
            obj.requester.connect(obj.fileid);
        end
        function reply = sendExpression(obj,expr)
            obj.requester.send(expr,0);
            reply=obj.requester.recvStr(0);
        end
        function delete(obj)
            delete(obj.portfile);
            obj.requester.close();
            delete(obj);
        end
    end
end
