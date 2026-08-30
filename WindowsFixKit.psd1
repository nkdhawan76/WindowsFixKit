@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'WindowsFixKit.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID = 'a8f56193-4b51-4f4c-83b6-1284d72bc194'

    # Author of this module
    Author = 'Nikil Dhawan'

    # Company or vendor of this module
    CompanyName = 'WindowsFixKit Open Source'

    # Copyright statement for this module
    Copyright = '(c) 2026 Nikil Dhawan. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Diagnostic and auto-fix toolkit for Windows Update, networking, Wi-Fi, Bluetooth, DNS, and hardware system health across Windows 7, 8.1, 10, and 11.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @('Invoke-WindowsFixKit')

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for PowerShell Gallery discovery
            Tags = @('windows-update', 'troubleshooting', 'powershell', 'diagnostics', 'hardware', 'network', 'wifi', 'bluetooth', 'dns', 'windows10', 'windows11')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/nkdhawan76/WindowsFixKit/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/nkdhawan76/WindowsFixKit'

            # ReleaseNotes of this module
            ReleaseNotes = 'Initial production release with Windows Update repair, hardware diagnosis, and network auto-fixes.'
        }
    }
}
