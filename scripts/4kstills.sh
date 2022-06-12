#! /bin/sh

# This script uses vlc to extract the images from a 4K burst.
#
# Usage: 4kstills dirname movie(s)
#
# Dirname may not exist and will be created.
# Resultant images will have several EXIF datums copied from the movie.
#
# Script requires vlc and exiftool.

path=$1; shift

# mkdir -p doesn't give errors if the dir exists.
if test -d $path ; then
    echo $path exists
    exit 1
fi
mkdir -p $path || exit

# Split into separate images.
vlc --ignore-config --no-qt-privacy-ask \
    --video-filter=scene \
    --scene-format=jpg \
    --scene-width=-1 \
    --scene-height=-1 \
    --scene-prefix=scene \
    --scene-path=$path \
    --no-scene-replace \
    --scene-ratio=1 \
    ${1+"$@"} vlc://quit

# Transfer exif data from mp4 to jpgs.
exiftool -TagsFromFile "$1" \
    -DateCreated -DateTimeOriginal -ModifyDate -CreateDate \
    -ExposureTime -FNumber -ExposureProgram -ISO -Scene \
    -CameraOrientation -FocalLength -Aperture -FocusMode \
    -WhiteBalance -Make -Model -MeteringMode \
    $path/scene*.jpg

# Remove unneeded files.
rm -f $path/scene*.jpg_original
