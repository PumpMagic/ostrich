pushd $OSTRICH_PATH

buildsucceeded=false

while [ "$buildsucceeded" != "true" ]
do
    xcodebuild -scheme ostrich clean
    xcodebuild -scheme ostrich build
    if [ $? == "0" ]
    then
        buildsucceeded=true
    fi
done

popd
