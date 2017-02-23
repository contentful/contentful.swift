#!/bin/bash
# Run Swift specific api-coverage tests

if [[ "$TRAVIS_PULL_REQUEST" == "false" ]]; then
    echo "Not a pull request, skipping integration testing phase."    
    exit 0
fi

ENV='"REPO_SDK=swift REPO_SLUG='$TRAVIS_REPO_SLUG' REPO_COMMIT='$TRAVIS_COMMIT'"'

BODY="{
  \"request\": {
    \"message\": \"$TRAVIS_REPO_SLUG SDK Triggered Request\",
    \"branch\":\"travis_experiments\",
    \"config\": {\"env\": $ENV}
  }
}"

# api-coverage
curl -s -X POST \
	-d "$BODY" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json"   \
    -H "Travis-API-Version: 3"   \
    -H "Authorization: token $TRAVIS_TOKEN" \
    'https://api.travis-ci.com/repo/1336919/requests'

