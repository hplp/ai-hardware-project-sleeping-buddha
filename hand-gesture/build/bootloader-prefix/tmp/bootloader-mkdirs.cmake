# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.5)

file(MAKE_DIRECTORY
  "/Users/afsarabenazir/esp/esp-idf-v4.4/components/bootloader/subproject"
  "/Users/afsarabenazir/Downloads/Blogs/ESP-DL/sample_project/build/bootloader"
  "/Users/afsarabenazir/Downloads/Blogs/ESP-DL/sample_project/build/bootloader-prefix"
  "/Users/afsarabenazir/Downloads/Blogs/ESP-DL/sample_project/build/bootloader-prefix/tmp"
  "/Users/afsarabenazir/Downloads/Blogs/ESP-DL/sample_project/build/bootloader-prefix/src/bootloader-stamp"
  "/Users/afsarabenazir/Downloads/Blogs/ESP-DL/sample_project/build/bootloader-prefix/src"
  "/Users/afsarabenazir/Downloads/Blogs/ESP-DL/sample_project/build/bootloader-prefix/src/bootloader-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/Users/afsarabenazir/Downloads/Blogs/ESP-DL/sample_project/build/bootloader-prefix/src/bootloader-stamp/${subDir}")
endforeach()
