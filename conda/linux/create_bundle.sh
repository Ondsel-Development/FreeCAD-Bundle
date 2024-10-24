#!/bin/bash

export MAMBA_NO_BANNER=1
if [[ -z "$ARCH" ]]; then
  # Get the architecture of the system
  export ARCH=$(uname -m)
fi
conda_env="AppDir/usr"
echo -e "\nCreate the environment"

packages="ondsel-es=*.pre occt vtk python=3.11 blas=*=openblas numpy \
          matplotlib-base scipy sympy pandas six pyyaml pycollada lxml \
          xlutils olefile requests blinker opencv nine docutils \
          opencamlib calculix ifcopenshell lark \
          pyjwt tzlocal git"

mamba create -p ${conda_env} ${packages} \
  --copy -c Ondsel/label/dev -c freecad/label/dev -c conda-forge -y

mamba run -p ${conda_env} python ../scripts/get_freecad_version.py
read -r version_name < bundle_name.txt

echo -e "\################"
echo -e "version_name:  ${version_name}"
echo -e "################"

echo -e "\nInstall additional addons"
mamba run -p ${conda_env} python ../scripts/install_addons.py ${conda_env}

echo -e "\nUninstall some packages not needed"
conda uninstall -p ${conda_env} libclang --force -y

mamba list -p ${conda_env} > AppDir/packages.txt
sed -i "1s/.*/\nLIST OF PACKAGES:/" AppDir/packages.txt

echo -e "\nDelete unnecessary stuff"
rm -rf ${conda_env}/include
find ${conda_env} -name \*.a -delete
mv ${conda_env}/bin ${conda_env}/bin_tmp
mkdir ${conda_env}/bin
cp ${conda_env}/bin_tmp/ondsel-es ${conda_env}/bin/
cp ${conda_env}/bin_tmp/ondsel-escmd ${conda_env}/bin/
cp ${conda_env}/bin_tmp/freecad ${conda_env}/bin/
cp ${conda_env}/bin_tmp/freecadcmd ${conda_env}/bin/
cp ${conda_env}/bin_tmp/ccx ${conda_env}/bin/
cp ${conda_env}/bin_tmp/python ${conda_env}/bin/
cp ${conda_env}/bin_tmp/pip ${conda_env}/bin/
cp ${conda_env}/bin_tmp/pyside2-rcc ${conda_env}/bin/
cp ${conda_env}/bin_tmp/gmsh ${conda_env}/bin/
cp ${conda_env}/bin_tmp/dot ${conda_env}/bin/
cp ${conda_env}/bin_tmp/unflatten ${conda_env}/bin/
cp ${conda_env}/bin_tmp/git ${conda_env}/bin/
cp ${conda_env}/bin_tmp/branding.xml ${conda_env}/bin/
sed -i '1s|.*|#!/usr/bin/env python|' ${conda_env}/bin/pip
rm -rf ${conda_env}/bin_tmp

# remove custom freecad logo from opentheme
find "${conda_env}/share/Gui/PreferencePacks/OpenTheme/" -type f \( -name "*.qss" -o -name "*.scss" \) \
   -exec sed -i "/background-image: url(qss:images_dark-light\/FreecadLogo\.png);/d" {} +

echo -e "\nCopy qt.conf"
cp qt.conf ${conda_env}/bin/
cp qt.conf ${conda_env}/libexec/

echo -e "\nCopying Icon and Desktop file"
cp ${conda_env}/share/applications/com.ondsel.ES.desktop AppDir/
sed -i 's/Exec=FreeCAD/Exec=AppRun/g' AppDir/com.ondsel.ES.desktop
cp ${conda_env}/share/icons/hicolor/scalable/apps/Ondsel.svg AppDir/


# Remove __pycache__ folders and .pyc files
find . -path "*/__pycache__/*" -delete
find . -name "*.pyc" -type f -delete

# reduce size
rm -rf ${conda_env}/conda-meta/
rm -rf ${conda_env}/doc/global/
rm -rf ${conda_env}/share/gtk-doc/
rm -rf ${conda_env}/lib/cmake/

find . -name "*.h" -type f -delete
find . -name "*.cmake" -type f -delete

echo -e "\nAdd libnsl (Fedora 28 and up)"
cp ../../libc6/lib/$ARCH-linux-gnu/libnsl* ${conda_env}/lib/

if [ "$DEPLOY_RELEASE" = "weekly-builds" ]; then
  export tag="weekly-builds"
else
  export tag="latest"
fi

echo -e "\nCreate the appimage"
if [ "$ARCH" = "aarch64" ]; then
  export ARCH=arm_aarch64
fi
chmod a+x ./AppDir/AppRun
../../appimagetool-$(uname -m).AppImage \
  AppDir  ${version_name}.AppImage

echo -e "\nCreate hash"
shasum -a 256 ${version_name}.AppImage > ${version_name}.AppImage-SHA256.txt
