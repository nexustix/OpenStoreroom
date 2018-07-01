# OpenStoreroom

### files

- poser.fnl - manages single transposers
- cluster.fnl - manages group of transposers and exposes them as a whole
- util-stack.fnl - utillities to deal with stack data
- fetcher-server.fnl - non-production proof of concept of a headless implementation
- fetcher-standalone.fnl - simple example program to utillize the storage system

### building

`make`

### deploying

#### simple:

Create a deploy.txt file, or just copy the example

`cp deploy.txt.example deploy.txt`

Change the (absolute) paths inside the deploy.txt to point towards the folder you want to deploy to

example deploy.txt file:

```
deploy:
/home/bernhard/this/as/my_deploy
debug:
/home/bernhard/this/as/my_debug
```

#### advanced:
manually customize the Makefile to your liking
