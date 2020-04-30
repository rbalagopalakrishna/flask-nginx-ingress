rm paths.txt

for i in {1..1000}
do
  echo http://$1/nginx-ingress-flask-$i >> paths.txt
done
