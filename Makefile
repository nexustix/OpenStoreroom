.PHONY: all debug clean build-dir run

targets := $(wildcard src/*.fnl)

all: build-dir $(targets)

clean:
	rm -rf ./build

build-dir:
	mkdir -p build

#FIXME
src/*.fnl: build-dir
	fennel --compile src/$(@F) | tee build/$(basename $(@F)).lua

patch:
	echo 'local args = {...}' | cat - build/fetcher-standalone.lua > temp && mv temp build/fetcher-standalone.lua

deploy: all patch
	cp --remove-destination ./build/* `sed '2q;d' ./deploy.txt`

debug: all patch
	cp --remove-destination ./build/* `sed '4q;d' ./deploy.txt`
