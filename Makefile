MATLAB_CC=mcc
BUILD_DIR=build/

.PHONY: clean

channelize: channelize.m
	$(MATLAB_CC) -m $^ -d $(BUILD_DIR)

synthesize: synthesize.m
	$(MATLAB_CC) -m $^ -d $(BUILD_DIR)

generate_test_vector: generate_test_vector.m
	$(MATLAB_CC) -m $^ -d $(BUILD_DIR)

clean:
	rm build/*
