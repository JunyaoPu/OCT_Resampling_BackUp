################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
CU_SRCS += \
../OCT-MPS-master/src/main.cu 

CPP_SRCS += \
../OCT-MPS-master/src/bias.cpp \
../OCT-MPS-master/src/mesh.cpp \
../OCT-MPS-master/src/octmps_io.cpp 

OBJS += \
./OCT-MPS-master/src/bias.o \
./OCT-MPS-master/src/main.o \
./OCT-MPS-master/src/mesh.o \
./OCT-MPS-master/src/octmps_io.o 

CU_DEPS += \
./OCT-MPS-master/src/main.d 

CPP_DEPS += \
./OCT-MPS-master/src/bias.d \
./OCT-MPS-master/src/mesh.d \
./OCT-MPS-master/src/octmps_io.d 


# Each subdirectory must supply rules for building sources it contributes
OCT-MPS-master/src/%.o: ../OCT-MPS-master/src/%.cpp
	@echo 'Building file: $<'
	@echo 'Invoking: NVCC Compiler'
	/usr/local/cuda-9.1/bin/nvcc -I/usr/local/cuda-9.1/samples/common/inc/ -G -g -O0 -gencode arch=compute_61,code=sm_61  -odir "OCT-MPS-master/src" -M -o "$(@:%.o=%.d)" "$<"
	/usr/local/cuda-9.1/bin/nvcc -I/usr/local/cuda-9.1/samples/common/inc/ -G -g -O0 --compile  -x c++ -o  "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

OCT-MPS-master/src/%.o: ../OCT-MPS-master/src/%.cu
	@echo 'Building file: $<'
	@echo 'Invoking: NVCC Compiler'
	/usr/local/cuda-9.1/bin/nvcc -I/usr/local/cuda-9.1/samples/common/inc/ -G -g -O0 -gencode arch=compute_61,code=sm_61  -odir "OCT-MPS-master/src" -M -o "$(@:%.o=%.d)" "$<"
	/usr/local/cuda-9.1/bin/nvcc -I/usr/local/cuda-9.1/samples/common/inc/ -G -g -O0 --compile --relocatable-device-code=false -gencode arch=compute_61,code=compute_61 -gencode arch=compute_61,code=sm_61  -x cu -o  "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


