#region Configuration
# Define common user folders
$commonFolders = @{
    "Desktop" = [Environment]::GetFolderPath("Desktop")
    "Documents" = [Environment]::GetFolderPath("MyDocuments") 
    "Downloads" = (Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads")
    "Pictures" = [Environment]::GetFolderPath("MyPictures")
    "Music" = [Environment]::GetFolderPath("MyMusic")
    "Videos" = [Environment]::GetFolderPath("MyVideos")
}

# Load required assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

# First install System.Drawing.Common if not present
Install-Package System.Drawing.Common -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Drawing.Common

# Initialize global variables and cache
$script:navigationHistory = @()
$script:currentHistoryIndex = -1
$script:clipboardPaths = $null
$script:clipboardOperation = $null
$script:iconCache = @{}
$script:folderIcon = $null

#endregion Configuration

#region UI creation functions
function New-MainForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "PowerShell File Explorer"
    $form.Size = New-Object System.Drawing.Size(1000, 600)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    return $form
}

function New-MenuStrip {
    $menuStrip = New-Object System.Windows.Forms.MenuStrip
    
    # File Menu
    $fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem("File")
    $script:newFolderMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("New Folder")
    $script:exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Exit")
    $fileMenu.DropDownItems.AddRange(@($script:newFolderMenuItem, $script:exitMenuItem))
    
    # Edit Menu
    $editMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Edit")
    $script:cutMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Cut")
    $script:copyMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Copy")
    $script:pasteMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Paste")
    $script:selectAllMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Select All")
    $editMenu.DropDownItems.AddRange(@($script:cutMenuItem, $script:copyMenuItem, $script:pasteMenuItem, $script:selectAllMenuItem))
    
    # View Menu
    $viewMenu = New-Object System.Windows.Forms.ToolStripMenuItem("View")
    $script:refreshMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Refresh")
    $script:showHiddenMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Show Hidden Files")
    $script:detailsViewMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Details")
    $script:largeIconsMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Large Icons")
    $script:smallIconsMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Small Icons")
    $script:listViewMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("List")
    $viewMenu.DropDownItems.AddRange(@($script:refreshMenuItem, $script:showHiddenMenuItem, 
        $script:detailsViewMenuItem, $script:largeIconsMenuItem, $script:smallIconsMenuItem, $script:listViewMenuItem))
    
    $menuStrip.Items.AddRange(@($fileMenu, $editMenu, $viewMenu))
    
    return @{ MenuStrip = $menuStrip }
}

function New-ToolStrip {
    $toolStrip = New-Object System.Windows.Forms.ToolStrip
    
    $script:backButton = New-Object System.Windows.Forms.ToolStripButton
    $script:backButton.Text = "Back"
    $script:backButton.Enabled = $false
    
    $script:forwardButton = New-Object System.Windows.Forms.ToolStripButton
    $script:forwardButton.Text = "Forward"
    $script:forwardButton.Enabled = $false
    
    $script:upButton = New-Object System.Windows.Forms.ToolStripButton
    $script:upButton.Text = "Up"
    
    $script:addressBar = New-Object System.Windows.Forms.ToolStripTextBox
    $script:addressBar.Width = 300
    
    $script:searchBox = New-Object System.Windows.Forms.ToolStripTextBox
    $script:searchBox.Width = 200
    $script:searchBox.PlaceholderText = "Search..."
    
    $toolStrip.Items.AddRange(@(
        $script:backButton,
        $script:forwardButton,
        $script:upButton,
        $script:addressBar,
        $script:searchBox
    ))
    
    return @{ ToolStrip = $toolStrip }
}

function New-TreeView {
    $treeView = New-Object System.Windows.Forms.TreeView
    $treeView.Dock = [System.Windows.Forms.DockStyle]::Left
    $treeView.Width = 200
    return $treeView
}

function New-ListView {
    $listView = New-Object System.Windows.Forms.ListView
    $listView.Dock = [System.Windows.Forms.DockStyle]::Fill
    $listView.View = [System.Windows.Forms.View]::Details
    $listView.FullRowSelect = $true
    $listView.MultiSelect = $true
    $listView.AllowDrop = $true
    
    # Add columns
    $listView.Columns.Add("Name", 200)
    $listView.Columns.Add("Date Modified", 150)
    $listView.Columns.Add("Type", 100)
    $listView.Columns.Add("Size", 100)
    
    # Create context menu
    $contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
        
    # Create menu items
    $script:contextDelete = New-Object System.Windows.Forms.ToolStripMenuItem("Delete")
    $script:contextCut = New-Object System.Windows.Forms.ToolStripMenuItem("Cut")
    $script:contextCopy = New-Object System.Windows.Forms.ToolStripMenuItem("Copy")
    $script:contextPaste = New-Object System.Windows.Forms.ToolStripMenuItem("Paste")
    $separator = New-Object System.Windows.Forms.ToolStripSeparator

    # Add items to context menu - using individual Add() calls instead of AddRange
    [void]$contextMenu.Items.Add($script:contextCut)
    [void]$contextMenu.Items.Add($script:contextCopy)
    [void]$contextMenu.Items.Add($script:contextPaste)
    [void]$contextMenu.Items.Add($separator)
    [void]$contextMenu.Items.Add($script:contextDelete)

    # Assign context menu to ListView
    $listView.ContextMenuStrip = $contextMenu
    
    return $listView
}

function New-PreviewPanel {
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Dock = [System.Windows.Forms.DockStyle]::Right
    $panel.Width = 300
    $panel.Visible = $false
    
    return @{ Panel = $panel }
}

function New-StatusStrip {
    $statusStrip = New-Object System.Windows.Forms.StatusStrip
    
    $script:itemCountLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
    $script:statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
    $script:statusLabel.Spring = $true
    
    $statusStrip.Items.AddRange(@($script:itemCountLabel, $script:statusLabel))
    
    return @{ StatusStrip = $statusStrip }
}

#end region UI creation function

#region Helper Functions
function Format-Size {
    param([long]$size)
    
    if ($size -ge 1TB) { return "{0:N2} TB" -f ($size / 1TB) }
    if ($size -ge 1GB) { return "{0:N2} GB" -f ($size / 1GB) }
    if ($size -ge 1MB) { return "{0:N2} MB" -f ($size / 1MB) }
    if ($size -ge 1KB) { return "{0:N2} KB" -f ($size / 1KB) }
    return "$size Bytes"
}

function Initialize-ImageLists {
    if (-not $script:folderIcon) {
        $script:folderIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Windows\System32\shell32.dll")
    }
    
    $largeImageList.Images.Clear()
    $smallImageList.Images.Clear()
    
    $largeImageList.Images.Add("folder", $script:folderIcon)
    $smallImageList.Images.Add("folder", $script:folderIcon)
    
    $defaultIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Windows\System32\notepad.exe")
    $largeImageList.Images.Add("file", $defaultIcon)
    $smallImageList.Images.Add("file", $defaultIcon)
}

function Get-FileIconIndex {
    param([string]$filePath)
    
    try {
        $extension = [System.IO.Path]::GetExtension($filePath)
        
        if ($script:iconCache.ContainsKey($extension)) {
            return $script:iconCache[$extension]
        }
        
        if ((Get-Item $filePath) -is [System.IO.DirectoryInfo]) {
            return 0
        }
        
        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($filePath)
        if ($icon) {
            $index = $largeImageList.Images.Count
            $largeImageList.Images.Add($extension, $icon)
            $smallImageList.Images.Add($extension, $icon)
            $script:iconCache[$extension] = $index
            return $index
        }
    }
    catch {
        return 1
    }
    
    return 1
}

function Get-ImageThumbnail {
    param (
        [string]$imagePath,
        [int]$size = 48
    )
    
    $image = $null
    $thumbnail = $null
    $graphics = $null
    $stream = $null
    
    try {
        if (Test-Path $imagePath) {
            $stream = [System.IO.File]::OpenRead($imagePath)
            $image = [System.Drawing.Image]::FromStream($stream)
            
            if ($image -eq $null) { throw "Invalid image format" }
            
            $thumbnail = New-Object System.Drawing.Bitmap($size, $size)
            $graphics = [System.Drawing.Graphics]::FromImage($thumbnail)
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            
            $ratio = [Math]::Min($size / $image.Width, $size / $image.Height)
            $newWidth = [Math]::Floor($image.Width * $ratio)
            $newHeight = [Math]::Floor($image.Height * $ratio)
            $x = ($size - $newWidth) / 2
            $y = ($size - $newHeight) / 2
            
            $destRect = New-Object System.Drawing.Rectangle($x, $y, $newWidth, $newHeight)
            $srcRect = New-Object System.Drawing.Rectangle(0, 0, $image.Width, $image.Height)
            
            $graphics.DrawImage($image, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
            
            return $thumbnail
        }
    }
    catch {
        Write-Warning "Error creating thumbnail: $_"
        return $null
    }
    finally {
        if ($graphics) { $graphics.Dispose() }
        if ($image) { $image.Dispose() }
        if ($stream) { $stream.Dispose() }
    }
}

# Add the missing Update-TreeView and Update-ListView functions here
function Update-TreeView {
    param([string]$selectedPath)
    
    $treeView.Nodes.Clear()
    
    # Add drives
    Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | ForEach-Object {
        $driveNode = New-Object System.Windows.Forms.TreeNode
        $driveNode.Text = "$($_.DeviceID) ($($_.VolumeName))"
        $driveNode.Tag = $_.DeviceID + "\"
        $driveNode.ImageIndex = 0
        $driveNode.SelectedImageIndex = 0
        [void]$treeView.Nodes.Add($driveNode)
        
        # If this is the selected path or its parent, expand it
        if ($selectedPath -and $selectedPath.StartsWith($driveNode.Tag)) {
            $driveNode.Expand()
            Add-TreeNodes $driveNode
        }
    }
}

function Add-TreeNodes {
    param([System.Windows.Forms.TreeNode]$parentNode)
    
    try {
        Get-ChildItem -Path $parentNode.Tag -Directory -ErrorAction Stop | ForEach-Object {
            $childNode = New-Object System.Windows.Forms.TreeNode
            $childNode.Text = $_.Name
            $childNode.Tag = $_.FullName
            $childNode.ImageIndex = 0
            $childNode.SelectedImageIndex = 0
            [void]$parentNode.Nodes.Add($childNode)
        }
    }
    catch {
        Write-Warning "Error accessing $($parentNode.Tag): $_"
    }
}

function Update-ListView {
    param([string]$path)
    
    $listView.Items.Clear()
    if (-not $path) { return }
    
    $addressBar.Text = $path
    
    try {
        $items = Get-ChildItem -Path $path -ErrorAction Stop
        if (-not $showHiddenMenuItem.Checked) {
            $items = $items | Where-Object { -not $_.Attributes.HasFlag([System.IO.FileAttributes]::Hidden) }
        }
        
        foreach ($item in $items) {
            $listItem = New-Object System.Windows.Forms.ListViewItem
            $listItem.Text = $item.Name
            $listItem.Tag = $item.FullName
            
            # Add subitems
            $listItem.SubItems.Add($item.LastWriteTime.ToString("g"))
            if ($item.PSIsContainer) {
                $listItem.SubItems.Add("Folder")
                $listItem.SubItems.Add("")
                $listItem.ImageIndex = 0
            }
            else {
                $listItem.SubItems.Add($item.Extension)
                $listItem.SubItems.Add((Format-Size $item.Length))
                $listItem.ImageIndex = (Get-FileIconIndex $item.FullName)
            }
            
            [void]$listView.Items.Add($listItem)
        }
        
        $itemCountLabel.Text = "$($listView.Items.Count) items"
        $statusLabel.Text = "Ready"
    }
    catch {
        $statusLabel.Text = "Error: $_"
    }
}
#endregion Helper Functions

#region UI Creation Functions
# Create main form
$form = New-MainForm
$menuItems = New-MenuStrip
$toolStripItems = New-ToolStrip
$treeView = New-TreeView
$listView = New-ListView
$previewPanel = New-PreviewPanel
$statusStrip = New-StatusStrip

# Create image lists for icons
$largeImageList = New-Object System.Windows.Forms.ImageList
$largeImageList.ImageSize = New-Object System.Drawing.Size(32, 32)
$smallImageList = New-Object System.Windows.Forms.ImageList
$smallImageList.ImageSize = New-Object System.Drawing.Size(16, 16)

# Set image lists
$listView.LargeImageList = $largeImageList
$listView.SmallImageList = $smallImageList
$treeView.ImageList = $smallImageList

function New-MainForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "PowerShell File Explorer"
    $form.Size = New-Object System.Drawing.Size(1000, 600)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    return $form
}

function New-MenuStrip {
    $menuStrip = New-Object System.Windows.Forms.MenuStrip
    
    # File Menu
    $fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem("File")
    $script:newFolderMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("New Folder")
    $script:exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Exit")
    $fileMenu.DropDownItems.AddRange(@($script:newFolderMenuItem, $script:exitMenuItem))
    
    # Edit Menu
    $editMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Edit")
    $script:cutMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Cut")
    $script:copyMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Copy")
    $script:pasteMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Paste")
    $script:selectAllMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Select All")
    $editMenu.DropDownItems.AddRange(@($script:cutMenuItem, $script:copyMenuItem, $script:pasteMenuItem, $script:selectAllMenuItem))
    
    # View Menu
    $viewMenu = New-Object System.Windows.Forms.ToolStripMenuItem("View")
    $script:refreshMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Refresh")
    $script:showHiddenMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Show Hidden Files")
    $script:detailsViewMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Details")
    $script:largeIconsMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Large Icons")
    $script:smallIconsMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Small Icons")
    $script:listViewMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("List")
    $viewMenu.DropDownItems.AddRange(@($script:refreshMenuItem, $script:showHiddenMenuItem, 
        $script:detailsViewMenuItem, $script:largeIconsMenuItem, $script:smallIconsMenuItem, $script:listViewMenuItem))
    
    $menuStrip.Items.AddRange(@($fileMenu, $editMenu, $viewMenu))
    
    return @{ MenuStrip = $menuStrip }
}

function New-ToolStrip {
    $toolStrip = New-Object System.Windows.Forms.ToolStrip
    
    $script:backButton = New-Object System.Windows.Forms.ToolStripButton
    $script:backButton.Text = "Back"
    $script:backButton.Enabled = $false
    
    $script:forwardButton = New-Object System.Windows.Forms.ToolStripButton
    $script:forwardButton.Text = "Forward"
    $script:forwardButton.Enabled = $false
    
    $script:upButton = New-Object System.Windows.Forms.ToolStripButton
    $script:upButton.Text = "Up"
    
    $script:addressBar = New-Object System.Windows.Forms.ToolStripTextBox
    $script:addressBar.Width = 300
    
    $script:searchBox = New-Object System.Windows.Forms.ToolStripTextBox
    $script:searchBox.Width = 200
    $script:searchBox.PlaceholderText = "Search..."
    
    $toolStrip.Items.AddRange(@(
        $script:backButton,
        $script:forwardButton,
        $script:upButton,
        $script:addressBar,
        $script:searchBox
    ))
    
    return @{ ToolStrip = $toolStrip }
}

function New-TreeView {
    $treeView = New-Object System.Windows.Forms.TreeView
    $treeView.Dock = [System.Windows.Forms.DockStyle]::Left
    $treeView.Width = 200
    return $treeView
}

function New-ListView {
    $listView = New-Object System.Windows.Forms.ListView
    $listView.Dock = [System.Windows.Forms.DockStyle]::Fill
    $listView.View = [System.Windows.Forms.View]::Details
    $listView.FullRowSelect = $true
    $listView.MultiSelect = $true
    $listView.AllowDrop = $true
    
    # Add columns
    $listView.Columns.Add("Name", 200)
    $listView.Columns.Add("Date Modified", 150)
    $listView.Columns.Add("Type", 100)
    $listView.Columns.Add("Size", 100)
    
    # Add context menu
    $contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
    $script:contextDelete = New-Object System.Windows.Forms.ToolStripMenuItem("Delete")
    $script:contextCut = New-Object System.Windows.Forms.ToolStripMenuItem("Cut")
    $script:contextCopy = New-Object System.Windows.Forms.ToolStripMenuItem("Copy")
    $script:contextPaste = New-Object System.Windows.Forms.ToolStripMenuItem("Paste")
    $contextMenu.Items.AddRange(@(
        $script:contextCut,
        $script:contextCopy,
        $script:contextPaste,
        New-Object System.Windows.Forms.ToolStripSeparator,
        $script:contextDelete
    ))
    $listView.ContextMenuStrip = $contextMenu
    
    return $listView
}

function New-PreviewPanel {
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Dock = [System.Windows.Forms.DockStyle]::Right
    $panel.Width = 300
    $panel.Visible = $false
    
    return @{ Panel = $panel }
}

function New-StatusStrip {
    $statusStrip = New-Object System.Windows.Forms.StatusStrip
    
    $script:itemCountLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
    $script:statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
    $script:statusLabel.Spring = $true
    
    $statusStrip.Items.AddRange(@($script:itemCountLabel, $script:statusLabel))
    
    return @{ StatusStrip = $statusStrip }
}

# Initialize image lists
Initialize-ImageLists

# Add controls to form
$form.Controls.AddRange(@(
    $menuItems.MenuStrip,
    $toolStripItems.ToolStrip,
    $treeView,
    $listView,
    $previewPanel.Panel,
    $statusStrip.StatusStrip
))

#endregion UI Creation Functions

#region Event Handlers
# Navigation Events
$treeView.Add_AfterSelect({
    $path = $_.Node.Tag
    Update-ListView $path
})

$listView.Add_SelectedIndexChanged({
    if ($_.SelectedItems.Count -eq 1) {
        Update-Preview $_.SelectedItems[0].Tag
    }
})

$listView.Add_DoubleClick({
    if ($listView.SelectedItems.Count -gt 0) {
        $selected = $listView.SelectedItems[0]
        $path = $selected.Tag
        if (Test-Path $path -PathType Container) {
            # Add to navigation history
            $script:navigationHistory = $script:navigationHistory[0..$script:currentHistoryIndex]
            $script:navigationHistory += $path
            $script:currentHistoryIndex++
            
            Update-ListView $path
            Update-TreeView $path
        }
        else {
            try {
                Invoke-Item -Path $path
            }
            catch {
                try {
                    $shell = New-Object -ComObject Shell.Application
                    $shell.ShellExecute($path)
                }
                catch {
                    Start-Process -FilePath $path -ErrorAction Stop
                }
            }
        }
    }
})

# Navigation Button Events
$backButton.Add_Click({
    if ($script:currentHistoryIndex -gt 0) {
        $script:currentHistoryIndex--
        $path = $script:navigationHistory[$script:currentHistoryIndex]
        Update-ListView $path
        Update-TreeView $path
        $statusLabel.Text = "Navigated back to $path"
    }
})

$forwardButton.Add_Click({
    if ($script:currentHistoryIndex -lt ($script:navigationHistory.Count - 1)) {
        $script:currentHistoryIndex++
        $path = $script:navigationHistory[$script:currentHistoryIndex]
        Update-ListView $path
        Update-TreeView $path
        $statusLabel.Text = "Navigated forward to $path"
    }
})

$upButton.Add_Click({
    $currentPath = $addressBar.Text
    if ($currentPath) {
        $parent = Split-Path $currentPath -Parent
        if ($parent) {
            # Add to navigation history
            $script:navigationHistory = $script:navigationHistory[0..$script:currentHistoryIndex]
            $script:navigationHistory += $parent
            $script:currentHistoryIndex++
            
            Update-ListView $parent
            Update-TreeView $parent
            $statusLabel.Text = "Navigated up to $parent"
        }
    }
})

# Context menu event handlers
$contextCut.Add_Click({ $cutMenuItem.PerformClick() })
$contextCopy.Add_Click({ $copyMenuItem.PerformClick() })
$contextPaste.Add_Click({ $pasteMenuItem.PerformClick() })

#endregion

#region File Operations
# Cut Operation
$cutMenuItem.Add_Click({
    if ($listView.SelectedItems.Count -gt 0) {
        $script:clipboardPaths = @($listView.SelectedItems | ForEach-Object { $_.Tag })
        $script:clipboardOperation = "cut"
        $statusLabel.Text = "Cut $($listView.SelectedItems.Count) items to clipboard"
    }
})

# Copy Operation
$copyMenuItem.Add_Click({
    if ($listView.SelectedItems.Count -gt 0) {
        $script:clipboardPaths = @($listView.SelectedItems | ForEach-Object { $_.Tag })
        $script:clipboardOperation = "copy"
        $statusLabel.Text = "Copied $($listView.SelectedItems.Count) items to clipboard"
    }
})

# Paste Operation
$pasteMenuItem.Add_Click({
    if ($script:clipboardPaths -and $addressBar.Text) {
        $totalItems = $script:clipboardPaths.Count
        $processedItems = 0
        
        foreach ($sourcePath in $script:clipboardPaths) {
            try {
                $destination = Join-Path $addressBar.Text (Split-Path $sourcePath -Leaf)
                if ($script:clipboardOperation -eq "cut") {
                    Move-Item -Path $sourcePath -Destination $destination -ErrorAction Stop
                } else {
                    Copy-Item -Path $sourcePath -Destination $destination -Recurse -ErrorAction Stop
                }
                $processedItems++
                $statusLabel.Text = "Processing... ($processedItems of $totalItems)"
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show(
                    "Error processing $sourcePath`: $_",
                    "Error",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
            }
        }
        
        Update-ListView $addressBar.Text
        if ($script:clipboardOperation -eq "cut") {
            $script:clipboardPaths = $null
            $script:clipboardOperation = $null
        }
        $statusLabel.Text = "Completed processing $processedItems of $totalItems items"
    }
})

# Delete Operation
$contextDelete.Add_Click({
    if ($listView.SelectedItems.Count -gt 0) {
        $itemCount = $listView.SelectedItems.Count
        $message = if ($itemCount -eq 1) {
            "Are you sure you want to delete '$(Split-Path $listView.SelectedItems[0].Tag -Leaf)'?"
        } else {
            "Are you sure you want to delete these $itemCount items?"
        }
        
        $result = [System.Windows.Forms.MessageBox]::Show(
            $message,
            "Confirm Delete",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            $processedItems = 0
            foreach ($item in $listView.SelectedItems) {
                try {
                    Remove-Item -Path $item.Tag -Recurse -Force -ErrorAction Stop
                    $processedItems++
                    $statusLabel.Text = "Deleting... ($processedItems of $itemCount)"
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Error deleting $(Split-Path $item.Tag -Leaf): $_",
                        "Error",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Error
                    )
                }
            }
            Update-ListView $addressBar.Text
            $statusLabel.Text = "Successfully deleted $processedItems of $itemCount items"
        }
    }
})
#endregion

#region Search and Filter
$searchBox.Add_TextChanged({
    $searchText = $searchBox.Text
    if ($searchText) {
        $currentPath = $addressBar.Text
        if ($currentPath) {
            $listView.Items.Clear()
            Get-ChildItem -Path $currentPath -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like "*$searchText*" } |
                ForEach-Object {
                    $listItem = $listView.Items.Add($_.Name)
                    $listItem.SubItems.Add($_.LastWriteTime.ToString("g"))
                    if ($_.PSIsContainer) {
                        $listItem.SubItems.Add("Folder")
                        $listItem.SubItems.Add("")
                    }
                    else {
                        $listItem.SubItems.Add($_.Extension)
                        $listItem.SubItems.Add((Format-Size $_.Length))
                    }
                    $listItem.Tag = $_.FullName
                }
        }
    }
    else {
        Update-ListView $addressBar.Text
    }
})

# Show/Hide Hidden Files
$showHiddenMenuItem.Add_Click({
    Update-ListView $addressBar.Text
})
#endregion

#region Drag and Drop Operations
$listView.Add_ItemDrag({
    if ($_.Item) {
        $listView.DoDragDrop($_.Item.Tag, [System.Windows.Forms.DragDropEffects]::Copy -bor [System.Windows.Forms.DragDropEffects]::Move)
    }
})

$listView.Add_DragEnter({
    if ($_.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
        $_.Effect = [System.Windows.Forms.DragDropEffects]::Copy
    }
})

$listView.Add_DragDrop({
    $files = $_.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
    $targetPath = $addressBar.Text
    
    foreach ($file in $files) {
        try {
            if (Test-Path $file -PathType Container) {
                Copy-Item -Path $file -Destination $targetPath -Recurse -ErrorAction Stop
            }
            else {
                Copy-Item -Path $file -Destination $targetPath -ErrorAction Stop
            }
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Error copying $file`: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    
    Update-ListView $targetPath
    $statusLabel.Text = "Files copied successfully"
})
#endregion

#region Keyboard Shortcuts
$form.KeyPreview = $true
$form.Add_KeyDown({
    param($sender, $e)
    
    if ($e.Control) {
        switch ($e.KeyCode) {
            'A' { $selectAllMenuItem.PerformClick() }
            'C' { $copyMenuItem.PerformClick() }
            'X' { $cutMenuItem.PerformClick() }
            'V' { $pasteMenuItem.PerformClick() }
        }
    }
    elseif ($e.KeyCode -eq 'F5') {
        $refreshMenuItem.PerformClick()
    }
    elseif ($e.KeyCode -eq 'Delete') {
        $contextDelete.PerformClick()
    }
    elseif ($e.KeyCode -eq 'F2') {
        Start-Rename
    }
})

# Zoom functionality
$form.Add_MouseWheel({
    if ([System.Windows.Forms.Control]::ModifierKeys -eq 'Control') {
        if ($_.Delta -gt 0) {
            # Zoom in
            if ($listView.View -eq [System.Windows.Forms.View]::LargeIcon) {
                $largeImageList.ImageSize = New-Object System.Drawing.Size(
                    [Math]::Min($largeImageList.ImageSize.Width + 8, 256),
                    [Math]::Min($largeImageList.ImageSize.Height + 8, 256)
                )
            } elseif ($listView.View -eq [System.Windows.Forms.View]::SmallIcon) {
                $smallImageList.ImageSize = New-Object System.Drawing.Size(
                    [Math]::Min($smallImageList.ImageSize.Width + 4, 64),
                    [Math]::Min($smallImageList.ImageSize.Height + 4, 64)
                )
            }
        } else {
            # Zoom out
            if ($listView.View -eq [System.Windows.Forms.View]::LargeIcon) {
                $largeImageList.ImageSize = New-Object System.Drawing.Size(
                    [Math]::Max($largeImageList.ImageSize.Width - 8, 32),
                    [Math]::Max($largeImageList.ImageSize.Height - 8, 32)
                )
            } elseif ($listView.View -eq [System.Windows.Forms.View]::SmallIcon) {
                $smallImageList.ImageSize = New-Object System.Drawing.Size(
                    [Math]::Max($smallImageList.ImageSize.Width - 4, 16),
                    [Math]::Max($smallImageList.ImageSize.Height - 4, 16)
                )
            }
        }
        Update-ListView $addressBar.Text
    }
})
#endregion

#region Menu Item Handlers
$newFolderMenuItem.Add_Click({
    $currentPath = $addressBar.Text
    if ($currentPath) {
        try {
            $folderName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter folder name:", "New Folder", "New Folder")
        }
        catch {
            $folderName = Show-InputDialog "New Folder" "Enter folder name:" "New Folder"
        }

        if ($folderName) {
            try {
                $newPath = Join-Path $currentPath $folderName
                New-Item -Path $newPath -ItemType Directory -ErrorAction Stop
                Update-ListView $currentPath
                Update-TreeView $currentPath
                $statusLabel.Text = "Folder created successfully"
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show("Error creating folder: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        }
    }
})

$exitMenuItem.Add_Click({ $form.Close() })

$refreshMenuItem.Add_Click({
    Update-ListView $addressBar.Text
    Update-TreeView $addressBar.Text
})

# View Menu Event Handlers
$detailsViewMenuItem.Add_Click({ $listView.View = [System.Windows.Forms.View]::Details })
$largeIconsMenuItem.Add_Click({ $listView.View = [System.Windows.Forms.View]::LargeIcon })
$smallIconsMenuItem.Add_Click({ $listView.View = [System.Windows.Forms.View]::SmallIcon })
$listViewMenuItem.Add_Click({ $listView.View = [System.Windows.Forms.View]::List })
#endregion

#region Cleanup
$form.Add_FormClosing({
    if ($largeImageList) {
        $largeImageList.Dispose()
    }
    if ($smallImageList) {
        $smallImageList.Dispose()
    }
    if ($script:folderIcon) {
        $script:folderIcon.Dispose()
    }
    foreach ($icon in $script:iconCache.Values) {
        if ($icon -is [System.Drawing.Icon]) {
            $icon.Dispose()
        }
    }
})
#endregion

#region Initialize and Show Form
# Initialize explorer
Update-TreeView
$drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
if ($drives) {
    Update-ListView $drives[0].DeviceID + "\"
    $script:navigationHistory += $drives[0].DeviceID + "\"
    $script:currentHistoryIndex = 0
}

# Show the form
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()