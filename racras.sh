rasServer=localhost:1545
rasPort=1545
version=8.3.10.2699
infobaseName=test1c
infobaseUser=""
infobasePwd=""
denniedMessage='Согласованы плановые работы. Установка релиза. Плановое время недоступности с 08:00 по 09:00 МСК 11.09.2019'
permissionCode="123"

lockInfobase=true
unlockInfobase=true
changeServerParams=false
timeRestart=10

pfx86=C:/Program\ Files\ \(x86\)/1cv8/$version/bin/rac.exe
pfx64=C:/Program\ Files/1cv8/$version/bin/rac.exe

pfx86result=$(ls "$pfx86" 2>1 | wc -l) 
pfx64result=$(ls "$pfx64" 2>1 | wc -l) 

if [[ $pfx86result != 0 ]]
then
    rac=$pfx86
elif [[ $pfx64result != 0 ]]
then
    rac=$pfx64
else
    echo "Не найдена компонента rac!" 1>&2
    exit 64
fi
echo "rac find in $rac"

clusterId=$("$rac" cluster list $rasServer | awk 'NR==1{print $3}')
echo "clusterId: $clusterId"

infobaseId=$("$rac" infobase summary list --cluster="$clusterId" $rasServer | grep -w -B 1 "$infobaseName" | sed -n "/infobase/p" | awk '{print $3}')
echo "infobaseId: $infobaseId"

if [[ $lockInfobase = true ]]
then

    if [[ $changeServerParams = true ]]
    then
        echo "start change server params"
        "$rac" cluster update --cluster="$clusterId" --lifetime-limit=$timeRestart --expiration-timeout=$timeRestart --kill-problem-processes=yes $rasServer
        #sleep 60
        echo "return server params"
        "$rac" cluster update --cluster="$clusterId" --lifetime-limit=0 --expiration-timeout=0 --kill-problem-processes=no $rasServer
    fi

    "$rac" infobase update --infobase=$infobaseId --infobase-user=$infobaseUser --infobase-pwd=$infobasePwd --cluster="$clusterId" --scheduled-jobs-deny=on $rasServer
    "$rac" infobase update --infobase=$infobaseId --infobase-user=$infobaseUser --infobase-pwd=$infobasePwd --cluster="$clusterId" --sessions-deny=on \
    --denied-message="$denniedMessage" --denied-from="" --permission-code="$permissionCode" $rasServer

    sleep 60

    sessions=$("$rac" session list --cluster="$clusterId" --infobase="$infobaseId" $rasServer | grep -w '^session\s' | awk '{print $3}')

    for session in $sessions
    do
        "$rac" session terminate --cluster="$clusterId" --session="$session" $rasServer
    done

fi

if [[ unlockInfobase = true ]]
then
    "$rac" infobase update --infobase=$infobaseId --infobase-user=$infobaseUser --infobase-pwd=$infobasePwd --cluster="$clusterId" --sessions-deny=off \
    --denied-message="" --denied-from="" --permission-code="" $rasServer
    "$rac" infobase update --infobase=$infobaseId --infobase-user=$infobaseUser --infobase-pwd=$infobasePwd --cluster="$clusterId" --scheduled-jobs-deny=off $rasServer
fi