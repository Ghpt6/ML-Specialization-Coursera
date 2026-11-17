# Shared by setup.ps1 and start-lab.ps1; paths are relative to this checkout.
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$CourseDirectories = @{
    '1' = 'Course 1 - Supervised Machine Learning (Regression and Classification)'
    '2' = 'Course 2 - Advanced Learning Algorithms'
}
