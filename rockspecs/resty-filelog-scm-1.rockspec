package = "resty-filelog"
version = "scm-1"
source = {
    url = "git://github.com/yebisu14/lua-resty-filelog.git"
}
description = {
    summary = "",
    homepage = "https://github.com/yebisu14/lua-resty-filelog",
    license = "MIT",
    maintainer = "Masatoshi Teruya"
}
dependencies = {
    "lua >= 5.1",
    "util >= 1.5.1"
}
build = {
    type = "builtin",
    modules = {
        ["resty.filelog"] = "filelog.lua"
    }
}
