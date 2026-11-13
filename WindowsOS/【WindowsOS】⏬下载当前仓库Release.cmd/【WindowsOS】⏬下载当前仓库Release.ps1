#requires -Version 5.1
<#
Jobs 当前仓库 Release 下载器；Windows 10+ / PowerShell 5.1+。
仅下载本脚本所属的 GitHub 仓库；确认后才创建 Releases 与本地排除规则。
#>
[CmdletBinding()]
param([switch]$Help, [switch]$List)

$script:Repository = 'WindowsOS_XP'
$script:Owner = 'JobsKits'
$script:RepositoryRoot = $null
$script:LogFile = $null
$script:Git = $null
$script:Fzf = $null
$script:ColorState = $null
$script:OriginalTls = $null
$script:WrittenTls = $null
$script:Downloaded = 0
$script:Skipped = 0
$script:NotStartedBatches = 0
$script:Pending = 0
# 从 JSON 对象安全读取可选字段。
function Get-ReleaseField($Object, [string]$Name) {
    $property = $Object.PSObject.Properties[$Name]
    if ($null -ne $property) { return $property.Value }
    return $null
}
# 日志始终以纯文本写入临时目录，颜色仅用于实际交互终端。
function Write-ReleaseLog([string]$Message, [ConsoleColor]$Color = 'Gray') {
    if ($script:ColorState) { Write-Host $Message -ForegroundColor $Color }
    else { Write-Host $Message }
    if ($script:LogFile) { Add-Content -LiteralPath $script:LogFile -Value $Message -Encoding UTF8 }
}
# 在原生 Windows 控制台保存本次颜色，无法可靠操作时使用纯文本。
function Initialize-ReleaseDisplay {
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT -or
        (Test-Path Env:NO_COLOR) -or $env:TERM -eq 'dumb' -or $Host.Name -ne 'ConsoleHost' -or
        [Console]::IsInputRedirected -or [Console]::IsOutputRedirected) { return }
    try {
        $script:ColorState = @{ Foreground = $Host.UI.RawUI.ForegroundColor; Background = $Host.UI.RawUI.BackgroundColor }
        $Host.UI.RawUI.BackgroundColor = 'Black'
        $Host.UI.RawUI.ForegroundColor = 'White'
    } catch { $script:ColorState = $null }
}
# 只还原本脚本仍然持有的颜色，保留用户运行中另行变更的值。
function Restore-ReleaseDisplay {
    if (-not $script:ColorState) { return }
    try {
        if ($Host.UI.RawUI.BackgroundColor -eq 'Black') { $Host.UI.RawUI.BackgroundColor = $script:ColorState.Background }
        if ($Host.UI.RawUI.ForegroundColor -eq 'White') { $Host.UI.RawUI.ForegroundColor = $script:ColorState.Foreground }
    } catch { Write-Warning '终端颜色恢复失败，请在当前终端中检查前景和背景设置。' }
    $script:ColorState = $null
}
# 提供无需依赖、无需联网的帮助入口。
function Show-ReleaseHelp {
    Write-Host @"
Jobs 当前仓库 Release 下载器（Windows）
仓库：https://github.com/$script:Owner/$script:Repository
用法：双击同目录 CMD，或 PowerShell -File "<本脚本>" [-Help | -List]
-Help  显示本说明，不联网、不写业务文件。
-List  只读列出本仓所有已发布 Release 及附件；查询失败立即返回非零。
普通模式需要 Windows 10+、PowerShell 5.1+、Git、fzf；不自动安装依赖。
选择：方向键/搜索；Release 回车确认；单个附件 Enter 勾选、Space 确认；多个附件首行“全选”。
全选行 Enter/Space 选择本次完整附件清单；真实附件 Enter 勾选、Space 确认，Ctrl-D 清空。
搜索后只有一个真实附件时 Space 直接确认；全选操作后仍须最终下载确认。
附件面板左方向键返回 Release；Esc 取消；Ctrl+C 停止并保留完成文件和断点。
确认下载后写入本仓 Releases/<编码标签>/，只追加本仓 info/exclude 的 /Releases/。
网络或 HTTP 下载错误持续退避重试；本地错误、身份变化和同名冲突立即停止。
下载完成后手工运行本仓 WindowsOS 中的子卷合并工具，不自动安装或合并镜像。
"@
}
# 自述与确认先于日志、网络和 Git 配置写入。
function Confirm-ReleaseIntro {
    Write-ReleaseLog '━━━━━━━━━━ Jobs 当前仓库 Release 下载 ━━━━━━━━━━' Red
    Write-ReleaseLog "对象：$script:Owner/$script:Repository；只下载本仓发布的附件。" Blue
    Write-ReleaseLog '影响：确认本版计划后创建 Releases，追加本仓本地排除规则；保留已有文件。' Blue
    Write-ReleaseLog '依赖：Windows 10+ / PowerShell 5.1+ / Git / fzf；不自动安装依赖或修改代理。' Blue
    Write-ReleaseLog '网络/HTTP错误自动退避重试至完成或 Ctrl+C；大小与可用 SHA256 均需通过。' Blue
    Write-ReleaseLog '完成后手工合并；镜像所属版本不代表这些工具支持在 XP/2003/7/8.1 上运行。' Blue
    if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) { throw '普通下载需要交互终端；只读清单请传 -List。' }
    if ((Read-ReleaseConfirmation '已了解用途和影响？') -ne '') { return $false }
    return $true
}
# 对回车和非空输入的整段选项分别强调，EOF 始终停止。
function Read-ReleaseConfirmation([string]$Question, [switch]$FreshInput) {
    if ([Console]::IsInputRedirected) { throw '输入已结束或被重定向，未执行本次下载。' }
    if ($FreshInput -and [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT -and $Host.Name -eq 'ConsoleHost') {
        $consoleReady = $false
        try { $null = [Console]::KeyAvailable; $consoleReady = $true }
        catch [InvalidOperationException] { }
        catch [IO.IOException] { }
        if ($consoleReady) {
            Write-Host '松开按键，等下面提示后重新按一次回车。'
            $quiet = [Diagnostics.Stopwatch]::StartNew()
            try {
                while ($quiet.ElapsedMilliseconds -lt 150) {
                    while ([Console]::KeyAvailable) {
                        $key = [Console]::ReadKey($true)
                        if ($key.KeyChar -eq [char]3 -or ($key.Key -eq [ConsoleKey]::C -and ($key.Modifiers -band [ConsoleModifiers]::Control))) {
                            exit 130
                        }
                        if ($key.KeyChar -eq [char]26 -or ($key.Key -eq [ConsoleKey]::Z -and ($key.Modifiers -band [ConsoleModifiers]::Control))) {
                            throw '输入已结束，未执行本次下载。'
                        }
                        $quiet.Restart()
                    }
                    [Threading.Thread]::Sleep(10)
                }
            } finally { $quiet.Stop() }
        }
    }
    $continueText = if ($FreshInput) { '回车或空格后回车开始下载' } else { '直接回车继续' }
    $cancelText = if ($FreshInput) { '输入非空白内容后回车不执行' } else { '输入任意字符后回车取消' }
    Write-Host "$Question " -NoNewline
    $bold = $script:ColorState -and $Host.UI.PSObject.Properties['SupportsVirtualTerminal'] -and $Host.UI.SupportsVirtualTerminal
    if ($bold) { [Console]::Write(([string][char]27) + '[1;32m') }
    if ($script:ColorState) { Write-Host $continueText -ForegroundColor Green -NoNewline }
    else { Write-Host $continueText -NoNewline }
    if ($bold) { [Console]::Write(([string][char]27) + '[0m') }
    Write-Host '；' -NoNewline
    if ($bold) { [Console]::Write(([string][char]27) + '[1;31m') }
    if ($script:ColorState) { Write-Host $cancelText -ForegroundColor Red -NoNewline }
    else { Write-Host $cancelText -NoNewline }
    if ($bold) { [Console]::Write(([string][char]27) + '[0m') }
    Write-Host '：' -NoNewline
    $answer = [Console]::ReadLine()
    if ($null -eq $answer) { throw '输入已结束，未执行本次下载。' }
    return $answer
}
# 创建唯一临时日志，保持其它运行的日志完整。
function Initialize-ReleaseRuntime {
    $script:ErrorActionPreference = 'Stop'
    $script:LogFile = Join-Path ([IO.Path]::GetTempPath()) ('WindowsOS-Release-' + [Guid]::NewGuid().ToString('N') + '.log')
    [IO.File]::WriteAllText($script:LogFile, '', (New-Object Text.UTF8Encoding($true)))
    Write-ReleaseLog "日志：$script:LogFile"
    $script:OriginalTls = [Net.ServicePointManager]::SecurityProtocol
    $script:WrittenTls = $script:OriginalTls -bor [Net.SecurityProtocolType]::Tls12
    [Net.ServicePointManager]::SecurityProtocol = $script:WrittenTls
}
# 检查从给定位置到根目录的每一层，拒绝符号链接和目录联接。
function Assert-ReleasePath([string]$Path, [ValidateSet('Any','File','Directory')][string]$Kind = 'Any') {
    $full = [IO.Path]::GetFullPath($Path)
    $cursor = $full
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force -ErrorAction Stop
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "路径含符号链接或目录联接，保留原状：$cursor" }
            if ($cursor -eq $full) {
                if ($Kind -eq 'File' -and $item.PSIsContainer) { throw "需要普通文件：$Path" }
                if ($Kind -eq 'Directory' -and -not $item.PSIsContainer) { throw "需要普通目录：$Path" }
            }
        }
        $cursor = [IO.Path]::GetDirectoryName($cursor)
    }
}
# 固定脚本归属，验证实际仓库根和 GitHub remote，不借用父仓配置。
function Assert-ReleaseRepository {
    $script:RepositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
    Assert-ReleasePath $script:RepositoryRoot Directory
    Assert-ReleasePath (Join-Path $script:RepositoryRoot '.git')
    $command = Get-Command git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $command) { throw '缺少 Git；请安装 Git for Windows 后重开终端。' }
    $script:Git = $command.Source
    $actual = @(& $script:Git -C $script:RepositoryRoot rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0 -or $actual.Count -ne 1 -or
        [IO.Path]::GetFullPath([string]$actual[0]) -ne $script:RepositoryRoot) { throw '脚本不在独立 Git 仓库的预期平台目录中；拒绝使用父仓或其它仓库。' }
    $matched = $false
    $remotes = @(& $script:Git -C $script:RepositoryRoot remote)
    if ($LASTEXITCODE -ne 0) { throw '无法读取本仓 remote。' }
    foreach ($remote in $remotes) {
        $urls = @(& $script:Git -C $script:RepositoryRoot remote get-url --all $remote)
        if ($LASTEXITCODE -ne 0) { throw '无法读取本仓 remote URL。' }
        foreach ($url in $urls) {
            $path = $null
            if ($url -match '^git@github\.com:(?<path>[^?#]+)$') { $path = $Matches.path }
            elseif ($url -match '^(?:https|ssh)://(?:(?:git)@)?github\.com(?::(?:22|443))?/(?<path>[^?#]+)$') { $path = $Matches.path }
            if ($path -and ($path.TrimEnd('/') -replace '\.git$','') -ieq "$script:Owner/$script:Repository") { $matched = $true }
        }
    }
    if (-not $matched) { throw "仓库来源不匹配；只接受 GitHub $script:Owner/$script:Repository，保留全部 remote 原状。" }
    $tracked = @(& $script:Git -C $script:RepositoryRoot ls-files -- Releases)
    if ($LASTEXITCODE -ne 0) { throw '无法核对 Releases 跟踪状态。' }
    $committed = @(& $script:Git -C $script:RepositoryRoot ls-tree -r --name-only HEAD -- Releases)
    if ($LASTEXITCODE -ne 0 -or $tracked.Count -gt 0 -or $committed.Count -gt 0) { throw 'Releases 已跟踪或无法核对；拒绝把下载附件混入源码。' }
    Assert-ReleasePath (Join-Path $script:RepositoryRoot 'Releases') Directory
    Write-ReleaseLog "来源：GitHub https://github.com/$script:Owner/$script:Repository/releases"
    Write-ReleaseLog "仓库位置：$script:RepositoryRoot"
}
# 检查实际选择器版本及所需选项，不安装或降级到数字菜单。
function Assert-ReleaseSelector {
    $command = Get-Command fzf -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $command) { throw '缺少 fzf；请安装 Windows 版 fzf 后重开终端。' }
    $script:Fzf = $command.Source
    $version = & $script:Fzf --version
    if ($LASTEXITCODE -ne 0) { throw 'fzf --version 执行失败。' }
    $usage = (& $script:Fzf --help) -join "`n"
    if ($LASTEXITCODE -ne 0 -or $usage -notmatch '--footer' -or $usage -notmatch 'transform') { throw 'fzf 版本不支持本入口所需 footer / transform；请更新 fzf。' }
    Write-ReleaseLog "选择器：fzf $version"
}
# 发出受限 HTTPS 请求，保留 HTTP 错误响应供限流和退避判断。
function Open-ReleaseResponse([string]$Address, [long]$Offset = 0) {
    $request = [Net.HttpWebRequest]::Create($Address)
    $request.UserAgent = 'Jobs-WindowsOS-Release/2026.11.09'
    $request.Accept = 'application/vnd.github+json'
    $request.Timeout = 30000
    $request.ReadWriteTimeout = 60000
    $request.AllowAutoRedirect = $true
    $request.MaximumAutomaticRedirections = 10
    if ($Offset -gt 0) { $request.AddRange($Offset) }
    try { return $request.GetResponse() }
    catch [Net.WebException] {
        if ($_.Exception.Response) { return $_.Exception.Response }
        throw
    }
}
# 尊重有效 Retry-After 和配额恢复时间，过期值使用正数退避。
function Get-ReleaseRetryDelay($Headers, [int]$Fallback) {
    $delay = [double]$Fallback
    if ($Headers) {
        $raw = [string]$Headers['Retry-After']
        $seconds = 0.0
        $date = [DateTimeOffset]::MinValue
        if ([double]::TryParse($raw, [ref]$seconds) -and $seconds -gt 0) { $delay = [Math]::Max($delay, $seconds) }
        elseif ([DateTimeOffset]::TryParse($raw, [ref]$date)) { $delay = [Math]::Max($delay, ($date - [DateTimeOffset]::UtcNow).TotalSeconds) }
        $reset = 0L
        if ([long]::TryParse([string]$Headers['X-RateLimit-Reset'], [ref]$reset)) {
            $delay = [Math]::Max($delay, ($reset - [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()))
        }
    }
    return [Math]::Ceiling([Math]::Max(1, $delay))
}
# 根据真实截止时刻分段等待，睡眠恢复后重新核对剩余时间。
function Wait-ReleaseRetry([double]$Seconds, [string]$Reason) {
    $until = [DateTimeOffset]::UtcNow.AddSeconds($Seconds)
    Write-ReleaseLog "$Reason；下次尝试：$($until.ToLocalTime().ToString('yyyy-MM-dd HH:mm:ss zzz'))；Ctrl+C 取消。" Yellow
    $nextLog = [DateTimeOffset]::UtcNow.AddSeconds(60)
    while ([DateTimeOffset]::UtcNow -lt $until) {
        $left = [Math]::Ceiling(($until - [DateTimeOffset]::UtcNow).TotalSeconds)
        Start-Sleep -Seconds ([Math]::Min(5, $left))
        if ([DateTimeOffset]::UtcNow -ge $nextLog) {
            Write-ReleaseLog "仍在等候，剩余 $([Math]::Ceiling(($until - [DateTimeOffset]::UtcNow).TotalSeconds)) 秒。"
            $nextLog = [DateTimeOffset]::UtcNow.AddSeconds(60)
        }
    }
}
# 清单分页只在全部页面成功后发布，-List 不自动进入长期等待。
function Get-ReleaseApiItems([string]$Endpoint) {
    $all = New-Object Collections.Generic.List[object]
    for ($page = 1; ; $page++) {
        $address = "${Endpoint}?per_page=100&page=$page"
        $fallback = 60
        while ($true) {
            $response = $null
            $reader = $null
            try {
                Write-ReleaseLog "清单来源：$address"
                $response = Open-ReleaseResponse $address
                $code = [int]$response.StatusCode
                if ($code -ne 200) {
                    $rateLimited = $code -eq 429 -or ($code -eq 403 -and
                        ($response.Headers['X-RateLimit-Remaining'] -eq '0' -or $response.Headers['Retry-After']))
                    if ($rateLimited -and -not $List) {
                        $delay = Get-ReleaseRetryDelay $response.Headers $fallback
                        $response.Close(); $response = $null
                        Wait-ReleaseRetry $delay "GitHub API HTTP $code 限流"
                        $fallback = [Math]::Min(300, $fallback * 2)
                        continue
                    }
                    throw "GitHub API HTTP $code：$address；稍后重试或在浏览器检查仓库 Release。"
                }
                $reader = New-Object IO.StreamReader($response.GetResponseStream(), [Text.Encoding]::UTF8)
                $body = $reader.ReadToEnd()
                if (-not $body.TrimStart().StartsWith('[')) { throw "API 返回的不是列表：$address" }
                $items = @($body | ConvertFrom-Json)
                foreach ($item in $items) { $all.Add($item) }
                break
            } finally {
                if ($reader) { $reader.Dispose() }
                if ($response) { $response.Close() }
            }
        }
        if ($items.Count -lt 100) { break }
    }
    return $all.ToArray()
}
# 验证标签和附件名字，Windows 保留设备名与不兼容字符不落盘。
function Assert-ReleaseFilename([string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Name) -or $Name -match '[\x00-\x1f\x7f<>:"/\\|?*]' -or
        $Name -match '[. ]$' -or $Name -in @('.','..','.git','.partial','.download-lock') -or
        $Name -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)') { throw "附件名称不适合 Windows 文件系统，未写入：$Name" }
}
# 验证发布清单中的身份和官方 URL，不接受其它仓库或本地路径。
function Assert-ReleaseAsset($Asset, [string]$Tag) {
    $assetId = 0L
    $size = 0L
    $name = [string](Get-ReleaseField $Asset 'name')
    Assert-ReleaseFilename $name
    if (-not [long]::TryParse([string](Get-ReleaseField $Asset 'id'), [ref]$assetId) -or $assetId -le 0 -or
        -not [long]::TryParse([string](Get-ReleaseField $Asset 'size'), [ref]$size) -or $size -lt 0) { throw '附件 ID 或大小无效。' }
    $digest = [string](Get-ReleaseField $Asset 'digest')
    if ($digest -and $digest -notmatch '^sha256:[a-fA-F0-9]{64}$') { throw "附件摘要类型不支持或无效：$name" }
    $null = Convert-ReleaseTimestamp (Get-ReleaseField $Asset 'updated_at')
    $address = [string](Get-ReleaseField $Asset 'browser_download_url')
    $uri = $null
    if ($address -match '[\x00-\x20\x7f]' -or -not [Uri]::TryCreate($address, [UriKind]::Absolute, [ref]$uri) -or $uri.Scheme -cne 'https' -or
        $uri.Host -cne 'github.com' -or -not $uri.IsDefaultPort -or $uri.UserInfo -or $uri.Query -or $uri.Fragment -or
        [Uri]::UnescapeDataString($uri.AbsolutePath) -cne "/$script:Owner/$script:Repository/releases/download/$Tag/$name") { throw "附件来源不属于当前仓库与标签：$name" }
}
# 拉取并验证全部已发布版本，不发布缺字段的部分清单。
function Get-RepositoryReleases {
    $releases = @(Get-ReleaseApiItems "https://api.github.com/repos/$script:Owner/$script:Repository/releases")
    $ids = @{}
    foreach ($release in $releases) {
        $id = 0L
        $tag = [string](Get-ReleaseField $release 'tag_name')
        if (-not [long]::TryParse([string](Get-ReleaseField $release 'id'), [ref]$id) -or $id -le 0 -or
            [string]::IsNullOrWhiteSpace($tag) -or $tag -match '[\x00-\x1f\x7f]' -or $ids.ContainsKey($id)) { throw 'Release 清单身份、标签缺失或 ID 重复。' }
        $ids[$id] = $true
    }
    return $releases
}
# 按当前版本 ID 查询完整附件列表并拒绝大小写冲突、重复身份。
function Get-RepositoryAssets($Release) {
    $assets = @(Get-ReleaseApiItems "https://api.github.com/repos/$script:Owner/$script:Repository/releases/$($Release.id)/assets")
    $names = @{}
    $ids = @{}
    foreach ($asset in $assets) {
        Assert-ReleaseAsset $asset $Release.tag_name
        if ($names.ContainsKey([string]$asset.name) -or $ids.ContainsKey([string]$asset.id)) { throw '附件名称（Windows 大小写不敏感）或 ID 重复。' }
        $names[[string]$asset.name] = $true
        $ids[[string]$asset.id] = $true
    }
    return $assets
}
# 保存并恢复 fzf 的环境配置与 UTF-8 编码，防止用户选项改变安全按键。
function Select-ReleaseRows([string[]]$Rows, [string]$Title, [switch]$Multiple, [switch]$Back, [switch]$Download) {
    if ($Rows.Count -eq 0) { return @{ Action = 'Empty'; Indices = @() } }
    $displayRows = $Rows
    $hasDownloadAll = $Download -and $Multiple -and $Rows.Count -gt 1
    if ($Download) {
        for ($index = 0; $index -lt $Rows.Count; $index++) {
            if (($Rows[$index] -split "`t", 2)[0] -cne $index.ToString([Globalization.CultureInfo]::InvariantCulture)) { throw '附件列表编号无效，未打开选择面板。' }
        }
    }
    if ($hasDownloadAll) { $displayRows = @("ALL`t全选") + $Rows }
    $options = @('--sync','--layout=reverse','--border','--height=80%','--delimiter=\t','--with-nth=2..',"--prompt=$Title > ")
    $hint = '方向键/搜索；Enter 确认；唯一匹配项 Space 确认；Esc 取消'
    if ($Download -and $Rows.Count -eq 1) {
        $hint = '只有一个附件；Enter 勾选/取消；Space 确认；Ctrl-D 清空；Esc 取消'
        $binding = 'enter:toggle,ctrl-a:ignore,ctrl-d:deselect-all,esc:abort,space:transform:if %FZF_SELECT_COUNT% GTR 0 (echo accept) else if %FZF_MATCH_COUNT% EQU 1 (echo select+accept) else (echo select)'
        $options += @('--multi',"--bind=$binding")
    } elseif ($hasDownloadAll) {
        $hint = '首行全选：Enter / Space 选择完整清单；附件：Enter 勾选/取消；Space 已选确认/唯一项直达/多项先勾选；Ctrl-D 清空；Esc 取消'
        # 只插入受控首字段；匹配文件避免长清单超过 CMD 参数长度限制。
        $allAction = 'if x{r1}==xALL (echo deselect-all+select+accept) else (echo toggle)'
        $spaceAction = 'if x{r1}==xALL (echo deselect-all+select+accept) else if %FZF_SELECT_COUNT% GTR 0 (echo accept) else if %FZF_MATCH_COUNT% EQU 1 (echo select+accept) else if %FZF_MATCH_COUNT% EQU 2 (findstr /x /c:ALL {*f1} >nul && echo select+accept || echo select) else (echo select)'
        $options += @('--multi',"--bind=enter:transform:$allAction","--bind=space:transform:$spaceAction",'--bind=ctrl-a:ignore,ctrl-d:deselect-all,esc:abort,tab:down,shift-tab:up')
    } elseif ($Multiple) {
        $hint = 'Enter 勾选/取消；Space 已选确认/唯一项直达/多项先勾选；Ctrl-A 全选；Ctrl-D 清空；Esc 取消'
        $binding = 'enter:toggle,ctrl-a:select-all,ctrl-d:deselect-all,esc:abort,space:transform:if %FZF_SELECT_COUNT% GTR 0 (echo accept) else if %FZF_MATCH_COUNT% EQU 1 (echo select+accept) else (echo select)'
        $options += @('--multi',"--bind=$binding")
    } else {
        $options += '--bind=enter:accept,esc:abort,space:transform:if %FZF_MATCH_COUNT% EQU 1 (echo accept) else echo put^( ^)'
    }
    if ($Back) { $options += '--expect=left'; $hint += '；← 返回 Release' }
    $options += @("--header=$Title | $hint", "--footer=$hint")
    $oldOptions = [Environment]::GetEnvironmentVariable('FZF_DEFAULT_OPTS', 'Process')
    $oldOptionsFile = [Environment]::GetEnvironmentVariable('FZF_DEFAULT_OPTS_FILE', 'Process')
    $oldShell = [Environment]::GetEnvironmentVariable('SHELL', 'Process')
    $oldConsoleEncoding = [Console]::OutputEncoding
    $oldOutputEncoding = $OutputEncoding
    try {
        $env:FZF_DEFAULT_OPTS = ''
        $env:FZF_DEFAULT_OPTS_FILE = ''
        $env:SHELL = $env:ComSpec
        $OutputEncoding = New-Object Text.UTF8Encoding($false)
        [Console]::OutputEncoding = $OutputEncoding
        $picked = @($displayRows | & $script:Fzf @options)
        $code = $LASTEXITCODE
    } finally {
        [Console]::OutputEncoding = $oldConsoleEncoding
        $OutputEncoding = $oldOutputEncoding
        [Environment]::SetEnvironmentVariable('FZF_DEFAULT_OPTS', $oldOptions, 'Process')
        [Environment]::SetEnvironmentVariable('FZF_DEFAULT_OPTS_FILE', $oldOptionsFile, 'Process')
        [Environment]::SetEnvironmentVariable('SHELL', $oldShell, 'Process')
    }
    if ($Back -and $picked.Count -gt 0 -and $picked[0] -ceq 'left' -and $code -in @(0,1)) { return @{ Action = 'Back'; Indices = @() } }
    if ($code -in @(1,130)) { return @{ Action = 'Cancel'; Indices = @() } }
    if ($code -ne 0) { throw "fzf 失败，退出码 $code；未执行选择计划。" }
    if ($Back) { $picked = @($picked | Select-Object -Skip 1) }
    $indices = @()
    $allPicked = $false
    foreach ($line in $picked) {
        $number = ($line -split "`t", 2)[0]
        if ($hasDownloadAll -and $number -ceq 'ALL') { $allPicked = $true; continue }
        if ($number -notmatch '^\d{1,8}$' -or [int]$number -ge $Rows.Count) { throw 'fzf 返回了无效编号。' }
        $indices += [int]$number
    }
    if ($allPicked) { return @{ Action = 'Select'; Indices = @(0..($Rows.Count - 1)) } }
    if ($indices.Count -eq 0) { return @{ Action = 'Cancel'; Indices = @() } }
    return @{ Action = 'Select'; Indices = $indices }
}
# 选中任意分卷时补齐同组，缺片、重号、总数冲突时拒绝整版计划。
function Expand-ReleaseSplitGroups([object[]]$Assets, [int[]]$Indices) {
    $selected = @{}
    foreach ($index in $Indices) { $selected[$index] = $true }
    $groups = @{}
    for ($index = 0; $index -lt $Assets.Count; $index++) {
        if ([string]$Assets[$index].name -match '^(?<base>.+)@(?<part>\d+)of(?<total>\d+)$') {
            $part = 0L; $total = 0L
            if (-not [long]::TryParse($Matches.part, [ref]$part) -or -not [long]::TryParse($Matches.total, [ref]$total)) { throw '分卷编号超过可解析范围。' }
            $key = $Matches.base
            if (-not $groups.ContainsKey($key)) { $groups[$key] = New-Object Collections.Generic.List[object] }
            $groups[$key].Add(@{ Index = $index; Part = $part; Total = $total })
        }
    }
    foreach ($group in $groups.Values) {
        if (@($group | Where-Object { $selected.ContainsKey($_.Index) }).Count -eq 0) { continue }
        $total = $group[0].Total
        $parts = @{}
        foreach ($member in $group) {
            if ($member.Total -ne $total -or $member.Part -lt 1 -or $member.Part -gt $total -or $parts.ContainsKey($member.Part)) { throw '所选分卷有重号、越界或总数冲突。' }
            $parts[$member.Part] = $true
        }
        if ($group.Count -ne $total) { throw '所选分卷缺片；未执行不完整计划。' }
        foreach ($member in $group) { $selected[$member.Index] = $true }
    }
    return @($selected.Keys | Sort-Object { [int]$_ } | ForEach-Object { $Assets[[int]$_] })
}
# 创建路径时逐层验证，防止落入链接和其它工作树。
function New-ReleaseDirectory([string]$Path) {
    Assert-ReleasePath $Path Directory
    if (-not (Test-Path -LiteralPath $Path)) { [IO.Directory]::CreateDirectory($Path) | Out-Null }
    Assert-ReleasePath $Path Directory
    $actual = @(& $script:Git -C $Path rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0 -or $actual.Count -ne 1 -or [IO.Path]::GetFullPath([string]$actual[0]) -ne $script:RepositoryRoot) { throw '下载目录进入了其它 Git 工作树，停止。' }
}
# 仅在执行确认后追加本仓精确本地排除，不修改受跟踪 .gitignore。
function Add-ReleaseLocalIgnore {
    $raw = @(& $script:Git -C $script:RepositoryRoot rev-parse --git-path info/exclude)
    if ($LASTEXITCODE -ne 0 -or $raw.Count -ne 1) { throw '无法定位本仓 info/exclude。' }
    $exclude = [string]$raw[0]
    if (-not [IO.Path]::IsPathRooted($exclude)) { $exclude = Join-Path $script:RepositoryRoot $exclude }
    Assert-ReleasePath $exclude File
    $parent = Split-Path -Parent $exclude
    Assert-ReleasePath $parent Directory
    [IO.Directory]::CreateDirectory($parent) | Out-Null
    $lines = @()
    if (Test-Path -LiteralPath $exclude) { $lines = [IO.File]::ReadAllLines($exclude) }
    if ($lines -cnotcontains '/Releases/') {
        [IO.File]::AppendAllText($exclude, "`n# WindowsOS Release downloads (local only)`n/Releases/`n", (New-Object Text.UTF8Encoding($false)))
        Write-ReleaseLog '已追加本仓 info/exclude：/Releases/；其它规则保留。'
    }
    & $script:Git -C $script:RepositoryRoot check-ignore --no-index --quiet -- Releases/.windowsos-download-check
    if ($LASTEXITCODE -ne 0) { throw '其它优先规则取消了 Releases 忽略，请核对后重试。' }
}
# 同版系统文件锁由内核管理，进程结束后释放，不删除或替换锁文件。
function Open-ReleaseLock([string]$Directory) {
    $path = Join-Path $Directory '.download-lock'
    Assert-ReleasePath $path File
    if ((Test-Path -LiteralPath $path) -and (Get-Item -LiteralPath $path -Force).Length -ne 0) { throw '下载锁含未知内容，保留原状。' }
    try { return [IO.File]::Open($path, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None) }
    catch { throw "同版下载正在运行或锁不可用，未开始传输：$path" }
}
# 校验长度和发布方提供的 SHA256，读取失败不当作网络错误。
function Test-ReleaseFile([string]$Path, $Asset) {
    Assert-ReleasePath $Path File
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    if ((Get-Item -LiteralPath $Path -Force).Length -ne [long]$Asset.size) { return $false }
    $digest = [string](Get-ReleaseField $Asset 'digest')
    if ($digest) {
        $hash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash
        if ($hash -ine $digest.Substring(7)) { return $false }
    }
    return $true
}
# 将新版 PowerShell 自动解析的日期还原为 GitHub 的 UTC 时间戳。
function Convert-ReleaseTimestamp($Value) {
    if ($Value -is [DateTimeOffset]) { return $Value.UtcDateTime.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture) }
    if ($Value -is [DateTime]) { return $Value.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture) }
    if ([string]$Value -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$') { throw '附件更新时间缺失或格式无效。' }
    return [string]$Value
}
# 建立与 MacOS 相同字段和字典序的附件身份，兼容已有断点 JSON。
function Get-ReleaseIdentity($Asset) {
    return [ordered]@{
        browser_download_url = [string]$Asset.browser_download_url
        digest = Get-ReleaseField $Asset 'digest'
        id = [long]$Asset.id
        name = [string]$Asset.name
        size = [long]$Asset.size
        updated_at = Convert-ReleaseTimestamp (Get-ReleaseField $Asset 'updated_at')
    }
}
# 按 JSON 标准转义字符串，避免 WinPS 不同序列化器的 HTML 转义破坏跨端身份。
function Convert-ReleaseJsonString($Value) {
    if ($null -eq $Value) { return 'null' }
    $result = New-Object Text.StringBuilder
    $null = $result.Append('"')
    foreach ($character in ([string]$Value).ToCharArray()) {
        switch ([int]$character) {
            34 { $null = $result.Append('\"'); break }
            92 { $null = $result.Append('\\'); break }
            8 { $null = $result.Append('\b'); break }
            9 { $null = $result.Append('\t'); break }
            10 { $null = $result.Append('\n'); break }
            12 { $null = $result.Append('\f'); break }
            13 { $null = $result.Append('\r'); break }
            default {
                if ([int]$character -lt 32) { $null = $result.Append(('\u{0:x4}' -f [int]$character)) }
                else { $null = $result.Append($character) }
            }
        }
    }
    $null = $result.Append('"')
    return $result.ToString()
}
# 输出与 jq -cS 相同的紧凑身份 JSON，供两平台互相续传。
function Convert-ReleaseIdentityJson($Identity) {
    $parts = @()
    foreach ($key in $Identity.Keys) {
        $value = if ($key -in @('id','size')) { ([long]$Identity[$key]).ToString([Globalization.CultureInfo]::InvariantCulture) }
        else { Convert-ReleaseJsonString $Identity[$key] }
        $parts += (Convert-ReleaseJsonString $key) + ':' + $value
    }
    return '{' + ($parts -join ',') + '}'
}
# 首份问题断点保留供核对，后续仅清理本轮新建候选。
function Reset-ReleasePartial([string]$Path, [ref]$Rejected) {
    Assert-ReleasePath $Path File
    if (-not (Test-Path -LiteralPath $Path)) { return }
    if (-not $Rejected.Value) {
        $backup = $Path + '.rejected.' + [Guid]::NewGuid().ToString('N')
        [IO.File]::Move($Path, $backup)
        $Rejected.Value = $true
        Write-ReleaseLog "首份问题断点已保留：$backup" Yellow
    } else {
        [IO.File]::Delete($Path)
    }
}
# 一次原生 HTTPS 传输；本地写入异常单独向上传递，不进入无限网络重试。
function Receive-ReleaseAttempt([string]$Address, [string]$Path, [long]$Expected) {
    $response = $null; $inputStream = $null; $outputStream = $null
    $offset = 0L
    if (Test-Path -LiteralPath $Path) { $offset = (Get-Item -LiteralPath $Path -Force).Length }
    try {
        try { $response = Open-ReleaseResponse $Address $offset }
        catch [Net.WebException] {
            if ($_.Exception.Status -in @([Net.WebExceptionStatus]::TrustFailure, [Net.WebExceptionStatus]::SecureChannelFailure, [Net.WebExceptionStatus]::RequestProhibitedByCachePolicy, [Net.WebExceptionStatus]::RequestProhibitedByProxy)) { throw }
            return @{ Kind = 'Retry'; Code = 0; Headers = $null; Message = $_.Exception.Status.ToString() }
        }
        $code = [int]$response.StatusCode
        if ($code -notin @(200,206)) { return @{ Kind = $(if ($code -eq 416) { 'Reset' } else { 'Retry' }); Code = $code; Headers = $response.Headers; Message = "HTTP $code" } }
        if ($response.ResponseUri.Scheme -ne 'https') { throw 'HTTPS 下载被重定向到非 HTTPS 来源，停止。' }
        if ($offset -gt 0 -and $code -eq 200) { return @{ Kind = 'Reset'; Code = $code; Headers = $null; Message = '远端不接受 Range 断点' } }
        if ($code -eq 206) {
            $range = [string]$response.Headers['Content-Range']
            if ($range -notmatch '^bytes (\d+)-(\d+)/(\d+)$' -or [long]$Matches[1] -ne $offset -or [long]$Matches[3] -ne $Expected) { return @{ Kind = 'Reset'; Code = $code; Headers = $null; Message = 'Content-Range 与断点身份不符' } }
        }
        $inputStream = $response.GetResponseStream()
        $outputStream = [IO.File]::Open($Path, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::Write, [IO.FileShare]::None)
        if ($outputStream.Length -ne $offset) { throw '断点在请求期间发生变化，停止。' }
        $outputStream.Position = $offset
        $buffer = New-Object byte[] 1048576
        $clock = [Diagnostics.Stopwatch]::StartNew()
        $nextLog = 0.0; $written = 0L
        while ($true) {
            try { $read = $inputStream.Read($buffer, 0, $buffer.Length) }
            catch [IO.IOException] { return @{ Kind = 'Retry'; Code = $code; Headers = $response.Headers; Message = '远端读取中断/超时' } }
            catch [Net.WebException] { return @{ Kind = 'Retry'; Code = $code; Headers = $response.Headers; Message = '远端连接中断/超时' } }
            if ($read -eq 0) { break }
            if ($outputStream.Position + $read -gt $Expected) { return @{ Kind = 'Reset'; Code = $code; Headers = $null; Message = '传输长度超过声明大小' } }
            $outputStream.Write($buffer, 0, $read)
            $written += $read
            if ($clock.Elapsed.TotalSeconds -ge $nextLog) {
                $percent = if ($Expected -gt 0) { 100.0 * $outputStream.Position / $Expected } else { 100.0 }
                $speed = $written / [Math]::Max(0.1, $clock.Elapsed.TotalSeconds)
                $eta = [Math]::Ceiling(($Expected - $outputStream.Position) / [Math]::Max(1, $speed))
                Write-ReleaseLog ('进度 {0:N1}% | {1:N0}/{2:N0} 字节 | {3:N0} 字节/秒 | 剩余约 {4} 秒' -f $percent,$outputStream.Position,$Expected,$speed,$eta)
                $nextLog = $clock.Elapsed.TotalSeconds + 2
            }
        }
        $outputStream.Flush()
        return @{ Kind = 'Verify'; Code = $code; Headers = $null; Message = '' }
    } finally {
        if ($outputStream) { $outputStream.Dispose() }
        if ($inputStream) { $inputStream.Dispose() }
        if ($response) { $response.Close() }
    }
}
# 持续重试当前附件，元数据变化、正式文件冲突和本地错误立即停止。
function Receive-ReleaseAsset($Asset, [string]$Directory, [string]$Tag) {
    Assert-ReleaseAsset $Asset $Tag
    $destination = Join-Path $Directory $Asset.name
    $partialRoot = Join-Path $Directory '.partial'
    $partial = Join-Path $partialRoot ($Asset.id.ToString() + '.part')
    $metadata = Join-Path $partialRoot ($Asset.id.ToString() + '.json')
    foreach ($path in @($destination,$partial,$metadata)) { Assert-ReleasePath $path File }
    Write-ReleaseLog '━━━━━━━━━━ 来源｜Release 附件 ━━━━━━━━━━'
    Write-ReleaseLog "对象：$script:Repository / $Tag / $($Asset.name)"
    Write-ReleaseLog "平台：GitHub / github.com；来源地址：$($Asset.browser_download_url)"
    Write-ReleaseLog "目标位置：$destination；大小：$($Asset.size) 字节"
    $digest = [string](Get-ReleaseField $Asset 'digest')
    if ($digest) { Write-ReleaseLog "SHA256：$digest" }
    else { Write-ReleaseLog 'API 未提供 SHA256，本附件仅核对声明大小。' Yellow }
    if (Test-Path -LiteralPath $destination) {
        if (-not (Test-ReleaseFile $destination $Asset)) { throw "已存在同名文件但校验不符，未覆盖：$destination" }
        Write-ReleaseLog "✔ 已存在且验证通过，跳过：$($Asset.name)" Green
        $script:Skipped++
        return
    }
    $identity = Get-ReleaseIdentity $Asset
    if (Test-Path -LiteralPath $metadata) {
        $oldIdentity = [IO.File]::ReadAllText($metadata) | ConvertFrom-Json
        $oldFields = @($oldIdentity.PSObject.Properties.Name | Sort-Object)
        if (($oldFields -join ',') -cne (($identity.Keys | Sort-Object) -join ',')) { throw '断点身份记录字段无效，保留原状。' }
        foreach ($key in $identity.Keys) {
            $oldValue = Get-ReleaseField $oldIdentity $key
            if ($key -eq 'updated_at') { $oldValue = Convert-ReleaseTimestamp $oldValue }
            if ([string]$oldValue -cne [string]$identity[$key]) { throw "断点身份已变化，保留：$partial；请移到其它位置后重试。" }
        }
    } elseif (Test-Path -LiteralPath $partial) { throw "断点缺少身份记录，保留：$partial" }
    else {
        $json = Convert-ReleaseIdentityJson $identity
        $stream = [IO.File]::Open($metadata, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes($json + "`n"); $stream.Write($bytes,0,$bytes.Length) }
        finally { $stream.Dispose() }
    }
    $rejected = $false
    $fallback = 1
    while ($true) {
        Assert-ReleasePath $partial File
        if ((Test-Path -LiteralPath $partial) -and (Test-ReleaseFile $partial $Asset)) { break }
        if ((Test-Path -LiteralPath $partial) -and (Get-Item -LiteralPath $partial).Length -ge [long]$Asset.size) {
            Reset-ReleasePartial $partial ([ref]$rejected)
        }
        $result = Receive-ReleaseAttempt $Asset.browser_download_url $partial ([long]$Asset.size)
        if ($result.Kind -eq 'Verify' -and (Test-ReleaseFile $partial $Asset)) { break }
        if ($result.Kind -eq 'Reset' -or ($result.Kind -eq 'Verify' -and (Get-Item -LiteralPath $partial).Length -ge [long]$Asset.size)) {
            Reset-ReleasePartial $partial ([ref]$rejected)
        }
        if ($result.Code -in @(401,403,404,429,503)) { $fallback = [Math]::Max(60, $fallback) }
        $delay = Get-ReleaseRetryDelay $result.Headers $fallback
        Wait-ReleaseRetry $delay "附件未通过传输与校验：$($Asset.name)；$($result.Message)"
        $fallback = [Math]::Min(300, $fallback * 2)
    }
    Assert-ReleasePath $destination File
    [IO.File]::Move($partial, $destination)
    Write-ReleaseLog "✔ 下载并校验完成：$($Asset.name)" Green
    $script:Downloaded++
}
# 下载前形成完整计划并再次确认；锁覆盖全部传输，finally 确保释放。
function Invoke-ReleasePlan($Release, [object[]]$Plan) {
    $tag = [string]$Release.tag_name
    $encoded = [Uri]::EscapeDataString($tag)
    if ($encoded -in @('.','..') -or $encoded -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)' -or $encoded.EndsWith('.')) { $encoded = 'tag-' + $encoded.Replace('.', '%2E') }
    $releaseRoot = Join-Path $script:RepositoryRoot 'Releases'
    $directory = Join-Path $releaseRoot $encoded
    Assert-ReleasePath $directory Directory
    $total = 0L
    foreach ($asset in $Plan) { $total += [long]$asset.size; Write-ReleaseLog "计划：$($asset.name)；$($asset.size) 字节" }
    Write-ReleaseLog "共 $($Plan.Count) 个附件，声明总量 $total 字节；目标：$directory"
    $downloadAnswer = Read-ReleaseConfirmation '开始本版下载？' -FreshInput
    if ($null -eq $downloadAnswer) { throw '输入已结束，未执行本次下载。' }
    if (-not [string]::IsNullOrWhiteSpace($downloadAnswer)) {
        $script:NotStartedBatches++
        $script:Pending += $Plan.Count
        Write-ReleaseLog "本版未启动下载：最终确认未执行；计划 $($Plan.Count) 个附件，本轮未检查/尝试 $($Plan.Count) 个。"
        Write-ReleaseLog "结果：新下载 $script:Downloaded；已存在且验证通过 $script:Skipped；未启动下载批次 $script:NotStartedBatches；未检查/尝试 $script:Pending。"
        return
    }
    Assert-ReleaseRepository
    Add-ReleaseLocalIgnore
    New-ReleaseDirectory $releaseRoot
    New-ReleaseDirectory $directory
    New-ReleaseDirectory (Join-Path $directory '.partial')
    $lock = Open-ReleaseLock $directory
    try {
        $position = 0
        foreach ($asset in $Plan) {
            $position++
            Write-ReleaseLog "附件进度 [$position/$($Plan.Count)]：$($asset.name)"
            Receive-ReleaseAsset $asset $directory $tag
        }
        $summaryColor = if ($script:NotStartedBatches -gt 0 -or $script:Pending -gt 0) { [ConsoleColor]::Yellow } else { [ConsoleColor]::Green }
        Write-ReleaseLog "结果：新下载 $script:Downloaded；已存在且验证通过 $script:Skipped；未启动下载批次 $script:NotStartedBatches；未检查/尝试 $script:Pending。" $summaryColor
        Write-ReleaseLog "下载位置：$directory；请手工运行本仓 WindowsOS 中的子卷合并工具并选择此目录。"
    } finally { $lock.Dispose() }
}
# 列表、选择与下载的唯一高层编排；返回只回到上一选择面板。
function Invoke-CurrentRepositoryRelease {
    if ($Help) { Show-ReleaseHelp; return }
    Set-StrictMode -Version 2.0
    Initialize-ReleaseDisplay
    try {
        if (-not $List -and -not (Confirm-ReleaseIntro)) { Write-ReleaseLog '已取消；未执行下载。'; return }
        Initialize-ReleaseRuntime
        Assert-ReleaseRepository
        if (-not $List) { Assert-ReleaseSelector }
        $releases = @(Get-RepositoryReleases)
        if ($releases.Count -eq 0) { Write-ReleaseLog '本仓暂无已发布 Release；可稍后重新运行本入口加载。' Yellow; return }
        if ($List) {
            foreach ($release in $releases) {
                Write-ReleaseLog "Release：$($release.tag_name)"
                $assets = @(Get-RepositoryAssets $release)
                if ($assets.Count -eq 0) { Write-ReleaseLog '  无附件；可稍后重新加载。' }
                foreach ($asset in $assets) { Write-ReleaseLog "  $($asset.name) | $($asset.size) 字节 | $($asset.browser_download_url)" }
            }
            return
        }
        while ($true) {
            $rows = @()
            for ($i = 0; $i -lt $releases.Count; $i++) {
                $name = [string](Get-ReleaseField $releases[$i] 'name') -replace '[\x00-\x1f\x7f]', ' '
                $rows += "$i`t$($releases[$i].tag_name) | $name"
            }
            $picked = Select-ReleaseRows $rows "$script:Repository：选择 Release"
            if ($picked.Action -ne 'Select') { Write-ReleaseLog '已取消 Release 选择。'; return }
            $release = $releases[$picked.Indices[0]]
            $assets = @(Get-RepositoryAssets $release)
            if ($assets.Count -eq 0) { Write-ReleaseLog '本版暂无附件；返回 Release，可稍后重新运行加载。' Yellow; continue }
            $rows = @()
            for ($i = 0; $i -lt $assets.Count; $i++) { $rows += "$i`t$($assets[$i].name) | $($assets[$i].size) 字节" }
            $picked = Select-ReleaseRows $rows '选择附件' -Multiple -Back -Download
            if ($picked.Action -eq 'Back') { continue }
            if ($picked.Action -ne 'Select') { Write-ReleaseLog '已取消附件选择。'; return }
            $plan = @(Expand-ReleaseSplitGroups $assets $picked.Indices)
            Invoke-ReleasePlan $release $plan
            return
        }
    } finally {
        if ($null -ne $script:WrittenTls -and [Net.ServicePointManager]::SecurityProtocol -eq $script:WrittenTls) {
            [Net.ServicePointManager]::SecurityProtocol = $script:OriginalTls
        }
        Restore-ReleaseDisplay
    }
}
try {
    Invoke-CurrentRepositoryRelease
    exit 0
} catch [System.Management.Automation.PipelineStoppedException] {
    exit 130
} catch {
    Write-ReleaseLog ('✖ ' + $_.Exception.Message) Red
    if ($script:LogFile) { Write-Host "日志：$script:LogFile" }
    exit 1
}
