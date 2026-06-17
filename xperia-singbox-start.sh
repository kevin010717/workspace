URL='https://30e9533d6d5c2e91c98c9b9e31cd9086.alicdn.sbs/alicdn.com/1729753854'
su -c /data/adb/modules/netproxy/scripts/cli service stop
su -c "/data/adb/modules/netproxy/scripts/cli sub add yep '$URL'"
su -c /data/adb/modules/netproxy/scripts/cli sub update-all
su -c '/data/adb/modules/netproxy/scripts/cli node use "Auto-Fastest"'

su -c /data/adb/modules/netproxy/scripts/cli service restart
su -c '/data/adb/modules/netproxy/scripts/cli mode rule'
su -c '/data/adb/modules/netproxy/scripts/cli api groups'
su -c /data/adb/modules/netproxy/scripts/cli node list
