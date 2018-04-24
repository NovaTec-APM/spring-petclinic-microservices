@echo off

rem usage: Start_all_with_appdynamics.bat
rem the startup scipt must be placed in the same folder than the spring petclinic application
rem the path to the WAITTIME between the startup of the services

set AGENTDIR=%1
set WAITTIME=5
set /a "x = 0"
set PATH=%PATH%;C:\windows\system32;
rem STARTTYPE, z.B. /B = start without open a new windows, /MIN start minized in new windows
set STARTTYPE=/B

call mvn clean install -DskipTests

cd spring-petclinic-config-server
echo "Starting Configuration Server"
if exist configuration-log.txt del configuration-log.txt
ping 127.0.0.1 -n 1 > nul
start %STARTTYPE% mvn spring-boot:run > configuration-log.txt
cd ..
echo|set /p="Waiting for Configuration Server"
:loop1
set /a "x = x + 1"
if %x% geq 60 (
	goto :eof
)

echo|set /p="."

find  "Started ConfigServerApplication" spring-petclinic-config-server\configuration-log.txt > nul
if errorlevel 1 (
	ping 127.0.0.1 -n 2 > nul
	goto :loop1
)
set /a "x = 0"

echo .

cd spring-petclinic-discovery-server
echo "Starting Discovery Server"
if exist discovery-log.txt del discovery-log.txt
ping 127.0.0.1 -n 1 > nul
start %STARTTYPE% mvn spring-boot:run > discovery-log.txt
cd ..
echo|set /p="Waiting for Eureka Service"
:loop2
set /a "x = x + 1"

if %x% geq 60 (
	goto :eof
)

echo|set /p="."

find  "Started DiscoveryServerApplication" spring-petclinic-discovery-server\discovery-log.txt > nul
if errorlevel 1 (
	ping 127.0.0.1 -n 2 > nul
	goto :loop2
)
start "" http://localhost:8761

echo .

set /a "x = 0"

cd spring-petclinic-customers-service
echo "Starting Customers Service"
start %STARTTYPE% mvn spring-boot:run -Drun.jvmArguments="-javaagent:..\put-appdynamics-agent-here\javaagent.jar -Dappdynamics.agent.tierName=CustomerService"
cd ..
ping 127.0.0.1 -n %WAITTIME% > nul
cd spring-petclinic-vets-service
echo "Starting Vets Service"
start %STARTTYPE% mvn spring-boot:run -Drun.jvmArguments="-javaagent:..\put-appdynamics-agent-here\javaagent.jar -Dappdynamics.agent.tierName=VetsService"
cd ..
ping 127.0.0.1 -n %WAITTIME% > nul
cd spring-petclinic-visits-service
echo "Starting Visits Service"
start %STARTTYPE% mvn spring-boot:run -Drun.jvmArguments="-javaagent:..\put-appdynamics-agent-here\javaagent.jar -Dappdynamics.agent.tierName=VisitsService"
cd ..
ping 127.0.0.1 -n %WAITTIME% > nul
cd spring-petclinic-api-gateway
echo "Starting API Gateway"
if exist api-gateway-log.txt del api-gateway-log.txt
ping 127.0.0.1 -n 1 > nul
start %STARTTYPE% mvn spring-boot:run -Drun.jvmArguments="-javaagent:..\put-appdynamics-agent-here\javaagent.jar -Dappdynamics.agent.tierName=ApiGateway" > api-gateway-log.txt
cd ..
ping 127.0.0.1 -n %WAITTIME% > nul
cd spring-petclinic-admin-server
echo "Starting Admin Server"
ping 127.0.0.1 -n %WAITTIME% > nul
start %STARTTYPE% mvn spring-boot:run -Drun.jvmArguments="-javaagent:..\put-appdynamics-agent-here\javaagent.jar -Dappdynamics.agent.tierName=AdminServer"
cd ..
echo|set /p="Waiting for Api Gateway"
:loop3
set /a "x = x + 1"

if %x% geq 200 (
	goto :eof
)

echo|set /p="."

find  "Started ApiGatewayApplication" spring-petclinic-api-gateway\api-gateway-log.txt > nul
if errorlevel 1 (
	ping 127.0.0.1 -n 2 > nul
	goto :loop3
)
start "" http://localhost:8080

echo .

set /a "x = 0"

echo "All Services started!"
