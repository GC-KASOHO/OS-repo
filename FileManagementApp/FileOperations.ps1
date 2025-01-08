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
$listView.Size = New-Object System.Drawing.Size(500, 500)  # Adjust size so there's space for preview
$listView.View = [System.Windows.Forms.View]::Details
$listView.FullRowSelect = $true
$listView.GridLines = $true

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

# Create PictureBox for image preview (move to the right side)
$imagePreview = New-Object System.Windows.Forms.PictureBox
$imagePreview.Location = New-Object System.Drawing.Point(520, 40)  # Move it to the right side
$imagePreview.Size = New-Object System.Drawing.Size(250, 250)      # Adjust the size if needed
$imagePreview.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$imagePreview.Visible = $false  # Hide by default

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

# Function to set up columns
function Set-ListViewColumns {
    param (
        [array]$columns
    )
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
    param (
        [string]$path
    )
    $pathBox.Text = $path
    $backButton.Enabled = $true
    Set-ListViewColumns $fileColumns
    $listView.Items.Clear()

    # Add parent directory item if not at root
    if ($path -ne "") {
        $item = New-Object Windows.Forms.ListViewItem("..")
        $item.Tag = "ParentDir"
        $item.SubItems.Add("Parent Directory")
        $item.SubItems.Add("")
        $item.SubItems.Add("")
        [void]$listView.Items.Add($item)
    }

    # Get directories
    Get-ChildItem -Path $path -Directory | ForEach-Object {
        $item = New-Object Windows.Forms.ListViewItem($_.Name)
        $item.Tag = "Directory"
        $item.SubItems.Add("Folder")
        $item.SubItems.Add("N/A")
        $item.SubItems.Add($_.LastWriteTime)
        [void]$listView.Items.Add($item)
    }

    # Get files
    Get-ChildItem -Path $path -File | ForEach-Object {
        $item = New-Object Windows.Forms.ListViewItem($_.Name)
        $item.Tag = "File"
        $item.SubItems.Add($_.Extension)
        $item.SubItems.Add((Format-Size $_.Length))
        $item.SubItems.Add($_.LastWriteTime)
        [void]$listView.Items.Add($item)
    }
}

# Handle single-click on list view items
$listView.Add_Click({
    $selected = $listView.SelectedItems[0]
    if ($selected -and $selected.Tag -eq "File") {
        $filePath = Join-Path $pathBox.Text $selected.Text
        # Preview image if it's an image file
        $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
        if ($extension -in @(".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff")) {
            $imagePreview.Image = [System.Drawing.Image]::FromFile($filePath)
            $imagePreview.Visible = $true
        } else {
            $imagePreview.Visible = $false  # Hide preview for non-image files
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
                $filePath = Join-Path $pathBox.Text $selected.Text
                Start-Process $filePath
            }
        }
    }
})

# Handle right-click
$listView.Add_MouseClick({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
        $hit = $listView.HitTest($e.Location)
        if ($hit.Item) {
            $hit.Item.Selected = $true
            switch ($hit.Item.Tag) {
                "Drive" { $driveContextMenu.Show($listView, $e.Location) }
                "Directory" { $folderContextMenu.Show($listView, $e.Location) }
                "File" { $fileContextMenu.Show($listView, $e.Location) }
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

# Add controls to form
$form.Controls.AddRange(@($listView, $pathBox, $backButton, $imagePreview))

# Load drives and show form
Show-Drives
$form.ShowDialog()
