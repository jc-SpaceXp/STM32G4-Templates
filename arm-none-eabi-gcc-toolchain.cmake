set(CROSS_TOOLCHAIN arm-none-eabi)
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR ARM)

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(CMAKE_C_COMPILER ${CROSS_TOOLCHAIN}-gcc CACHE INTERNAL "C compiler")
set(CMAKE_ASM_COMPILER ${CROSS_TOOLCHAIN}-as CACHE INTERNAL "ASM compiler")
set(CMAKE_OBJCOPY ${CROSS_TOOLCHAIN}-objcopy CACHE INTERNAL "Objcopy tool")
set(CMAKE_SIZE_UTIL ${CROSS_TOOLCHAIN}-size CACHE INTERNAL "Size tool")

set(CPUFLAGS "-mcpu=cortex-m4;-mthumb")
set(FPUFLAGS "-mfloat-abi=hard;-mfpu=fpv4-sp-d16")
set(SIZEFLAGS "-ffunction-sections;-fdata-sections")

set(LINKER_SCRIPT ${CMAKE_CURRENT_LIST_DIR}/STM32G431KBTX_FLASH.ld)
set(LINKER_NOSYS -Wl,--start-group -lc -lgcc -lnosys -Wl,--end-group)
set(LINKER_MAPFILE -Wl,-Map=main.map,--cref)
set(LINKER_SECTIONS -Wl,--gc-sections)
