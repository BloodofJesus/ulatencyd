SCHEDULER_MAPPING_DESKTOP = { 
  {
    name = "system_essential",
    cgroups_name = "s_essential",
    param = { ["cpu.shares"]="3048" },
    label = { "system.essential" }
  },
  {
    name = "user",
    cgroups_name = "u_${euid}",
    check = function(proc)
              return ( proc.euid > 999 )
            end,
    param = { ["cpu.shares"]="3048" },
    children = {
      { 
        name = "poison",
        param = { ["cpu.shares"]="10" },
        label = { "user.poison" },
        cgroups_name = "p_${pid}",
        check = function(proc)
                  print("poison detected", proc)
                  return true
                end,
        adjust = function(cgroup, proc)
                end,
        adjust_new = function(cgroup, proc)
                print("adjust_new",cgroup, proc)
                cgroup:add_task(proc.pid)
                cgroup:commit()
                bytes = cgroup:get_value("memory.usage_in_bytes")
                print("bytes" .. tostring(bytes))
                if not bytes then
                  ulatency.log_warning("can't access memory subsystem")
                  return
                end
                bytes = math.floor(bytes-((bytes/100)*5))
                print("bytes" .. tostring(bytes))
                cgroup:set_value("memory.soft_limit_in_bytes", bytes)
                cgroup:commit()
                --pprint(cgroup)
                --ulatency.quit_daemon()
                end
      },
      { 
        name = "bg_high",
        param = { ["cpu.shares"]="1024" },
        label = { "user.bg_high" },
        check = function(proc)
                  print("classived, ui.bg_high", proc)
                  return true
                end,
      },
      { 
        name = "media",
        param = { ["cpu.shares"]="2048" },
        label = { "user.media" },
        check = function(proc)
                  print("classived, ui.media", proc)
                  return true
                end,
      },
      { 
        name = "ui",
        param = { ["cpu.shares"]="2048" },
        label = { "user.ui" }
      },
      { 
        name = "idle",
        param = {  },
      },
      { 
        name = "session",
        param = { ["cpu.shares"]="600" },
        cgroups_name = "${session}",
        check = function(proc)
                  return true
                end,
      },
    },
  },
  {
    name = "system",
    cgroups_name = "s_daemon",
    check = function(proc)
              -- don't put kernel threads into a cgroup
              return (proc.ppid ~= 0 or proc.pid == 1)
            end,
    param = { ["cpu.shares"]="800" },
  },
}