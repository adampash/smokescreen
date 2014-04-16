#!/bin/bash
# open Chrome in kiosk mode with no extensions
open "/Applications/Google Chrome Canary.app" --args --enable-kiosk-mode --kiosk https://smokescreen.dev

# fire up the face detection app
cd ~/code/learning/face_det
ruby app.rb -p 3000

# run tunnelss
# rvmsudo tunnelss

