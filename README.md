

# PowerShell Module "KNSModulesDocsGenerator"
Version 1.0.0

This module generate automatically documentation from Powershell Modules in Markdown (md Files) and Confluence Markup syntax


## Format-ConfluenceMarkup

### SYNTAX
```powershell
Format-ConfluenceMarkup [-ContentObject] <Object> [[-FileName] <Object>] [-NoTableOfContent] [<CommonParameters>]
```

### PARAMETERS
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>ContentObject</nobr> | None | Content Generated from Get-ModuleDocumentation | true | true \(ByValue\) |  |
| <nobr>FileName</nobr> | None | If specified, the content will be exported to this file | false | false |  |
| <nobr>NoTableOfContent</nobr> | None |  | false | false |  |


## Format-Markdown

### SYNTAX
```powershell
Format-Markdown [-ContentObject] <Object> [[-FileName] <Object>] [<CommonParameters>]
```

### PARAMETERS
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>ContentObject</nobr> | None | Content Generated from Get-ModuleDocumentation | true | true \(ByValue\) |  |
| <nobr>FileName</nobr> | None | If specified, the content will be exported to this file | false | false |  |


## Get-ModuleDocumentation

### SYNTAX
```powershell
Get-ModuleDocumentation [-ModuleName] <Object> [<CommonParameters>]
```

### PARAMETERS
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>ModuleName</nobr> | None | The module name to be documented | true | false |  |


## Update-ConfluenceDoc

### SYNTAX
```powershell
Update-ConfluenceDoc [-Content] <Object> [-ConfluenceURL] <string> [-ConfluencePageID] <string> [-Credential] <pscredential> [<CommonParameters>]
```

### PARAMETERS
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>ConfluencePageID</nobr> | PageID, ID |  | true | false |  |
| <nobr>ConfluenceURL</nobr> | URL |  | true | false |  |
| <nobr>Content</nobr> | None |  | true | true \(ByValue\) |  |
| <nobr>Credential</nobr> | None |  | true | false |  |

