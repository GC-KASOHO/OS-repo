$commonFolders = @{
    "Desktop" = [Environment]::GetFolderPath("Desktop")
    "Documents" = [Environment]::GetFolderPath("MyDocuments")
    "Downloads" = (Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads")
    "Pictures" = [Environment]::GetFolderPath("MyPictures")
    "Music" = [Environment]::GetFolderPath("MyMusic")
    "Videos" = [Environment]::GetFolderPath("MyVideos")
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Drawing.Common  # Add this line
Add-Type -AssemblyName Microsoft.VisualBasic

# Create ImageList for icons (Add these lines)
$largeImageList = New-Object System.Windows.Forms.ImageList
$largeImageList.ImageSize = New-Object System.Drawing.Size(48, 48)
$smallImageList = New-Object System.Windows.Forms.ImageList
$smallImageList.ImageSize = New-Object System.Drawing.Size(16, 16)

$script:iconCache = @{}
$script:folderIcon = $null

# Create main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Enhanced File Explorer"
$form.Size = New-Object System.Drawing.Size(1200, 800)
$form.StartPosition = "CenterScreen"
$form.Icon = [System.Drawing.SystemIcons]::FolderOpen

# Create MenuStrip
$menuStrip = New-Object System.Windows.Forms.MenuStrip
$fileMenu = $menuStrip.Items.Add("&File")
$editMenu = $menuStrip.Items.Add("&Edit")
$viewMenu = $menuStrip.Items.Add("&View")
$toolsMenu = $menuStrip.Items.Add("&Tools")

# File Menu Items
$newFolderMenuItem = $fileMenu.DropDownItems.Add("New Folder")
$newFileMenuItem = $fileMenu.DropDownItems.Add("New File")
$fileMenu.DropDownItems.Add("-")  # Separator
$exitMenuItem = $fileMenu.DropDownItems.Add("Exit")

# Edit Menu Items
$cutMenuItem = $editMenu.DropDownItems.Add("Cut")
$copyMenuItem = $editMenu.DropDownItems.Add("Copy")
$pasteMenuItem = $editMenu.DropDownItems.Add("Paste")
$editMenu.DropDownItems.Add("-")
$selectAllMenuItem = $editMenu.DropDownItems.Add("Select All")

# View Menu Items
$refreshMenuItem = $viewMenu.DropDownItems.Add("Refresh")
$viewMenu.DropDownItems.Add("-")
$detailsViewMenuItem = $viewMenu.DropDownItems.Add("Details")
$largeIconsMenuItem = $viewMenu.DropDownItems.Add("Large Icons")
$smallIconsMenuItem = $viewMenu.DropDownItems.Add("Small Icons")
$listViewMenuItem = $viewMenu.DropDownItems.Add("List")
$viewMenu.DropDownItems.Add("-")
$showHiddenMenuItem = $viewMenu.DropDownItems.Add("Show Hidden Files")
$showHiddenMenuItem.CheckOnClick = $true

# Tools Menu Items
$searchMenuItem = $toolsMenu.DropDownItems.Add("Search...")
$propertiesMenuItem = $toolsMenu.DropDownItems.Add("Properties")

# Create ToolStrip
$toolStrip = New-Object System.Windows.Forms.ToolStrip
$backButton = New-Object System.Windows.Forms.ToolStripButton
$backButton.Text = "←"
$backButton.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
$backButton.ToolTipText = "Back"
$forwardButton = New-Object System.Windows.Forms.ToolStripButton
$forwardButton.Text = "→"
$forwardButton.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
$forwardButton.ToolTipText = "Forward"
[void]$toolStrip.Items.AddRange(@($backButton, $forwardButton))

# Create address bar
$addressBar = New-Object System.Windows.Forms.ToolStripTextBox
$addressBar.Size = New-Object System.Drawing.Size(300, 25)
$toolStrip.Items.Add("Address:")
$toolStrip.Items.Add($addressBar)

# Create search box
$searchBox = New-Object System.Windows.Forms.ToolStripTextBox
$searchBox.Size = New-Object System.Drawing.Size(200, 25)
$searchBox.PlaceholderText = "Search..."
$toolStrip.Items.Add("Search:")
$toolStrip.Items.Add($searchBox)

# Create TreeView for folder structure
$treeView = New-Object System.Windows.Forms.TreeView
$treeView.Location = New-Object System.Drawing.Point(0, 50)
$treeView.Size = New-Object System.Drawing.Size(250, 700)
$treeView.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left

# Create ListView
$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(260, 50)
$listView.Size = New-Object System.Drawing.Size(700, 700)
$listView.View = [System.Windows.Forms.View]::Details
$listView.FullRowSelect = $true
$listView.GridLines = $true
$listView.AllowDrop = $true
$listView.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$listView.LargeImageList = $largeImageList
$listView.SmallImageList = $smallImageList

# Create Preview Panel
$previewPanel = New-Object System.Windows.Forms.Panel
$previewPanel.Location = New-Object System.Drawing.Point(970, 50)
$previewPanel.Size = New-Object System.Drawing.Size(220, 700)
$previewPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
$previewPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

# Create Preview Components
$previewImage = New-Object System.Windows.Forms.PictureBox
$previewImage.Location = New-Object System.Drawing.Point(10, 10)
$previewImage.Size = New-Object System.Drawing.Size(200, 200)
$previewImage.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom

$previewText = New-Object System.Windows.Forms.TextBox
$previewText.Location = New-Object System.Drawing.Point(10, 220)
$previewText.Size = New-Object System.Drawing.Size(200, 400)
$previewText.Multiline = $true
$previewText.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$previewText.ReadOnly = $true

$previewPanel.Controls.AddRange(@($previewImage, $previewText))

# Create Status Bar
$statusStrip = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Ready"
$itemCountLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$itemCountLabel.Alignment = [System.Windows.Forms.ToolStripItemAlignment]::Right
[void]$statusStrip.Items.AddRange(@($statusLabel, $itemCountLabel))

# Initialize navigation history
$script:navigationHistory = @()
$script:currentHistoryIndex = -1
$script:clipboardPaths = $null
$script:clipboardOperation = $null

# Function to format size
function Initialize-ImageLists {
    # Initialize image lists if not already done
    if (-not $script:folderIcon) {
        $script:folderIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Windows\System32\shell32.dll")
    }
    
    # Clear existing images
    $largeImageList.Images.Clear()
    $smallImageList.Images.Clear()
    
    # Add folder icon
    $largeImageList.Images.Add("folder", $script:folderIcon)
    $smallImageList.Images.Add("folder", $script:folderIcon)
    
    # Add default file icon
    $defaultIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Windows\System32\notepad.exe")
    $largeImageList.Images.Add("file", $defaultIcon)
    $smallImageList.Images.Add("file", $defaultIcon)
}

function Get-FileIconIndex {
    param (
        [string]$filePath
    )
    
    try {
        $extension = [System.IO.Path]::GetExtension($filePath)
        
        # Return cached icon index if available
        if ($script:iconCache.ContainsKey($extension)) {
            return $script:iconCache[$extension]
        }
        
        # If it's a folder, return folder icon
        if ((Get-Item $filePath) -is [System.IO.DirectoryInfo]) {
            return 0  # Index of folder icon
        }
        
        # Get icon for the file type
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
        # Return default file icon on error
        return 1  # Index of default file icon
    }
    
    return 1  # Default to file icon
}

# Function to populate TreeView
function Update-TreeView {
    param([string]$selectedPath)
    $treeView.Nodes.Clear()
    try {
        $myDeviceNode = $treeView.Nodes.Add("My Device"); $myDeviceNode.Tag = "MyDevice"
        
        $commonFolders.GetEnumerator() | ForEach-Object {
            if ($_.Key -ne "My Device" -and (Test-Path $_.Value)) {
                $node = $myDeviceNode.Nodes.Add($_.Key); $node.Tag = $_.Value
                [void]$node.Nodes.Add("dummy")
            }
        }

        Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | ForEach-Object {
            $node = $myDeviceNode.Nodes.Add("$($_.DeviceID) ($($_.VolumeName))")
            $node.Tag = "$($_.DeviceID)\"; [void]$node.Nodes.Add("dummy")
        }

        if ($selectedPath) {
            $node = FindNodeByPath $treeView.Nodes $selectedPath
            if ($node) { $node.Expand(); $treeView.SelectedNode = $node }
        }
    } catch { Write-Warning "Error updating TreeView: $_" }
}

# Function to expand tree node
function Expand-TreeNode {
    param($node, $path)

    try {
        Get-ChildItem -Path $node.Tag -Directory -ErrorAction Stop | ForEach-Object {
            $newNode = $node.Nodes.Add($_.Name); $newNode.Tag = $_.FullName
            if ($path -and $path.StartsWith($_.FullName)) {
                $newNode.Expand(); Expand-TreeNode $newNode $path
            }
        }
    } catch { }
}


# Function to get thumbnail for image files
function Get-ImageThumbnail {
    param (
        [string]$imagePath,
        [int]$size = 48
    )
    
    try {
        if (Test-Path $imagePath) {
            $stream = [System.IO.File]::OpenRead($imagePath)
            $image = [System.Drawing.Image]::FromStream($stream)
            if (-not $image) { throw "Invalid image format" }
            
            $thumbnail = New-Object System.Drawing.Bitmap($size, $size)
            $graphics = [System.Drawing.Graphics]::FromImage($thumbnail)
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

            $ratio = [Math]::Min($size / $image.Width, $size / $image.Height)
            $newWidth = [Math]::Floor($image.Width * $ratio)
            $newHeight = [Math]::Floor($image.Height * $ratio)
            $x = ($size - $newWidth) / 2
            $y = ($size - $newHeight) / 2
            $graphics.DrawImage($image, $x, $y, $newWidth, $newHeight)
            
            return $thumbnail
        }
    }
    catch { 
        Write-Warning "Error creating thumbnail: $_"
    }
    finally {
        # Dispose of resources
        $graphics.Dispose(); $image.Dispose(); $stream.Dispose() 
    }
}


function FindNodeByPath {
    param($nodes, $path)
    
    foreach ($node in $nodes) {
        if ($node.Tag -eq $path) {
            return $node
        }
        if ($node.Nodes.Count -gt 0) {
            $result = FindNodeByPath $node.Nodes $path
            if ($result) {
                return $result
            }
        }
    }
    return $null
}

# Modified Update-TreeView function with improved error handling
function Update-TreeView {
    param([string]$selectedPath)
    
    $treeView.Nodes.Clear()
    try {
        $drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        
        foreach ($drive in $drives) {
            $driveNode = $treeView.Nodes.Add($drive.DeviceID, $drive.DeviceID)
            $driveNode.Tag = $drive.DeviceID + "\"
            
            # Force immediate population of first level
            try {
                $folders = Get-ChildItem -Path ($drive.DeviceID + "\") -Directory -ErrorAction Stop
                foreach ($folder in $folders) {
                    $folderNode = $driveNode.Nodes.Add($folder.Name)
                    $folderNode.Tag = $folder.FullName
                    
                    # Add a dummy node if there are subfolders
                    try {
                        if (Get-ChildItem -Path $folder.FullName -Directory -ErrorAction Stop) {
                            [void]$folderNode.Nodes.Add("dummy")
                        }
                    }
                    catch {
                        Write-Warning "Could not access subfolders of $($folder.FullName): $_"
                    }
                }
            }
            catch {
                Write-Warning "Could not access drive $($drive.DeviceID): $_"
                continue
            }
            
            if ($selectedPath -and $selectedPath.StartsWith($drive.DeviceID)) {
                $driveNode.Expand()
            }
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Error populating directory tree: $_",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

# Add TreeView expansion handler
$treeView.Add_BeforeExpand({
    $node = $_.Node
    
    if ($node.Nodes.Count -eq 1 -and $node.Nodes[0].Text -eq "dummy") {
        $node.Nodes.Clear()
        
        try {
            $folders = Get-ChildItem -Path $node.Tag -Directory -ErrorAction Stop
            foreach ($folder in $folders) {
                $newNode = $node.Nodes.Add($folder.Name)
                $newNode.Tag = $folder.FullName
                
                # Add dummy node if there are subfolders
                try {
                    if (Get-ChildItem -Path $folder.FullName -Directory -ErrorAction Stop) {
                        [void]$newNode.Nodes.Add("dummy")
                    }
                }
                catch {
                    Write-Warning "Could not access subfolders of $($folder.FullName): $_"
                }
            }
        }
        catch {
            Write-Warning "Could not expand node $($node.Tag): $_"
            [void]$node.Nodes.Add("(Access Denied)")
        }
    }
})

# Modified ListView update function with better error handling
function Update-ListView {
    param([string]$path)
    
    $listView.Items.Clear()
    if (-not $path -or $path -eq "MyDevice") {
        # Show common folders and drives if we're at My Device
        foreach ($folder in $commonFolders.GetEnumerator()) {
            if ($folder.Key -ne "My Device" -and (Test-Path $folder.Value)) {
                $listItem = $listView.Items.Add($folder.Key)
                $listItem.SubItems.Add("")  # Modified date
                $listItem.SubItems.Add("System Folder")
                $listItem.SubItems.Add("")  # Size
                $listItem.Tag = $folder.Value
                $listItem.ImageIndex = 0  # Use folder icon
            }
        }
        
        # Add drives
        $drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        foreach ($drive in $drives) {
            $listItem = $listView.Items.Add("$($drive.DeviceID) ($($drive.VolumeName))")
            $listItem.SubItems.Add("")
            $listItem.SubItems.Add("Drive")
            $listItem.SubItems.Add((Format-Size $drive.Size))
            $listItem.Tag = $drive.DeviceID + "\"
            $listItem.ImageIndex = 0  # Use folder icon
        }
        
        $addressBar.Text = "My Device"
        return
    }
    
    # Initialize image lists if needed
    Initialize-ImageLists
    
    try {
        $items = Get-ChildItem -Path $path -ErrorAction Stop
        if (-not $showHiddenMenuItem.Checked) {
            $items = $items | Where-Object { -not $_.Attributes.HasFlag([System.IO.FileAttributes]::Hidden) }
        }
        
        foreach ($item in $items) {
            $listItem = $listView.Items.Add($item.Name)
            $listItem.SubItems.Add($item.LastWriteTime.ToString("g"))
            
            if ($item.PSIsContainer) {
                $listItem.SubItems.Add("Folder")
                $listItem.SubItems.Add("")
                $listItem.ImageIndex = 0  # Folder icon
            }
            else {
                $listItem.SubItems.Add($item.Extension)
                $listItem.SubItems.Add((Format-Size $item.Length))
                $listItem.ImageIndex = (Get-FileIconIndex $item.FullName)
            }
            
            $listItem.Tag = $item.FullName
        }
    }
    catch {
        $statusLabel.Text = "Error accessing $path`: $_"
    }
    
    $itemCountLabel.Text = "$($listView.Items.Count) items"
    $addressBar.Text = $path
}

# Add simple error handling for initial load
try {
    Update-TreeView
    $drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    if ($drives) {
        $initialDrive = $drives[0].DeviceID + "\"
        Update-ListView $initialDrive
        $script:navigationHistory += $initialDrive
        $script:currentHistoryIndex = 0
    }
}
catch {
    [System.Windows.Forms.MessageBox]::Show(
        "Error initializing file explorer: $_",
        "Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
}

# Create context menu
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$contextOpen = $contextMenu.Items.Add("Open")
$contextMenu.Items.Add("-") # Separator
$contextCut = $contextMenu.Items.Add("Cut")
$contextCopy = $contextMenu.Items.Add("Copy")
$contextPaste = $contextMenu.Items.Add("Paste")
$contextDelete = $contextMenu.Items.Add("Delete")
$contextMenu.Items.Add("-") # Separator
$contextNewMenu = $contextMenu.Items.Add("New")
$contextNewFolder = $contextNewMenu.DropDownItems.Add("Folder")
$contextNewFile = $contextNewMenu.DropDownItems.Add("File")
$contextMenu.Items.Add("-") # Separator
$contextProperties = $contextMenu.Items.Add("Properties")

# Assign context menu to ListView
$listView.ContextMenuStrip = $contextMenu

# Context menu event handlers
$contextOpen.Add_Click({
    if ($listView.SelectedItems.Count -gt 0) {
        $selected = $listView.SelectedItems[0]
        $path = $selected.Tag
        if (Test-Path $path -PathType Container) {
            Update-ListView $path
            Update-TreeView $path
            # Add to navigation history
            $script:navigationHistory = $script:navigationHistory[0..$script:currentHistoryIndex]
            $script:navigationHistory += $path
            $script:currentHistoryIndex++
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

$contextCut.Add_Click({ $cutMenuItem.PerformClick() })
$contextCopy.Add_Click({ $copyMenuItem.PerformClick() })
$contextPaste.Add_Click({ $pasteMenuItem.PerformClick() })

# Modify delete operation
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

# Rename function
function Start-Rename {
    if ($listView.SelectedItems.Count -eq 1) {
        try {
            $selectedItem = $listView.SelectedItems[0]
            $selectedItem.BeginEdit()
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Error starting rename: $_",
                "Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    }
}

$contextRename = $contextMenu.Items.Add("Rename")
$contextRename.ShortcutKeys = "F2"
$contextRename.Add_Click({ Start-Rename })

$renameMenuItem = $editMenu.DropDownItems.Add("Rename")
$renameMenuItem.ShortcutKeys = "F2"
$renameMenuItem.Add_Click({ Start-Rename })

# Add F2 key handler to the form if not already present
$form.Add_KeyDown({
    param($sender, $e)
    
    if ($e.KeyCode -eq 'F2') {
        Start-Rename
        $e.Handled = $true
    }
})

# Add ListView label edit handlers
$listView.LabelEdit = $true

$listView.Add_BeforeLabelEdit({
    param($sender, $e)
    $e.CancelEdit = $false
})

$listView.Add_AfterLabelEdit({
    param($sender, $e)
    if ($e.Label -ne $null) {
        try {
            $oldPath = $listView.SelectedItems[0].Tag
            $newPath = Join-Path (Split-Path $oldPath) $e.Label
            Rename-Item -Path $oldPath -NewName $e.Label -ErrorAction Stop
            $listView.SelectedItems[0].Tag = $newPath
            $statusLabel.Text = "Item renamed successfully"
        }
        catch {
            $e.CancelEdit = $true
            [System.Windows.Forms.MessageBox]::Show(
                "Error renaming item: $_",
                "Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    }
})

$contextNewFolder.Add_Click({ $newFolderMenuItem.PerformClick() })
$contextNewFile.Add_Click({ $newFileMenuItem.PerformClick() })
$contextProperties.Add_Click({ $propertiesMenuItem.PerformClick() })

# Event Handlers
$treeView.Add_AfterSelect({
    $path = $_.Node.Tag
    Update-ListView $path
})

$listView.Add_SelectedIndexChanged({
    if ($_.SelectedItems.Count -eq 1) {
        Update-Preview $_.SelectedItems[0].Tag
    }
})

# Modify the ListView double-click handler to include history
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

# Update back button handler
$backButton.Add_Click({
    if ($script:currentHistoryIndex -gt 0) {
        $script:currentHistoryIndex--
        $path = $script:navigationHistory[$script:currentHistoryIndex]
        Update-ListView $path
        Update-TreeView $path
        $statusLabel.Text = "Navigated back to $path"
    }
})

# Update forward button handler
$forwardButton.Add_Click({
    if ($script:currentHistoryIndex -lt ($script:navigationHistory.Count - 1)) {
        $script:currentHistoryIndex++
        $path = $script:navigationHistory[$script:currentHistoryIndex]
        Update-ListView $path
        Update-TreeView $path
        $statusLabel.Text = "Navigated forward to $path"
    }
})

# Update up button handler to include history
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

# Initialize columns
$listView.Columns.Add("Name", 300)
$listView.Columns.Add("Modified", 150)
$listView.Columns.Add("Type", 100)
$listView.Columns.Add("Size", 100)

# Add controls to form
$form.Controls.AddRange(@(
    $menuStrip,
    $toolStrip,
    $treeView,
    $listView,
    $previewPanel,
    $statusStrip
))

# Additional Menu Item Event Handlers
$newFolderMenuItem.Add_Click({
    $currentPath = $addressBar.Text
    if ($currentPath) {
        try {
            # Try Visual Basic Input Box first
            $folderName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter folder name:", "New Folder", "New Folder")
        }
        catch {
            # Fallback to Windows Forms Input Dialog
            $form = New-Object System.Windows.Forms.Form
            $form.Text = "New Folder"
            $form.Size = New-Object System.Drawing.Size(300,150)
            $form.StartPosition = "LeftScreen"

            $textBox = New-Object System.Windows.Forms.TextBox
            $textBox.Location = New-Object System.Drawing.Point(10,20)
            $textBox.Size = New-Object System.Drawing.Size(260,20)
            $textBox.Text = "New Folder"
            $form.Controls.Add($textBox)

            $okButton = New-Object System.Windows.Forms.Button
            $okButton.Location = New-Object System.Drawing.Point(75,70)
            $okButton.Size = New-Object System.Drawing.Size(75,23)
            $okButton.Text = "OK"
            $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $form.Controls.Add($okButton)

            $cancelButton = New-Object System.Windows.Forms.Button
            $cancelButton.Location = New-Object System.Drawing.Point(150,70)
            $cancelButton.Size = New-Object System.Drawing.Size(75,23)
            $cancelButton.Text = "Cancel"
            $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
            $form.Controls.Add($cancelButton)

            $form.AcceptButton = $okButton
            $form.CancelButton = $cancelButton

            $result = $form.ShowDialog()
            $folderName = if ($result -eq [System.Windows.Forms.DialogResult]::OK) { $textBox.Text } else { $null }
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

$newFileMenuItem.Add_Click({
    $currentPath = $addressBar.Text
    if ($currentPath) {
        $form = New-Object System.Windows.Forms.Form
        $form.Text = "New File"
        $form.Size = New-Object System.Drawing.Size(400,200)
        $form.StartPosition = "CenterScreen"

        $nameLabel = New-Object System.Windows.Forms.Label
        $nameLabel.Location = New-Object System.Drawing.Point(10,20)
        $nameLabel.Size = New-Object System.Drawing.Size(100,20)
        $nameLabel.Text = "File Name:"
        $form.Controls.Add($nameLabel)

        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Location = New-Object System.Drawing.Point(110,20)
        $textBox.Size = New-Object System.Drawing.Size(260,20)
        $textBox.Text = "New File.txt"
        $form.Controls.Add($textBox)

        $typeLabel = New-Object System.Windows.Forms.Label
        $typeLabel.Location = New-Object System.Drawing.Point(10,50)
        $typeLabel.Size = New-Object System.Drawing.Size(100,20)
        $typeLabel.Text = "File Type:"
        $form.Controls.Add($typeLabel)

        $comboBox = New-Object System.Windows.Forms.ComboBox
        $comboBox.Location = New-Object System.Drawing.Point(110,50)
        $comboBox.Size = New-Object System.Drawing.Size(260,20)
        $comboBox.Items.AddRange(@(
            "Text File (.txt)",
            "Rich Text Format (.rtf)",
            "HTML File (.html)",
            "XML File (.xml)",
            "PowerShell Script (.ps1)",
            "Batch File (.bat)",
            "Other..."
        ))
        $comboBox.SelectedIndex = 0
        $form.Controls.Add($comboBox)

        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Location = New-Object System.Drawing.Point(110,120)
        $okButton.Size = New-Object System.Drawing.Size(75,23)
        $okButton.Text = "OK"
        $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Controls.Add($okButton)

        $cancelButton = New-Object System.Windows.Forms.Button
        $cancelButton.Location = New-Object System.Drawing.Point(200,120)
        $cancelButton.Size = New-Object System.Drawing.Size(75,23)
        $cancelButton.Text = "Cancel"
        $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.Controls.Add($cancelButton)

        $form.AcceptButton = $okButton
        $form.CancelButton = $cancelButton

        $result = $form.ShowDialog()
        
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $fileName = $textBox.Text
            
            # Add default extension if none provided
            $extension = [System.IO.Path]::GetExtension($fileName)
            if (-not $extension) {
                $selectedType = $comboBox.SelectedItem
                $extension = switch ($selectedType) {
                    "Text File (.txt)" { ".txt" }
                    "Rich Text Format (.rtf)" { ".rtf" }
                    "HTML File (.html)" { ".html" }
                    "XML File (.xml)" { ".xml" }
                    "PowerShell Script (.ps1)" { ".ps1" }
                    "Batch File (.bat)" { ".bat" }
                    default { ".txt" }
                }
                $fileName = $fileName + $extension
            }

            try {
                $newPath = Join-Path $currentPath $fileName
                New-Item -Path $newPath -ItemType File -ErrorAction Stop
                Update-ListView $currentPath
                $statusLabel.Text = "File created successfully"
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show(
                    "Error creating file: $_",
                    "Error",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
            }
        }
    }
})

# Initialize explorer
Update-TreeView
$drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
if ($drives) {
    Update-ListView $drives[0].DeviceID + "\"
    $script:navigationHistory += $drives[0].DeviceID + "\"
    $script:currentHistoryIndex = 0
}

# Additional Menu Item Event Handlers
$newFolderMenuItem.Add_Click({
    $currentPath = $addressBar.Text
    if ($currentPath) {
        $folderName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter folder name:", "New Folder", "New Folder")
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

# Modify cut operation
$cutMenuItem.Add_Click({
    if ($listView.SelectedItems.Count -gt 0) {
        $script:clipboardPaths = @($listView.SelectedItems | ForEach-Object { $_.Tag })
        $script:clipboardOperation = "cut"
        $statusLabel.Text = "Cut $($listView.SelectedItems.Count) items to clipboard"
    }
})

# Modify copy operation
$copyMenuItem.Add_Click({
    if ($listView.SelectedItems.Count -gt 0) {
        $script:clipboardPaths = @($listView.SelectedItems | ForEach-Object { $_.Tag })
        $script:clipboardOperation = "copy"
        $statusLabel.Text = "Copied $($listView.SelectedItems.Count) items to clipboard"
    }
})

# Modify paste operation
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

$selectAllMenuItem.Add_Click({
    foreach ($item in $listView.Items) {
        $item.Selected = $true
    }
})

$refreshMenuItem.Add_Click({
    Update-ListView $addressBar.Text
    Update-TreeView $addressBar.Text
})

# View Menu Event Handlers
$detailsViewMenuItem.Add_Click({ $listView.View = [System.Windows.Forms.View]::Details })
$largeIconsMenuItem.Add_Click({ $listView.View = [System.Windows.Forms.View]::LargeIcon })
$smallIconsMenuItem.Add_Click({ $listView.View = [System.Windows.Forms.View]::SmallIcon })
$listViewMenuItem.Add_Click({ $listView.View = [System.Windows.Forms.View]::List })

$showHiddenMenuItem.Add_Click({
    Update-ListView $addressBar.Text
})

# Search functionality
$searchMenuItem.Add_Click({
    $searchTerm = [Microsoft.VisualBasic.Interaction]::InputBox("Enter search term:", "Search", "")
    if ($searchTerm -and $addressBar.Text) {
        $listView.Items.Clear()
        $statusLabel.Text = "Searching..."
        $results = Get-ChildItem -Path $addressBar.Text -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "*$searchTerm*" }
        
        foreach ($item in $results) {
            $listItem = $listView.Items.Add($item.Name)
            $listItem.SubItems.Add($item.LastWriteTime.ToString("g"))
            if ($item.PSIsContainer) {
                $listItem.SubItems.Add("Folder")
                $listItem.SubItems.Add("")
            }
            else {
                $listItem.SubItems.Add($item.Extension)
                $listItem.SubItems.Add((Format-Size $item.Length))
            }
            $listItem.Tag = $item.FullName
        }
        $statusLabel.Text = "Search complete: $($results.Count) items found"
    }
})

# Properties dialog
$propertiesMenuItem.Add_Click({
    if ($listView.SelectedItems.Count -gt 0) {
        $path = $listView.SelectedItems[0].Tag
        $item = Get-Item $path
        
        $properties = "Name: $($item.Name)`n"
        $properties += "Path: $($item.FullName)`n"
        $properties += "Created: $($item.CreationTime)`n"
        $properties += "Modified: $($item.LastWriteTime)`n"
        
        if ($item.PSIsContainer) {
            $fileCount = (Get-ChildItem $path -File -Recurse -ErrorAction SilentlyContinue).Count
            $folderCount = (Get-ChildItem $path -Directory -Recurse -ErrorAction SilentlyContinue).Count
            $properties += "Contains: $fileCount files, $folderCount folders"
        }
        else {
            $properties += "Size: $(Format-Size $item.Length)`n"
            $properties += "Type: $($item.Extension)"
        }
        
        [System.Windows.Forms.MessageBox]::Show($properties, "Properties", [System.Windows.Forms.MessageBoxButtons]::OK)
    }
})

# Drag and Drop Support
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

# Keyboard shortcuts
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
        if ($listView.SelectedItems.Count -gt 0) {
            $path = $listView.SelectedItems[0].Tag
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Are you sure you want to delete '$(Split-Path $path -Leaf)'?",
                "Confirm Delete",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                try {
                    Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                    Update-ListView $addressBar.Text
                    $statusLabel.Text = "Item deleted successfully"
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show("Error deleting item: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            }
        }
    }
})

# Add zoom functionality
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

# Show the form
$form.Add_Shown({ $form.Activate() })

# Add Form Closing event handler to clean up resources
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

[void]$form.ShowDialog()