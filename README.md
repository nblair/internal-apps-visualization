## Internal Applications Visualizations

This project is intended to capture the means for producing [Gource](http://gource.io/) videos of the projects that Internal Applications manages.

### Requirements

1. A reasonable shell with sed, cat, sort, grep, and curl.
2. git
3. [Gource](http://gource.io/)
4. [jq](https://stedolan.github.io/jq/)
5. [ffmpeg](https://www.ffmpeg.org/)

The latter 2 are easily installed on a Mac using [Homebrew](http://brew.sh)

### Configuration

Copy the provided `config.sample` file to `config` and populate the GitLab properties. You'll need to create a personal access token to access the GitLab API.

### Creating the combined git log

A shell script is provided to generate the file that gource will consume.

1. Start by creating a text file that on each line contains 2 fields: the group and the repository name in our git repository. Example:
```
adi-ia star
adi-ia wisclist-custom
wams-java caos-schemas
```
2. Execute the provided script:
```bash
g.sh yourfilename.txt
```

The script will clone each repository (via ssh), produce the gource output, then concatenate/sort it all as `yourfilename.txt.log`.

### Creating the video

Sample command, won't save anything:

```
gource archive/projects.2016-09.txt.log -s 0.25 --highlight-users --highlight-dirs -1600x1080 --user-image-dir workdir/avatars/ --file-extensions --user-scale 2 --bloom-intensity 0.5 --hide dirnames --camera-mode overview --start-date '2016-03-01'
```

Tack on a `-o filename.ppm` to save the output in raw ppm format.

To convert the ppm to an mp4 video:

> ffmpeg -y -r 60 -f image2pipe -vcodec ppm -i filename.ppm -vcodec libx264 -preset ultrafast -pix_fmt yuv420p -crf 1 -threads 0 -bf 0 filename.mp4

### References

* https://code.google.com/p/gource/wiki/Videos
* https://code.google.com/p/gource/wiki/GourceMashups
