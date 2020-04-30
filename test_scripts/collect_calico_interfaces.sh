rm /tmp/flask-containers
rm /tmp/flask-containers-pids
rm /tmp/pods-virtual-ethernet-interfaces
rm /tmp/pods-virtual-ethernet-interface
rm /tmp/pod-interface-on-node
rm /tmp/ifconfig-dump

crictl ps | grep flask- | cut -d " " -f1 >> /tmp/flask-containers

containers="/tmp/flask-containers"
while IFS= read -r container
do
  crictl inspect $container -o json | grep pid | head -n 1 | gawk '{print $(NF)}' | rev | cut -c 2- | rev >> /tmp/flask-containers-pids
done < "$containers"

pids="/tmp/flask-containers-pids"
while IFS= read -r pid
do
  nsenter -t $pid -n ip addr | head -n 7 | tail -1 >> /tmp/pods-virtual-ethernet-interfaces
done < "$pids"

awk '{ print $2 }' /tmp/pods-virtual-ethernet-interfaces  | sed 's/:.*//' | sed 's/:.*//' | cut -d'f' -f 2 >> /tmp/pods-virtual-ethernet-interface

interface="/tmp/pods-virtual-ethernet-interface"
while IFS= read -r pvif
do
  ip addr | grep "^$pvif" >> /tmp/pod-interface-on-node
done < "$interface"

rm /tmp/pod-interfaces
awk '{ print $2 }' /tmp/pod-interface-on-node | sed 's/@.*//' >> /tmp/pod-interfaces

interfaces="/tmp/pod-interfaces"
while IFS= read -r pvif
do
  ip -s link show $pvif >> /tmp/ifconfig-dump
done < "$interfaces"
