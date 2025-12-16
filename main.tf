## Problems encountered

#1 before you start the cluster make sure the cloudwatch log is disabled on aws consul or you can just check the name of the cluster in locals and also in in the create bucket.sh
#2 check if you have deleted the previously created cluster-autoscaler or you can just remain it
# you need to run terraform apply twice because of the metric server
