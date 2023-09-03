Add-Type -assembly System.Windows.Forms
Add-Type -assembly System.Drawing
Add-Type -assembly PresentationFramework

$global:SearchResults = $null

function Switch-Layer(){
    $MangaTitle.Visible = !$MangaTitle.Visible
    $MangaAuthors.Visible = !$MangaAuthors.Visible
    $MangaDesc.Visible = !$MangaDesc.Visible
    $MangaGenres.Visible = !$MangaGenres.Visible
    $MangaChapters.Visible = !$MangaChapters.Visible
    $BackButton.Visible = !$BackButton.Visible

    $SearchBar.Visible = !$SearchBar.Visible
    $SearchButton.Visible = !$SearchButton.Visible
    $List.Visible = !$List.Visible
}

function Get-Chapters($Hid, $Page){
    $ProgressPreference = 'SilentlyContinue'
    $src = Invoke-WebRequest -UserAgent "Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) AppleWebKit/534.6 (KHTML, like Gecko) Chrome/7.0.500.0 Safari/534.6" "https://api.comick.app/comic/$(Hid)/chapters?page=$(Page)&lang=en"
    $chapters = $src.Content | ConvertFrom-Json 
    $ProgressPreference = 'Continue'

    return $chapters
}


function Get-MangaNames (){
    if($List.Items.Count -gt 0){
        $List.Items.Clear()
        $List.Size = New-Object System.Drawing.Size($SearchBar.Size.Width, 0)
    } 
    if([System.String]::IsNullOrEmpty($SearchBar.Text)){
        return
    } 

    $ProgressPreference = 'SilentlyContinue'
    $src = Invoke-WebRequest -UserAgent "Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) AppleWebKit/534.6 (KHTML, like Gecko) Chrome/7.0.500.0 Safari/534.6" "https://api.comick.app/v1.0/search/?type=comic&page=1&limit=30&tachiyomi=true&q=$($SearchBar.Text)"
    $ProgressPreference = 'Continue'

    $global:SearchResults = $src.Content | ConvertFrom-Json
    $titles = $SearchResults.title

    $List.Size = New-Object System.Drawing.Size($SearchBar.Size.Width, $(($titles.Count) * 15))
    foreach($item in $titles){
        $List.Items.Add($item)
    }
}

function Select-Manga($Manga){
    $MangaChapters.Items.Clear()

    $ProgressPreference = 'SilentlyContinue'
    $src = Invoke-WebRequest -UserAgent "Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) AppleWebKit/534.6 (KHTML, like Gecko) Chrome/7.0.500.0 Safari/534.6" "https://api.comick.app/comic/$($Manga.slug)/?tachiyomi=true"
    $GeneralInfo = $src.Content | ConvertFrom-Json

    $src = Invoke-WebRequest -UserAgent "Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) AppleWebKit/534.6 (KHTML, like Gecko) Chrome/7.0.500.0 Safari/534.6" "https://api.comick.app/comic/$($Manga.hid)/chapters?lang=en"
    $ChapterListInfo = $src.Content | ConvertFrom-Json 
    $ProgressPreference = 'Continue'

    $MangaTitle.Text = if($GeneralInfo.comic.title.Length -le 52) {$GeneralInfo.comic.title} else {"$($GeneralInfo.comic.title.SubString(0, 49))..."}
    $MangaAuthors.Text = "Authors: $($GeneralInfo.authors.name)"
    $MangaDesc.Text = "Description: $($GeneralInfo.comic.desc)"
    $MangaGenres.Text = "Genres: $($GeneralInfo.genres.name -join ', ')"

    #Extract unique chapters from each page based on up_count
    $MangaChapters.Items.AddRange($($($ChapterListInfo.chapters | Group-Object -Property chap) | %{($_.Group | Sort-Object {$_.up_count} -Descending)[0]} | %{"Chapter $($_.chap) $($_.title)"}))

    Switch-Layer
}

######################
# HomePage Controls
######################

#Main Window properties
$main_form = New-Object System.Windows.Forms.Form
$main_form.Text ='Bundle'
$main_form.Width = 1200
$main_form.Height = 800
$main_form.StartPosition = "CenterScreen"
$main_form.MaximumSize=New-Object System.Drawing.Size(1200,800)
$main_form.MinimumSize=New-Object System.Drawing.Size(1200,800)
$main_form.BackColor = [System.Drawing.Color]::FromArgb(46, 46, 46)

#Title
$Title = New-Object System.Windows.Forms.Label
$Title.Text = "Bundle"
$Title.Location = New-Object System.Drawing.Point(490, 25)
$Title.Size = New-Object System.Drawing.Size(220, 50)
$Title.Font = New-Object System.Drawing.Font("Lucida Console", 40)
$Title.ForeColor = [System.Drawing.Color]::FromArgb(232, 125, 62)

#Brief guidence to program usage
$HelperText = New-Object System.Windows.Forms.Label
$HelperText.Text = "Welcome to Bundle! With the help of this program you can easily extract pages from mangas or convert them into .pdf files.

Usage: Search for the manga of your choice, select the chapters you want to convert or extract pages from, click the convert button!"
$HelperText.Location = New-Object System.Drawing.Point(50, 85)
$HelperText.Size = New-Object System.Drawing.Size(1100, 90)
$HelperText.Font = New-Object System.Drawing.Font("Lucida Console", 13)
$HelperText.ForeColor = [System.Drawing.Color]::FromArgb(158, 134, 20)

#Search button and bar
$SearchBar = New-Object System.Windows.Forms.TextBox
$SearchBar.Location = New-Object System.Drawing.Point(190, 200)
$SearchBar.Size = New-Object System.Drawing.Size(700, 10)
$SearchBar.Font = New-Object System.Drawing.Font("Lucida Console", 13, [System.Drawing.FontStyle]::Bold)
$SearchBar.BackColor = [System.Drawing.Color]::FromArgb(121, 121, 121)
$SearchBar.ForeColor = [System.Drawing.Color]::FromArgb(244, 244, 244)

#List to display search results
$List = New-Object System.Windows.Forms.ListBox
$List.Location = New-Object System.Drawing.Point($SearchBar.Location.x, $($SearchBar.Location.y + $SearchBar.Size.Height))
#List size will adjust according to search results
$List.Font = New-Object System.Drawing.Font("Lucida Console", 13)
$List.Size = New-Object System.Drawing.Size($SearchBar.Size.Width, 10)
$List.Add_DoubleClick({Select-Manga $global:SearchResults[$List.SelectedIndex]})
$List.BackColor = [System.Drawing.Color]::FromArgb(39, 40, 34)
$List.ForeColor = [System.Drawing.Color]::FromArgb(141, 141, 141)


$SearchButton = New-Object System.Windows.Forms.Button
$SearchButton.Text = "Search"
$SearchButton.Font = New-Object System.Drawing.Font("Lucida Console", 15)
$SearchButton.Location = New-Object System.Drawing.Point($($SearchBar.Location.x + $SearchBar.Size.Width + 20), $SearchBar.Location.y)
$SearchButton.Size = New-Object System.Drawing.Size(100, 40)
$SearchButton.Add_Click({Get-MangaNames})
$SearchButton.BackColor = [System.Drawing.Color]::FromArgb(121, 121, 121)
$SearchButton.ForeColor = [System.Drawing.Color]::FromArgb(39, 40, 34)



####################################
# Selected Manga Description
####################################

$MangaTitle = New-Object System.Windows.Forms.Label
$MangaTitle.Text = "Manga Title"
$MangaTitle.Location = New-Object System.Drawing.Point(50, 200)
$MangaTitle.Size = New-Object System.Drawing.Size(900, 30)
$MangaTitle.Font = New-Object System.Drawing.Font("Lucida Console", 20, [System.Drawing.FontStyle]::Bold)
$MangaTitle.ForeColor = [System.Drawing.Color]::FromArgb(244, 244, 244)
$MangaTitle.Visible = $false

$MangaAuthors = New-Object System.Windows.Forms.Label
$MangaAuthors.Text = "Authors:"
$MangaAuthors.Location = New-Object System.Drawing.Point($MangaTitle.Location.x, $($MangaTitle.Location.y + $MangaTitle.Size.Height + 20))
$MangaAuthors.Size = New-Object System.Drawing.Size(700, 20)
$MangaAuthors.Font = New-Object System.Drawing.Font("Lucida Console", 13)
$MangaAuthors.ForeColor = [System.Drawing.Color]::FromArgb(141, 141, 141)
$MangaAuthors.Visible = $false

$MangaDesc = New-Object System.Windows.Forms.Label
$MangaDesc.Text = "Description"
$MangaDesc.Location = New-Object System.Drawing.Point($MangaAuthors.Location.x, $($MangaAuthors.Location.y + $MangaAuthors.Size.Height + 20))
$MangaDesc.Size = New-Object System.Drawing.Size(450, 225)
$MangaDesc.Font = New-Object System.Drawing.Font("Lucida Console", 13)
$MangaDesc.ForeColor = [System.Drawing.Color]::FromArgb(141, 141, 141)
$MangaDesc.Visible = $false

$MangaGenres = New-Object System.Windows.Forms.Label
$MangaGenres.Text = "Genres"
$MangaGenres.Location = New-Object System.Drawing.Point($MangaDesc.Location.x, $($MangaDesc.Location.y + $MangaDesc.Size.Height + 20))
$MangaGenres.Size = New-Object System.Drawing.Size($MangaDesc.Size.Width, 205)
$MangaGenres.Font = New-Object System.Drawing.Font("Lucida Console", 13)
$MangaGenres.TextAlign = [System.Drawing.ContentAlignment]::BottomLeft
$MangaGenres.ForeColor = [System.Drawing.Color]::FromArgb(141, 141, 141)
$MangaGenres.Visible = $false

$MangaChapters = New-Object System.Windows.Forms.CheckedListBox
$MangaChapters.Location = New-Object System.Drawing.Point($($MangaDesc.Location.x + $MangaDesc.Size.Width + 20), $MangaDesc.Location.y)
$MangaChapters.Size = New-Object System.Drawing.Size(490, 450)
#$MangaChapters.ScrollAlwaysVisible = $true
$MangaChapters.Font = New-Object System.Drawing.Font("Lucida Console", 13)
$MangaChapters.BackColor = [System.Drawing.Color]::FromArgb(39, 40, 34)
$MangaChapters.ForeColor = [System.Drawing.Color]::FromArgb(141, 141, 141)
$MangaChapters.Visible = $false

$BackButton = New-Object System.Windows.Forms.Button
$BackButton.Text = "Back"
$BackButton.Font = New-Object System.Drawing.Font("Lucida Console", 15)
$BackButton.Location = New-Object System.Drawing.Point($($SearchButton.Location.x + $SearchButton.Size.Width + 20), $SearchButton.Location.y)
$BackButton.Size = New-Object System.Drawing.Size(100, 40)
$BackButton.Visible = $false
$BackButton.BackColor = [System.Drawing.Color]::FromArgb(121, 121, 121)
$BackButton.ForeColor = [System.Drawing.Color]::FromArgb(39, 40, 34)
$BackButton.Add_Click({Switch-Layer})



#Add elements to Main Window
$main_form.Controls.Add($Title)
$main_form.Controls.Add($HelperText)
$main_form.Controls.Add($SearchButton)
$main_form.Controls.Add($SearchBar)
$main_form.Controls.Add($List)

$main_form.Controls.Add($BackButton)
$main_form.Controls.Add($MangaTitle)
$main_form.Controls.Add($MangaAuthors)
$main_form.Controls.Add($MangaDesc)
$main_form.Controls.Add($MangaGenres)
$main_form.Controls.Add($MangaChapters)


$main_form.ShowDialog() | Out-Null