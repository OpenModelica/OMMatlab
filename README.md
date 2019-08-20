# OMMatlab
Matlab scripting OpenModelica interface using ZEROMQ 

# Requirement:
[Openmodelica](https://www.openmodelica.org/)<br>
[Matlab](https://se.mathworks.com/products/matlab.html)<br>
[zeromq/jeromq](https://github.com/zeromq/jeromq)<br>

The jeromq/zeromq library can be build by following the instructions in the repository, or the users can use the pre-build "jeromq-0.4.4-SNAPSHOT.jar" available in this repository and start using it straight away.

# Installation
Clone the repository and add the installation directory to Matlab PATH for future sessions. For Example <br>
```
from the matlab terminal, in windows
>>> pathtool
will open a window, add the directory to the list of entries and save. For example in windows
"C:/OPENMODELICAGIT/OpenModelica/OMMatlab"
```
```
Then we have to set the java classpath, so that the jeromq library can be used from Matlab. for that we need to create a file called javaclasspath.txt and add the jar file location to the file, To do that 
>>> prefdir
will show the preferred directory path, For example in windows 
'C:\Users\arupa54\AppData\Roaming\MathWorks\MATLAB\R2017b'
create a file javaclasspath.txt in that location and add the jar file path to the file, for example in windows the entry would be
C:/OPENMODELICAGIT/OpenModelica/OMMatlab/jeromq-0.4.4-SNAPSHOT.jar
Note: The path should be added without any quotes either single or double
```
You can also directly use the OMMatlab package directly from the directory where you have cloned, without need to perform the above steps. But the package cannot be used globally.

# Usage
```
>>> import OMMatlab.*;
>>> omc=OMMatlab();
>>> omc.sendExpression("getVersion()")
"v1.13.0-dev-531-gde26b558a (64-bit)"
>>> omc.sendExpression("model a end a;")
"{a}"
>>> omc.sendExpression('loadFile("C:\OMMatlab\BouncingBall.mo")')
true
>>> omc.sendExpression("getClassNames()")
{a,BouncingBall}
>>> omc.sendExpression("simulate(BouncingBall)")
record SimulationResult
    resultFile = "C:/Users/arupa54/BouncingBall_res.mat",
    simulationOptions = "startTime = 0.0, stopTime = 1.0, numberOfIntervals = 500, tolerance = 1e-006, method = 'dassl', fileNamePrefix = 'BouncingBall', options = '', outputFormat = 'mat', variableFilter = '.*', cflags = '', simflags = ''",
    messages = "LOG_SUCCESS       | info    | The initialization finished successfully without homotopy method.
LOG_SUCCESS       | info    | The simulation finished successfully.
",
    timeFrontend = 0.03334629789025638,
    timeBackend = 0.05818852816547053,
    timeSimCode = 0.02908068832276598,
    timeTemplates = 0.04130980342652182,
    timeCompile = 4.495768417986718,
    timeSimulation = 0.135430370984969,
    timeTotal = 4.795528603068404
end SimulationResult;
```
To see the list of available OpenModelicaScripting API see    (https://www.openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html
