clear -x

echo "Box64 script started!"

# obtain the system info
get_system
case "$dpkg_architecture" in
"arm64")
  case "$__os_codename" in
  bionic) ppa_name="theofficialgman/cmake-bionic" && ppa_installer ;;
  esac
  ;;
"amd64")
  echo "Installing Dependencies"
  ;;
*)
  error_user "Error: your cpu architecture ($dpkg_architecture) is not supporeted by box64 and will fail to compile"
  ;;
esac

# add toolchain ppa for gcc 11 on bionic and focal
# newer releases of ubuntu have gcc-11 in the normal repos
# older releases of ubuntu are not supported
case "$__os_codename" in
bionic | focal) ppa_name="ubuntu-toolchain-r/test" && ppa_installer ;;
esac

sudo apt install zenity cmake git build-essential gcc-11 g++-11 -y || error "Could not install dependencies"
cd
rm -rf box64
git clone --depth=1 https://github.com/ptitSeb/box64
cd box64
mkdir build
cd build

case "$dpkg_architecture" in
"arm64")
  case "$jetson_model" in
  "tegra-x1")
    cmake .. -DTEGRAX1=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_C_COMPILER=gcc-11
    echo "Tegra X1 based system"
    ;;
  *)
    cmake .. -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_C_COMPILER=gcc-11
    echo "Universal aarch64 system"
    ;;
  esac
  ;;
"amd64")
  cmake .. -DLD80BITS=1 -DNOALIGN=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_C_COMPILER=gcc-11
  echo "x86_64 based system"
  ;;
*) error "Something is very wrong... how did you get past the first check?" ;;
esac

echo "Building Box64"

make -j$(nproc) || error "Compilation failed"
sudo make install || error "Make install failed"
sudo systemctl restart systemd-binfmt
sudo mkdir /usr/share/box64
cd ..
sudo cp docs/img/Box64Icon.png /usr/share/box64/icon.png

echo "Adding box64 to applications list"
sudo tee /usr/share/applications/box64.desktop <<'EOF'
[Desktop Entry]
Type=Application
Exec=bash -c '/usr/local/bin/box64 "$(zenity --file-selection)"'
Name=Box64
Icon=/usr/share/box64/icon.png
Terminal=hidden
Categories=Game;System
EOF

echo "Adding box64 application helper to list"
sudo tee /usr/share/applications/box64_helper.desktop <<'EOF'
[Desktop Entry]
Type=Application
Exec=bash -c 'bash <( wget -O - https://raw.githubusercontent.com/cobalt2727/L4T-Megascript/master/assets/Box64/box64_program_helper.sh )'
Name=Box64 Application Helper
Icon=/usr/share/box64/icon.png
Terminal=hidden
Categories=System
EOF

rm -rf ~/box64

echo "Box64 successfully installed"
echo ""
echo "Start box64 from the applications list and select the x86_64 program or"
echo "start programs by typing 'box64 /path/to/my/application' in terminal"
sleep 3
