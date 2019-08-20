#!/usr/bin/env bash

###### CONFIGS ######

fst_lvl=clang-llvm
llvm_proj="http://llvm.org/git/llvm.git"
clang_proj="http://llvm.org/git/clang.git"
clang_proj_extra="http://llvm.org/git/clang-tools-extra.git"

plugin=reduction

#####################
pwd_root=`pwd`;
log_file=$pwd_root/start.sh.log

function _shout ()
{
  #red=;
  #blue=;
  #nc=;

  if [ "$1" == "eonly" ]; then
    echo "$2";
  elif [ "$1" == "fonly" ]; then
    echo "$2" >> $log_file;
  else
    echo "$1" >> $log_file;
    echo "$1";
  fi
}

mkdir -p $fst_lvl
cd $fst_lvl
_shout "Cloning llvm project"
git clone $llvm_proj;
[ $? -eq 0 ] || exit $?;

cd llvm/tools
_shout "Cloning clang project"
git clone $clang_proj;
[ $? -eq 0 ] || exit $?;

cd clang/tools
_shout "Cloning clang extra project"
git clone $clang_proj_extra extra;
[ $? -eq 0 ] || exit $?;

_shout "Done cloning stuff"

_shout "Starting build process"
cd $pwd_root/$fst_lvl;
mkdir build
cd build

_shout "Changing CMakeList.txt"
sed -i "93,94{s|\.\./|\.\./llvm/tools/|}" ../llvm/CMakeLists.txt
[ $? -eq 0 ] || exit $?;

_shout "Run cmake"
cmake -G "Unix Makefiles" ../llvm -DLLVM_ENABLE_PROJECTS=clang -DLLVM_BUILD_TESTS=ON  # Enable tests; default is off.
[ $? -eq 0 ] || exit $?;

_shout "Running make"
make
_re=$?
_shout "make: $_re
[ $_re -eq 0 ] || exit $_re

_shout "Running make check"
make check
_re=$?
_shout "make: $_re
[ $_re -eq 0 ] || exit $_re

_shout "Running make clang-test"
make clang-test
_re=$?
_shout "make: $_re
[ $_re -eq 0 ] || exit $_re


_shout "Time to make instalation (y/N)"
read -n 1 ANS;
case "$ANS" in
  [yY]*)
    ;;
  [nN]*)
    ;;
  *)
    _msg eonly "assming no"
    ;;
esac

cd $pwd_root/$fst_lvl/build
_shout "Starting cmake.."
cmake -D CMAKE_CXX_COMPILER="`pwd`/`ls bin/clang++`"
[ $? -eq 0 ] || exit $?;

echo "`pwd`/`ls bin/clang++`"
read -n 1 N
exit 0

_shout "..cmake is done"

_shout "Time to add the plugin to the project"
cd $pwd_root/$fst_lvl/llvm/tools/clang
mkdir tools/extra/$plugin
echo 'add_subdirectory('"$plugin"')' >> tools/extra/CMakelists.txt
[ $? -eq 0 ] || exit $?;

cp $pwd_root/generic-CMakeLists.txt ./tools/extra/$plugin/CMakeList.txt

sed -i "s/plugin/$plugin/" "./tools/extra/$plugin/CMakeLists.txt"
[ $? -eq 0 ] || exit $?;

_shout "Run the plugin"
cd $pwd_root/$fst_lvl/build
make
[ $? -eq 0 ] || exit $?;

_shout eonly "Run the plugin"
_shout eonly "./bin/reduction your-test-file.cpp --"
_shot "FINISHED"


