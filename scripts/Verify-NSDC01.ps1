Start-Transcript -Path "C:\evidence\ns-dc01-domain-services.txt"

Get-ADDomain | Select-Object DNSRoot, NetBIOSName, DomainMode
Get-ADForest | Select-Object Name, ForestMode
Get-Service NTDS, DNS, DHCPServer | Select-Object Name, Status
Get-DnsServerZone | Select-Object ZoneName, ZoneType, IsDsIntegrated, DynamicUpdate
Get-DnsServerForwarder
Get-DhcpServerInDC
Get-DhcpServerv4Scope
Get-DhcpServerv4OptionValue -ScopeId 10.10.10.0
dcdiag /test:Advertising /test:SysVolCheck

Stop-Transcript
