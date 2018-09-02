## Install

```
./install
```

## Features

### Amixer

- turn down
- turn up
- toogle

### Tag

- add new a tag
- delete a tag
- rename a tag
- swap two tags
- move a tag to a new tag

## Test

```
Xephyr -ac -br -noreset -screen 1152x720 :1 &
DISPLAY=:1.0 awesome -c ./rc.lua
```
