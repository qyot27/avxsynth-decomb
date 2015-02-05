project(Decomb)
cmake_minimum_required(VERSION 2.8)

find_path(AVXSYNTH_INCLUDE_DIR avxsynth/avxplugin.h)
include_directories(${AVXSYNTH_INCLUDE_DIR})

enable_language(ASM_NASM)

add_definitions(-DAVXSYNTH -D_AMD64_)
add_library(decomb SHARED src/asmfuncsYUY2.asm src/AvisynthPluginInit.cpp src/Decimate.cpp src/DecimateYUY2.cpp src/FieldDeinterlace.cpp src/FieldDeinterlaceYUY2.cpp src/Telecide.cpp src/Utilities.cpp)
