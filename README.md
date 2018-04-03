# archapp
Deploy archifiltre app with docker stack

To (start\|update\|stop\|restart) the app :

```bash
# default target is update
make (start|update|stop|restart)
```

To start the app in local/dev mode, instead of **make start**, use :

```bash
make dev
```

Don't forget to change the **domain** makefile variable with your domain name.