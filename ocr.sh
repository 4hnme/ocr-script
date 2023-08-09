#!/bin/sh

# get list of supported languages and choose it by dmenu
# see https://github.com/tesseract-ocr/tesseract for more info
language=$(tesseract --list-langs | sed '1d' |
  # create combinations of all possible languages, taken from: https://stackoverflow.com/questions/68178062/how-to-generate-all-possible-combinations-of-lines-in-a-file-using-bash
  awk -v FS=+ '{ a[NR]=$1 }
    END { for (i=0; i<2^NR; i++)
      { s="";
        for (j=0; j<NR; j++)
          { e=and(i, 2^j);
          printf "%s", e?s a[j+1]:""; if (e)s=FS }
        print comb } }' |
  dmenu -p "languages: ")
# language=$(tesseract --list-langs | sed '1d' | dmenu -p "language: ")

if [[ $language == "" ]]; then
  echo "error: no input provided"
else
  # capturing the image and temporarily saving it
  maim --quiet --select /tmp/ocr.png

  # checking for brightness by compressing grayscale version of captured image to 1x1
  # tesseract works better with black text on white background
  brightness=$(convert /tmp/ocr.png -colorspace gray -resize 1x1 txt:- | grep -Po 'a\(\K[0-9]*') 

  if [[ $brightness < 50 ]]; then
    # convert image to negative if it's dark and pass it to tesseract
    output=$(convert /tmp/ocr.png -channel RGB -negate - | tesseract - stdout -l $language --oem 1)
  else
    # else pass to tesseract as is
    output=$(tesseract /tmp/ocr.png stdout -l $language --oem 1)
  fi

  if [[ $output == "" ]]; then
    echo "error: selection was cancelled"
  else
    # open transcribed text in your editor of choice
    $TERMINAL -e $SHELL -c "echo '$output' | $EDITOR"
    # $TERMINAL --title="Tesseract OCR" -e $SHELL -c "echo '$output' | $EDITOR"
    #                 ^
    #     works only for Alacritty
  fi

  # removing temporary image we created earlier
  rm /tmp/ocr.png
fi
