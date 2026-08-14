# goto fxa-dev-launcher's temp profile folder (default ~/tmp)
inotifywait -m -e create . |  while read a b file; do echo "output"  $a  $b $file ; sleep 2 && certutil -A  -d  $file  -n fxaroot -t "C,," -i path_of_your_generated_rootCA.crt ; done
