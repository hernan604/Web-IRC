CMD="packer build -only=arch.amd64.virtualbox arch-template.json"
echo EXECUTING: $CMD
$CMD
