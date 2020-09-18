###################
# PARAMETERS TO MODIFY
IMAGE_NAME = image_name
IMAGE_TAG = 1.0
###################
# FIXED PARAMETERS
TEST_FOLDER = src/tests
FORMAT_FOLDER = src
DOCKER_RUN = docker run -it --entrypoint=bash -w /home -v $(PWD):/home/
DOCKER_IMAGE = $(IMAGE_NAME):$(IMAGE_TAG)
DOCKERFILE_PIPTOOLS = Dockerfile_piptools
DOCKER_IMAGE_PIPTOOLS = piptools:1.0
###################

#
# build image
#
.PHONY : build
build: .build

.build: Dockerfile requirements.txt
	$(info ***** Building Image *****)
	docker build -t $(DOCKER_IMAGE) .
	@touch .build

requirements.txt: .build_piptools requirements.in
	$(info ***** Pinning requirements.txt *****)
	$(DOCKER_RUN) $(DOCKER_IMAGE_PIPTOOLS) -c "pip-compile --output-file requirements.txt requirements.in"
	@touch requirements.txt

.build_piptools: Dockerfile_piptools
	$(info ***** Building Image piptools:1.0 *****)
	docker build -f $(DOCKERFILE_PIPTOOLS) -t $(DOCKER_IMAGE_PIPTOOLS) .
	@touch .build_piptools

.PHONY : upgrade
upgrade:
	$(info ***** Upgrading dependencies *****)
	$(DOCKER_RUN) $(DOCKER_IMAGE_PIPTOOLS) -c "pip-compile --upgrade --output-file requirements.txt requirements.in"
	@touch requirements.txt

#
# Run commands
#
.PHONY : run
run: build
	$(info ***** Running *****)
	$(DOCKER_RUN) $(DOCKER_IMAGE)  -c "cd src; python hello_world.py"

.PHONY : shell
shell: build
	$(info ***** Creating shell *****)
	$(DOCKER_RUN) $(DOCKER_IMAGE)

.PHONY : notebook
notebook: build
	$(info ***** Starting a notebook *****)
	$(DOCKER_RUN) -p 8888:8888 $(DOCKER_IMAGE) -c "jupyter notebook --ip=$(hostname -I) --no-browser --allow-root"

#
# Testing
#
.PHONY : tests
tests: build
	$(info ***** Running all unit tests *****)
	$(DOCKER_RUN) $(DOCKER_IMAGE) -c "pytest -v --rootdir=$(TEST_FOLDER)"

#
# Formatting
#
.PHONY : format
format: build
	$(info ***** Formatting: running isort *****)
	$(DOCKER_RUN) $(DOCKER_IMAGE) -c "isort -rc $(FORMAT_FOLDER)"
	$(info ***** Formatting: running black *****)
	$(DOCKER_RUN) $(DOCKER_IMAGE) -c "black $(FORMAT_FOLDER)"

#
# Cleaning
#
.PHONY : clean
clean:
	$(info ***** Cleaning files *****)
	rm -rf .build .build_piptools requirements.txt
