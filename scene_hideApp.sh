su -c 'am force-stop com.limelight.qiin'
su -c 'pm disable-user --user 0 com.limelight.qiin'
su -c 'pm enable com.limelight.qiin'
su -c "sh -c 'pm enable com.limelight.qiin && monkey -p com.limelight.qiin -c android.intent.category.LAUNCHER 1'"

su -c 'pm list packages | grep -i limelight'

su -c 'pm list packages -3'
su -c 'pm list packages'
su -c 'pm list packages -s'
su -c "sh -c 'pm list packages -3 | sort'"
