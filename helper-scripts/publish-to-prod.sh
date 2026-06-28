#!/bin/bash

flutterfire configure --project=harbor-connect-prod --platforms=android,web --yes

flutter build apk --dart-define=APP_ENV=prod --release


flutterfire configure --project=harbor-connect-dev --platforms=android,web --yes
