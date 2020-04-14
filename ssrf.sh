#!/bin/bash

red=`tput setaf 1`
reset=`tput sgr0`

logo(){
 echo "${red}

          ____________________  __   ________________________________
          __  ____/__    |_  / / /   __  ___/_  ___/__  __ \__  ____/
          _  / __ __  /| |  / / /    _____ \_____ \__  /_/ /_  /_
          / /_/ / _  ___ / /_/ /     ____/ /____/ /_  _, _/_  __/
          \____/  /_/  |_\____/      /____/ /____/ /_/ |_| /_/



${reset}"
}

killit(){
        logo
        echo "Usage : ./ssrf.sh domain.com"
        echo "Usage : ./ssrf.sh domain.com -o output_directory"
        echo "Usage : ./ssrf.sh domain.com --output output_directory"
        exit 1
}

recon(){
logo

##Getting SubDomains
echo -e "\nRUNNING \e[31m[assetfinder]\e[0m"
assetfinder --subs-only $1 > $output_directory/$1/$1.assetfinder.txt
cat $output_directory/$1/$1.assetfinder.txt | sort -u > $output_directory/$1/subs.txt
echo "FOUND SUBDOMAINS [$(cat $output_directory/$1/subs.txt | wc -l)]"
echo -e "RUNNING ASSETFINDER \e[32mFINISH\e[0m"

##Starting GETALLURLS
echo -e "\nRUNNING \e[31m[GAU]\e[0m"
cat  $output_directory/$1/subs.txt | gau > $output_directory/$1/$1.urls.txt
echo -e "RUNNING GAU \e[32mFINISH\e[0m"

echo "${red} ---------------COLLECTED URLS OF SUBDOMAINS--------------- ${reset}"

##Checking urls with anti-burl
echo -e "\nRUNNING \e[31m[anti-burl]\e[0m"
cat $output_directory/$1/$1.urls.txt | grep "=http" | anti-burl | tee $output_directory/$1/$1.urls_with_params.txt

echo -e "RUNNING Anti-burl \e[32mFINISH\e[0m"

##Cleaning the list for urls
echo -e "\nCleaning \e[31m[LIST]\e[0m"
cat $output_directory/$1/$1.urls_with_params.txt | sed 's/[^http]*\(http.*\)/\1/' > $output_directory/$1/$1.ssrf_testing.txt
echo "FOUND POSSIBLE SSRF URLS [$(cat $output_directory/$1/$1.ssrf_testing.txt | wc -l)]"
echo -e "Cleaning list \e[32mFINISH\e[0m"

##FUZZ
echo -e "\nHope You Have Added Burp Collab Url In burp.txt Fuzzing\e[31m[LIST]\e[0m"
cat $output_directory/$1/$1.ssrf_testing.txt | qsreplace FUZZ > $output_directory/$1/fuzzable.txt
cat $output_directory/$1/fuzzable.txt | while read url;do ffuf -w ./burp.txt -u "$url" -v;done
echo "${red} --------------DONE---------------- ${reset}"
}

if [[ -z "$1" || $1 == "-h" || $1 == "--help" ]]
        then
                killit
elif [[ $2 == "-o" || $2 == "--output" ]]
then
  output_directory="$3/gaussrf/recon/"
  mkdir -p "$output_directory"/"$1"
  recon $1
else
  output_directory="recon"
  mkdir -p "$output_directory"/"$1"
  recon $1
fi
