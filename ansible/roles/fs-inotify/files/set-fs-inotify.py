import os

def get_total_ram_memory():
    try:
        with open('/proc/meminfo', 'r') as meminfo_file:
            for line in meminfo_file:
                if line.startswith('MemTotal'):
                    total_memory_kb = int(line.split()[1])
                    return total_memory_kb
    except Exception as e:
        print(f"An error occurred: {e}")
        return None

# System defaults for comparison
default_max_user_instances = 128
default_max_queued_events = 16384
default_max_user_watches = 8192

# Total available memory in KB for the inotify settings
available_memory_kb = get_total_ram_memory()

# Calculate the total "weight" based on default values to keep the same ratio
total_weight = default_max_user_watches + default_max_user_watches + default_max_user_watches

# Calculate how much memory each "unit" represents
memory_per_unit = available_memory_kb / total_weight

# Allocate memory based on the original ratio
os.system("sysctl -w fs.inotify.max_user_watches=%s" %int(memory_per_unit * default_max_user_watches))
os.system("sysctl -w fs.inotify.max_user_instances=%s" %int(memory_per_unit * default_max_user_instances))
os.system("sysctl -w fs.inotify.max_queued_events=%s" %int(memory_per_unit * default_max_queued_events))
