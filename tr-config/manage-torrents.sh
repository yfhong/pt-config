#!/bin/sh
# https://community.wd.com/t/guide-auto-removal-of-downloads-from-transmission-2-82/93156
# script to check for complete torrents in transmission folder, then stop and move them
# either hard-code the MOVEDIR variable here…
# MOVEDIR=/home/amhiserver/.box # the folder to move completed downloads to
# …or set MOVEDIR using the first command-line argument
# MOVEDIR=%1
#


__errmsg() {
	echo "tr-torrent-manage: $*" >&2
}


tr_torrent_manage_usage() {
	cat >&2 <<EOF
Usage: tr-torrent-manage [options]

    -h, --help      Show this help message then exit

EOF
}


# User define constants
# Remote server with auth info.
# port, username, password
SERVER="192.168.100.99:9091 --auth homer:qwer1234"

# Get all torrents
# transmission-remote $SERVER --list
#
# use sed to delete first / last line of output, and remove leading spaces
# use cut to get first field from each line
TORRENTLIST=\
    $(transmission-remote "$SERVER" --list \
                    | sed -e '1d;$d;s/^ *//' \
                    | cut -d" " -f1)

LOG_DIR="$PWD/logs"
LOG_FILE_NAME="tr-torrent-manage.log"

TR_PT_ARCHIVED_DIR_BASE="/tank/nas/pt"
TR_PT_DL_DIR_BASE="/tank/nas/pt/_tr_down"

__size_of_file() {
    case "$(uname)" in
        FreeBSD) return "$(stat -f%z $1)" ;;
        Linux) return "$(stat -c%s $1)" ;;
        *) return -1;;
    esac
}

__log_rotate() {
    local _logfile="$LOG_DIR"/"$LOG_FILE_NAME"
    local _log_file_count=\
        $(find "$LOG_DIR" -maxdepth 1 -name "$LOG_FILE_NAME*" | wc -l)

    ## logrotate
    if [ -f "$_logfile" ] && [ "$(__size_of_file $_logfile)" -gt 100000 ]; then
        local i=$_log_file_count;
        while [ $i -ge 1 ]; do
            if [ -f "$_logfile"."$i" ]; then
                mv "$_logfile"."$i" "$_logfile"."$(($i+1))"
            fi
        done
        mv "$_logfile" "$_logfile"."1"
    fi

    ## create logfile
    if ! [ -f "$_logfile" ]; then
        touch "$_logfile"
        chmod 644 "$_logfile"
    fi
}

__log() {
    local _log_msg=$1
    local _logfile="$LOG_DIR"/"$LOG_FILE_NAME"

    ## create logfile
    if ! [ -f "$_logfile" ]; then
        touch "$_logfile"
        chmod 644 "$_logfile"
    fi

    ## log it
    local _timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$_timestamp] $_log_msg" >> "$_logfile"
}

# Add labels
_add_label() {
    local torrent_id = $1
    local label_to_add = $2
    local current_labels
}
# for each torrent in the list
for TORRENTID in $TORRENTLIST
do
  TORRENTID=$(echo "$TORRENTID" | sed -e 's:*::')
  # removes asterisk * from torrent ID# which had error associated with it
  echo "$TORRENTID"
  # check if torrent download is completed
  DL_COMPLETED=$(transmission-remote "$SERVER" --torrent "$TORRENTID" --info | grep "Percent Done: 100%")
  echo "$DL_COMPLETED"
  # check torrent's current state is "Stopped", "Finished", or "Idle"
  STATE_STOPPED=$(transmission-remote "$SERVER" --torrent "$TORRENTID" --info | grep "State: Stopped\|Finished\|Idle")
  #(transmission-remote --torrent 1 --info | grep "Error: No data found! Ensure your drives are connected")
  echo "$STATE_STOPPED"
  # get torrent's saved directory
  TORRENT_CURRENT_DIR=$(transmission-remote "$SERVER" --torrent "$TORRENTID" --info | grep "Location" | sed 's/^ *//' | cut -d' ' -f2)
  target_dir="/tank/nas/pt/_move_from_mihuan"
  _check_dir = "${TORRENT_CURRENT_DIR#*$target_dir}"
  echo "$TORRENT_CURRENT_DIR ---- $_check_dir"
  # if the torrent is "Stopped", "Finished", or "Idle" after downloading 100%…
  if [ "$DL_COMPLETED" != "" ] && [ "$STATE_STOPPED" != "" ] && [ "$_check_dir" != "$TORRENT_CURRENT_DIR" ]; then
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
    transmission-remote "$SERVER" --torrent "$TORRENTID" --move "/tank/nas/pt/_tr_down"
  else
    echo "Torrent #$TORRENTID is not completed. Ignoring."
  fi
  echo "* * * * * Operations on torrent ID $TORRENTID completed. * * * * *"
done
