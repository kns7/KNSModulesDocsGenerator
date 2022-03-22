#########################################################################################
# KNS7 Modules Documentations Generator
# 
# Copyright 2018, Nicolas Kapfer
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
# and associated documentation files (the "Software"), to deal in the Software without restriction, 
# including without limitation the rights to use, copy, modify, merge, publish, distribute, 
# sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is 
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or 
# substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING 
# BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#########################################################################################

function Get-ModuleDocumentation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,HelpMessage="The module name to be documented")]
        $ModuleName
    )

    # Get Commands Informations
    $commandsHelp = (Get-Command -module $ModuleName) | get-help -full | Where-Object {! $_.name.EndsWith('.ps1')}

    foreach ($h in $commandsHelp){
        $cmdHelp = (Get-Command $h.Name)
    
        # Get any aliases associated with the method
        $alias = get-alias -definition $h.Name -ErrorAction SilentlyContinue
        if($alias){
            $h | Add-Member Alias $alias
        }
    
        # Parse the related links and assign them to a links hashtable.
        if(($h.relatedLinks | Out-String).Trim().Length -gt 0) {
            $links = $h.relatedLinks.navigationLink | ForEach-Object {
                if($_.uri){ @{name = $_.uri; link = $_.uri; target='_blank'} }
                if($_.linkText){ @{name = $_.linkText; link = "#$($_.linkText)"; cssClass = 'psLink'; target='_top'} }
            }
            $h | Add-Member Links $links
        }
    
        # Add parameter aliases to the object.
        foreach($p in $h.parameters.parameter ){
            $paramAliases = ($cmdHelp.parameters.values | Where-Object name -like $p.name | Select-Object aliases).Aliases
            if($paramAliases){
                $p | Add-Member Aliases "$($paramAliases -join ', ')" -Force
            }
        }
    }

    $totalCommands = $commandsHelp.Count
    if (!$totalCommands) {
        $totalCommands = 1
    }


    # Get Module Informations (Version, Description)
    $Manifest = Test-ModuleManifest (Get-Module -Name $ModuleName -list).Path



    # Building Return Object
    $return = @{
        moduleName=$ModuleName;
        version=$Manifest.version.ToString();
        description=$Manifest.Description;
        Content=$commandsHelp;
        totalCommands=$totalCommands
    }

    Write-Output $return
}

function Format-ConfluenceMarkup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,HelpMessage="Content Generated from Get-ModuleDocumentation")]
        $ContentObject,
        [Parameter(Mandatory=$False,HelpMessage="If specified, the content will be exported to this file")]
        $FileName,
        [Parameter()]
        [switch]$NoTableOfContent
    )

    $return = "`n`n"
    $return += "h1. $($ContentObject.moduleName)`n"
    if(!$NoTableOfContent){
        $return += "{toc:printable=true|style=square|maxLevel=2|indent=5px|minLevel=2|class=bigpink|exclude=[1//2]|type=list|outline=true|include=.*}`n"
    }
    $return += "\\`n\\`n"

    $progress = 0
    $ContentObject.Content | ForEach-Object {
        # Update the ProgressBar
        Update-Progress $_.Name 'Documentation' $progress $ContentObject.totalCommands
        $progress++

        $return += "`nh2. $(FixMarkupString($_.Name))`n"

        $synopsis = $_.synopsis.Trim()
        $syntax = $_.syntax | out-string
        if(-not ($synopsis -ilike "$($_.Name.Trim())*")){
            $tmp = $synopsis
            $synopsis = $syntax
            $syntax = $tmp
            $return += "h3. Synopsis`n$(FixMarkupString($syntax))`n"
        }
        
        # Document Description & Syntax
        $return += "h3. Description`n$(FixMarkupString $(($_.Description | out-string).Trim()) $true)"
        $return += "h3. Syntax`n{code:theme=Confluence|linenumbers=false|language=Powershell|firstline=0001|collapse=false}`n$(TrimAllLines $synopsis)`n{code}`n"

        # Document Aliases
        if (!($_.alias.Length -eq 0)) {
            $return += "h3. $($_.Name) Aliases`n"
            $_.alias | ForEach-Object {
                $return += " - $($_.Name)`n"
            }
        }

        # Document Parameters
        if($_.parameters){
            $return += "h3. Parameters`n||Name||Alias||Description||Required?||Pipeline Input||Default Value||`n"
            $_.parameters.parameter | ForEach-Object {
                $return += "|$(FixMarkupString $_.Name $false $true)|$(FixMarkupString $_.Aliases $false $true)|$(FixMarkupString $($_.Description  | out-string).Trim() $true $true)|$(FixMarkupString $_.Required $false $true)|$(FixMarkupString $_.PipelineInput $false $true)|$(FixMarkupString $_.DefaultValue $false $true)|`n"
            }
        }

        # Document Inputs
        $inputTypes = $(FixMarkupString($_.inputTypes  | out-string))
	    if ($inputTypes.Length -gt 0 -and -not $inputTypes.Contains('inputType')) {
            $return += "h3. Inputs`n - $inputTypes`n"
        }

        # Document Outputs
        $returnValues = $(FixMarkupString($_.returnValues  | out-string))
	    if ($returnValues.Length -gt 0 -and -not $returnValues.StartsWith("returnValue")) {
            $return += "h3. Outputs`n  - $returnValues`n"
        }

        # Document Notes
        $notes = $(FixMarkupString($_.alertSet  | out-string))
	    if ($notes.Trim().Length -gt 0) {
            $return += "h3. Notes`n  - $notes`n"   
        }

        # Document Examples
        if(($_.examples | Out-String).Trim().Length -gt 0) {
            $return += "h3. Examples`n"
            $_.examples.example | ForEach-Object {
                $return += "{code:title=$(FixMarkupString($_.title.Trim(('-',' '))))|theme=Confluence|linenumbers=true|language=Powershell|firstline=0001|collapse=false}`n$(FixMarkdownCodeString($_.code | out-string ))`n{code}`n"
                $return += "`n$(FixMarkupString($_.remarks | out-string ) $true)`n"
            }
        }

        # Document Links
        if(($_.relatedLinks | Out-String).Trim().Length -gt 0) {
            $return += "h3. Links`n"
            $_.links | ForEach-Object {
                $return += " - [$_.name]($_.link)`n"
            }
        }

        $return += "`n\\`n\\`n----`n\\`n\\`n"
    }

    if($FileName){
        Write-Output $return | Out-File $FileName
    }else{
        Write-Output $return
    }
}


function Format-Markdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,HelpMessage="Content Generated from Get-ModuleDocumentation")]
        $ContentObject,
        [Parameter(Mandatory=$False,HelpMessage="If specified, the content will be exported to this file")]
        $FileName
    )
    
    $return = "`n`n"
    $return += "# PowerShell Module `"$($ContentObject.moduleName)`"`n"
    
    $return += "Version $($ContentObject.version)`n"

    if(-not ([string]::IsNullOrEmpty($ContentObject))){
        $return += "`n$($ContentObject.Description)`n"
    }

    $progress = 0
    $ContentObject.Content | ForEach-Object {
        # Update the ProgressBar
        Update-Progress $_.Name 'Documentation' $progress $ContentObject.totalCommands
        $progress++

        $return += "`n`n## $(FixMarkdownString($_.Name))`n"

        $synopsis = $_.synopsis.Trim()
        $syntax = $_.syntax | out-string
        if (-not ($synopsis -ilike "$($_.Name.Trim())*")) {
            $tmp = $synopsis
            $synopsis = $syntax
            $syntax = $tmp
            $return += "`n### SYNOPSIS`n$(FixMarkdownString($syntax))`n"
        }

        $return += "`n### SYNTAX`n"
        $return += "``````powershell`n"
        $return += "$(TrimAllLines($synopsis))`n"
        $return +="```````n"

        # Document Aliases
        if (!($_.alias.Length -eq 0)) {
            $return += "`n### $($_.Name) ALIASES`n"
            $_.alias | ForEach-Object {
                $return += " - $($_.Name)`n"
            }
        }

        # Document Description
        if ($_.description) {
            $return += "`n### DESCRIPTION`n"
            $description = $_.description | Out-String
            $return += "$(TrimAllLines($description))`n"
        }

        # Document Parameters
        if ($_.parameters) {
            $return += "`n### PARAMETERS`n"
            $return += "| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |`n"
            $return += "| - | - | - | - | - | - |`n"

            $_.parameters.parameter | ForEach-Object {
                $return += "| <nobr>$(FixMarkdownString($_.Name))</nobr> | $(FixMarkdownString($_.Aliases)) | $(FixMarkdownString(($_.Description  | out-string).Trim())) | $(FixMarkdownString($_.Required)) | $(FixMarkdownString($_.PipelineInput)) | $(FixMarkdownString($_.DefaultValue)) |`n"
            }

            if($_.parameters | Out-String | Select-String -Pattern "<CommonParameters>" -SimpleMatch){
                $return += "`n`n_This cmdlet supports the common parameters: Verbose, Debug,
                ErrorAction, ErrorVariable, WarningAction, WarningVariable,
                OutBuffer, PipelineVariable, and OutVariable. For more information, see
                about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216)._`n"
            }
        }

        # Document Inputs
        $inputTypes = $(FixMarkdownString($_.inputTypes  | out-string))
        if ($inputTypes.Length -gt 0 -and -not $inputTypes.Contains('inputType')) {
            $return += "`n### INPUTS`n - $inputTypes`n"
        }

        # Document Return Values
        $returnValues = $(FixMarkdownString($_.returnValues  | out-string))
        if ($returnValues.Length -gt 0 -and -not $returnValues.StartsWith("returnValue")) {
            $return += "`n### OUTPUTS`n - $returnValues`n"
        }

        # Document Notes
        $notes = $(FixMarkdownString($_.alertSet  | out-string))
        if ($notes.Trim().Length -gt 0) {
            $return += "`n### NOTES`n$notes`n"
        }

        # Document Examples
        if (($_.examples | Out-String).Trim().Length -gt 0) {
            $return += "`n### EXAMPLES`n"
            $_.examples.example | ForEach-Object {
                $return += "`n**$(FixMarkdownString($_.title.Trim(('-',' '))))**`n"
                $return += "``````powershell`n"
                $return += "$(FixMarkdownCodeString($_.code | out-string ))`n"
                $return += "```````n"
                $return += "$(FixMarkdownString($_.remarks | out-string ) $true)`n"
            }
        }  

        # Document Links
        if (($_.relatedLinks | Out-String).Trim().Length -gt 0) {
            $return += "`n### LINKS`n"
            $_.links | ForEach-Object { 
                $return += "`n - [$($_.name)]($($_.link))`n"
            }
        }
    }

    if($FileName){
        Write-Output $return | Out-File $FileName
    }else{
        Write-Output $return
    }
}

function Update-ConfluenceDoc{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        $Content,
        [Parameter(Mandatory=$True)]
        [Alias('URL')]
        [string]$ConfluenceURL,
        [Parameter(Mandatory=$True)]
        [Alias('PageID','ID')]
        [string]$ConfluencePageID,
        [Parameter(Mandatory=$True)]
        [System.Management.Automation.PSCredential]$Credential
    )

    $MaxJsonLength = 67108864
    $Headers = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($Credential.UserName+":"+[System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($Credential.Password)) )))}
    $ContentType = "application/json"
    $Call = "content/$($ConfluencePageID)?expand=body.storage,version,space,ancestors"
    try {
        $CurrentConfluence = Invoke-WebRequest -Method GET -Headers $Headers -Uri ($ConfluenceURL + $Call)
    }catch{
        Write-Host "Error: "+ $_.Exception.Message
        Return $False
    }
    

    $Body = @{
        "id" = ($CurrentConfluence.id)
        "type" = "page"
        "title" = ($CurrentConfluence.title)
        "version" = @{
             "number" = ($CurrentConfluence.version.number + 1)
        }
       "status" = "current"
        "body" = @{
            "storage" = @{
                 "value" = $Content
                 "representation" = "wiki"
            }
       }
    }

    #$Body = $Body | ConvertTo-Json
    #$ContentType = "application/json"
    #$Call = "content/$($ConfluencePageID)"

    #$UpdateConfluence = Invoke-WebRequest -Method PUT -Uri ($ConfluenceURL + $Call) -Body $Body -ContentType $ContentType

    #$JSONSerial = New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer
    #$JSONSerial.MaxJsonLength = $MaxJsonLength
    
    #$UpdateConfluence = ($JSONSerial.DeserializeObject($UpdateConfluence))

    #write-output $UpdateConfluence
}




### Private Functions
function FixString ($in = '', [bool]$includeBreaks = $false){
    if ($in -eq $null) { return }

    $rtn = $in.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Trim()

    if($includeBreaks){
        $rtn = $rtn.Replace([Environment]::NewLine, '<br>')
    }
    return $rtn
}

function TrimAllLines([string] $str) {
    $lines = $str -split "`n"

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $lines[$i] = $lines[$i].Trim()
    }

    # Trim EOL.
    ($lines | Out-String).Trim()
}

function Update-Progress($name, $action,$progress,$total){
    Write-Progress -Activity "Rendering $action for $name" -CurrentOperation "Completed $progress of $total." -PercentComplete $(($progress/$total)*100)
}


### Confluence Functions
function FixMarkupString([string] $in = '', [bool] $includeBreaks = $false, [bool]$BlankStringToSpace = $False) {

	if ($in -eq $null) { return  }
	
	if($in -eq "" -and $BlankStringToSpace ) { return " " }

	$replacements = @{
		'\' = '\\'
		'`' = '\`'
		'*' = '\*'
		'_' = '\_'
		'{' = '\{'
		'}' = '\}'
		'[' = '\['
		']' = '\]'
		'(' = '\('
		')' = '\)'
		'#' = '\#'
		'+' = '\+'
		'!' = '\!'
	}

	$rtn = $in.Trim()
	foreach ($key in $replacements.Keys) {
		$rtn = $rtn.Replace($key, $replacements[$key])
	}

	$rtn = TrimAllLines $rtn

	if ($includeBreaks) {
		$crlf = [Environment]::NewLine
		$rtn = $rtn.Replace($crlf, "  $crlf")
	}
	$rtn
}

function IncludeConfluenceTableOfContents {

	return "{toc:printable=true|style=square|maxLevel=2|indent=5px|minLevel=2|class=bigpink|exclude=[1//2]|type=list|outline=true|include=.*}"
}


### Markdown Functions
function FixMarkdownString([string] $in = '', [bool] $includeBreaks = $false) {
    if ($in -eq $null) { return }
  
    $replacements = @{
      '\' = '\\'
      '`' = '\`'
      '*' = '\*'
      '_' = '\_'
      '{' = '\{'
      '}' = '\}'
      '[' = '\['
      ']' = '\]'
      '(' = '\('
      ')' = '\)'
      '#' = '\#'
      '+' = '\+'
      '!' = '\!'
      '<' = '\<'
      '>' = '\>'
    }
  
    $rtn = $in.Trim()
    foreach ($key in $replacements.Keys) {
      $rtn = $rtn.Replace($key, $replacements[$key])
    }
  
    $rtn = TrimAllLines $rtn
    $crlf = [Environment]::NewLine
    if ($includeBreaks) {
      $rtn = $rtn.Replace($crlf, "  $crlf")
    }
    else {
      $rtn = $rtn.Replace($crlf, " ").Trim()
    }
    $rtn
  }
  
  function FixMarkdownCodeString([string] $in) {
    if ($in -eq $null) { return }
      
    TrimAllLines $in
  }
