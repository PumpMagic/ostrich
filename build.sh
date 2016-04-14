pushd $OSTRICH_PATH

buildsucceeded=false

while [ "$buildsucceeded" != "true" ]
do
    xcodebuild -scheme audiotest clean
    xcodebuild -scheme audiotest build
    if [ $? == "0" ]
    then
        buildsucceeded=true
    fi
done

popd
