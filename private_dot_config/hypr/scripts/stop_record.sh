
#!/bin/bash

# Kill the ffmpeg process
pkill -x wf-recorder

notify-send -i camera-video "wf-recorder" "Recording stopped"
