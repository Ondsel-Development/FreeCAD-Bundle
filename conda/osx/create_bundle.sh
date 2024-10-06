# assume we have a working conda available


export MAMBA_NO_BANNER=1
conda_env="APP/Ondsel ES.app/Contents/Resources"


mamba create \
    -p "${conda_env}" \
    ondsel-es=*.pre occt vtk python=3.11 calculix blas=*=openblas \
    numpy matplotlib-base scipy sympy pandas six \
    pyyaml jinja2 opencamlib ifcopenshell lark \
    pycollada lxml xlutils olefile requests \
    blinker opencv nine docutils \
    pyjwt tzlocal mistune \
    --copy -c Ondsel/label/dev -c freecad/label/dev -c conda-forge -y


mamba run -p "${conda_env}" python ../scripts/get_freecad_version.py
read -r version_name < bundle_name.txt

echo -e "\################"
echo -e "version_name:  ${version_name}"
echo -e "################"

echo -e "\nInstall additional addons"
mamba run -p "${conda_env}" python ../scripts/install_addons.py "${conda_env}"

mamba list -p "${conda_env}" > "APP/Ondsel ES.app/Contents/packages.txt"
sed -i "" "1s/.*/\nLIST OF PACKAGES:/"  "APP/Ondsel ES.app/Contents/packages.txt"

# copy the QuickLook plugin into its final location
mv "${conda_env}"/Library "${conda_env}"/../Library

# delete unnecessary stuff
rm -rf "${conda_env}"/include
find "${conda_env}" -name \*.a -delete
mv "${conda_env}"/bin "${conda_env}"/bin_tmp
mkdir "${conda_env}"/bin
cp "${conda_env}"/bin_tmp/ondsel-es "${conda_env}"/bin/
cp "${conda_env}"/bin_tmp/ondsel-escmd "${conda_env}"/bin
cp "${conda_env}"/bin_tmp/freecad "${conda_env}"/bin/
cp "${conda_env}"/bin_tmp/freecadcmd "${conda_env}"/bin
cp "${conda_env}"/bin_tmp/ccx "${conda_env}"/bin/
cp "${conda_env}"/bin_tmp/python "${conda_env}"/bin/
cp "${conda_env}"/bin_tmp/pip "${conda_env}"/bin/
cp "${conda_env}"/bin_tmp/pyside2-rcc "${conda_env}"/bin/
cp "${conda_env}"/bin_tmp/gmsh "${conda_env}"/bin/
cp "${conda_env}"/bin_tmp/dot "${conda_env}"/bin/
cp "${conda_env}"/bin_tmp/unflatten "${conda_env}"/bin/
cp "${conda_env}"/bin_tmp/branding.xml "${conda_env}"/bin/
sed -i "" '1s|.*|#!/usr/bin/env python|' "${conda_env}"/bin/pip
rm -rf "${conda_env}"/bin_tmp

# remove custom freecad logo from opentheme
find "${conda_env}/share/Gui/PreferencePacks/OpenTheme/" -type f \( -name "*.qss" -o -name "*.scss" \) \
   -exec sed -i "" "/background-image: url(qss:images_dark-light\/FreecadLogo\.png);/d" {} +

#copy qt.conf
cp qt.conf "${conda_env}"/bin/
cp qt.conf "${conda_env}"/libexec/

# Remove __pycache__ folders and .pyc files
find . -path "*/__pycache__/*" -delete
find . -name "*.pyc" -type f -delete

# fix problematic rpaths and reexport_dylibs for signing
# see https://github.com/FreeCAD/FreeCAD/issues/10144#issuecomment-1836686775
# and https://github.com/FreeCAD/FreeCAD-Bundle/pull/203
mamba run -p "${conda_env}" python ../scripts/fix_macos_lib_paths.py "${conda_env}"/lib

# create the dmg
pip3 install --break-system-packages "dmgbuild[badge_icons]>=1.6.0,<1.7.0"
dmgbuild -s dmg_settings.py "Ondsel ES" "${version_name}.dmg"

# create hash
shasum -a 256 ${version_name}.dmg > ${version_name}.dmg-SHA256.txt
