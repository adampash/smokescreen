#!/bin/bash
# open Chrome in kiosk mode
open "/Applications/Google Chrome Canary.app" --args --kiosk https://smokescreen.dev

# fire up the face detection app
cd ~/code/learning/face_det
ruby app.rb -p 3000
