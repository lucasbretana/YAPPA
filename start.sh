#!/usr/bin/env bash

###### CONFIGS ######

fst_lvl=clang-llvm;
llvm_proj="http://llvm.org/git/llvm.git";
clang_proj="http://llvm.org/git/clang.git";
clang_proj_extra="http://llvm.org/git/clang-tools-extra.git";

plugin=reduction;

#####################
pwd_root=$(pwd);
log_file="$pwd_root"/start.sh.log;

function _shout ()
{
  #red=;
  #blue=;
  #nc=;

  local _t="[";
  _t+="$(date '+%d.%m-%H:%M:%S')";
  _t+="]";

  if [ "$1" == "fonly" ]; then
    echo "$_t" >> "$log_file";
    echo "$2" >> "$log_file";
  else
    echo "$_t" >> "$log_file";
    echo "$1" >> "$log_file";
    echo "$_t";
    echo "$1";
  fi
}

mkdir -p "$fst_lvl";
cd "$fst_lvl" || exit 10;
_shout "Cloning llvm project";
git clone "$llvm_proj";
[ $? -eq 0 ] || exit $?;

cd llvm/tools || exit 11;
_shout "Cloning clang project";
git clone "$clang_proj";
[ $? -eq 0 ] || exit $?;

cd clang/tools || exit 12;
_shout "Cloning clang extra project";
git clone "$clang_proj_extra" extra;
[ $? -eq 0 ] || exit $?;

_shout "Done cloning stuff";

_shout "Starting build process";
cd "$pwd_root"/"$fst_lvl" || exit 13;
mkdir build;
cd build || exit 14;

_shout "Changing CMakeList.txt";
sed -i "93,94{s|\.\./|\.\./llvm/tools/|}" ../llvm/CMakeLists.txt;
[ $? -eq 0 ] || exit $?;

_shout "Run cmake";
cmake -G "Unix Makefiles" ../llvm -DLLVM_ENABLE_PROJECTS=clang -DLLVM_BUILD_TESTS=ON ; # Enable tests; default is off.;
[ $? -eq 0 ] || exit $?;

_shout "Running make";
make;
_re=$?;
_shout "make: $_re";
[ $_re -eq 0 ] || exit $_re;

_shout "Running make check";
make check;
_re=$?;
_shout "make: $_re";
[ $_re -eq 0 ] || exit $_re;

_shout "Running make clang-test";
make clang-test;
_re=$?;
_shout "make: $_re";
[ $_re -eq 0 ] || exit $_re;


_shout "Time to make instalation (y/N)";
read -n 1 ANS;
case "$ANS" in
  [yY]*)
    _shout eonly "to implement";
    ;;
  [nN]*)
    _shout eonly "nothing todo";
    ;;
  *)
    _shout eonly "assuming no";
    _shout eonly "nothing todo";
    ;;
esac

cd "$pwd_root"/"$fst_lvl"/build || exit 15;
_shout "Starting cmake..";
cmake -DCMAKE_CXX_COMPILER="$(pwd)/$(ls bin/clang++)" ../llvm;
[ $? -eq 0 ] || exit $?;
_shout "..cmake is done";

_shout "Time to add the plugin to the project";
cd "$pwd_root"/"$fst_lvl"/llvm/tools/clang || exit 16;
mkdir -p tools/extra/"$plugin";
echo 'add_subdirectory('"$plugin"')' >> tools/extra/CMakelists.txt;
[ $? -eq 0 ] || exit $?;

cp "$pwd_root"/generic-CMakeLists.txt ./tools/extra/"$plugin"/CMakeList.txt;

sed -i "s/plugin/$plugin/" "./tools/extra/$plugin/CMakeLists.txt";
[ $? -eq 0 ] || exit $?;

_shout "Run the plugin";
cd "$pwd_root"/"$fst_lvl"/build || exit 17;
make;
[ $? -eq 0 ] || exit $?;

_shout eonly "Run the plugin";
_shout eonly "./bin/reduction your-test-file.cpp --";
_shot "FINISHED";


