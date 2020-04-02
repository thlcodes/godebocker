# GoDebocker

Dockerized Go (golang) debugger helper using [delve](https://github.com/go-delve/delve), optimized for usage with VSCode.

# Motivation

Being able to debug (preferably) a go app that is part of (i.e. with the network of) a distributed, locally running (containerized via e.g. docker-compose) system.

# What this is

Basically this runs a debuggable go binary via `delve exec ...` within a docker container.

By default, this expects an debuggable binary (exec mode)), but can also build the binary before debugging for your (build mode).

Both in build mode and exec mode all files have to be mounted manually (e.g. via `docker run` or `docker-compose`)

IMPORTANT: expose the delve port, otherwise there is no way to connect to it from the host.

## Environment variables

- __DLVPORT__: delve server port _(default: 4040)_
- __BINARY__: path of the debug binary absolute or relative to the workdir _(default: "./bin")_
- __ARGS__: arguments for the debug binary _(default: "")_
- __WORKDIR__: work dir within the container _(default: "/app")_
- __BEGIN_MSG__: message to print when GoDebocker is ready to start delve _(default: "godebocker started")_
- __DLV_LOG__: whether to enable delve debug logs _(default: false)_
- __CONTINUE__: whether delve shall continue on start _(default: true)_
- __PORT__: good old port env, may be used by the debug binary _(default: 8080)_
- __BUILD__: whether to build the sources before debugging _(default: false)_
- __GOPRIVATE__: see [here](https://tip.golang.org/cmd/go/#hdr-Module_configuration_for_non_public_modules) (default: "")_
- __CGO_ENABLED__:see [here](https://golang.org/cmd/cgo/) _(default: 0)_
- __SSH_KEY__: private ssh key to write to `~/.ssh/id_rsa`, will be removed after the build (fail & success) _(default: "")_
- __KNOWN_HOSTS__: ssh's known_hosts file _(default: "")_

## Usage

### Exec mode

With default settings (see above)
```sh
docker run -it --rm -v "$(pwd):/app" -p 4040:4040 thlcodes/godebocker

```

With custom delve port, binary path, workdir, log config & some args, all in a specific existing docker network 
```sh
docker run -it --rm -v "$(pwd):/myapp" -p 4040:4040 --network mynetwork --name myapp-debug -e ENV=development -e BINARY=./debug -e ARGS="--mode=2 --silent" -e WORKDIR="/myapp/build" thlcodes/godebocker

```

### Build mode

With default settings (see above), will build the debug binary to the default `$BINARY`
```sh
docker run -it --rm -v "$(pwd):/app" -p 4040:4040 -e BUILD=true thlcodes/godebocker

```

With custom settings for build & default settings subsequent exec:
- private repo for go modules in `github.com/myname/myrepo`, thus `GOPRIVATE` is set accordingly, 
- `known_hosts` with github's fingerprint for the private repo
- an ssh private key to access above repo via git ssh
- `replace` entry in `go.mod` pointing to another go module with this parent's dir (this is why ``` $(pwd)/..``` is mounted),
  - e.g. `replace github.com/myname/mylibrary => ../mylibrary`
- persistent volume pointing to `$GOPATH` to cache go dependencies to speed up subsequent builds
  - create with `docker volume create godebockercache`
```sh
docker run -it --rm -v "$(pwd)/..:/myproject" -p 4040:4040 --name myapp-debug -e ENV=development -e BUILD=true -e WORKDIR=/myproject/myapp -e SSH_KEY="$(<~./github.key)" -e KNOWN_HOSTS="$(ssh-keyscan github.com)" -v "godebockercache:/go" godebocker
er

```

### Debug with VSCode

See configuration in [examples/.vscode](./examples/.vscode).

## License

MIT. Do whatever you want.