name = "File commands"
description = "Add interactions to your game - execute commands from file"
author = "vanokh"
version = "0.1.0"

forumthread = ""

api_version = 10
priority = 9999

all_clients_require_mod = true
client_only_mod = false
dst_compatible = true

--icon_atlas = "fc_mod_icon.xml"
--icon = "fc_mod_icon.tex"

server_filter_tags = { "interaction" }

configuration_options =
{
    {
        name = "file_path",
        label = "Path to command file",
        options =
        {            
            {description = "Temp", data = "C:\\temp\\cmd.txt"},
            {description = "Documents", data = 2}
        },
        default = 2
    }
}
