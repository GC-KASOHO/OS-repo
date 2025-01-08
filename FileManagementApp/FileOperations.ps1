Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Drive Explorer"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = "CenterScreen"

# Create ListView for drives and files
$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(10, 40)
$listView.Size = New-Object System.Drawing.Size(500, 500)
$listView.View = [System.Windows.Forms.View]::Details
$listView.FullRowSelect = $true
$listView.GridLines = $true
$listView.AllowDrop = $true  # Enable drag and drop
$listView.BackColor = [System.Drawing.Color]::White  # Set background color to make empty area visible

# Create TextBox for current path
$pathBox = New-Object System.Windows.Forms.TextBox
$pathBox.Location = New-Object System.Drawing.Point(10, 10)
$pathBox.Size = New-Object System.Drawing.Size(660, 20)
$pathBox.ReadOnly = $true

# Create Back button
$backButton = New-Object System.Windows.Forms.Button
$backButton.Location = New-Object System.Drawing.Point(680, 10)
$backButton.Size = New-Object System.Drawing.Size(90, 20)
$backButton.Text = "Back"
$backButton.Enabled = $false

# Create PictureBox for image preview
$imagePreview = New-Object System.Windows.Forms.PictureBox
$imagePreview.Location = New-Object System.Drawing.Point(520, 40)
$imagePreview.Size = New-Object System.Drawing.Size(250, 250)
$imagePreview.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$imagePreview.Visible = $false

# Initialize clipboard variables
$script:clipboardPath = $null
$script:clipboardOperation = $null # 'copy' or 'cut'

# Create context menus
$fileContextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$copyMenuItem = $fileContextMenu.Items.Add("Copy")
$cutMenuItem = $fileContextMenu.Items.Add("Cut")
$pasteMenuItem = $fileContextMenu.Items.Add("Paste")
$deleteFileMenuItem = $fileContextMenu.Items.Add("Delete")
$propertiesMenuItem = $fileContextMenu.Items.Add("Properties")

$folderContextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$folderCopyMenuItem = $folderContextMenu.Items.Add("Copy")
$folderCutMenuItem = $folderContextMenu.Items.Add("Cut")
$folderPasteMenuItem = $folderContextMenu.Items.Add("Paste")
$deleteFolderMenuItem = $folderContextMenu.Items.Add("Delete")
$folderPropertiesMenuItem = $folderContextMenu.Items.Add("Properties")

$driveContextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$drivePropertiesMenuItem = $driveContextMenu.Items.Add("Properties")

# Create empty area context menu
$emptyAreaContextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$emptyAreaPasteMenuItem = $emptyAreaContextMenu.Items.Add("Paste")
$refreshMenuItem = $emptyAreaContextMenu.Items.Add("Refresh")

# Initialize columns for drive view
$driveColumns = @(
    @{Name="Drive"; Width=100},
    @{Name="Label"; Width=150},
    @{Name="Total Size"; Width=120},
    @{Name="Used Space"; Width=120},
    @{Name="Free Space"; Width=120},
    @{Name="% Used"; Width=100}
)

# Initialize columns for file view
$fileColumns = @(
    @{Name="Name"; Width=300},
    @{Name="Type"; Width=100},
    @{Name="Size"; Width=120},
    @{Name="Modified Date"; Width=200}
)

# Function to format size
function Format-Size {
    param([long]$size)
    if ($size -gt 1TB) { return "{0:N2} TB" -f ($size / 1TB) }
    if ($size -gt 1GB) { return "{0:N2} GB" -f ($size / 1GB) }
    if ($size -gt 1MB) { return "{0:N2} MB" -f ($size / 1MB) }
    if ($size -gt 1KB) { return "{0:N2} KB" -f ($size / 1KB) }
    return "{0} Bytes" -f $size
}

# Handle right-click for both items and empty area
$listView.Add_MouseUp({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
        $hit = $listView.HitTest($e.X, $e.Y)
        
        # If clicked on an item
        if ($hit.Item) {
            $hit.Item.Selected = $true
            switch ($hit.Item.Tag) {
                "Drive" { $driveContextMenu.Show($listView, $e.Location) }
                "Directory" { $folderContextMenu.Show($listView, $e.Location) }
                "File" { $fileContextMenu.Show($listView, $e.Location) }
            }
        }
        # If clicked on empty area
        else {
            $listView.SelectedItems.Clear()
            if ($script:clipboardPath) {
                $emptyAreaPasteMenuItem.Enabled = $true
            } else {
                $emptyAreaPasteMenuItem.Enabled = $false
            }
            $emptyAreaContextMenu.Show($listView, $e.Location)
        }
    }
})

# Function to show properties
function Show-ItemProperties {
    param (
        [string]$path
    )
    
    $item = Get-Item $path
    $properties = @"
Name: $($item.Name)
Type: $($item.GetType().Name)
Created: $($item.CreationTime)
Modified: $($item.LastWriteTime)
"@

    if ($item -is [System.IO.FileInfo]) {
        $properties += "`nSize: $(Format-Size $item.Length)"
    } elseif ($item -is [System.IO.DirectoryInfo]) {
        $fileCount = (Get-ChildItem $path -File -Recurse -ErrorAction SilentlyContinue).Count
        $folderCount = (Get-ChildItem $path -Directory -Recurse -ErrorAction SilentlyContinue).Count
        $properties += "`nContains: $fileCount files, $folderCount folders"
    }
[System.Windows.Forms.MessageBox]::Show($properties, "Properties", [System.Windows.Forms.MessageBoxButtons]::OK)
}

# Function to copy or move items
function Copy-MoveItem {
    param (
        [string]$sourcePath,
        [string]$operation # 'copy' or 'cut'
    )
    $script:clipboardPath = $sourcePath
    $script:clipboardOperation = $operation
    # Enable paste menu items
    $pasteMenuItem.Enabled = $true
    $folderPasteMenuItem.Enabled = $true
    $emptyAreaPasteMenuItem.Enabled = $true
}

# Function to paste items
function Paste-Item {
    param (
        [string]$destinationPath
    )
    if ($script:clipboardPath -and $script:clipboardOperation) {
        $item = Get-Item $script:clipboardPath
        $destPath = Join-Path $destinationPath $item.Name

        try {
            if ($script:clipboardOperation -eq 'copy') {
                Copy-Item -Path $script:clipboardPath -Destination $destPath -Recurse
            } else {
                Move-Item -Path $script:clipboardPath -Destination $destPath
            }
            Show-Directory $destinationPath
            $script:clipboardPath = $null
            $script:clipboardOperation = $null
            # Disable paste menu items
            $pasteMenuItem.Enabled = $false
            $folderPasteMenuItem.Enabled = $false
            $emptyAreaPasteMenuItem.Enabled = $false
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Error: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK)
        }
    }
}

# Function to remove items with confirmation
function Remove-SelectedItem {
    param (
        [string]$path
    )
    
    $confirmMessage = "Are you sure you want to delete '$path'?"
    $confirmation = [System.Windows.Forms.MessageBox]::Show(
        $confirmMessage,
        "Confirm Delete",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    
    if ($confirmation -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            if (Test-Path $path -PathType Container) {
                Remove-Item -Path $path -Recurse -Force
            } else {
                Remove-Item -Path $path -Force
            }
            Show-Directory $pathBox.Text
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Error deleting item: $_",
                "Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    }
}

# Function to set up columns
function Set-ListViewColumns {
    param ([array]$columns)
    $listView.Columns.Clear()
    foreach ($col in $columns) {
        $listView.Columns.Add($col.Name, $col.Width)
    }
}

# Function to show drives
function Show-Drives {
    $pathBox.Text = ""
    $backButton.Enabled = $false
    Set-ListViewColumns $driveColumns
    $listView.Items.Clear()
    
    $drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    foreach ($drive in $drives) {
        $item = New-Object Windows.Forms.ListViewItem($drive.DeviceID)
        $item.Tag = "Drive"
        $item.SubItems.Add($drive.VolumeName)
        $item.SubItems.Add((Format-Size $drive.Size))
        $usedSpace = $drive.Size - $drive.FreeSpace
        $item.SubItems.Add((Format-Size $usedSpace))
        $item.SubItems.Add((Format-Size $drive.FreeSpace))
        $usedPercent = [math]::Round(($usedSpace / $drive.Size) * 100, 2)
        $item.SubItems.Add("$usedPercent%")
        [void]$listView.Items.Add($item)
    }
}

# Function to show directory contents
function Show-Directory {
    param ([string]$path)
    $pathBox.Text = $path
    $backButton.Enabled = $true
    Set-ListViewColumns $fileColumns
    $listView.Items.Clear()

    if ($path -ne "") {
        $item = New-Object Windows.Forms.ListViewItem("..")
        $item.Tag = "ParentDir"
        $item.SubItems.Add("Parent Directory")
        $item.SubItems.Add("")
        $item.SubItems.Add("")
        [void]$listView.Items.Add($item)
    }

    Get-ChildItem -Path $path -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $item = New-Object Windows.Forms.ListViewItem($_.Name)
        $item.Tag = "Directory"
        $item.SubItems.Add("Folder")
        $item.SubItems.Add("N/A")
        $item.SubItems.Add($_.LastWriteTime)
        [void]$listView.Items.Add($item)
    }

    Get-ChildItem -Path $path -File -ErrorAction SilentlyContinue | ForEach-Object {
        $item = New-Object Windows.Forms.ListViewItem($_.Name)
        $item.Tag = "File"
        $item.SubItems.Add($_.Extension)
        $item.SubItems.Add((Format-Size $_.Length))
        $item.SubItems.Add($_.LastWriteTime)
        [void]$listView.Items.Add($item)
    }
}

# Handle context menu events
$copyMenuItem.Add_Click({
    $selected = $listView.SelectedItems[0]
    if ($selected) {
        $path = Join-Path $pathBox.Text $selected.Text
        Copy-MoveItem -sourcePath $path -operation 'copy'
    }
})

$cutMenuItem.Add_Click({
    $selected = $listView.SelectedItems[0]
    if ($selected) {
        $path = Join-Path $pathBox.Text $selected.Text
        Copy-MoveItem -sourcePath $path -operation 'cut'
    }
})

$pasteMenuItem.Add_Click({
    Paste-Item -destinationPath $pathBox.Text
})

$deleteFileMenuItem.Add_Click({
    $selected = $listView.SelectedItems[0]
    if ($selected) {
        $path = Join-Path $pathBox.Text $selected.Text
        Remove-SelectedItem -path $path
    }
})

$propertiesMenuItem.Add_Click({
    $selected = $listView.SelectedItems[0]
    if ($selected) {
        $path = Join-Path $pathBox.Text $selected.Text
        Show-ItemProperties -path $path
    }
})

# Handle folder context menu events
$folderCopyMenuItem.Add_Click({ $copyMenuItem.PerformClick() })
$folderCutMenuItem.Add_Click({ $cutMenuItem.PerformClick() })
$folderPasteMenuItem.Add_Click({ $pasteMenuItem.PerformClick() })
$folderPropertiesMenuItem.Add_Click({ $propertiesMenuItem.PerformClick() })
$deleteFolderMenuItem.Add_Click({ $deleteFileMenuItem.PerformClick() })

# Handle empty area context menu events
$emptyAreaPasteMenuItem.Add_Click({ $pasteMenuItem.PerformClick() })
$refreshMenuItem.Add_Click({
    if ($pathBox.Text -eq "") {
        Show-Drives
    } else {
        Show-Directory $pathBox.Text
    }
})

# Handle single-click on list view items
$listView.Add_Click({
    $selected = $listView.SelectedItems[0]
    if ($selected -and $selected.Tag -eq "File") {
        $filePath = Join-Path $pathBox.Text $selected.Text
        $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
        if ($extension -in @(".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff")) {
            try {
                $imagePreview.Image = [System.Drawing.Image]::FromFile($filePath)
                $imagePreview.Visible = $true
            }
            catch {
                $imagePreview.Visible = $false
            }
        } else {
            $imagePreview.Visible = $false
        }
    }
})

# Handle double-click
$listView.Add_DoubleClick({
    $selected = $listView.SelectedItems[0]
    if ($selected) {
        switch ($selected.Tag) {
            "Drive" {
                $drivePath = $selected.Text + "\"
                Show-Directory $drivePath
            }
            "Directory" {
                $newPath = Join-Path $pathBox.Text $selected.Text
                Show-Directory $newPath
            }
            "ParentDir" {
                $parentPath = Split-Path $pathBox.Text -Parent
                if ($parentPath) {
                    Show-Directory $parentPath
                } else {
                    Show-Drives
                }
            }
            "File" {
                try {
                    $filePath = Join-Path $pathBox.Text $selected.Text
                    Start-Process $filePath
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Error opening file: $_",
                        "Error",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Error
                    )
                }
            }
        }
    }
})

# Handle Back button
$backButton.Add_Click({
    if ($pathBox.Text -eq "") {
        return
    }
    
    $parentPath = Split-Path $pathBox.Text -Parent
    if ($parentPath) {
        Show-Directory $parentPath
    } else {
        Show-Drives
    }
})

# Handle keyboard shortcuts
$form.KeyPreview = $true
$form.Add_KeyDown({
    param($sender, $e)
    
    if ($e.Control) {
        switch ($e.KeyCode) {
            'C' {
                if ($listView.SelectedItems.Count -gt 0) {
                    $copyMenuItem.PerformClick()
                }
            }
            'X' {
                if ($listView.SelectedItems.Count -gt 0) {
                    $cutMenuItem.PerformClick()
                }
            }
            'V' {
                if ($script:clipboardPath) {
                    $pasteMenuItem.PerformClick()
                }
            }
        }
    }
    elseif ($e.KeyCode -eq 'F5') {
        $refreshMenuItem.PerformClick()
    }
    elseif ($e.KeyCode -eq 'Delete') {
        if ($listView.SelectedItems.Count -gt 0) {
            $deleteFileMenuItem.PerformClick()
        }
    }
})

# Add controls to form
$form.Controls.AddRange(@($listView, $pathBox, $backButton, $imagePreview))

# Initialize paste menu items as disabled
$pasteMenuItem.Enabled = $false
$folderPasteMenuItem.Enabled = $false
$emptyAreaPasteMenuItem.Enabled = $false

# Load drives and show form
Show-Drives
$form.ShowDialog()
