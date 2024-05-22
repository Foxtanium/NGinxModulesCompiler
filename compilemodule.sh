#!/bin/bash
set -e

nginx_location=./nginx
modules_sources_location=./modules-src
nginx_binary_modules_location=/etc/nginx/modules


## End of modifieable UwU

echo "-------------------------------------------------------------"
echo "                 Nginx Module Compiler V2"
echo "               by @FoxieFlakey for Foxtanium"
echo "             Published and edited by @Fjox at"
echo "      https://github.com/Foxtanium/NGinxModuleCompiler"
echo "-------------------------------------------------------------"
echo ""
echo "We expect you to already have NGinx installed otherwisethe script doesnt work"
echo ""
neofetch
echo ""
echo "Installing dependencies if needed."
sudo apt install libpcre2-dev libpcre3-dev gcc git

nginx_binary_modules_location=$(realpath "$nginx_binary_modules_location")
nginx_location=$(realpath "$nginx_location")
modules_location=$(realpath "$modules_sources_location")
mkdir -p "$modules_location"

nginx_version=$(nginx -v 2>&1 | grep -Eo "nginx/(([0-9]|\.)+)+" | grep -Eo "[^/]+$")
echo "Nginx $nginx_version detected"

updateNginx=
if [ ! -d "$nginx_location" ]; then
  updateNginx="yes"
  echo "Nginx source not present at $nginx_location: Downloading"
fi

if [ x$(cat "$nginx_location/.nginx_version_uwu") != "x$nginx_version" ]; then
  updateNginx="yes"
  echo "Nginx source out of date at $nginx_location: Downloading"
  rm -rf "$nginx_location"
fi

if [ "x$updateNginx" == "xyes" ]; then
  # Get new nginx
  url="http://nginx.org/download/nginx-$nginx_version.tar.gz"
  echo "Getting Nginx at $url"
  mkdir -p "$nginx_location"

  wget "$url" -O - | tar zx --directory "$nginx_location"
  innerDirectory="$nginx_location/nginx-$nginx_version"
  (find "$innerDirectory" -mindepth 1 -maxdepth 1; echo "$nginx_location") | xargs mv
  rm -r "$innerDirectory"
  echo $nginx_version > $nginx_location/.nginx_version_uwu
fi

echo "Paste github links here, then press Ctrl+D when done."

location=0
args=""
commands=""
while IFS=$'\n' read -r line; do
  path=$(realpath "$modules_location/$location")
  location=$(($location + 1))
  args="$args --add-dynamic-module=$path"
  
  rm -rf "$path"
  commands="$commands git clone --recursive --depth=1 \"$line\" \"$path\"; "
done

if [ -z "$commands" ]; then
  echo "No github links pasted exiting UwU"
  exit 0
fi

bash -c "$commands"

# Do configure
cd "$nginx_location/"

cmd="./configure --with-compat --with-openssl=../openssl --with-zlib=../zlib $args"
$cmd

# Do make
rm -f "objs/*.so"
make -j$(nproc) modules

echo "----------------------"
echo "[Script] Copying files"
echo "----------------------"

mkdir -p "$nginx_binary_modules_location"

cd objs
addition=""
for FILE in $(find . -maxdepth 1 -regex ".+.so"); do
  echo "[Script] Copying $FILE to $nginx_binary_modules_location/$FILE UwU"
  addition="${addition}load_module $nginx_binary_modules_location/$FILE;\n"
  sudo cp "$FILE" "$nginx_binary_modules_location/$FILE"
done
cd ..

# Copy files
echo "-------------[[Copy this to /etc/nginx/nginx.conf]]-------------"
echo -ne "$addition"
echo "----------------------------------------------------------------"
