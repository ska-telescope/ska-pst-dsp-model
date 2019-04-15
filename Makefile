MATLAB_CC=mcc
BUILD_DIR=build/

.PHONY: clean

channelize: matlab/channelize.m
	$(MATLAB_CC) -m $^ -d $(BUILD_DIR)

pipeline: matlab/pipeline.m
	$(MATLAB_CC) -m $^ -d $(BUILD_DIR)

synthesize: matlab/synthesize.m
	$(MATLAB_CC) -m $^ -d $(BUILD_DIR)

generate_test_vector: matlab/generate_test_vector.m
	$(MATLAB_CC) -m $^ -d $(BUILD_DIR)

clean:
	rm build/*
