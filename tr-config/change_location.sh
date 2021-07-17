#!/bin/sh
# https://community.wd.com/t/guide-auto-removal-of-downloads-from-transmission-2-82/93156
# script to check for complete torrents in transmission folder, then stop and move them
# either hard-code the MOVEDIR variable here…
# MOVEDIR=/home/amhiserver/.box # the folder to move completed downloads to
# …or set MOVEDIR using the first command-line argument
# MOVEDIR=%1
#
# auth
# port, username, password
# SERVER="localhost:9091 --auth osmc:osmc"
# transmission-remote $SERVER --list
#
# use sed to delete first / last line of output, and remove leading spaces
# use cut to get first field from each line
TORRENTLIST=$(transmission-remote --auth 'homer:qwer1234' --list | sed -e '1d;$d;s/^ *//' | cut -d" " -f1)
# for each torrent in the list
for TORRENTID in $TORRENTLIST
do
  TORRENTID=$(echo "$TORRENTID" | sed -e 's:*::')
  # removes asterisk * from torrent ID# which had error associated with it
  echo "$TORRENTID"
  # check if torrent download is completed
  DL_COMPLETED=$(transmission-remote --auth 'homer:qwer1234' --torrent "$TORRENTID" --info | grep "Percent Done: 100%")
  echo "$DL_COMPLETED"
  # check torrent's current state is "Stopped", "Finished", or "Idle"
  STATE_STOPPED=$(transmission-remote --auth 'homer:qwer1234' --torrent "$TORRENTID" --info | grep "State: Stopped\|Finished\|Idle")
  #(transmission-remote --torrent 1 --info | grep "Error: No data found! Ensure your drives are connected")
  echo "$STATE_STOPPED"
  # get torrent's saved directory
  #TORRENT_CURRENT_DIR=$(transmission-remote --auth 'homer:qwer1234' --torrent "$TORRENTID" --info | grep "Location" | sed 's/^ *//' | cut -d' ' -f2)
  #target_dir="/tank/nas/pt/_move_from_mihuan"
  #_check_dir = "${TORRENT_CURRENT_DIR#*$target_dir}"
  #echo "$TORRENT_CURRENT_DIR ---- $_check_dir"
  # if the torrent is "Stopped", "Finished", or "Idle" after downloading 100%…
  #if [ "$DL_COMPLETED" != "" ] && [ "$STATE_STOPPED" != "" ] && [ "$_check_dir" != "$TORRENT_CURRENT_DIR" ]; then
  if [ "$DL_COMPLETED" != "" ] && [ "$STATE_STOPPED" != "" ]; then
  # move the files and remove the torrent from Transmission
  # echo "Torrent #$TORRENTID is completed."
  # echo "Moving downloaded file(s) to $MOVEDIR."
  #transmission-remote --torrent $TORRENTID --move $MOVEDIR
    #echo "Removing torrent from list."
    #transmission-remote --auth 'homer:qwer1234' --torrent "$TORRENTID" --remove
    # copy .torrent file to archive directory.
    #TORRENT_HASH=$(transmission-remote --auth 'homer:qwer1234' --torrent "$TORRENTID" --info | grep 'Hash:' | sed -e 's/^ *//' | cut -d" " -f2)
    #echo "copy $TORRENT_HASH.torrent file to archive directory."
    #sudo -u transmission cp "/usr/local/etc/transmission/home/torrents/$TORRENT_HASH.torrent" "/tank/nas/pt/torrent_archived"
    transmission-remote --auth 'homer:qwer1234' --torrent "$TORRENTID" --move "/tank/nas/pt/_exchange"
    sudo cp 
  else
    echo "Torrent #$TORRENTID is not completed. Ignoring."
  fi
  echo "* * * * * Operations on torrent ID $TORRENTID completed. * * * * *"
done
