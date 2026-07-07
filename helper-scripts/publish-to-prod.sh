#!/bin/bash

CALLING_DIR=$(dirname $0)

. $CALLING_DIR/publish-secrets.sh
echo $HOST_DIR

cd $CALLING_DIR/..
pwd

flutterfire configure --project=harbor-connect-prod --platforms=android,web --yes

flutter build apk --dart-define=APP_ENV=prod --release

flutter build appbundle --dart-define=APP_ENV=prod --release

flutter build web --dart-define=APP_ENV=prod --release


scp helper-scripts/apply-new-package.sh $HOST_SERVER:$HOST_DIR
scp -r build/web $HOST_SERVER:$HOST_DIR
ssh $HOST_SERVER $HOST_DIR/apply-new-package.sh


flutterfire configure --project=harbor-connect-dev --platforms=android,web --yes
