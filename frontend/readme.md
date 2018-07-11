# rasmus frontend

The `rasmus` frontend uses [react][react] and [material ui][material]. 

# build

A call to

    $ make

will build the project.

    $ make deploy

will copy the build result to `../priv/static`.

    $ make all

will clean the `dist` folder, build the project and deploy the application to `../priv/static`.
Currently it is also possible to run the application localy without the backend.

    $ make run

For details, take a look at the `Makefile`.


# contact

Jan Frederik Hake, <jan_hake@gmx.de>. [@enter_haken](https://twitter.com/enter_haken) on Twitter.

[react]: https://reactjs.org/
[material]: https://material-ui.com/
