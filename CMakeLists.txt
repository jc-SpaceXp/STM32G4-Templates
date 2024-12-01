cmake_minimum_required(VERSION 3.21)
project(STM32G4-Templates LANGUAGES C ASM)

if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux")
	set(CMAKE_EXECUTABLE_SUFFIX .elf)
endif()

set(CMAKE_C_STANDARD 11)

set(CMAKE_VERBOSE_MAKEFILE OFF)


set(SRCTARGET template)
set(TSTTARGET test_template)

set(FLASHUTIL st-flash)

set(SRCDIR ${CMAKE_SOURCE_DIR}/src)
set(INCDIR inc)
set(LIBDIR lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${LIBDIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${LIBDIR})

set(BASECMSISDIR "${LIBDIR}/cmsis")
set(STMHALDIR "${BASECMSISDIR}/stm32g4xx_hal_driver")
set(STMHALINC "${STMHALDIR}/Inc")
set(STMCMSISDIR "${BASECMSISDIR}/cmsis_device_g4")
set(STMCMSISINC "${STMCMSISDIR}/Include")
set(ARMCMSISDIR "${BASECMSISDIR}/CMSIS_6/CMSIS/Core")
set(ARMCMSISINC "${ARMCMSISDIR}/Include")
set(BSPDIR "${BASECMSISDIR}/stm32g4xx-nucleo-bsp")
set(CMSISMODULES "${STMHALDIR} ${STMCMSISDIR} ${BSPDIR} ${BASECMSISDIR}/CMSIS_6")

set(COMMON_CFLAGS "-Wall;-Wextra;-g3;-Os")
set(CMSIS_CPPFLAGS "-DUSE_HAL_DRIVER;-DUSE_NUCLEO_32;-DSTM32G431xx")
set(CMSIS_INCLUDES ${STMHALINC} ${STMCMSISINC} ${ARMCMSISINC} ${BSPDIR})


set(STARTUPFILE "${STMCMSISDIR}/Source/Templates/gcc/startup_stm32g431xx.s")
set(SYSFILE "${STMCMSISDIR}/Source/Templates/system_stm32g4xx.c")
set(STMHALSRCS "${STMHALDIR}/Src/stm32g4xx_hal.c")
string(APPEND STMHALSRCS ";${STMHALDIR}/Src/stm32g4xx_hal_cortex.c")
string(APPEND STMHALSRCS ";${STMHALDIR}/Src/stm32g4xx_hal_gpio.c")
file(GLOB_RECURSE SRCS
	RELATIVE ${CMAKE_SOURCE_DIR}
	CONFIGURE_DEPENDS ${SRCDIR}/*.c
)

set(TSTDIR ${CMAKE_SOURCE_DIR}/tests)
set(MOCKLIBDIR "${LIBDIR}/FFF")
set(TESTLIBDIR "${LIBDIR}/greatest")
set(TSTSRCS "${TSTDIR}/all_tests.c;${TSTDIR}/suite_001.c")

# Sanity checks
if (${DEBUG_CMAKE})
	message("DEBUG_VARS (DIRS):\n"
		"SRCDIR ${SRCDIR}\n"
		"TSTDIR ${TSTDIR}\n"
		"INCDIR ${INCDIR}\n"
		"ARDIR ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}\n"
		"LIBDIR ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}\n"
		"BASECMSISDIR ${BASECMSISDIR}\n"
		"STMHALDIR ${STMHALDIR}\n"
		"STMHALINC ${STMHALINC}\n"
		"ARMCMSISDIR ${ARMCMSISDIR}\n"
		"ARMCMSISINC ${ARMCMSISINC}\n"
		"BSPDIR ${BSPDIR}\n"
		"CMSISMODULES ${CMSISMODULES}\n"
		"MOCKLIBDIR ${MOCKLIBDIR}\n"
		"TESTLIBDIR ${TESTLIBDIR}"
	)

	message("DEBUG_VARS (COMPILER FLAGS):\n"
		"COMMON_CFLAGS ${COMMON_CFLAGS}\n"
		"CMSIS_CPPFLAGS ${CMSIS_CPPFLAGS}"
	)
	if (${CMAKE_CROSSCOMPILING})
		message("CPUFLAGS ${CPUFLAGS}\n"
			"FPUFLAGS ${FPUFLAGS}\n"
			"SIZEFLAGS ${SIZEFLAGS}"
		)

		message("DEBUG_VARS (LINKER FLAGS):\n"
			"LINKER_SCRIPT ${LINKER_SCRIPT}\n"
			"LINKER_NOSYS ${LINKER_NOSYS}\n"
			"LINKER_MAPFILE ${LINKER_MAPFILE}"
		)
	endif()

	message("DEBUG_VAR (FILE_GLOBS): SRCS == ${SRCS}")
	message("DEBUG_VAR (FILES): \n"
		"STMHALSRCS ${STMHALSRCS}\n"
		"SYSFILE ${SYSFILE}\n"
		"STATUPFILE ${STARTUPFILE}\n"
		"TSTSRCS ${TSTSRCS}"
	)
endif()


# STM32 section
if (${CMAKE_CROSSCOMPILING})
	add_library(stmcommon INTERFACE)

	target_compile_options(stmcommon INTERFACE
		${COMMON_CFLAGS}
		${CMSIS_CPPFLAGS}
		${CPUFLAGS}
		${FPUFLAGS}
		${SIZEFLAGS}
	)

	add_library(stmhal ${STMHALSRCS})

	target_include_directories(stmhal PRIVATE
		${INCDIR}
		${CMSIS_INCLUDES}
	)

	add_library(startup ${STARTUPFILE})

	target_compile_options(startup PRIVATE
		-D
		--warn
		${CPUFLAGS}
		-g
	)

	add_library(sysfile ${SYSFILE})

	target_include_directories(sysfile PRIVATE
		${INCDIR}
		${CMSIS_INCLUDES}
	)

	add_executable(${SRCTARGET} ${SRCS})

	target_include_directories(${SRCTARGET} PRIVATE
		${INCDIR}
		${CMSIS_INCLUDES}
	)

	target_link_options(${SRCTARGET} PRIVATE
		-T ${LINKER_SCRIPT}
		${LINKER_NOSYS}
		${LINKER_MAPFILE}
		${CPUFLAGS}
		${FPUFLAGS}
	)

	target_link_libraries(stmhal PRIVATE stmcommon)
	target_link_libraries(sysfile PRIVATE stmcommon)
	target_link_libraries(${SRCTARGET} PRIVATE stmcommon stmhal startup sysfile)

	add_custom_command(TARGET ${SRCTARGET} POST_BUILD
		COMMAND ${CMAKE_SIZE_UTIL} "$<TARGET_FILE_NAME:${SRCTARGET}>"
		COMMENT "Executable size"
	)

	add_custom_command(TARGET ${SRCTARGET} POST_BUILD
		COMMAND ${CMAKE_OBJCOPY} -O binary "$<TARGET_FILE_NAME:${SRCTARGET}>" "${SRCTARGET}.bin"
		COMMENT "Binary generation (for flashing) --> $<TARGET_FILE_BASE_NAME:${SRCTARGET}>.bin"
	)
else ()
	# Unit test section
	enable_testing()

	add_executable(${TSTTARGET} ${TSTSRCS})
	add_test(NAME ${TSTTARGET} COMMAND ${TSTTARGET})

	target_compile_options(${TSTTARGET} PRIVATE
		${COMMON_CFLAGS}
		${CMSIS_CPPFLAGS}
	)

	target_include_directories(${TSTTARGET} PRIVATE
		${TSTDIR}
		${MOCKLIBDIR}
		${TESTLIBDIR}
		${INCDIR}
	)
endif()

# St-util flashing commands
add_custom_target(flash-write
	COMMAND ${FLASHUTIL} --flash=128k write "$<TARGET_FILE_BASE_NAME:${SRCTARGET}>.bin" 0x08000000
	DEPENDS "$<TARGET_FILE_BASE_NAME:${SRCTARGET}>.bin"
	COMMENT "Flashing $<TARGET_FILE_BASE_NAME:${SRCTARGET}>.bin to STM32 device"
)

add_custom_target(flash-erase
	COMMAND ${FLASHUTIL} erase
	COMMENT "Erasing flash on STM32 device"
)

add_custom_target(flash-backup
	COMMAND ${FLASHUTIL} read BIN_BACKUP.bin 0x08000000 0x20000
	COMMENT "Backing up flash from STM32 device"
)

unset(CMAKE_TOOLCHAIN_FILE)
unset(DEBUG_CMAKE CACHE)
