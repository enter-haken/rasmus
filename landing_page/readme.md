# landing page

The rasmus landing page is used for showing some examples.
Currently this site is not used.

## build requirements

* yarn >= 1.6.0
* gulp >= 3.9.1

## build

    $ make

This will install the node packages if necessary and build the page.
The target of the page is the `./dist` directory

## clean

    $ make clean

The folder `./dist` will be removed.

## deep_clean 

    $ make deep_clean

The folder `./node_modules` and `./dist` will be deleted.

## deploy

The content of the `./dist` folder will be copied to the `../docs` folder.
The `../docs` folder contains all files for the github project page.

## all

    $ make all

This will execute the make targets `clean`, `build` and `deploy`

# contact

Jan Frederik Hake, <jan_hake@gmx.de>. [@enter_haken](https://twitter.com/enter_haken) on Twitter.

