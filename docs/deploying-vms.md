Deploying Vms using spiceweasel
===============================
You can deploy all the common vms by running
    spiceweasel common-infrastructure.yml

To delete all the vms in common-infrastructure.yml
    spiceweasel -d common-infrastructure.yml

To see what these commands will run without execting the commands add a
--dryrun option to spiceweasel for example
    spiceweasel --dryrun common-infrastructure.yml
