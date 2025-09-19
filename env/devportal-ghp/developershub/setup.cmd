@echo off
@goto :batch 2>nul
@rem The above line jumps to :batch in Windows, but in Linux/shell this file gets re-executed as shell script

:batch
echo Running Windows commands...
cmd /c scripts\setupHost.bat
exit /b %ERRORLEVEL%

@rem This section never executes in Windows due to the exit above
: <<'EOF'
echo "Running Linux commands..."
./scripts/setupHost.sh
exit $?
EOF
