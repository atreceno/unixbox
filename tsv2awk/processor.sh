#!/bin/bash
# 
# Script to generate CSV files to import into mongodb
# 

# Create dist folder if it doesn't exist
if [ ! -d "dist" ]
then
  mkdir dist
fi

# Generate Sports
sport_file="14_discipline.txt"
if [ -f $sport_file ]
then
  echo "Generating dist/sports.tsv ..."
  tail -n +2 $sport_file | \
    awk 'BEGIN { print "code\tname"; }
    $4 = /N/ && $7 = /Y/ { FS="\t"; printf("%s\t%s\n",$1,$2); }
    END{}' > dist/sports.tsv
else
  echo "File $sport_file doesn't exist"
fi
wc -l dist/sports.tsv

# Generate Tournaments 
tournament_file="23_event.txt"
description="Dominus Quixotus senex erat cui placebat libros de equitibus legere."
location="London, UK"

# Random generation of dates
for i in {0..20}
do
  if [ $[ $i % 2 ] -eq "0" ]
  then
    dates[$i]=`date -v +$(jot -rn 1 1 15)d +%Y-%m-%d`
  else
    dates[$i]=`date -v -$(jot -rn 1 1 15)d +%Y-%m-%d`
  fi
done
dates=${dates[@]}

if [ -f $tournament_file ]
then
  echo "Generating dist/tournaments.tsv ..."
  tail -n +2 $tournament_file | \
    awk -v strdates="$dates" 'BEGIN { split(strdates,arrdates," "); FS="\t"; OFS="\t"; print "sport", "code", "name", "description", "location", "startDate"; }
    $2 != 0 && $3 != 000 { print $1, $1$2$3, $5, desc, loc, arrdates[NR%20 + 1]; }
    END{}' desc="$description" loc="$location" > dist/trn.tsv
else
  echo "File $tournament_file doesn't exist"
fi

# Substitute the Sport code in Tournaments
tail -n +2 dist/sports.tsv | \
awk 'BEGIN { print "#!/usr/bin/sed -f"; } 
  { FS="\t"; printf("s\/^%s\/%s\/1\n",$1,$2); }' > dist/tmp.sed
sed -f dist/tmp.sed < dist/trn.tsv > dist/tournaments.tsv
wc -l dist/tournaments.tsv
rm dist/tmp.sed dist/trn.tsv

# Another random way of counting CM events
#awk 'BEGIN { count=0; }
#$1 = /CM/ { count ++; }
#END { print "Total = ",count; }' 23_event.txt

# Import into MongoDB:
#/usr/local/mongodb/bin/mongoimport -h ds059957.mongolab.com:59957 -d stadion -c sports -u $username -p --file dist/sports.tsv --type tsv --headerline
#/usr/local/mongodb/bin/mongoimport -h ds059957.mongolab.com:59957 -d stadion -c tournaments -u $username -p --file dist/tournaments.tsv --type tsv --headerline
