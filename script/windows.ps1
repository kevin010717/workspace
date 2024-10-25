# 安装所需模块
Install-Module posh-git -Scope CurrentUser -Force
Install-Module oh-my-posh -Scope CurrentUser -Force
Install-Module -Name Terminal-Icons -Repository PSGallery -Force

# 创建或追加配置文件
$ohMyPoshConfigPath = "C:\Users\admin\ohmyposh.ps1"
if (-Not (Test-Path $ohMyPoshConfigPath)) {
    New-Item -Path $ohMyPoshConfigPath -ItemType File -Force
}

# 将初始化内容写入 oh-my-posh 配置文件
$initContent = @'
# Specific theme
& ([ScriptBlock]::Create((oh-my-posh init pwsh --config 'C:\Program Files (x86)\oh-my-posh\themes\jandedobbeleer.omp.json' --print) -join '
'))
Import-Module -Name Terminal-Icons

# Random theme
$themes = Get-ChildItem 'C:\Program Files (x86)\oh-my-posh\themes\'
$theme = $themes | Get-Random
echo "hello! today's lucky theme is: $($theme.Name) :)"
oh-my-posh --init --shell pwsh --config $theme.FullName | Invoke-Expression
'@

# 写入内容到配置文件
Set-Content -Path $ohMyPoshConfigPath -Value $initContent -Force

# 输出可用的主题
Get-PoshThemes

#win11激活
irm https://get.activated.win | iex
