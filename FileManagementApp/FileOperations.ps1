Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Drive Explorer"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = "CenterScreen"

# Create ListView for drives
$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(10, 10)
$listView.Size = New-Object System.Drawing.Size(760, 530)
$listView.View = [System.Windows.Forms.View]::Details
$listView.FullRowSelect = $true
$listView.GridLines = $true

# Add columns to ListView
$listView.Columns.Add("Drive", 100)
$listView.Columns.Add("Label", 150)
$listView.Columns.Add("Total Size", 120)
$listView.Columns.Add("Used Space", 120)
$listView.Columns.Add("Free Space", 120)
$listView.Columns.Add("% Used", 100)

# Create context menu
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip

# Open in Explorer menu item
$openMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$openMenuItem.Text = "Open in Explorer"
$openMenuItem.Add_Click({
    $selected = $listView.SelectedItems[0]
    if ($selected) {
        Start-Process "explorer.exe" $selected.Text
    }
})

# Properties menu item
$propertiesMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$propertiesMenuItem.Text = "Properties"
$propertiesMenuItem.Add_Click({
    $selected = $listView.SelectedItems[0]
    if ($selected) {
        $driveRoot = $selected.Text + "\"
        Start-Process "properties" $driveRoot
    }
})

# Refresh menu item
$refreshMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$refreshMenuItem.Text = "Refresh"
$refreshMenuItem.Add_Click({
    Show-Drives
})

# Add items to context menu
$contextMenu.Items.Add($openMenuItem)
$contextMenu.Items.Add($propertiesMenuItem)
$contextMenu.Items.AddRange([System.Windows.Forms.ToolStripMenuItem]@(
    (New-Object System.Windows.Forms.ToolStripSeparator),
    $refreshMenuItem
))

# Assign context menu to ListView
$listView.ContextMenuStrip = $contextMenu

# Function to format size
function Format-Size {
    param([long]$size)
    if ($size -gt 1TB) { return "{0:N2} TB" -f ($size / 1TB) }
    if ($size -gt 1GB) { return "{0:N2} GB" -f ($size / 1GB) }
    if ($size -gt 1MB) { return "{0:N2} MB" -f ($size / 1MB) }
    if ($size -gt 1KB) { return "{0:N2} KB" -f ($size / 1KB) }
    return "{0} Bytes" -f $size
}

# Function to show drives
function Show-Drives {
    $listView.Items.Clear()
    $drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    
    foreach ($drive in $drives) {
        $item = New-Object Windows.Forms.ListViewItem($drive.DeviceID)
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

# Add double-click handler
$listView.Add_DoubleClick({
    $selected = $listView.SelectedItems[0]
    if ($selected) {
        Start-Process "explorer.exe" $selected.Text
    }
})

# Add controls to form
$form.Controls.Add($listView)

# Load drives and show form
Show-Drives
$form.ShowDialog()