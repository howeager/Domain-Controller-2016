New-Item -ItemType Directory -Path C:\Sysmon

Expand-Archive -Path "<PATH>\Sysmon.zip" -DestinationPath "C:\Sysmon"

wget -Uri https://wazuh.com/resources/blog/emulation-of-attack-techniques-and-detection-with-wazuh/sysmonconfig.xml -OutFile C:\Sysmon\sysmonconfig.xml

cd C:\Sysmon 
.\Sysmon64.exe -accepteula -i sysmonconfig.xml