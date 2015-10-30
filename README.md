## Internal Applications Visualizations

This project is intended to capture the means for producing [Gource](http://gource.io/) videos of the projects that Internal Applications manages.

### Requirements

1. A reasonable shell with sed, cat, and sort.
2. [Gource](http://gource.io/)
3. [ffmpeg](https://www.ffmpeg.org/)

The latter 2 are easily installed on a Mac using [Homebrew](http://brew.sh)

### Creating the combined git log

1. Clone locally each repository you want to include.
2. Run the command `gource --output-custom-log repo-name.txt repo-name` for each repo-name.
3. Mutate the output with sed to include the repo-name in the path using `sed -i -r "s#\(.+\)\|#\1|/repo-name#" repo-name.txt`. This command doesn't work for OS X, you need to use this instead: `sed "s/\|\//\|\/repo-name\//" repo-name.txt > repo-name.edited.txt`. Look at star.txt and star.edited.txt to see an example of the difference.
4. Cat all the logs together with `cat repo-name1.txt repo-name2.txt | sort -n > combined.txt`

Feed the file `combined.txt` into the command listed below.

### Creating the video

Sample command, won't save anything:

> gource attempt5.txt -s 0.25 --highlight-users --highlight-dirs -1600x1080 --user-image-dir avatars/ --file-extensions --user-scale 2 --bloom-intensity 0.5 --hide dirnames --start-date '2014-06-01'

Tack on a `-o filename.ppm` to save the output in raw ppm format.

To convert the ppm to an mp4 video:

> ffmpeg -y -r 60 -f image2pipe -vcodec ppm -i filename.ppm -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -crf 1 -threads 0 -bf 0 filename.mp4

### References

* https://code.google.com/p/gource/wiki/Videos
* https://code.google.com/p/gource/wiki/GourceMashups