$params = @{
   "ResourceGroupName"= "Storage-Account-Resource-Group"
   "TemplateFile"= "t.json"
   "TemplateParameterFile"= "p.json"
   "Tag" = @{"Department"="IT"; "Email"="me@company.com";}
}
New-AzResourceGroupDeployment @params