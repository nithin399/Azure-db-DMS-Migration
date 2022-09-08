$ProjectName = "MyDMSProject"
$databasename = @("Database1","Database2","Database3")
$adminlogin ="Adminuser"
$selectdata = "select TABLE_SCHEMA+'.'+TABLE_NAME AS TABLENAME from information_schema.tables"
$Sourceserver = "Localhost"
$Location = "EAST US"
$resourcegroupname="Resourcegroup"
$serviceName="test"
$servername = "Azureserver"


#create scource and target connection info
$sourceConnInfo = New-AzDataMigrationConnectionInfo -ServerType SQL -DataSource $Sourceserver -AuthType SqlAuthentication -TrustServerCertificate:$true
$targetConnInfo = New-AzDataMigrationConnectionInfo -ServerType SQL -DataSource $servername -AuthType SqlAuthentication -TrustServerCertificate:$true

#create database info objects by iterating through source db list
$dbList = [System.Collections.ArrayList]@()
For ($i=0; $i -lt $databasename.Length; $i++) {
    $dbInfo = New-AzDataMigrationDatabaseInfo -SourceDatabaseName $databasename[$i]
    $dbList.Add($dbInfo)
}
$project = New-AzDataMigrationProject -Name $ProjectName -Location $location -ResourceGroupName $resourcegroupname -ServiceName $serviceName -SourceType SQL -TargetType SQLDB -SourceConnection $sourceConnInfo -TargetConnection $targetConnInfo -DatabaseInfo $dbList


$taskName = “myDMSTask”

#convert creds for Source

$secpasswd = ConvertTo-SecureString "**********"  -AsPlainText -Force
$sourceCred = New-Object System.Management.Automation.PSCredential ("username", $secpasswd)

#convert creds for Target
$secpasswd = ConvertTo-SecureString "**********"  -AsPlainText -Force
$targetCred = New-Object System.Management.Automation.PSCredential ($adminlogin, $secpasswd)

#create table map
$tableMap = New-Object 'system.collections.generic.dictionary[string,string]'

$tableList = [System.Collections.ArrayList]@()

$dbSelectedList = [System.Collections.ArrayList]@()
For ($i=0; $i -lt $databasename.Length; $i++) {

$tableList=Invoke-Sqlcmd -ServerInstance $Sourceserver -Database $databasename[$i] -Query $selectdata

For ($j=0; $j -lt $tableList.Length; $j++) {

$tableMap.Add($tableList.ItemArray[$j],$tableList.ItemArray[$j])

}
$selectedDb = New-AzDataMigrationSelectedDB -MigrateSqlServerSqlDb -Name $databasename[$i] -TargetDatabaseName $databasename[$i] -TableMap $tableMap
$dbSelectedList.Add($selectedDb)
}
#run a task
$MyTask = New-AzDataMigrationTask -Name "MyDMSTask" -ResourceGroupName $resourcegroupname -ServiceName $service.Name -ProjectName $project.Name -TaskType MigrateSqlServerSqlDb -SourceCred $sourceCred -TargetCred $targetCred -SourceConnection $sourceConnInfo -TargetConnection $targetConnInfo -SelectedDatabase $selectedDb




##Monitor

 #wait to finish
 $mytask =get-azurermdmstask -Name $migTask.Name -ServiceName $serviceName -ProjectName $projectName -ResourceGroupName $resourcegroupname
 if (($mytask.ProjectTask.Properties.State -eq "Running") -or ($mytask.ProjectTask.Properties.State -eq "Queued")) {
 Start-Sleep -s 15
 }