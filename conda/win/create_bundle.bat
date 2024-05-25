set conda_env="fc_env"
set copy_dir="FreeCAD_Conda_Build"

mkdir %copy_dir%

call mamba create ^
 -p %conda_env% ^
 ondsel-es=2024.2.1 python=3.11 occt vtk calculix gmsh ^
 numpy matplotlib-base scipy sympy pandas six ^
 pyyaml opencamlib ifcopenshell lark ^
 pycollada lxml xlutils olefile requests ^
 blinker opencv nine docutils ^
 pyjwt tzlocal ^
 -c Ondsel ^
 -c freecad/label/dev ^
 -c conda-forge ^
 --copy -y 
 
 
%conda_env%\python ..\scripts\get_freecad_version.py
set /p freecad_version_name= <bundle_name.txt

echo **********************
echo %freecad_version_name%
echo **********************

echo "Install additional addons"
%conda_env%\python ../scripts/install_addons.py %conda_env%

REM remove arm binaries that fails to extract unless using latest 7zip
for /r %conda_env% %%i in (*arm*.exe) do @echo "%%i will be removed"
for /r %conda_env% %%i in (*arm*.exe) do @del "%%i"

REM Copy Conda's Python and (U)CRT to FreeCAD/bin
robocopy %conda_env%\DLLs %copy_dir%\bin\DLLs /S /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Lib %copy_dir%\bin\Lib /XD __pycache__ /S /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Scripts %copy_dir%\bin\Scripts /S /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\ python*.* %copy_dir%\bin\ /XF *.pdb /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\ msvc*.* %copy_dir%\bin\ /XF *.pdb /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\ ucrt*.* %copy_dir%\bin\ /XF *.pdb /MT:%NUMBER_OF_PROCESSORS% > nul
REM Copy gmsh and calculix
robocopy %conda_env%\Library\bin %copy_dir%\bin\ ccx.exe /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Library\bin %copy_dir%\bin\ gmsh.exe /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Library\mingw-w64\bin * %copy_dir%\bin\ /MT:%NUMBER_OF_PROCESSORS% > nul
REM Copy Conda's QT5/plugins to FreeCAD/bin
robocopy %conda_env%\Library\plugins %copy_dir%\bin\ /S /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Library\resources %copy_dir%\resources /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Library\translations %copy_dir%\translations /MT:%NUMBER_OF_PROCESSORS% > nul
echo [Paths] > %copy_dir%\bin\qt.conf
echo Prefix =.. >> "%copy_dir%\bin\qt.conf"
REM get all the dependency .dlls
robocopy %conda_env%\Library\bin *.dll %copy_dir%\bin /XF *.pdb /XF api*.* /MT:%NUMBER_OF_PROCESSORS% > nul
REM Copy FreeCAD build
robocopy %conda_env%\Library\bin FreeCAD* %copy_dir%\bin /XF *.pdb /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Library\bin ondsel* %copy_dir%\bin /XF *.pdb /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Library\bin %copy_dir%\bin\ branding.xml /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Library\share\Gui %copy_dir%\share\Gui /S /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Library\data %copy_dir%\data /XF *.txt /S /MT:%NUMBER_OF_PROCESSORS% > nul
REM robocopy %conda_env%\Library\doc\ *.html %copy_dir%\doc MT:%NUMBER_OF_PROCESSORS% > nul

robocopy %conda_env%\Library\Ext %copy_dir%\Ext /S /XD __pycache__ /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Library\lib %copy_dir%\lib /XF *.lib /XF *.prl /XF *.sh /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Library\Mod %copy_dir%\Mod /S /XD __pycache__ /MT:%NUMBER_OF_PROCESSORS% > nul
REM Apply Patches
rename %copy_dir%\bin\Lib\ssl.py ssl-orig.py
copy ssl-patch.py %copy_dir%\bin\Lib\ssl.py

REM delete custom freecad logo from opentheme
for /r "%copy_dir%\data\Gui\PreferencePacks\OpenTheme" %%F in (*.qss *.scss) do (
   findstr /v /c:"background-image: url(qss:images_dark-light/FreecadLogo.png);" "%%F" > "%%F.tmp" & move /y "%%F.tmp" "%%F"
)
REM move opentheme QtNormalizer module so it gets properly loaded
move "%copy_dir%\data\Gui\PreferencePacks\OpenTheme\QtNormalizer" "%copy_dir%\Mod\"

cd %copy_dir%\..
ren %copy_dir% %freecad_version_name%
dir

REM if errorlevel1 exit 1

"%ProgramFiles%\7-Zip\7z.exe" a -t7z -mx9 -mmt=%NUMBER_OF_PROCESSORS% %freecad_version_name%.7z %freecad_version_name%\ -bb
certutil -hashfile "%freecad_version_name%.7z" SHA256 > "%freecad_version_name%.7z"-SHA256.txt
echo  %date%-%time% >>"%freecad_version_name%.7z"-SHA256.txt
