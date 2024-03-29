#
# Modulmanifest für das Modul "KNSModulesDocsGenerator"
#
# Generiert von: Nicolas Kapfer
#
# Generiert am: 27.08.2018
#

@{
RootModule = 'KNSModulesDocsGenerator.psm1'
ModuleVersion = '1.0.0'
# CompatiblePSEditions = @()
GUID = '8e54ad72-e2b3-4755-9a15-6939affc9e34'
Author = 'Nicolas Kapfer'
CompanyName = 'KNS7'
Copyright = '(c) 2018 Nicolas Kapfer. All rights reserved.'
Description = 'This module generate automatically documentation from Powershell Modules in Markdown (md Files) and Confluence Markup syntax'
PowerShellVersion = '4.0'

# PowerShellHostName = ''
# PowerShellHostVersion = ''
# DotNetFrameworkVersion = ''
# CLRVersion = ''
# ProcessorArchitecture = ''
# RequiredModules = @()
# RequiredAssemblies = @()
# ScriptsToProcess = @()
# TypesToProcess = @()
# FormatsToProcess = @()
# NestedModules = @()
FunctionsToExport = @(
    'Format-ConfluenceMarkup',
    'Format-Markdown',
    'Get-ModuleDocumentation',
    'Update-ConfluenceDoc'
    )
CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = @()
# DscResourcesToExport = @()
# ModuleList = @()
# FileList = @()
PrivateData = @{

    PSData = @{
        # Tags = @()
        # LicenseUri = ''
        ProjectUri = 'https://github.com/kns7/KNSModulesDocsGenerator'
        # IconUri = ''
        # ReleaseNotes = ''

    }

}

# HelpInfoURI = ''

# DefaultCommandPrefix = ''

}

