$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$destDir = "c:\Users\hoang\Project\PTIT\Flutter\flutter_application_initial\android\app\src\main\assets"
if (!(Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
$models = @(
    @("pose_landmarker/pose_landmarker_full/float16/1/pose_landmarker_full.task", "pose_landmarker.task"),
    @("hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task", "hand_landmarker.task"),
    @("face_landmarker/face_landmarker/float16/1/face_landmarker.task", "face_landmarker.task")
)
$baseUrl = "https://storage.googleapis.com/mediapipe-models"
foreach ($m in $models) {
    $url = "$baseUrl/$($m[0])"
    $out = "$destDir\$($m[1])"
    Write-Host "Downloading $url to $out..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing
    } catch {
        Write-Error "Failed to download $url : $_"
    }
}
Write-Host "Models Downloaded."
