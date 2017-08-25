Test
====

```
Xephyr -ac -br -noreset -screen 1152x720 :1 &
DISPLAY=:1.0 awesome -c ./rc.lua.new
```
