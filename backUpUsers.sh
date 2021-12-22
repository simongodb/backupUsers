#!/bin/bash




if [ -z "$1" ]
then
  echo "No arguments or incorrect argument(s) supplied. Please run with users.txt file"
  exit 1
fi

USERS_FILE=$1

# declaring array of users
declare -a ARRAY_USERS


#stdin replaced with a file supplied as a first argument
exec < $1
let count=0

while read LINE; do
   ARRAY_USERS[$count]=$LINE
   ((count++))
done

echo Number of users: ${#ARRAY_USERS[@]}

#echo array's content
echo ${ARRAY_USERS[@]}

for USER in "${ARRAY_USERS[@]}"
do
  echo "BACKUP OF ${USER}"
  USER_HOME=/home/${USER}

  # Verif user exists
  if [[ -d "${USER_HOME}" ]]
  then
    echo "USER path is ${USER_HOME}"
    # Create /tmp/backup/<user>
    mkdir -p "/tmp/backup/${USER}"
    
    # Verif backup exists
    if [[ -f "${USER_HOME}/.backup" ]]
    then
      BACKUP_FILE="${USER_HOME}/.backup"
      ls ${USER_HOME} > ${BACKUP_FILE}
      echo ".backup path is ${BACKUP_FILE}"

    # extract backup.tar to /tmp/backup
      if [ -f /var/backup.tar ]; then
        sudo tar -xf /var/backup.tar -C /tmp/backup/
        echo "backup.tar extracted to /tmp/backup"
      fi

      # loop through home directory and see uf files are diff with /tmp/backup/user
      ls ${USER_HOME} | while read FILE_NAME; do
        if [ -f "/tmp/backup/${USER}/${FILE_NAME}" ]; then
          DIFF=1
          cmp -s "tmp/backup/${USER}/${FILE_NAME}" "${USER_HOME}/${FILE_NAME}"
          DIFF=$?
  
          if [ ${DIFF} -ne 0 ]; then
            INDEX=1
            while [ -f "/tmp/backup/${USER}/${FILE_NAME}.${INDEX}" ]; do
              let INDEX=INDEX+1
            done
            # change file name adding+1  and copy latest version of file from home
            mv -v "/tmp/backup/${USER}/${FILE_NAME}" "/tmp/backup/${USER}/${FILE_NAME}.${INDEX}"  
            cp "${USER_HOME}/${FILE_NAME}" "/tmp/backup/${USER}"
            echo "Files from HOME moved to /tmp/backup/${USER} directory"
          fi
        else
        cp "${USER_HOME}/${FILE_NAME}" "/tmp/backup/${USER}"
        echo "Files from HOME moved to /tmp/backup/${USER} directory - FIRST VERSION"
        fi  
      done
      # Gzip to /var/backup.tar.gz
          cd /tmp/backup/
          tar -czf "backup.tar" "${USER}" 
          sudo mv "backup.tar" /var
          echo "backup has been Gzip to /var"     
    else
      echo "${USER_HOME}/.backup does not exist, creating file with 0 value"
      touch ${USER_HOME}/.backup
    fi  
  else
    echo "${USER_HOME} does not exist"
  fi  
  sleep 1
done
