Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Drawing.Common  # Add this line
Add-Type -AssemblyName Microsoft.VisualBasic

# Create ImageList for icons (Add these lines)
$largeImageList = New-Object System.Windows.Forms.ImageList
$largeImageList.ImageSize = New-Object System.Drawing.Size(48, 48)
$smallImageList = New-Object System.Windows.Forms.ImageList
$smallImageList.ImageSize = New-Object System.Drawing.Size(16, 16)

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
$backButton.Image = [System.Drawing.SystemIcons]::ArrowShortLeft.ToBitmap()
$backButton.Text = "Back"
$forwardButton = New-Object System.Windows.Forms.ToolStripButton
$forwardButton.Image = [System.Drawing.SystemIcons]::ArrowShortRight.ToBitmap()
$forwardButton.Text = "Forward"
$upButton = New-Object System.Windows.Forms.ToolStripButton
$upButton.Image = [System.Drawing.SystemIcons]::WinLogo.ToBitmap()
$upButton.Text = "Up"
[void]$toolStrip.Items.AddRange(@($backButton, $forwardButton, $upButton))

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
function Format-Size {
    param([long]$size)
    if ($size -gt 1TB) { return "{0:N2} TB" -f ($size / 1TB) }
    if ($size -gt 1GB) { return "{0:N2} GB" -f ($size / 1GB) }
    if ($size -gt 1MB) { return "{0:N2} MB" -f ($size / 1MB) }
    if ($size -gt 1KB) { return "{0:N2} KB" -f ($size / 1KB) }
    return "{0} Bytes" -f $size
}

function Get-FileIcon {
    param (
        [string]$filePath,
        [bool]$large = $true
    )
    
    try {
        $shell = New-Object -ComObject Shell.Application
        $folderObject = $shell.Namespace((Split-Path $filePath))
        $fileObject = $folderObject.ParseName((Split-Path $filePath -Leaf))
        
        if ($large) {
            $iconSize = 0x4 # SHGFI_LARGEICON
        } else {
            $iconSize = 0x1 # SHGFI_SMALLICON
        }
        
        $bitmap = $null
        try {
            # For image files, try to get thumbnail
            if ($filePath -match '\.(jpg|jpeg|png|gif|bmp)$') {
                $image = [System.Drawing.Image]::FromFile($filePath)
                $size = if ($large) { 32 } else { 16 }
                $bitmap = New-Object System.Drawing.Bitmap($image, $size, $size)
                $image.Dispose()
            }
        }
        catch {
            # If thumbnail creation fails, fall back to icon
            $bitmap = $fileObject.IconLocation
        }
        
        return $bitmap
    }
    catch {
        return $null
    }
}

# Function to populate TreeView
function Update-TreeView {
    param([string]$selectedPath)
    
    $treeView.Nodes.Clear()
    $drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    
    foreach ($drive in $drives) {
        $driveNode = $treeView.Nodes.Add($drive.DeviceID, $drive.DeviceID)
        $driveNode.Tag = $drive.DeviceID + "\"
        if ($selectedPath -and $selectedPath.StartsWith($drive.DeviceID)) {
            Expand-TreeNode $driveNode $selectedPath
        }
    }
}

# Function to expand tree node
function Expand-TreeNode {
    param($node, $path)
    
    try {
        $folders = Get-ChildItem -Path $node.Tag -Directory -ErrorAction Stop
        foreach ($folder in $folders) {
            $newNode = $node.Nodes.Add($folder.Name)
            $newNode.Tag = $folder.FullName
            if ($path -and $path.StartsWith($folder.FullName)) {
                $newNode.Expand()
                Expand-TreeNode $newNode $path
            }
        }
    }
    catch { }
}

# Function to get thumbnail for image files
function Get-ImageThumbnail {
    param (
        [string]$imagePath,
        [int]$size = 48
    )
    
    try {
        if (Test-Path $imagePath) {
            $image = [System.Drawing.Image]::FromFile($imagePath)
            $thumbnail = New-Object System.Drawing.Bitmap($size, $size)
            $graphics = [System.Drawing.Graphics]::FromImage($thumbnail)
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            
            # Calculate dimensions to maintain aspect ratio
            $ratio = [Math]::Min($size / $image.Width, $size / $image.Height)
            $newWidth = [Math]::Floor($image.Width * $ratio)
            $newHeight = [Math]::Floor($image.Height * $ratio)
            $x = ($size - $newWidth) / 2
            $y = ($size - $newHeight) / 2
            
            $graphics.DrawImage($image, $x, $y, $newWidth, $newHeight)
            $graphics.Dispose()
            $image.Dispose()
            return $thumbnail
        }
    }
    catch {
        return $null
    }
}

# Modify the Update-ListView function to handle icons
function Update-ListView {
    param([string]$path)
    
    $listView.Items.Clear()
    $largeImageList.Images.Clear()
    $smallImageList.Images.Clear()
    if (-not $path) { return }
    
    try {
        $items = Get-ChildItem -Path $path -ErrorAction Stop
        if (-not $showHiddenMenuItem.Checked) {
            $items = $items | Where-Object { -not $_.Attributes.HasFlag([System.IO.FileAttributes]::Hidden) }
        }
        
        $imageIndex = 0
        foreach ($item in $items) {
            $listItem = $listView.Items.Add($item.Name)
            $listItem.SubItems.Add($item.LastWriteTime.ToString("g"))
            
            if ($item.PSIsContainer) {
                $listItem.SubItems.Add("Folder")
                $listItem.SubItems.Add("")
                # Use folder icon
                $folderIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Windows\System32\shell32.dll")
                $largeImageList.Images.Add($folderIcon.ToBitmap())
                $smallImageList.Images.Add($folderIcon.ToBitmap())
            }
            else {
                $listItem.SubItems.Add($item.Extension)
                $listItem.SubItems.Add((Format-Size $item.Length))
                
                # Handle image files
                if ($item.Extension -match '\.(jpg|jpeg|png|gif|bmp)$') {
                    $thumbnail = Get-ImageThumbnail -imagePath $item.FullName
                    if ($thumbnail) {
                        $largeImageList.Images.Add($thumbnail)
                        $smallImageList.Images.Add($thumbnail)
                    }
                    else {
                        # Fallback to file icon if thumbnail creation fails
                        $icon = Get-FileIcon -filePath $item.FullName -large $true
                        $largeImageList.Images.Add($icon)
                        $smallImageList.Images.Add($icon)
                    }
                }
                else {
                    # Get icon for non-image files
                    $icon = Get-FileIcon -filePath $item.FullName -large $true
                    if ($icon) {
                        $largeImageList.Images.Add($icon)
                        $smallImageList.Images.Add($icon)
                    }
                }
            }
            
            $listItem.ImageIndex = $imageIndex
            $imageIndex++
            $listItem.Tag = $item.FullName
        }
    }
    catch {
        $statusLabel.Text = "Error: $_"
    }
    
    $itemCountLabel.Text = "$($listView.Items.Count) items"
    $addressBar.Text = $path
}

# Function to update ListView
function Update-ListView {
    param([string]$path)
    
    $listView.Items.Clear()
    $largeImageList.Images.Clear()
    $smallImageList.Images.Clear()
    if (-not $path) { return }
    
    try {
        $items = Get-ChildItem -Path $path -ErrorAction Stop
        if (-not $showHiddenMenuItem.Checked) {
            $items = $items | Where-Object { -not $_.Attributes.HasFlag([System.IO.FileAttributes]::Hidden) }
        }
        
        $imageIndex = 0
        foreach ($item in $items) {
            $listItem = $listView.Items.Add($item.Name)
            $listItem.SubItems.Add($item.LastWriteTime.ToString("g"))
            
            if ($item.PSIsContainer) {
                $listItem.SubItems.Add("Folder")
                $listItem.SubItems.Add("")
                
                # Add folder icon
                try {
                    $folderIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Windows\System32\shell32.dll")
                    $largeImageList.Images.Add($folderIcon.ToBitmap())
                    $smallImageList.Images.Add($folderIcon.ToBitmap())
                }
                catch {
                    $largeImageList.Images.Add([System.Drawing.SystemIcons]::Folder.ToBitmap())
                    $smallImageList.Images.Add([System.Drawing.SystemIcons]::Folder.ToBitmap())
                }
            }
            else {
                $listItem.SubItems.Add($item.Extension)
                $listItem.SubItems.Add((Format-Size $item.Length))
                
                # Handle image files
                if ($item.Extension -match '\.(jpg|jpeg|png|gif|bmp)$') {
                    try {
                        $image = [System.Drawing.Image]::FromFile($item.FullName)
                        $largeThumbnail = New-Object System.Drawing.Bitmap($image, 32, 32)
                        $smallThumbnail = New-Object System.Drawing.Bitmap($image, 16, 16)
                        $largeImageList.Images.Add($largeThumbnail)
                        $smallImageList.Images.Add($smallThumbnail)
                        $image.Dispose()
                    }
                    catch {
                        # Fallback to default icon
                        $icon = Get-FileIcon -filePath $item.FullName -large $true
                        $largeImageList.Images.Add($icon)
                        $smallImageList.Images.Add($icon)
                    }
                }
                else {
                    # Get icon for non-image files
                    $icon = Get-FileIcon -filePath $item.FullName -large $true
                    $largeImageList.Images.Add($icon)
                    $smallImageList.Images.Add($icon)
                }
            }
            
            $listItem.ImageIndex = $imageIndex
            $imageIndex++
            $listItem.Tag = $item.FullName
        }
    }
    catch {
        $statusLabel.Text = "Error: $_"
    }
    
    $itemCountLabel.Text = "$($listView.Items.Count) items"
    $addressBar.Text = $path
}

# Function to update preview
function Update-Preview {
    param($path)
    
    $previewImage.Image = $null
    $previewText.Text = ""
    
    if (-not $path) { return }
    
    try {
        $item = Get-Item $path
        if ($item.PSIsContainer) {
            $previewText.Visible = $true
            $previewImage.Visible = $false
            
            $previewText.Text = "Folder: $($item.Name)`r`n"
            $previewText.Text += "Created: $($item.CreationTime)`r`n"
            $previewText.Text += "Modified: $($item.LastWriteTime)`r`n"
            
            # Calculate folder size and contents
            $folderStats = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
            $previewText.Text += "Size: $((Format-Size $folderStats.Sum))`r`n"
            $previewText.Text += "Contains: $($folderStats.Count) items"
        }
        else {
            $extension = $item.Extension.ToLower()
            
            if ($extension -match '\.(jpg|jpeg|png|gif|bmp)$') {
                try {
                    $previewImage.Visible = $true
                    $previewText.Visible = $true
                    
                    # Load and display image
                    $image = [System.Drawing.Image]::FromFile($path)
                    $previewImage.Image = $image
                    
                    # Show image details
                    $previewText.Text = "Image Details:`r`n"
                    $previewText.Text += "Dimensions: $($image.Width) x $($image.Height)`r`n"
                    $previewText.Text += "Size: $(Format-Size $item.Length)`r`n"
                    $previewText.Text += "Created: $($item.CreationTime)`r`n"
                    $previewText.Text += "Modified: $($item.LastWriteTime)"
                }
                catch {
                    $previewText.Text = "Error loading image preview: $_"
                }
            }
            elseif ($extension -in @(".txt", ".log", ".xml", ".json", ".ps1", ".cmd", ".bat", ".html", ".css", ".js")) {
                $previewImage.Visible = $false
                $previewText.Visible = $true
                
                try {
                    $content = Get-Content $path -Raw -ErrorAction Stop
                    if ($content.Length -gt 5000) {
                        $content = $content.Substring(0, 5000) + "`r`n... (content truncated)"
                    }
                    $previewText.Text = $content
                }
                catch {
                    $previewText.Text = "Error loading text preview: $_"
                }
            }
            else {
                $previewImage.Visible = $false
                $previewText.Visible = $true
                
                $previewText.Text = "File Details:`r`n"
                $previewText.Text += "Name: $($item.Name)`r`n"
                $previewText.Text += "Type: $($item.Extension)`r`n"
                $previewText.Text += "Size: $(Format-Size $item.Length)`r`n"
                $previewText.Text += "Created: $($item.CreationTime)`r`n"
                $previewText.Text += "Modified: $($item.LastWriteTime)"
            }
        }
    }
    catch {
        $previewText.Text = "Error loading preview: $_"
    }
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

# Add Rename option to context menu (add this after other context menu items)
$contextRename = $contextMenu.Items.Add("Rename")
$contextRename.ShortcutKeys = "F2"

# Add Rename to Edit menu
$renameMenuItem = $editMenu.DropDownItems.Add("Rename")
$renameMenuItem.ShortcutKeys = "F2"

# Rename function
function Start-Rename {
    if ($listView.SelectedItems.Count -eq 1) {
        $selectedItem = $listView.SelectedItems[0]
        $selectedItem.BeginEdit()
    }
}

# Add click handlers
$contextRename.Add_Click({ Start-Rename })
$renameMenuItem.Add_Click({ Start-Rename })

# Add ListView label edit handlers
$listView.LabelEdit = $true
$listView.Add_BeforeLabelEdit({
    $_.CancelEdit = $false
})

$listView.Add_AfterLabelEdit({
    if ($_.Label -ne $null) {
        try {
            $oldPath = $_.Item.Tag
            $newPath = Join-Path (Split-Path $oldPath) $_.Label
            Rename-Item -Path $oldPath -NewName $_.Label -ErrorAction Stop
            $_.Item.Tag = $newPath
            $statusLabel.Text = "Item renamed successfully"
        }
        catch {
            $_.CancelEdit = $true
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
})

[void]$form.ShowDialog()
