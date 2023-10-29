#!/bin/bash

HOST=https://weblate.libra-app.eu
TOKEN=a secret token
PROJECT=tudo
COMPONENT=app
TEMP_FILE=translations.zip

# Upload current version of base language
curl -X POST \
  -H "Authorization: Token $TOKEN" \
  $HOST/api/translations/$PROJECT/$COMPONENT/en/file/ \
  -F file=@l10n/app_en.arb \
  -F method=replace

# Download latest translations
curl \
  -H "Authorization: Token $TOKEN" \
  $HOST/api/components/$PROJECT/$COMPONENT/file/ \
  -o $TEMP_FILE

# Unzip file on top of existing files
# o overwrite without prompting
# j do not create subdirs
unzip -oj -d l10n translations.zip

# Delete zip
rm $TEMP_FILE
