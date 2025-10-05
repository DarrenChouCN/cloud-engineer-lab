## Terraform Graph
```bash
terraform graph
apt install graphviz
terraform graph | dot -Tsvg > graph.svg
```
 
## Saving Terraform Plan to File
```bash
terraform plan -out=infra.plan
terraform apply infra.plan

terraform show infra.plan
terraform show -json infra.plan

terraform show -json infra.plan | jq
```

## Resource Targeting
```bash
terraform plan -target local_file.foo
terraform apply -target local_file.foo
terraform destroy -target local_file.foo
```


## Dealing with Large Infrastructure
```bash
terraform plan -refresh=false
```